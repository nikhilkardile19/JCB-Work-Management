import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';
import 'package:jcb_work_management/features/work/data/work_log_repository.dart';
import 'package:jcb_work_management/features/work/domain/work_log.dart';
import 'package:jcb_work_management/features/work/presentation/work_logs_screen.dart';

import '../helpers/pump_app.dart';

const company = 'co1';

class Seed {
  late String client, site, machine, operator;
}

/// Masters for one client/site/machine (meter at 1000 h) and an operator.
Future<Seed> seedMasters(AppDatabase db) async {
  final repo = MastersRepository(db);
  const s = MasterScope(companyId: company, userId: 'seed');
  final seed = Seed();
  seed.client = await repo.save(MasterKind.clients, s, {
    'name': 'Patil Constructions',
  });
  seed.site = await repo.save(MasterKind.sites, s, {
    'clientId': seed.client,
    'name': 'Hinjewadi Yard',
  });
  seed.machine = await repo.save(MasterKind.machines, s, {
    'name': 'JCB 3DX',
    'initialMeterReading': 100000,
  });
  seed.operator = await repo.save(MasterKind.operators, s, {'name': 'Suresh'});
  return seed;
}

Future<(TestHarness, Seed)> pumpWork(
  WidgetTester tester, {
  CompanyRole role = CompanyRole.owner,
  bool seed = true,
}) async {
  final h = TestHarness.signedIn(
    companies: [membership(company, 'Sai Earthmovers', role: role)],
  );
  final ids = seed ? await seedMasters(h.db) : Seed();
  await pumpApp(tester, harness: h, online: false);
  await tapAndSettle(tester, find.text('Work'));
  return (h, ids);
}

Finder inReading(String which, Finder f) =>
    find.descendant(of: find.byKey(Key('${which}_reading')), matching: f);

Future<void> typeReading(
  WidgetTester tester,
  String which,
  String value,
) async {
  final field = inReading(which, find.byKey(const Key('reading_value')));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await settle(tester);
}

Future<void> photo(WidgetTester tester, String which) => tapAndSettle(
  tester,
  inReading(which, find.byKey(const Key('reading_take_photo'))),
);

