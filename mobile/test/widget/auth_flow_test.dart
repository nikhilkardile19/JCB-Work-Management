import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/dashboard/dashboard_screen.dart';

import '../helpers/pump_app.dart';

Future<void> signIn(WidgetTester tester, {String password = 'secret1'}) async {
  await tester.enterText(
    find.byKey(const Key('login_email')),
    'owner@jcbworks.in',
  );
  await tester.enterText(find.byKey(const Key('login_password')), password);
  await tapAndSettle(tester, find.byKey(const Key('login_submit')));
}

/// Fills the sign-up form; [confirm] defaults to [password].
Future<void> fillSignUp(
  WidgetTester tester, {
  String email = 'new@saiearth.in',
  String password = 'secret123',
  String? confirm,
}) async {
  await tester.enterText(find.byKey(const Key('signup_email')), email);
  await tester.enterText(find.byKey(const Key('signup_password')), password);
  await tester.enterText(
    find.byKey(const Key('signup_confirm')),
    confirm ?? password,
  );
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
  testWidgets('unauthenticated user lands on login', (tester) async {
    await pumpApp(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await unmount(tester);
  });

  testWidgets('login validates input before submitting', (tester) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.byKey(const Key('login_submit')));
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login_email')), 'bad');
    await tester.enterText(find.byKey(const Key('login_password')), '123');
    await tapAndSettle(tester, find.byKey(const Key('login_submit')));
    expect(find.textContaining('valid email'), findsOneWidget);
    expect(find.textContaining('at least 6'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('wrong password shows the server error inline', (tester) async {
    await pumpApp(tester);
    await signIn(tester, password: wrongPassword);
    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('forgot password sends a reset link', (tester) async {
    final h = await pumpApp(tester);
    await tapAndSettle(tester, find.byKey(const Key('login_forgot')));
    expect(find.text('Reset password'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('forgot_email')),
      'owner@jcbworks.in',
    );
    await tapAndSettle(tester, find.byKey(const Key('forgot_submit')));
    expect(find.text('Check your email'), findsOneWidget);
    expect(h.auth.lastResetEmail, 'owner@jcbworks.in');
    await tapAndSettle(tester, find.text('Back to sign in'));
    expect(find.text('Welcome back'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('reset is disabled offline', (tester) async {
    final h = await pumpApp(tester, online: false);
    await tapAndSettle(tester, find.byKey(const Key('login_forgot')));
    await tester.enterText(find.byKey(const Key('forgot_email')), 'a@b.co');
    await tapAndSettle(tester, find.byKey(const Key('forgot_submit')));
    expect(h.auth.lastResetEmail, isNull);
    expect(find.textContaining('Connect to the internet'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a new owner signs up and is told to wait for approval', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await tapAndSettle(tester, find.byKey(const Key('login_sign_up')));
    expect(find.text('Create account'), findsWidgets);

    // Validation first, account fields included.
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('Enter the company name'), findsOneWidget);

    await fillSignUp(tester, password: 'short1', confirm: 'other12');
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(find.textContaining('at least 8'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(h.auth.lastSignUp, isNull);

    await fillSignUp(tester);
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(find.text('Registration submitted'), findsOneWidget);
    expect(find.textContaining('Sai Earthmovers'), findsOneWidget);
    expect(find.textContaining('new@saiearth.in'), findsOneWidget);
    expect(h.auth.lastSignUp?.email, 'new@saiearth.in');
    expect(h.auth.lastSignUp?.password, 'secret123');
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
    h.auth.takenEmails.add('owner@jcbworks.in');
    await pumpApp(tester, harness: h);
    await tapAndSettle(tester, find.byKey(const Key('login_sign_up')));
    await fillSignUp(tester, email: 'Owner@jcbworks.in');
    await tapAndSettle(tester, find.byKey(const Key('company_submit')));
    expect(
      find.text(
        'An account with this email already exists. Sign in, or reset your password.',
      ),
      findsOneWidget,
    );
    expect(find.text('Registration submitted'), findsNothing);
    await unmount(tester);
  });

  testWidgets('new user registers a company and waits for approval', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await signIn(tester);
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
    final uid = FakeAuthRepository.userFor('owner@jcbworks.in').uid;
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
