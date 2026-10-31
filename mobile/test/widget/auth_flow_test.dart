import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/dashboard/dashboard_screen.dart';
import 'package:jcb_work_management/features/license/presentation/activation_screen.dart';

import '../helpers/pump_app.dart';

const ownerEmail = 'owner@jcbworks.in';

/// Step 1: enters [email] and continues.
Future<void> enterEmail(
  WidgetTester tester, {
  String email = ownerEmail,
}) async {
  await tester.enterText(find.byKey(const Key('login_email')), email);
  await tapAndSettle(tester, find.byKey(const Key('login_submit')));
}

/// Step 2: enters [code] and signs in.
Future<void> enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(const Key('code_activation')), code);
  await tapAndSettle(tester, find.byKey(const Key('code_submit')));
}

/// The owner has an account in company `a`; the license is driven by the
/// real controller, so the dashboard proves the phone was activated.
TestHarness ownerHarness() {
  final h = TestHarness(licensed: false);
  h.remote.memberships[FakeAuthRepository.userFor(ownerEmail).uid] = [
    membership('a', 'Sai Earthmovers'),
  ];
  return h;
}

/// Fills the sign-up form.
Future<void> fillSignUp(
  WidgetTester tester, {
  String email = 'new@saiearth.in',
}) async {
  await tester.enterText(find.byKey(const Key('signup_email')), email);
  await tester.enterText(
    find.byKey(const Key('company_name')),
    'Sai Earthmovers',
  );
  await tester.enterText(
    find.byKey(const Key('company_address')),
    'Plot 4, MIDC Bhosari, Pune',
  );
  await tester.enterText(
    find.byKey(const Key('company_contact')),
    'Ravi Patil',
  );
  await tester.enterText(find.byKey(const Key('company_phone')), '9876543210');
  await tester.enterText(find.byKey(const Key('company_prefix')), 'sai');
}