void main() {
  testWidgets('owner logs work with photos; hours calculated and approved', (
    tester,
  ) async {
    final (h, _) = await pumpWork(tester);
    expect(find.text('No work logs yet'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('work_add')));

    // Single client/site/machine are picked automatically.
    expect(find.text('Patil Constructions'), findsOneWidget);
    expect(find.text('Hinjewadi Yard'), findsOneWidget);
    expect(find.text('JCB 3DX'), findsOneWidget);

    await photo(tester, 'start');
    expect(find.textContaining('Location permission denied'), findsWidgets);
    await tapAndSettle(tester, find.byKey(const Key('reading_use_last')));
    h.location.status = LocationStatus.captured;
    await photo(tester, 'end');
    await typeReading(tester, 'end', '1008.5');
    expect(find.text('8.5 h'), findsOneWidget);
    expect(find.text('Manual entry'), findsNothing);

    await tapAndSettle(tester, find.byKey(const Key('work_submit')));
    expect(find.text('Work log approved'), findsOneWidget);
    expect(find.byType(WorkLogCard), findsOneWidget);
    expect(find.text('8.5 h'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WorkLogCard),
        matching: find.text('Approved'),
      ),
      findsOneWidget,
    );

    final row = await h.db.select(h.db.workLogs).getSingle();
    expect(row.startReading, 100000);
    expect(row.endReading, 100850);
    expect(row.workingHours, 850);
    expect(row.entryMode, 'photo');
    expect(row.startLocationStatus, 'denied');
    expect(row.endLocationStatus, 'captured');
    expect(row.endLat, 18.5912);
    expect(row.startPhotoPath, startsWith('evidence/co1/'));
    expect(h.photos.kept, hasLength(2));

    // Detail shows evidence and history.
    await tapAndSettle(tester, find.byType(WorkLogCard));
    expect(find.text('Photo evidence'), findsOneWidget);
    expect(find.textContaining('18.59120, 73.73890 ±12 m'), findsOneWidget);
    expect(
      await scrollTo(tester, find.text('Submitted and approved')),
      findsOneWidget,
    );

    // Dashboard tile reflects today's hours.
    await tester.pageBack();
    await settle(tester);
    await tapAndSettle(tester, find.text('Dashboard'));
    expect(
      find.descendant(
        of: find.byKey(const Key('dash_today_hours')),
        matching: find.text('8.5 h'),
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('operator manual entry needs a reason and waits for approval', (
    tester,
  ) async {
    final (h, _) = await pumpWork(tester, role: CompanyRole.operator);
    await tapAndSettle(tester, find.byKey(const Key('work_add')));
    await typeReading(tester, 'start', '1000');
    await typeReading(tester, 'end', '1006');
    expect(find.text('Manual entry'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('work_submit')));
    expect(
      find.textContaining('Say why there is no meter photo'),
      findsWidgets,
    );

    await tester.enterText(
      find.byKey(const Key('work_manual_reason')),
      'Meter glass fogged',
    );
    await tapAndSettle(tester, find.byKey(const Key('work_submit')));
    expect(find.text('Submitted for approval'), findsOneWidget);
    expect(find.text('Pending approval'), findsWidgets);
    expect(find.text('Manual'), findsOneWidget);
    final row = await h.db.select(h.db.workLogs).getSingle();
    expect(row.status, 'submitted');
    expect(row.manualReason, 'Meter glass fogged');
    await unmount(tester);
  });

  testWidgets('camera denied explains and lets the user continue manually', (
    tester,
  ) async {
    final (h, _) = await pumpWork(tester);
    h.camera.denied = true;
    await tapAndSettle(tester, find.byKey(const Key('work_add')));
    await photo(tester, 'start');
    expect(find.text('Camera access is off'), findsOneWidget);
    await tapAndSettle(tester, find.text('Open settings'));
    expect(h.location.settingsOpened, isTrue);
    await typeReading(tester, 'start', '1000');
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('start now, add end reading later', (tester) async {
    await pumpWork(tester);
    await tapAndSettle(tester, find.byKey(const Key('work_add')));
    await photo(tester, 'start');
    await typeReading(tester, 'start', '1000');
    await tapAndSettle(tester, find.byKey(const Key('work_save_draft')));
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('In progress'), findsWidgets);

    await tapAndSettle(tester, find.byType(WorkLogCard));
    await tapAndSettle(
      tester,
      find.byKey(const Key('work_edit')),
    ); // "Add end reading"
    await photo(tester, 'end');
    await typeReading(tester, 'end', '1007.25');
    expect(find.text('7.25 h'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('work_submit')));
    expect(await scrollTo(tester, find.text('7.25 h')), findsWidgets);
    expect(find.text('Approved'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('end below start is blocked; long shifts need confirmation', (
    tester,
  ) async {
    final (h, _) = await pumpWork(tester);
    await tapAndSettle(tester, find.byKey(const Key('work_add')));
    await photo(tester, 'start');
    await photo(tester, 'end');
    await typeReading(tester, 'start', '1000');
    await typeReading(tester, 'end', '999');
    expect(find.text('Check readings'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('work_submit')));
    expect(find.textContaining('must not be less than'), findsWidgets);
    expect(await h.db.select(h.db.workLogs).get(), isEmpty);

    await typeReading(tester, 'end', '1015');
    expect(find.textContaining('More than 12 hours'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('work_submit')));
    expect(find.text('Please check'), findsOneWidget);
    await tapAndSettle(tester, find.text('Save anyway'));
    expect(find.text('Check'), findsOneWidget);
    final row = await h.db.select(h.db.workLogs).getSingle();
    expect(row.anomalyFlags, 'highHours');
    await unmount(tester);
  });

  testWidgets('manager approves and rejects with a reason', (tester) async {
    final h = TestHarness.signedIn(
      companies: [membership(company, 'Sai', role: CompanyRole.manager)],
    );
    final ids = await seedMasters(h.db);
    final repo = WorkLogRepository(h.db);
    const op = WorkActor(
      companyId: company,
      userId: 'op',
      role: CompanyRole.operator,
    );
    WorkLogInput input(int start, int end) => WorkLogInput(
      workDate: WorkLogRules.dateKey(DateTime.now()),
      clientId: ids.client,
      siteId: ids.site,
      machineId: ids.machine,
      start: MeterCapture(reading: start),
      end: MeterCapture(reading: end),
      manualReason: 'No camera',
      anomalyFlags: const {AnomalyFlag.duplicateDay},
    );
    await repo.submit(op, input(100000, 100500));
    await repo.submit(op, input(100500, 100900));
    await pumpApp(tester, harness: h, online: false);
    expect(
      find.descendant(
        of: find.byKey(const Key('dash_pending')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await tapAndSettle(tester, find.text('Work'));
    await tapAndSettle(tester, find.byKey(const Key('work_filter_pending')));
    expect(find.byType(WorkLogCard), findsNWidgets(2));
    await tapAndSettle(tester, find.text('5 h'));
    await tapAndSettle(tester, find.byKey(const Key('work_approve')));
    expect(find.text('Work log approved'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    expect(find.byType(WorkLogCard), findsOneWidget);

    await tapAndSettle(tester, find.byType(WorkLogCard));
    await tapAndSettle(tester, find.byKey(const Key('work_reject')));
    await tapAndSettle(tester, find.byKey(const Key('reason_confirm')));
    expect(find.text('Please enter a reason'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('reason_field')),
      'Wrong site selected',
    );
    await tapAndSettle(tester, find.byKey(const Key('reason_confirm')));
    expect(
      await scrollTo(tester, find.text('Rejected: Wrong site selected')),
      findsOneWidget,
    );
    expect(await scrollTo(tester, find.text('Rejected')), findsWidgets);
    await unmount(tester);
  });

  testWidgets('owner corrects an approved log with an audited reason', (
    tester,
  ) async {
    final (h, ids) = await pumpWork(tester);
    const owner = WorkActor(
      companyId: company,
      userId: 'someone',
      role: CompanyRole.owner,
    );
    await WorkLogRepository(h.db).submit(
      owner,
      WorkLogInput(
        workDate: WorkLogRules.dateKey(DateTime.now()),
        clientId: ids.client,
        siteId: ids.site,
        machineId: ids.machine,
        start: const MeterCapture(reading: 100000),
        end: const MeterCapture(reading: 100800),
        manualReason: 'Meter dirty',
      ),
    );
    await settle(tester);
    await tapAndSettle(tester, find.byType(WorkLogCard));
    expect(find.byKey(const Key('work_edit')), findsNothing);
    await tapAndSettle(tester, find.byKey(const Key('work_correct')));
    expect(find.textContaining('correcting an approved log'), findsOneWidget);
    await typeReading(tester, 'end', '1008.5');
    await tapAndSettle(tester, find.byKey(const Key('work_submit')));
    await tester.enterText(
      find.byKey(const Key('reason_field')),
      'End reading misread',
    );
    await tapAndSettle(tester, find.byKey(const Key('reason_confirm')));
    expect(find.text('Correction saved'), findsOneWidget);
    expect(await scrollTo(tester, find.text('8.5 h')), findsWidgets);
    expect(await scrollTo(tester, find.text('Corrected')), findsOneWidget);
    expect(find.textContaining('Reason: End reading misread'), findsOneWidget);
    expect(find.textContaining('End: 1,008 h → 1,008.5 h'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('discarding a new log removes photos taken in it', (
    tester,
  ) async {
    final (h, _) = await pumpWork(tester);
    await tapAndSettle(tester, find.byKey(const Key('work_add')));
    await photo(tester, 'start');
    expect(h.photos.kept, hasLength(1));
    await tester.pageBack();
    await settle(tester);
    await tapAndSettle(tester, find.text('Discard'));
    expect(h.photos.kept, isEmpty);
    expect(h.photos.discarded, hasLength(1));
    await unmount(tester);
  });

  testWidgets('asks to set up masters first', (tester) async {
    await pumpWork(tester, seed: false);
    await tapAndSettle(tester, find.byKey(const Key('work_add')));
    expect(find.text('Set up your clients first'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('accounts role views work but cannot log it', (tester) async {
    await pumpWork(tester, role: CompanyRole.accounts);
    expect(find.byKey(const Key('work_add')), findsNothing);
    await unmount(tester);
  });
}
