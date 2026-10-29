import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/dashboard/dashboard_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('active company: tabs, theme, profile edit, sign out', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      harness: TestHarness.signedIn(companies: [membership('a', 'Alpha JCB')]),
    );
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.textContaining('Alpha JCB'), findsOneWidget);

    await tapAndSettle(tester, find.text('Work'));
    expect(find.text('No work logs yet'), findsOneWidget);
    await tapAndSettle(tester, find.text('Billing'));
    expect(find.text('No invoices yet'), findsOneWidget);

    await tapAndSettle(tester, find.text('More'));
    await tapAndSettle(tester, find.byKey(const Key('more_appearance')));
    await tapAndSettle(tester, find.text('Dark'));
    expect(await h.db.readSetting('theme_mode'), 'dark');
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
    );

    // Company profile: view, edit, save.
    await tapAndSettle(tester, find.byKey(const Key('more_company')));
    expect(find.text('Company profile'), findsOneWidget);
    expect(find.text('Plot 12, MIDC, Pune'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('company_edit')));
    await tester.enterText(
      find.byKey(const Key('company_name')),
      'Alpha JCB Services',
    );
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(find.text('Company profile saved'), findsOneWidget);
    expect(find.text('Alpha JCB Services'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    await tapAndSettle(tester, find.byKey(const Key('more_sign_out')));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Sign out'));
    expect(find.text('Welcome back'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('operators cannot edit the company profile', (tester) async {
    await pumpApp(
      tester,
      harness: TestHarness.signedIn(
        companies: [membership('a', 'Alpha', role: CompanyRole.operator)],
      ),
    );
    await tapAndSettle(tester, find.text('More'));
    await tapAndSettle(tester, find.byKey(const Key('more_company')));
    expect(find.text('Operator'), findsOneWidget);
    expect(find.byKey(const Key('company_edit')), findsNothing);
    await unmount(tester);
  });

  testWidgets('works offline from the cached company', (tester) async {
    final h = TestHarness.signedIn(companies: [membership('a', 'Alpha')]);
    // First launch online fills the cache.
    await pumpApp(tester, harness: h);
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
    // Next launch: offline, server unreachable.
    h.remote.offline = true;
    await pumpApp(tester, harness: h, online: false);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.textContaining('Offline — your work is saved'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('multi-company user picks and switches company', (tester) async {
    await pumpApp(
      tester,
      harness: TestHarness.signedIn(
        companies: [membership('a', 'Alpha'), membership('b', 'Beta')],
      ),
    );
    expect(find.text('Choose company'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('company_b')));
    expect(find.textContaining('Beta'), findsOneWidget);

    await tapAndSettle(tester, find.text('More'));
    await tapAndSettle(tester, find.byKey(const Key('more_switch_company')));
    expect(find.text('Choose company'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('company_a')));
    expect(find.textContaining('Alpha'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('component gallery opens from More and validates', (
    tester,
  ) async {
    await pumpApp(
      tester,
      harness: TestHarness.signedIn(companies: [membership('a', 'Alpha')]),
    );
    await tapAndSettle(tester, find.text('More'));
    await tapAndSettle(tester, find.byKey(const Key('more_components')));
    expect(find.text('Design system'), findsWidgets);
    await tapAndSettle(tester, find.text('Validate form'));
    expect(find.text('Select a machine'), findsOneWidget);
    await unmount(tester);
  });
}
