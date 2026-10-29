import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';
import 'package:jcb_work_management/features/work/data/work_log_repository.dart';
import 'package:jcb_work_management/features/work/domain/work_log.dart';

import '../helpers/pump_app.dart';

const co = 'co1';

Future<TestHarness> pumpSync(WidgetTester tester) async {
  final h = TestHarness.signedIn(
    companies: [membership(co, 'Sai Earthmovers')],
  );
  await MastersRepository(h.db).save(
    MasterKind.clients,
    const MasterScope(companyId: co, userId: 'x'),
    {'name': 'Patil'},
  );
  await pumpApp(tester, harness: h);
  return h;
}

Future<void> openSync(WidgetTester tester) async {
  await tapTab(tester, 'More');
  await tapAndSettle(tester, find.byKey(const Key('more_sync')));
}

void main() {
  testWidgets(
    'pending changes upload with Sync now; dashboard shows the state',
    (tester) async {
      final h = await pumpSync(tester);
      expect(find.text('Pending sync'), findsOneWidget);
      await openSync(tester);
      expect(find.textContaining('waiting to upload'), findsOneWidget);
      expect(find.text('Not synced yet'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('sync_now')));
      expect(
        find.text('Everything on this phone is on the server.'),
        findsOneWidget,
      );
      expect(find.textContaining('Last synced'), findsOneWidget);
      expect(find.text('1 synced'), findsWidgets);
      expect(h.server.count(co, 'clients'), 1);
      expect(find.text('Synced'), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('server unreachable: work stays safe and is reported', (
    tester,
  ) async {
    final h = await pumpSync(tester);
    h.server.offline = true;
    await openSync(tester);
    await tapAndSettle(tester, find.byKey(const Key('sync_now')));
    expect(find.textContaining('Could not reach the server'), findsOneWidget);
    expect(find.textContaining('waiting to upload'), findsOneWidget);
    expect(await h.db.select(h.db.clients).get(), hasLength(1));
    await unmount(tester);
  });

  testWidgets(
    'conflicting work log is shown and resolved with the server version',
    (tester) async {
      final h = await pumpSync(tester);
      final m = MastersRepository(h.db);
      const s = MasterScope(companyId: co, userId: 'x');
      final client = (await h.db.select(h.db.clients).getSingle()).id;
      final site = await m.save(MasterKind.sites, s, {
        'clientId': client,
        'name': 'Yard',
      });
      final machine = await m.save(MasterKind.machines, s, {
        'name': 'JCB',
        'initialMeterReading': 0,
      });
      const owner = WorkActor(
        companyId: co,
        userId: 'x',
        role: CompanyRole.owner,
      );
      WorkLogInput input(int end) => WorkLogInput(
        workDate: '2026-10-29',
        clientId: client,
        siteId: site,
        machineId: machine,
        start: const MeterCapture(reading: 0),
        end: MeterCapture(reading: end),
        manualReason: 'x',
      );
      final repo = WorkLogRepository(h.db);
      final (id, _) = await repo.submit(owner, input(800));
      await openSync(tester);
      await tapAndSettle(tester, find.byKey(const Key('sync_now')));

      h.server.simulateRemoteEdit(co, 'workLogs', id, {
        'endReading': 900,
        'workingHours': 900,
      });
      // Repository reads use stream queries: run them on the real clock.
      await tester.runAsync(
        () => repo.correct(owner, id, input(950), reason: 'mine'),
      );
      await tapAndSettle(tester, find.byKey(const Key('sync_now')));
      expect(find.text('Needs your attention'), findsOneWidget);
      expect(find.byKey(Key('sync_issue_$id')), findsOneWidget);
      expect(
        find.textContaining('Changed on this phone and on another device'),
        findsOneWidget,
      );

      await tapAndSettle(tester, find.byKey(const Key('sync_use_server')));
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, 'Use server version'),
      );
      expect(find.text('Needs your attention'), findsNothing);
      final after = await tester.runAsync(() => repo.watchOne(co, id).first);
      expect(after!.end.reading, 900);
      await unmount(tester);
    },
  );

  testWidgets('refused change shows the reason and can be retried', (
    tester,
  ) async {
    final h = await pumpSync(tester);
    h.server.rejectCollections.add('clients');
    await openSync(tester);
    await tapAndSettle(tester, find.byKey(const Key('sync_now')));
    expect(find.text('Refused by server rules'), findsOneWidget);
    h.server.rejectCollections.clear();
    await tapAndSettle(tester, find.byKey(const Key('sync_retry')));
    expect(find.text('Needs your attention'), findsNothing);
    expect(h.server.count(co, 'clients'), 1);
    await unmount(tester);
  });
}
