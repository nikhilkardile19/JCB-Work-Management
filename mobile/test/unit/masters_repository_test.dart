import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';

import '../helpers/pump_app.dart';

void main() {
  late AppDatabase db;
  late MastersRepository repo;
  var now = DateTime.utc(2026, 10, 29, 9);
  const a = MasterScope(companyId: 'co-a', userId: 'u1');
  const b = MasterScope(companyId: 'co-b', userId: 'u2');

  setUp(() {
    db = memoryDatabase();
    now = DateTime.utc(2026, 10, 29, 9);
    repo = MastersRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<List<MasterRecord>> list(
    MasterKind k,
    MasterScope s, {
    String search = '',
    StatusFilter status = StatusFilter.active,
    String? clientId,
  }) => repo
      .watchList(
        k,
        s.companyId,
        search: search,
        status: status,
        clientId: clientId,
      )
      .first;

  Future<String> client(String name, {MasterScope scope = a}) => repo.save(
    MasterKind.clients,
    scope,
    {'name': name, 'phone': '9876543210'},
  );

  group('create and read', () {
    test('stores fields with sync and audit metadata', () async {
      final id = await client('  Patil Constructions ');
      final r = (await list(MasterKind.clients, a)).single;
      expect(r.id, id);
      expect(r.name, 'Patil Constructions');
      expect(r['phone'], '9876543210');
      expect(r.isActive, isTrue);
      expect(r.syncStatus, 'pending');
      expect(r.version, 1);
      expect(r['createdBy'], 'u1');
      expect(r['companyId'], 'co-a');
      expect(r.updatedAt, now.millisecondsSinceEpoch);

      final audit = await db.select(db.auditLogs).get();
      expect(audit.single.action, 'create');
      expect(audit.single.entityType, 'clients');
      expect(audit.single.companyId, 'co-a');
    });

    test('machines store meter reading as hundredths', () async {
      await repo.save(MasterKind.machines, a, {
        'name': 'JCB 3DX',
        'registrationNumber': 'MH12AB1234',
        'initialMeterReading': 123450,
      });
      final m = (await list(MasterKind.machines, a)).single;
      expect(m['initialMeterReading'], 123450);
      expect(m['meterUnit'], 'hours');
    });

    test('every master kind round-trips', () async {
      final cid = await client('C');
      final samples = {
        MasterKind.sites: {
          'clientId': cid,
          'name': 'Hinjewadi',
          'defaultHourlyRatePaise': 150000,
        },
        MasterKind.operators: {'name': 'Suresh', 'code': 'OP-1'},
        MasterKind.petrolPumps: {'name': 'HP Wakad', 'address': 'Wakad'},
      };
      for (final e in samples.entries) {
        await repo.save(e.key, a, e.value);
        expect(
          (await list(e.key, a)).single.name,
          e.value['name'],
          reason: e.key.name,
        );
      }
    });
  });

  group('tenant isolation', () {
    test('lists, reads and writes are scoped to the company', () async {
      final id = await client('Alpha', scope: a);
      await client('Beta', scope: b);
      expect((await list(MasterKind.clients, a)).map((r) => r.name), ['Alpha']);
      expect(await repo.watchOne(MasterKind.clients, 'co-b', id).first, isNull);
      await expectLater(
        repo.setActive(MasterKind.clients, b, id, active: false),
        throwsStateError,
      );
      await expectLater(
        repo.save(MasterKind.clients, b, {'name': 'Hijack'}, id: id),
        throwsStateError,
      );
      expect((await list(MasterKind.clients, a)).single.isActive, isTrue);
    });

    test('same name is allowed in different companies', () async {
      await client('Same', scope: a);
      await expectLater(client('Same', scope: b), completes);
    });

    test('a site cannot link to another company\'s client', () async {
      final foreign = await client('Foreign', scope: b);
      await expectLater(
        repo.save(MasterKind.sites, a, {'clientId': foreign, 'name': 'S'}),
        throwsA(
          isA<MasterSaveException>().having(
            (e) => e.fieldErrors.keys,
            'fields',
            contains('clientId'),
          ),
        ),
      );
    });
  });

  group('validation and duplicates', () {
    test('required fields are enforced', () async {
      await expectLater(
        repo.save(MasterKind.machines, a, {'name': ' '}),
        throwsA(
          isA<MasterSaveException>().having(
            (e) => e.fieldErrors.keys,
            'fields',
            containsAll(['name', 'initialMeterReading']),
          ),
        ),
      );
    });

    test('duplicate names are rejected case-insensitively', () async {
      await client('Patil Constructions');
      await expectLater(
        client('PATIL constructions'),
        throwsA(
          isA<MasterSaveException>().having(
            (e) => e.fieldErrors['name'],
            'name',
            contains('already exists'),
          ),
        ),
      );
    });

    test('editing a record keeps its own name', () async {
      final id = await client('Alpha');
      await expectLater(
        repo.save(MasterKind.clients, a, {
          'name': 'Alpha',
          'phone': '9000000000',
        }, id: id),
        completes,
      );
    });

    test('site names are unique per client, not per company', () async {
      final c1 = await client('C1');
      final c2 = await client('C2');
      await repo.save(MasterKind.sites, a, {
        'clientId': c1,
        'name': 'Main yard',
      });
      await expectLater(
        repo.save(MasterKind.sites, a, {'clientId': c2, 'name': 'Main yard'}),
        completes,
      );
      await expectLater(
        repo.save(MasterKind.sites, a, {'clientId': c1, 'name': 'main YARD'}),
        throwsA(isA<MasterSaveException>()),
      );
    });

    test('duplicate machine registration is rejected', () async {
      await repo.save(MasterKind.machines, a, {
        'name': 'M1',
        'registrationNumber': 'MH12AB1234',
        'initialMeterReading': 0,
      });
      await expectLater(
        repo.save(MasterKind.machines, a, {
          'name': 'M2',
          'registrationNumber': 'MH12AB1234',
          'initialMeterReading': 0,
        }),
        throwsA(
          isA<MasterSaveException>().having(
            (e) => e.fieldErrors.keys,
            'fields',
            ['registrationNumber'],
          ),
        ),
      );
    });
  });

  group('search and filters', () {
    setUp(() async {
      await client('Patil Constructions');
      await client('Shinde Infra');
      final id = await client('Old Client');
      await repo.setActive(MasterKind.clients, a, id, active: false);
    });

    test('status filter', () async {
      expect((await list(MasterKind.clients, a)).length, 2);
      expect(
        (await list(
          MasterKind.clients,
          a,
          status: StatusFilter.inactive,
        )).single.name,
        'Old Client',
      );
      expect(
        (await list(MasterKind.clients, a, status: StatusFilter.all)).length,
        3,
      );
    });

    test(
      'search is case-insensitive, sorted, and treats % and _ literally',
      () async {
        expect(
          (await list(MasterKind.clients, a, search: 'patil')).single.name,
          'Patil Constructions',
        );
        expect(
          (await list(
            MasterKind.clients,
            a,
            search: 'I',
            status: StatusFilter.all,
          )).map((r) => r.name),
          ['Old Client', 'Patil Constructions', 'Shinde Infra'],
        );
        expect(await list(MasterKind.clients, a, search: '%'), isEmpty);
        expect(await list(MasterKind.clients, a, search: '_'), isEmpty);
      },
    );

    test('active count', () async {
      expect(await repo.watchActiveCount(MasterKind.clients, 'co-a').first, 2);
      expect(await repo.watchActiveCount(MasterKind.clients, 'co-b').first, 0);
    });

    test('sites filter by client', () async {
      final c = (await list(MasterKind.clients, a)).first.id;
      final other = (await list(MasterKind.clients, a)).last.id;
      await repo.save(MasterKind.sites, a, {'clientId': c, 'name': 'S1'});
      await repo.save(MasterKind.sites, a, {'clientId': other, 'name': 'S2'});
      expect((await list(MasterKind.sites, a, clientId: c)).single.name, 'S1');
    });
  });

  group('updates, activation, deletion', () {
    test('update bumps version, marks pending and audits the diff', () async {
      final id = await client('Alpha');
      now = now.add(const Duration(hours: 1));
      await repo.save(
        MasterKind.clients,
        b.companyId == 'x'
            ? b
            : const MasterScope(companyId: 'co-a', userId: 'u9'),
        {'name': 'Alpha Infra', 'phone': '9876543210'},
        id: id,
      );
      final r = (await list(MasterKind.clients, a)).single;
      expect(r.name, 'Alpha Infra');
      expect(r.version, 2);
      expect(r['updatedBy'], 'u9');
      expect(r['createdBy'], 'u1');
      expect(r.updatedAt, now.millisecondsSinceEpoch);
      final audit = await (db.select(
        db.auditLogs,
      )..where((t) => t.action.equals('update'))).getSingle();
      final details = jsonDecode(audit.details!) as Map<String, dynamic>;
      expect(details.keys, ['name']);
      expect(details['name'], {'from': 'Alpha', 'to': 'Alpha Infra'});
    });

    test('deactivate and reactivate', () async {
      final id = await client('Alpha');
      await repo.setActive(MasterKind.clients, a, id, active: false);
      await repo.setActive(MasterKind.clients, a, id, active: false); // no-op
      final r = (await list(
        MasterKind.clients,
        a,
        status: StatusFilter.all,
      )).single;
      expect(r.isActive, isFalse);
      expect(r.version, 2);
      await repo.setActive(MasterKind.clients, a, id, active: true);
      final actions = (await db.select(db.auditLogs).get()).map(
        (l) => l.action,
      );
      expect(actions, ['create', 'deactivate', 'activate']);
    });

    test('client with sites cannot be deleted', () async {
      final id = await client('Alpha');
      await repo.save(MasterKind.sites, a, {'clientId': id, 'name': 'S1'});
      expect(await repo.referenceCount(MasterKind.clients, 'co-a', id), 1);
      await expectLater(
        repo.delete(MasterKind.clients, a, id),
        throwsA(
          isA<MasterInUseException>().having(
            (e) => e.message,
            'msg',
            contains('Deactivate'),
          ),
        ),
      );
      expect(await list(MasterKind.clients, a), hasLength(1));
    });

    test(
      'unreferenced record is deleted as a pending-sync tombstone',
      () async {
        final id = await client('Temp');
        await repo.delete(MasterKind.clients, a, id);
        expect(
          await list(MasterKind.clients, a, status: StatusFilter.all),
          isEmpty,
        );
        final row = await (db.select(
          db.clients,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(row.deletedAt, isNotNull);
        expect(row.syncStatus, 'pending');
        expect(row.version, 2);
        // Name becomes reusable.
        await expectLater(client('Temp'), completes);
      },
    );

    test('a deleted site frees its client for deletion', () async {
      final id = await client('Alpha');
      final site = await repo.save(MasterKind.sites, a, {
        'clientId': id,
        'name': 'S1',
      });
      await repo.delete(MasterKind.sites, a, site);
      await expectLater(repo.delete(MasterKind.clients, a, id), completes);
    });
  });
}
