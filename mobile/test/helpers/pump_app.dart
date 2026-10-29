import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/app/app.dart';
import 'package:jcb_work_management/core/connectivity/connectivity_provider.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/data/local/database_provider.dart';
import 'package:jcb_work_management/features/auth/application/auth_providers.dart';
import 'package:jcb_work_management/features/company/application/company_providers.dart';
import 'package:jcb_work_management/features/billing/application/billing_providers.dart';
import 'package:jcb_work_management/features/company/domain/company.dart';
import 'package:jcb_work_management/features/license/application/license_controller.dart';
import 'package:jcb_work_management/features/license/domain/license.dart';
import 'package:jcb_work_management/features/sync/application/sync_controller.dart';
import 'package:jcb_work_management/features/users/application/users_providers.dart';
import 'package:jcb_work_management/features/users/data/company_users_service.dart';
import 'package:jcb_work_management/features/work/application/work_providers.dart';

import 'fake_remote_store.dart';
import 'fakes.dart';

export 'package:jcb_work_management/features/company/domain/company.dart'
    show CompanyStatus;

export 'fake_remote_store.dart';
export 'fakes.dart';

AppDatabase memoryDatabase() => AppDatabase(NativeDatabase.memory());

class TestHarness {
  TestHarness({
    AppDatabase? db,
    FakeAuthRepository? auth,
    FakeCompanyRemote? remote,
    this.licensed = true,
  }) : db = db ?? memoryDatabase(),
       auth = auth ?? FakeAuthRepository(),
       remote = remote ?? FakeCompanyRemote();

  final camera = FakePhotoCapture();
  final location = FakeLocation();
  final photos = FakePhotoStore();
  final invoiceNumbers = FakeInvoiceNumbers();
  final server = FakeRemoteStore();
  final licenses = FakeLicenseService();
  final replacements = FakeReplacementService();
  late final users = FakeCompanyUsersService([
    CompanyMember(
      uid: auth.currentUid ?? 'owner',
      email: 'owner@jcbworks.in',
      role: 'owner',
      active: true,
    ),
  ]);

  /// When true the license is treated as valid (tests of other features);
  /// license tests set it false and drive the real license controller.
  final bool licensed;

  /// Test clock for license time rules.
  DateTime now = DateTime.now();

  /// Harness with [email] already signed in and member of [companies].
  factory TestHarness.signedIn({
    String email = 'owner@jcbworks.in',
    List<CompanyMembership> companies = const [],
    bool licensed = true,
  }) {
    final user = FakeAuthRepository.userFor(email);
    final remote = FakeCompanyRemote()..memberships[user.uid] = [...companies];
    return TestHarness(
      auth: FakeAuthRepository(signedIn: user),
      remote: remote,
      licensed: licensed,
    );
  }

  final AppDatabase db;
  final FakeAuthRepository auth;
  final FakeCompanyRemote remote;
}

/// Pumps the full app against fakes and an in-memory database.
Future<TestHarness> pumpApp(
  WidgetTester tester, {
  bool online = true,
  TestHarness? harness,
}) async {
  final h = harness ?? TestHarness();
  addTearDown(h.db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(h.db),
        authRepositoryProvider.overrideWithValue(h.auth),
        companyRemoteSourceProvider.overrideWithValue(h.remote),
        isOnlineProvider.overrideWith((ref) => Stream.value(online)),
        photoCaptureServiceProvider.overrideWithValue(h.camera),
        locationServiceProvider.overrideWithValue(h.location),
        photoStoreProvider.overrideWithValue(h.photos),
        invoiceNumberServiceProvider.overrideWithValue(h.invoiceNumbers),
        remoteStoreProvider.overrideWithValue(h.server),
        autoSyncProvider.overrideWithValue(false),
        licenseServiceProvider.overrideWithValue(h.licenses),
        replacementServiceProvider.overrideWithValue(h.replacements),
        companyUsersServiceProvider.overrideWithValue(h.users),
        autoLicenseCheckProvider.overrideWithValue(false),
        clockProvider.overrideWithValue(() => h.now),
        if (h.licensed)
          licenseAccessProvider.overrideWithValue(const AsyncData(LicenseOk())),
      ],
      child: const JcbApp(),
    ),
  );
  await settle(tester);
  return h;
}

/// pumpAndSettle that also lets drift's async queries complete.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

/// The screen's main vertical list: skips the internal scrollables of text
/// fields and horizontal scrollers.
Finder pageScrollable() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .evaluate()
    .where((e) => e.findAncestorWidgetOfExactType<EditableText>() == null)
    .map((e) => find.byElementPredicate((x) => x == e))
    .last;

/// Scrolls [finder] into view (building it if the list is lazy), then taps.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  // Dismiss the keyboard like a user would, so a focused field doesn't
  // scroll itself back into view after we scroll to the target.
  FocusManager.instance.primaryFocus?.unfocus();
  // Floating snack bars can sit over bottom buttons; a user would wait.
  for (final m in tester.stateList<ScaffoldMessengerState>(
    find.byType(ScaffoldMessenger),
  )) {
    m.clearSnackBars();
  }
  await settle(tester);
  if (finder.evaluate().isEmpty) {
    final scrollable = pageScrollable();
    try {
      await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    } on StateError {
      await tester.scrollUntilVisible(finder, -200, scrollable: scrollable);
    }
  }
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
  await settle(tester);
}

/// Unmounts the app so drift stream subscriptions are cancelled.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await settle(tester);
}

/// Scrolls the page until [finder] is built and visible (lazy lists).
Future<Finder> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    try {
      await tester.scrollUntilVisible(
        finder,
        -200,
        scrollable: pageScrollable(),
      );
    } on StateError {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: pageScrollable(),
      );
    }
    await settle(tester);
  }
  return finder;
}

/// Taps a bottom-navigation tab by its label.
Future<void> tapTab(WidgetTester tester, String label) => tapAndSettle(
  tester,
  find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
);