void main() {
  testWidgets('unauthenticated user lands on the email step, no password', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.textContaining('Password'), findsNothing);
    expect(find.textContaining('Forgot'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    await unmount(tester);
  });

  testWidgets('the email step validates before asking for the code', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.byKey(const Key('login_submit')));
    expect(find.text('Enter your email address'), findsOneWidget);

    await enterEmail(tester, email: 'bad');
    expect(find.textContaining('valid email'), findsOneWidget);
    expect(find.text('Enter activation code'), findsNothing);
    await unmount(tester);
  });

  testWidgets('an email without an account is explained on the email step', (
    tester,
  ) async {
    final h = TestHarness()..auth.unknownEmails.add('nobody@jcbworks.in');
    await pumpApp(tester, harness: h);
    await enterEmail(tester, email: 'Nobody@jcbworks.in');
    expect(find.text(FakeAuthRepository.noAccount.message), findsOneWidget);
    expect(find.text('Enter activation code'), findsNothing);
    await unmount(tester);
  });

  testWidgets('email, then activation code, goes straight to the dashboard', (
    tester,
  ) async {
    final h = ownerHarness();
    await pumpApp(tester, harness: h);
    await enterEmail(tester, email: ' $ownerEmail ');
    expect(find.text('Enter activation code'), findsOneWidget);
    expect(find.text('Signing in as $ownerEmail'), findsOneWidget);

    // Validation first.
    await tapAndSettle(tester, find.byKey(const Key('code_submit')));
    expect(find.text('Enter your activation code'), findsOneWidget);
    await enterCode(tester, 'JCBW-AAAA');
    expect(find.textContaining('full code'), findsOneWidget);
    expect(h.auth.lastCodeSignIn, isNull);

    // A wrong code keeps the user here with the server's message.
    await enterCode(tester, 'JCBW-AAAA-BBBB-CCCC');
    expect(
      find.text('That activation code is not valid for this email address.'),
      findsOneWidget,
    );
    expect(h.auth.currentUid, isNull);

    await enterCode(tester, validActivationCode.toLowerCase());
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(ActivationScreen), findsNothing);
    expect(find.textContaining('Sai Earthmovers'), findsWidgets);
    expect(h.auth.lastCodeSignIn?.email, ownerEmail);
    expect(h.auth.lastCodeSignIn?.deviceId, await h.db.installationId());
    await unmount(tester);
  });

  testWidgets('the code step can go back to change the email', (tester) async {
    await pumpApp(tester, harness: ownerHarness());
    await enterEmail(tester);
    await tapAndSettle(tester, find.byKey(const Key('code_change_email')));
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Enter activation code'), findsNothing);
    await unmount(tester);
  });

  testWidgets('the code step waits for internet', (tester) async {
    final h = ownerHarness();
    await pumpApp(tester, harness: h, online: false);
    await enterEmail(tester);
    expect(find.text('Waiting for internet'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('code_activation')),
      validActivationCode,
    );
    await tapAndSettle(tester, find.byKey(const Key('code_submit')));
    expect(h.auth.lastCodeSignIn, isNull);
    await unmount(tester);
  });

  testWidgets(
    'all devices in use: signed in and offered a replacement, code kept',
    (tester) async {
      final h = ownerHarness()..auth.refusalReason = 'device_limit';
      await pumpApp(tester, harness: h);
      await enterEmail(tester);
      await enterCode(tester, validActivationCode);
      expect(find.byType(ActivationScreen), findsOneWidget);
      expect(find.textContaining('All devices allowed'), findsOneWidget);
      expect(
        find.byKey(const Key('activation_request_replacement')),
        findsOneWidget,
      );
      expect(find.text(validActivationCode), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('a new owner signs up and is told to wait for approval', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await tapAndSettle(tester, find.byKey(const Key('login_sign_up')));
    expect(find.text('Create account'), findsWidgets);
    expect(find.textContaining('Password'), findsNothing);

    // Validation first, account fields included.
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter the company name'), findsOneWidget);
    expect(h.auth.lastSignUp, isNull);

    await fillSignUp(tester);
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(find.text('Registration submitted'), findsOneWidget);
    expect(find.textContaining('Sai Earthmovers'), findsOneWidget);
    expect(find.textContaining('new@saiearth.in'), findsOneWidget);
    expect(h.auth.lastSignUp?.email, 'new@saiearth.in');
    expect(h.auth.lastSignUp?.profile.invoicePrefix, 'SAI');
    // Sign-up does not sign in.
    expect(h.auth.currentUid, isNull);

    await tapAndSettle(tester, find.text('Go to sign in'));
    expect(find.text('Welcome back'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('sign-up with a registered email explains what to do', (
    tester,
  ) async {
    final h = TestHarness();
    h.auth.takenEmails.add(ownerEmail);
    await pumpApp(tester, harness: h);
    await tapAndSettle(tester, find.byKey(const Key('login_sign_up')));
    await fillSignUp(tester, email: 'Owner@jcbworks.in');
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(
      find.text(
        'An account with this email already exists. Sign in with your email and activation code.',
      ),
      findsOneWidget,
    );
    expect(find.text('Registration submitted'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a signed-in user without a company registers one', (
    tester,
  ) async {
    final h = TestHarness.signedIn();
    await pumpApp(tester, harness: h);
    expect(find.text('Set up your company'), findsOneWidget);

    // Validation first.
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(find.text('Enter the company name'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('company_name')),
      'Sai Earthmovers',
    );
    await tester.enterText(
      find.byKey(const Key('company_address')),
      'Plot 4, MIDC Bhosari, Pune',
    );
    await tester.enterText(
      find.byKey(const Key('company_contact')),
      'Ravi Patil',
    );
    await tester.enterText(
      find.byKey(const Key('company_phone')),
      '98765 43210',
    );
    await tester.enterText(find.byKey(const Key('company_prefix')), 'sai');
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));

    expect(find.text('Awaiting approval'), findsOneWidget);
    expect(find.text('Sai Earthmovers'), findsOneWidget);
    final uid = FakeAuthRepository.userFor(ownerEmail).uid;
    final registered = h.remote.memberships[uid]!.single;
    expect(registered.company.profile.invoicePrefix, 'SAI');

    // Developer admin approves; owner taps "Check again".
    h.remote.setStatus(uid, registered.companyId, CompanyStatus.active);
    await tapAndSettle(tester, find.byKey(const Key('status_check_again')));
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.textContaining('Sai Earthmovers'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('first launch offline with no cached company asks to connect', (
    tester,
  ) async {
    final h = TestHarness.signedIn()..remote.offline = true;
    await pumpApp(tester, online: false, harness: h);
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // Connection comes back: retry reaches the server → setup.
    h.remote.offline = false;
    await tapAndSettle(tester, find.text('Retry'));
    expect(find.text('Set up your company'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('company setup submit is disabled while offline', (tester) async {
    final h = TestHarness.signedIn();
    await pumpApp(tester, online: false, harness: h);
    expect(find.text('Set up your company'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(find.text('Connect to the internet to save'), findsOneWidget);
    expect(find.text('Enter the company name'), findsNothing);
    await unmount(tester);
  });

  testWidgets('suspended company is blocked without deleting data', (
    tester,
  ) async {
    await pumpApp(
      tester,
      harness: TestHarness.signedIn(
        companies: [
          membership('s', 'Stopped Co', status: CompanyStatus.suspended),
        ],
      ),
    );
    expect(find.text('Account suspended'), findsOneWidget);
    expect(
      find.textContaining('Records saved on this phone are kept'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    await unmount(tester);
  });
}
