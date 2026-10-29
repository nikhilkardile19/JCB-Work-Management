import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/billing/presentation/billing_screen.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';
import 'package:jcb_work_management/features/work/data/work_log_repository.dart';
import 'package:jcb_work_management/features/work/domain/work_log.dart';

import '../helpers/pump_app.dart';

const company = 'co1';

class BillingSeed {
  late String client, site, machine;
  final logs = <String>[];
}

/// One client/site (₹1,500/h) and two approved logs this month: 8 h + 8.5 h.
Future<BillingSeed> seedBilling(AppDatabase db) async {
  final m = MastersRepository(db);
  const s = MasterScope(companyId: company, userId: 'seed');
  final b = BillingSeed();
  b.client = await m.save(MasterKind.clients, s, {
    'name': 'Patil Constructions',
    'billingAddress': 'Hinjewadi, Pune',
  });
  b.site = await m.save(MasterKind.sites, s, {
    'clientId': b.client,
    'name': 'Hinjewadi Yard',
    'defaultHourlyRatePaise': 150000,
  });
  b.machine = await m.save(MasterKind.machines, s, {
    'name': 'JCB 3DX',
    'initialMeterReading': 0,
  });
  const owner = WorkActor(
    companyId: company,
    userId: 'seed',
    role: CompanyRole.owner,
  );
  final today = DateTime.now();
  final first = DateTime(today.year, today.month);
  final days = [first, today];
  var reading = 0;
  for (final (i, hours) in [800, 850].indexed) {
    final (id, _) = await WorkLogRepository(db).submit(
      owner,
      WorkLogInput(
        workDate: WorkLogRules.dateKey(days[i]),
        clientId: b.client,
        siteId: b.site,
        machineId: b.machine,
        start: MeterCapture(reading: reading),
        end: MeterCapture(reading: reading + hours),
        manualReason: 'seed',
        anomalyFlags: const {AnomalyFlag.duplicateDay},
      ),
    );
    reading += hours;
    b.logs.add(id);
  }
  return b;
}

Future<(TestHarness, BillingSeed)> pumpBilling(
  WidgetTester tester, {
  CompanyRole role = CompanyRole.owner,
  bool online = true,
}) async {
  final h = TestHarness.signedIn(
    companies: [membership(company, 'Sai Earthmovers', role: role)],
  );
  final seed = await seedBilling(h.db);
  await pumpApp(tester, harness: h, online: online);
  await tapTab(tester, 'Billing');
  return (h, seed);
}

Future<void> createDraft(WidgetTester tester, {String? rate}) async {
  await tapAndSettle(tester, find.byKey(const Key('invoice_add')));
  await tapAndSettle(tester, find.byKey(const Key('invoice_client')));
  await tapAndSettle(tester, find.text('Patil Constructions').last);
  if (rate != null) {
    await tester.enterText(find.byKey(const Key('group_rate')), rate);
    await settle(tester);
  }
  await tapAndSettle(tester, find.byKey(const Key('invoice_save')));
}

Future<void> finalize(WidgetTester tester) async {
  await tapAndSettle(tester, find.byKey(const Key('invoice_finalize')));
  await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Finalize'));
}

Future<void> pay(WidgetTester tester, String amount) async {
  await tapAndSettle(tester, find.byKey(const Key('invoice_record_payment')));
  await tester.enterText(find.byKey(const Key('payment_amount')), amount);
  await tapAndSettle(tester, find.byKey(const Key('payment_save')));
}

