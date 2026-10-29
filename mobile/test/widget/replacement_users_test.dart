import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/dashboard/dashboard_screen.dart';
import 'package:jcb_work_management/features/users/application/users_providers.dart';
import 'package:jcb_work_management/features/users/data/company_users_service.dart';

import '../helpers/pump_app.dart';

const co = 'co1';

Future<TestHarness> fullLicensePhone(WidgetTester tester) async {
  final h = TestHarness.signedIn(
    companies: [membership(co, 'Sai Earthmovers')],
    licensed: false,
  );
  h.licenses.deny = 'device_limit';
  await pumpApp(tester, harness: h);
  await tester.enterText(
    find.byKey(const Key('activation_code')),
    validActivationCode,
  );
  await tapAndSettle(tester, find.byKey(const Key('activation_submit')));
  return h;
}

Future<void> sendRequest(WidgetTester tester) async {
  await tapAndSettle(
    tester,
    find.byKey(const Key('activation_request_replacement')),
  );
  expect(find.text('Replace a phone'), findsOneWidget);
  await tapAndSettle(
    tester,
    find.byKey(const Key('replacement_reason_Phone damaged')),
  );
  await tester.enterText(
    find.byKey(const Key('replacement_details')),
    'Replaces Ramesh’s old Redmi',
  );
  await tapAndSettle(tester, find.byKey(const Key('replacement_submit')));
}

