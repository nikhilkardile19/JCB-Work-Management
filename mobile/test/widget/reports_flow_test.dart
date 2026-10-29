import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/billing/data/invoice_repository.dart';
import 'package:jcb_work_management/features/billing/domain/invoice.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/work/data/work_log_repository.dart';
import 'package:jcb_work_management/features/work/domain/work_log.dart';

import '../helpers/pump_app.dart';
import 'billing_flow_test.dart' show BillingSeed, company, seedBilling;
import 'work_flow_test.dart' show photo, pumpWork;

String textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

/// A phone tall enough that the whole dashboard is built, so absent tiles
/// are really absent rather than just scrolled off.
void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 9000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// [textOf] after scrolling a lazy list until [key] is built.
Future<String> scrolledTextOf(WidgetTester tester, String key) async {
  await scrollTo(tester, find.byKey(Key(key)));
  return textOf(tester, key);
}

/// Owner with two approved logs this month (16.5 h) on one invoice of
/// ₹24,750, of which ₹10,000 is paid.
Future<(TestHarness, BillingSeed)> pumpWithBilling(
  WidgetTester tester, {
  CompanyRole role = CompanyRole.owner,
}) async {
  final h = TestHarness.signedIn(
    companies: [membership(company, 'Sai Earthmovers', role: role)],
  );
  // Repository work outside the widget tree needs real async: drift's
  // queries don't complete under the test's fake clock.
  final b = (await tester.runAsync(() async {
    final b = await seedBilling(h.db);
    const owner = WorkActor(
      companyId: company,
      userId: 'seed',
      role: CompanyRole.owner,
    );
    final repo = InvoiceRepository(h.db);
    final today = WorkLogRules.dateKey(DateTime.now());
    final id = await repo.saveDraft(
      owner,
      InvoiceDraftInput(
        clientId: b.client,
        periodFrom: WorkLogRules.dateKey(
          DateTime(DateTime.now().year, DateTime.now().month),
        ),
        periodTo: today,
        invoiceDate: today,
        workLogRates: {for (final l in b.logs) l: 150000},
      ),
    );
    await repo.finalize(
      owner,
      id,
      numbers: h.invoiceNumbers,
      company: const PartySnapshot(name: 'Sai Earthmovers'),
    );
    await repo.recordPayment(
      owner,
      id,
      PaymentInput(
        paymentDate: today,
        amountPaise: 1000000,
        method: PaymentMethod.bank,
      ),
    );
    return b;
  }))!;
  await pumpApp(tester, harness: h);
  return (h, b);
}

