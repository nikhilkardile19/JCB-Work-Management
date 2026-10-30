import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';
import 'package:jcb_work_management/features/sync/data/remote_store.dart';
import 'package:jcb_work_management/features/sync/data/sync_engine.dart';

import '../helpers/fake_http.dart';
import '../helpers/pump_app.dart' show memoryDatabase;

void main() {
  late ApiHarness h;
  late HttpRemoteStore store;

  setUp(() async {
    h = ApiHarness();
    store = HttpRemoteStore(h.api);
    await h.signIn();
  });

  Future<PushResult> push({int? baseRev = 3, bool force = false}) => store.push(
    companyId: 'co',
    collection: 'workLogs',
    id: 'w1',
    data: const {'id': 'w1', 'endMeter': 800},
    baseRev: baseRev,
    userId: 'u1',
    deviceId: 'phone-9',
    force: force,
  );

  group('push', () {
    test('accepted', () async {
      h.http.handler = (r) => const FakeReply(200, {'rev': 4});
      final result = await push();
      expect(result, isA<PushAccepted>().having((r) => r.rev, 'rev', 4));
      final put = h.http.requests.single;
      expect('$put', 'PUT /companies/co/sync/workLogs/w1');
      expect(put.headers['x-device-id'], 'phone-9');
      expect(put.json, {
        'baseRev': 3,
        'data': {'id': 'w1', 'endMeter': 800},
      });
    });

    test(
      'a new record, or one missing on the server, has no base revision',
      () async {
        h.http.handler = (r) => const FakeReply(200, {'rev': 1});
        await push(baseRev: null);
        await push(baseRev: 0);
        expect(h.http.requests.map((r) => r.json['baseRev']), [null, null]);
      },
    );

    test('revision mismatch is a conflict with the server copy', () async {
      h.http.handler = (r) => FakeReply.error(
        409,
        'conflict',
        extra: {
          'serverRev': 5,
          'serverData': {'id': 'w1', 'endMeter': 900, 'rev': 5},
        },
      );
      final result = await push();
      expect(
        result,
        isA<PushConflict>().having((r) => r.serverRev, 'serverRev', 5).having(
          (r) => r.serverData,
          'serverData',
          {'id': 'w1', 'endMeter': 900},
        ),
      );
    });

    test('a refused record is rejected with the server message', () async {
      for (final reply in [
        FakeReply.error(403, 'permission_denied', message: 'Role matrix.'),
        FakeReply.error(400, 'invalid_argument', message: 'Role matrix.'),
        FakeReply.error(404, 'not_found', message: 'Role matrix.'),
        FakeReply.error(409, 'already_exists', message: 'Role matrix.'),
      ]) {
        h.http.handler = (r) => reply;
        expect(
          await push(),
          isA<PushRejected>().having(
            (r) => r.message,
            'message',
            'Role matrix.',
          ),
          reason: '${reply.status}',
        );
      }
    });

    test(
      'a whole-pass refusal throws instead of rejecting the record',
      () async {
        for (final reason in HttpRemoteStore.passRefusals) {
          h.http.handler = (r) => FakeReply.error(
            403,
            'permission_denied',
            message: 'No access.',
            reason: reason,
          );
          await expectLater(push(), throwsA(isA<SyncUnavailable>()));
        }
      },
    );

    test('network, 5xx and 429 are SyncUnavailable', () async {
      for (final handler in <FakeHandler>[
        (r) => throw const Offline(),
        (r) => throw const TimedOut(),
        (r) => FakeReply.error(503, 'unavailable'),
        (r) => FakeReply.error(429, 'resource_exhausted'),
      ]) {
        h.http.handler = handler;
        await expectLater(push(), throwsA(isA<SyncUnavailable>()));
      }
    });

    test('force is refused: the server never overwrites silently', () async {
      await expectLater(push(force: true), throwsArgumentError);
      expect(h.http.requests, isEmpty);
    });
  });

  group('pull', () {
    test('maps items to documents with their cursors', () async {
      h.http.handler = (r) => const FakeReply(200, {
        'items': [
          {
            'id': 'c1',
            'rev': 2,
            'cursor': '41|c1',
            'data': {'id': 'c1', 'name': 'Patil', 'rev': 2},
          },
          {
            'id': 'c2',
            'rev': 1,
            'cursor': '42|c2',
            'data': {'id': 'c2', 'name': 'Shinde'},
          },
        ],
      });
      final docs = await store.pull(
        companyId: 'co',
        collection: 'clients',
        after: const SyncCursor(40, 'c0'),
        limit: 200,
      );
      final get = h.http.requests.single;
      expect('$get', 'GET /companies/co/sync/clients');
      expect(get.query, {'after': '40|c0', 'limit': '200'});
      expect(docs.map((d) => (d.id, d.rev, d.cursor.encode())), [
        ('c1', 2, '41|c1'),
        ('c2', 1, '42|c2'),
      ]);
      expect(docs.first.data, {'id': 'c1', 'name': 'Patil'});
      expect(docs.first.cursor.position, 41);
    });

    test('first pull has no cursor', () async {
      h.http.handler = (r) => const FakeReply(200, {'items': <Object>[]});
      await store.pull(
        companyId: 'co',
        collection: 'clients',
        after: null,
        limit: 50,
      );
      expect(h.http.requests.single.query, {'limit': '50'});
    });

    test('403 means nothing to download', () async {
      h.http.handler = (r) => FakeReply.error(403, 'permission_denied');
      expect(
        await store.pull(
          companyId: 'co',
          collection: 'invoices',
          after: null,
          limit: 200,
        ),
        isEmpty,
      );
    });

    test('unreachable server is SyncUnavailable', () async {
      h.http.offline = true;
      await expectLater(
        store.pull(
          companyId: 'co',
          collection: 'clients',
          after: null,
          limit: 200,
        ),
        throwsA(isA<SyncUnavailable>()),
      );
    });
  });

  test('sync engine: a whole-pass refusal keeps records pending', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await MastersRepository(db).save(
      MasterKind.clients,
      const MasterScope(companyId: 'co', userId: 'u1'),
      {'name': 'Patil'},
    );
    h.http.handler = (r) => FakeReply.error(
      403,
      'permission_denied',
      reason: 'device_not_licensed',
    );

    await expectLater(
      SyncEngine(
        db,
        store,
      ).run(companyId: 'co', userId: 'u1', canViewBilling: true),
      throwsA(isA<SyncUnavailable>()),
    );
    final client = await db.select(db.clients).getSingle();
    expect(client.syncStatus, 'pending');
    expect(await db.select(db.syncRecords).get(), isEmpty);
  });
}