void main() {
  group('device replacement', () {
    testWidgets('full license → request → approved → this phone is activated', (
      tester,
    ) async {
      final h = await fullLicensePhone(tester);
      expect(find.text('Refused: device_limit'), findsOneWidget);
      await sendRequest(tester);
      expect(find.text('Request sent'), findsOneWidget);
      expect(
        h.replacements.requests.values.single['reason'],
        'Phone damaged: Replaces Ramesh’s old Redmi',
      );

      await tapAndSettle(tester, find.text('Check again'));
      expect(find.text('Still waiting for approval'), findsOneWidget);

      h.replacements.decision = 'approved';
      await tapAndSettle(tester, find.text('Check again'));
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(h.licenses.validations, 1);
      await unmount(tester);
    });

    testWidgets('a rejected request is explained and a new one can be made', (
      tester,
    ) async {
      final h = await fullLicensePhone(tester);
      await sendRequest(tester);
      h.replacements
        ..decision = 'rejected'
        ..reviewReason = 'Not a company phone';
      await tapAndSettle(tester, find.text('Check again'));
      expect(
        find.text('Your last request was rejected: Not a company phone'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('replacement_submit')), findsOneWidget);
      expect(
        find.byType(NavigationBar),
        findsNothing,
        reason: 'still not activated',
      );
      await unmount(tester);
    });

    testWidgets('a reason is required', (tester) async {
      await fullLicensePhone(tester);
      await tapAndSettle(
        tester,
        find.byKey(const Key('activation_request_replacement')),
      );
      await tapAndSettle(tester, find.byKey(const Key('replacement_submit')));
      expect(
        find.text('Choose why this phone is replacing another'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('a pending request survives restarting the app', (
      tester,
    ) async {
      final h = await fullLicensePhone(tester);
      await sendRequest(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      await pumpApp(tester, harness: h);
      expect(find.text('Activate this phone'), findsOneWidget);
      // The replacement screen shows the pending state, not a new form.
      await tester.enterText(
        find.byKey(const Key('activation_code')),
        validActivationCode,
      );
      await tapAndSettle(tester, find.byKey(const Key('activation_submit')));
      await tapAndSettle(
        tester,
        find.byKey(const Key('activation_request_replacement')),
      );
      expect(find.text('Request sent'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('company users', () {
    Future<TestHarness> pumpUsers(
      WidgetTester tester, {
      CompanyRole role = CompanyRole.owner,
    }) async {
      final h = TestHarness.signedIn(
        companies: [membership(co, 'Sai Earthmovers', role: role)],
      );
      final me = FakeAuthRepository.userFor('owner@jcbworks.in').uid;
      h.users.members
        ..clear()
        ..addAll([
          CompanyMember(
            uid: me,
            email: 'owner@jcbworks.in',
            role: role.name,
            active: true,
          ),
          const CompanyMember(
            uid: 'boss',
            email: 'aaa.owner@sai.in',
            role: 'owner',
            active: true,
          ),
          const CompanyMember(
            uid: 'adm',
            email: 'admin@sai.in',
            role: 'admin',
            active: true,
          ),
          const CompanyMember(
            uid: 'op',
            email: 'ramesh@sai.in',
            role: 'operator',
            active: true,
          ),
        ]);
      await pumpApp(tester, harness: h);
      await tapTab(tester, 'More');
      return h;
    }

    testWidgets('owner adds a user, changes a role and disables access', (
      tester,
    ) async {
      final h = await pumpUsers(tester);
      await tapAndSettle(tester, find.byKey(const Key('more_users')));
      expect(find.text('ramesh@sai.in'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('users_invite')));
      await tester.enterText(
        find.byKey(const Key('invite_email')),
        'suresh@sai.in',
      );
      await tapAndSettle(tester, find.byKey(const Key('invite_role_accounts')));
      await tapAndSettle(tester, find.byKey(const Key('invite_submit')));
      expect(h.users.members.last.role, 'accounts');
      expect(find.text('suresh@sai.in'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('user_ramesh@sai.in')));
      await tapAndSettle(tester, find.byKey(const Key('role_manager')));
      expect(h.users.members.firstWhere((m) => m.uid == 'op').role, 'manager');

      await tapAndSettle(tester, find.byKey(const Key('user_ramesh@sai.in')));
      await tapAndSettle(tester, find.byKey(const Key('user_toggle')));
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Disable'));
      expect(h.users.members.firstWhere((m) => m.uid == 'op').active, isFalse);
      expect(find.text('Disabled'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('admins cannot change admins, the owner or themselves', (
      tester,
    ) async {
      await pumpUsers(tester, role: CompanyRole.admin);
      await tapAndSettle(tester, find.byKey(const Key('more_users')));
      await tapAndSettle(tester, find.byKey(const Key('user_admin@sai.in')));
      expect(find.byKey(const Key('user_toggle')), findsNothing);
      await tapAndSettle(
        tester,
        find.byKey(const Key('user_aaa.owner@sai.in')),
      );
      expect(find.byKey(const Key('user_toggle')), findsNothing);
      await tapAndSettle(tester, find.byKey(const Key('user_ramesh@sai.in')));
      expect(find.byKey(const Key('user_toggle')), findsOneWidget);
      expect(
        find.byKey(const Key('role_admin')),
        findsNothing,
        reason: 'only the owner grants admin',
      );
      await unmount(tester);
    });

    testWidgets('managers and operators have no user management', (
      tester,
    ) async {
      await pumpUsers(tester, role: CompanyRole.manager);
      expect(find.byKey(const Key('more_users')), findsNothing);
      await unmount(tester);
    });
  });

  test('user admin policy', () {
    const op = CompanyMember(
      uid: 'op',
      email: 'o',
      role: 'operator',
      active: true,
    );
    const adm = CompanyMember(
      uid: 'a',
      email: 'a',
      role: 'admin',
      active: true,
    );
    const own = CompanyMember(
      uid: 'w',
      email: 'w',
      role: 'owner',
      active: true,
    );
    expect(UserAdminPolicy.canChange(CompanyRole.owner, 'me', op), isTrue);
    expect(UserAdminPolicy.canChange(CompanyRole.owner, 'me', adm), isTrue);
    expect(UserAdminPolicy.canChange(CompanyRole.admin, 'me', adm), isFalse);
    expect(UserAdminPolicy.canChange(CompanyRole.owner, 'me', own), isFalse);
    expect(
      UserAdminPolicy.canChange(CompanyRole.owner, 'op', op),
      isFalse,
      reason: 'self',
    );
    expect(UserAdminPolicy.canChange(CompanyRole.manager, 'me', op), isFalse);
    expect(
      UserAdminPolicy.assignableRoles(CompanyRole.admin),
      isNot(contains(CompanyRole.admin)),
    );
  });
}