void main() {
  testWidgets('owner bills approved work: draft → finalize → partial payment', (
    tester,
  ) async {
    final (h, seed) = await pumpBilling(tester);
    expect(find.text('No invoices yet'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('invoice_add')));
    await tapAndSettle(tester, find.byKey(const Key('invoice_client')));
    await tapAndSettle(tester, find.text('Patil Constructions').last);
    // Both logs selected by default at the site rate: 16.5 h × ₹1,500.
    expect(find.text('2 of 2 logs · 16.5 h'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('invoice_builder_total'))).data,
      '₹24,750.00',
    );
    // Invoice-only rate override.
    await tester.enterText(find.byKey(const Key('group_rate')), '1600');
    await settle(tester);
    expect(
      tester.widget<Text>(find.byKey(const Key('invoice_builder_total'))).data,
      '₹26,400.00',
    );
    await tapAndSettle(tester, find.byKey(const Key('invoice_save')));

    expect(find.text('Draft invoice saved'), findsOneWidget);
    expect(find.text('Draft'), findsWidgets);
    final site = await (h.db.select(
      h.db.sites,
    )..where((t) => t.id.equals(seed.site))).getSingle();
    expect(site.defaultHourlyRatePaise, 150000, reason: 'site rate unchanged');

    await finalize(tester);
    expect(find.text('Invoice finalized'), findsOneWidget);
    final year = DateTime.now().month >= 4
        ? DateTime.now().year
        : DateTime.now().year - 1;
    final fy = '$year-${((year + 1) % 100).toString().padLeft(2, '0')}';
    expect(find.text('JCB/$fy/0001'), findsOneWidget);
    expect(await scrollTo(tester, find.text('Unpaid')), findsOneWidget);

    await pay(tester, '10000');
    expect(find.text('Payment of ₹10,000.00 recorded'), findsOneWidget);
    expect(await scrollTo(tester, find.text('Partially paid')), findsOneWidget);
    expect(
      await scrollTo(tester, find.textContaining('Outstanding ₹16,400.00')),
      findsOneWidget,
    );

    // Work logs are now invoiced and locked.
    final logs = await h.db.select(h.db.workLogs).get();
    expect(logs.every((l) => l.status == 'invoiced'), isTrue);

    await tester.pageBack();
    await settle(tester);
    expect(find.byType(InvoiceCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('billing_outstanding')),
        matching: find.text('₹16,400.00'),
      ),
      findsNothing,
    );
    expect(find.text('₹16,400.00'), findsWidgets);
    await tapTab(tester, 'Dashboard');
    expect(
      find.descendant(
        of: find.byKey(const Key('dash_outstanding')),
        matching: find.text('₹16,400.00'),
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('finalizing offline keeps the draft', (tester) async {
    final (h, _) = await pumpBilling(tester, online: false);
    await createDraft(tester);
    await tapAndSettle(tester, find.byKey(const Key('invoice_finalize')));
    // Connectivity hint is offline: we don't even ask the server.
    expect(
      find.textContaining('Connect to the internet to finalize'),
      findsOneWidget,
    );
    expect(h.invoiceNumbers.issued, isEmpty);
    expect((await h.db.select(h.db.invoices).getSingle()).status, 'draft');
    await unmount(tester);
  });

  testWidgets('server unreachable while finalizing shows a clear message', (
    tester,
  ) async {
    final (h, _) = await pumpBilling(tester);
    h.invoiceNumbers.offline = true;
    await createDraft(tester);
    await tapAndSettle(tester, find.byKey(const Key('invoice_finalize')));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Finalize'));
    expect(find.textContaining('Could not reach the server'), findsOneWidget);
    expect((await h.db.select(h.db.invoices).getSingle()).status, 'draft');
    await unmount(tester);
  });

  testWidgets('overpayment is blocked; full payment marks Paid', (
    tester,
  ) async {
    await pumpBilling(tester);
    await createDraft(tester);
    await finalize(tester);
    await tapAndSettle(tester, find.byKey(const Key('invoice_record_payment')));
    await tester.enterText(find.byKey(const Key('payment_amount')), '99999');
    await tapAndSettle(tester, find.byKey(const Key('payment_save')));
    expect(find.textContaining('more than the outstanding'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('payment_amount')), '24750');
    await tapAndSettle(tester, find.byKey(const Key('payment_method_cheque')));
    await tapAndSettle(tester, find.byKey(const Key('payment_save')));
    expect(await scrollTo(tester, find.text('Paid')), findsWidgets);
    expect(await scrollTo(tester, find.text('Fully paid')), findsOneWidget);
    expect(find.byKey(const Key('invoice_record_payment')), findsNothing);
    await unmount(tester);
  });

  testWidgets(
    'cancel needs payments reversed first, then frees the work for re-billing',
    (tester) async {
      final (h, _) = await pumpBilling(tester);
      await createDraft(tester);
      await finalize(tester);
      await pay(tester, '1000');

      await tapAndSettle(tester, find.byKey(const Key('invoice_cancel')));
      await tester.enterText(
        find.byKey(const Key('reason_field')),
        'Wrong rate',
      );
      await tapAndSettle(tester, find.byKey(const Key('reason_confirm')));
      expect(find.textContaining('Reverse the payments'), findsOneWidget);

      await tapAndSettle(tester, find.byTooltip('Reverse payment'));
      await tester.enterText(
        find.byKey(const Key('reason_field')),
        'Entered by mistake',
      );
      await tapAndSettle(tester, find.byKey(const Key('reason_confirm')));
      expect(find.text('Payment reversed'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('invoice_cancel')));
      await tester.enterText(
        find.byKey(const Key('reason_field')),
        'Wrong rate',
      );
      await tapAndSettle(tester, find.byKey(const Key('reason_confirm')));
      expect(
        await scrollTo(tester, find.text('Cancelled: Wrong rate')),
        findsWidgets,
      );
      final logs = await h.db.select(h.db.workLogs).get();
      expect(
        logs.every((l) => l.status == 'approved' && l.invoiceId == null),
        isTrue,
      );

      // The same work can be billed on a new invoice.
      await tester.pageBack();
      await settle(tester);
      await tapAndSettle(tester, find.byKey(const Key('invoice_add')));
      await tapAndSettle(tester, find.byKey(const Key('invoice_client')));
      await tapAndSettle(tester, find.text('Patil Constructions').last);
      expect(find.text('2 of 2 logs · 16.5 h'), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('deleting a draft releases its work logs', (tester) async {
    final (h, _) = await pumpBilling(tester);
    await createDraft(tester);
    expect(
      (await h.db.select(h.db.workLogs).get()).every(
        (l) => l.invoiceId != null,
      ),
      isTrue,
    );
    await tapAndSettle(tester, find.byKey(const Key('invoice_delete')));
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Delete draft'),
    );
    expect(find.text('No invoices yet'), findsOneWidget);
    expect(
      (await h.db.select(h.db.workLogs).get()).every(
        (l) => l.invoiceId == null,
      ),
      isTrue,
    );
    await unmount(tester);
  });

  testWidgets(
    'operators cannot see billing; managers can view but not invoice',
    (tester) async {
      await pumpBilling(tester, role: CompanyRole.operator);
      expect(find.text('Billing access is off'), findsOneWidget);
      await unmount(tester);

      await pumpBilling(tester, role: CompanyRole.manager);
      expect(find.text('No invoices yet'), findsOneWidget);
      expect(find.byKey(const Key('invoice_add')), findsNothing);
      await unmount(tester);
    },
  );
}