void main() {
  testWidgets('owner opens reports; figures match the records', (tester) async {
    await pumpWithBilling(tester);
    await tapTab(tester, 'More');
    await tapAndSettle(tester, find.byKey(const Key('more_reports')));

    expect(
      await scrolledTextOf(tester, 'report_work_headline'),
      '16.5 h approved',
    );
    expect(
      await scrolledTextOf(tester, 'report_invoices_headline'),
      '₹24,750.00 · 1 invoice',
    );
    expect(
      await scrolledTextOf(tester, 'report_payments_headline'),
      '₹10,000.00 received',
    );
    expect(
      await scrolledTextOf(tester, 'report_outstanding_headline'),
      '₹14,750.00 · ₹0.00 overdue',
    );
    expect(
      await scrolledTextOf(tester, 'report_manual_headline'),
      '2 manual · 2 with warnings',
    );

    await tapAndSettle(tester, find.byKey(const Key('report_work')));
    expect(textOf(tester, 'report_headline'), '16.5 h');
    expect(find.byTooltip('Share or print as PDF'), findsOneWidget);
    expect(await scrollTo(tester, find.text('JCB 3DX')), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('report_by_Client')));
    expect(
      await scrollTo(tester, find.text('Patil Constructions')),
      findsOneWidget,
    );

    // The period is shared; last month had no work.
    await tapAndSettle(
      tester,
      find.byKey(const Key('report_period_lastMonth')),
    );
    expect(await scrolledTextOf(tester, 'report_headline'), '0 h');
    expect(
      await scrollTo(tester, find.text('Nothing in this period.')),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('outstanding and payments reports list the invoice', (
    tester,
  ) async {
    await pumpWithBilling(tester);
    await tapTab(tester, 'More');
    await tapAndSettle(tester, find.byKey(const Key('more_reports')));
    await tapAndSettle(tester, find.byKey(const Key('report_outstanding')));
    expect(textOf(tester, 'report_headline'), '₹14,750.00');
    expect(find.textContaining('As of today'), findsOneWidget);
    expect(await scrollTo(tester, find.textContaining('JCB/')), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    await tapAndSettle(tester, find.byKey(const Key('report_payments')));
    expect(textOf(tester, 'report_headline'), '₹10,000.00');
    expect(
      await scrollTo(tester, find.textContaining('Bank transfer')),
      findsWidgets,
    );
    await unmount(tester);
  });

  testWidgets('dashboard shows month totals for owners', (tester) async {
    tallView(tester);
    await pumpWithBilling(tester);
    expect(find.byKey(const Key('dash_received')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('dash_received')),
        matching: find.text('₹10,000.00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('dash_invoiced')),
        matching: find.text('₹24,750.00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('dash_machines')),
        matching: find.text('16.5 h'),
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('operators see no money and no reports', (tester) async {
    tallView(tester);
    await pumpWithBilling(tester, role: CompanyRole.operator);
    for (final k in ['dash_outstanding', 'dash_received', 'dash_fuel']) {
      expect(find.byKey(Key(k)), findsNothing, reason: k);
    }
    expect(find.byKey(const Key('dash_today_hours')), findsOneWidget);
    expect(find.byKey(const Key('dash_reports')), findsNothing);
    await tapTab(tester, 'More');
    expect(find.byKey(const Key('more_sync')), findsOneWidget);
    expect(find.byKey(const Key('more_reports')), findsNothing);
    await unmount(tester);
  });

  testWidgets('accounts and managers can open reports', (tester) async {
    tallView(tester);
    for (final role in [CompanyRole.accounts, CompanyRole.manager]) {
      await pumpWithBilling(tester, role: role);
      expect(find.byKey(const Key('dash_outstanding')), findsOneWidget);
      await tapTab(tester, 'More');
      expect(find.byKey(const Key('more_reports')), findsOneWidget);
      await unmount(tester);
    }
  });

  group('location permission', () {
    testWidgets('explained before asking; "Not now" still saves the photo', (
      tester,
    ) async {
      final (h, _) = await pumpWork(tester);
      h.location.needsPrompt = true;
      await tapAndSettle(tester, find.byKey(const Key('work_add')));
      await photo(tester, 'start');
      expect(find.text('Add location to photos?'), findsOneWidget);
      await tapAndSettle(tester, find.text('Not now'));
      expect(h.location.requests, 0, reason: 'system dialog not shown');
      expect(h.camera.taken, 1);
      expect(find.textContaining('Location permission denied'), findsWidgets);

      // Not asked again for every photo.
      await photo(tester, 'end');
      expect(find.text('Add location to photos?'), findsNothing);
      expect(h.location.requests, 0);
      expect(h.camera.taken, 2);
      await unmount(tester);
    });

    testWidgets('"Continue" goes on to Android\'s permission request', (
      tester,
    ) async {
      final (h, _) = await pumpWork(tester);
      h.location
        ..needsPrompt = true
        ..status = LocationStatus.captured;
      await tapAndSettle(tester, find.byKey(const Key('work_add')));
      await photo(tester, 'start');
      await tapAndSettle(tester, find.text('Continue'));
      expect(h.location.requests, 1);
      expect(find.textContaining('Location permission denied'), findsNothing);
      await unmount(tester);
    });
  });

  testWidgets('privacy screen explains storage and opens settings', (
    tester,
  ) async {
    final h = TestHarness.signedIn(
      companies: [membership(company, 'Sai Earthmovers')],
    );
    await pumpApp(tester, harness: h);
    await tapTab(tester, 'More');
    await tapAndSettle(tester, find.byKey(const Key('more_privacy')));
    expect(find.text('Privacy and permissions'), findsOneWidget);
    expect(
      await scrollTo(tester, find.text('No phone backup')),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.byKey(const Key('privacy_settings')));
    expect(h.location.settingsOpened, isTrue);
    await unmount(tester);
  });
}
