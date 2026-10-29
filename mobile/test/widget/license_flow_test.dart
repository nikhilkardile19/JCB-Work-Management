import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/dashboard/dashboard_screen.dart';
import 'package:jcb_work_management/features/license/domain/license.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';

import '../helpers/pump_app.dart';

const co = 'co1';
final uid = FakeAuthRepository.userFor('owner@jcbworks.in').uid;

TestHarness harness() => TestHarness.signedIn(
  companies: [membership(co, 'Sai Earthmovers')],
  licensed: false,
);

/// Puts a license state in the phone's cache as if checked [ago].
Future<void> cacheLicense(
  TestHarness h, {
  LicenseStatus status = LicenseStatus.active,
  Duration ago = Duration.zero,
}) => h.db.writeSetting(
  'license:$co:$uid',
  LicenseSnapshot(
    licenseId: 'lic1',
    status: status,
    deviceStatus: DeviceStatus.active,
    validUntil: DateTime.utc(2027, 3, 31).millisecondsSinceEpoch,
    maxDevices: 2,
    lastValidatedAt: h.now.subtract(ago).toUtc().millisecondsSinceEpoch,
  ).toJson(),
);

void main() {
  testWidgets('a new phone must be activated with a valid code', (
    tester,
  ) async {
    final h = harness();
    await pumpApp(tester, harness: h);
    expect(find.text('Activate this phone'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.enterText(
      find.byKey(const Key('activation_code')),
      'JCBW-WRONG-CODE-0000',
    );
    await tapAndSettle(tester, find.byKey(const Key('activation_submit')));
    expect(
      find.text('That activation code is not valid for this company.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('activation_code')),
      validActivationCode.toLowerCase(),
    );
    await tapAndSettle(tester, find.byKey(const Key('activation_submit')));
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(h.licenses.activations, 1);
    expect(
      await h.db.readSetting('license:$co:$uid'),
      contains('"status":"active"'),
    );
    await unmount(tester);
  });

  testWidgets('activation needs internet', (tester) async {
    await pumpApp(tester, harness: harness(), online: false);
    expect(find.text('Waiting for internet'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('device limit refusal is explained', (tester) async {
    final h = harness()..licenses.deny = 'device_limit';
    await pumpApp(tester, harness: h);
    await tester.enterText(
      find.byKey(const Key('activation_code')),
      validActivationCode,
    );
    await tapAndSettle(tester, find.byKey(const Key('activation_submit')));
    expect(find.text('Refused: device_limit'), findsOneWidget);
    expect(find.text('Activate this phone'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'offline within the grace period: still editable, with a warning',
    (tester) async {
      final h = harness();
      await cacheLicense(h, ago: const Duration(days: 3, hours: 1));
      await pumpApp(tester, harness: h, online: false);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.textContaining('Connect within 4 days'), findsOneWidget);
      await tapTab(tester, 'Work');
      await tapAndSettle(tester, find.byKey(const Key('work_add')));
      expect(find.text('Log work'), findsWidgets, reason: 'form opens');
      await unmount(tester);
    },
  );

  testWidgets(
    'offline too long: read-only — forms redirect, data still visible',
    (tester) async {
      final h = harness();
      await MastersRepository(h.db).save(
        MasterKind.clients,
        const MasterScope(companyId: co, userId: 'x'),
        {'name': 'Patil'},
      );
      await cacheLicense(h, ago: const Duration(days: 8));
      await pumpApp(tester, harness: h, online: false);
      expect(
        find.textContaining("hasn't been checked for too long"),
        findsOneWidget,
      );

      await tapTab(tester, 'Work');
      await tapAndSettle(tester, find.byKey(const Key('work_add')));
      expect(find.text('License'), findsWidgets);
      expect(find.text('Read-only'), findsOneWidget);
      await tester.pageBack();
      await settle(tester);

      // Viewing works; changing via in-place actions is refused with an explanation.
      await tapTab(tester, 'More');
      await tapAndSettle(tester, find.byKey(const Key('more_master_clients')));
      await tapAndSettle(tester, find.text('Patil'));
      await tapAndSettle(tester, find.byKey(const Key('master_toggle_active')));
      expect(find.text('Read-only mode'), findsOneWidget);
      await tapAndSettle(tester, find.text('OK'));
      expect((await h.db.select(h.db.clients).getSingle()).isActive, isTrue);
      await unmount(tester);
    },
  );

  testWidgets('Check now picks up a suspension from the server', (
    tester,
  ) async {
    final h = harness();
    await cacheLicense(h);
    await pumpApp(tester, harness: h);
    expect(find.byKey(const Key('license_banner')), findsNothing);
    h.licenses.licenseStatus = 'suspended';
    await tapTab(tester, 'More');
    await tapAndSettle(tester, find.byKey(const Key('more_license')));
    expect(find.text('Active'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('license_check')));
    expect(find.text('Read-only'), findsOneWidget);
    expect(find.text('This license is suspended.'), findsWidgets);
    expect(h.licenses.validations, 1);
    await unmount(tester);
  });

  testWidgets('read-only phones download but do not upload', (tester) async {
    final h = harness();
    await MastersRepository(h.db).save(
      MasterKind.clients,
      const MasterScope(companyId: co, userId: 'x'),
      {'name': 'Patil'},
    );
    await cacheLicense(h, status: LicenseStatus.expired);
    await pumpApp(tester, harness: h);
    await tapTab(tester, 'More');
    await tapAndSettle(tester, find.byKey(const Key('more_sync')));
    await tapAndSettle(tester, find.byKey(const Key('sync_now')));
    expect(h.server.pushCalls, 0);
    expect(find.textContaining('waiting to upload'), findsOneWidget);
    await unmount(tester);
  });
}
