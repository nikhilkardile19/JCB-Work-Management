import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import 'reports_flow_test.dart' show pumpWithBilling;

/// Android accessibility guidelines (sprint doc §1.3): 48dp tap targets,
/// every control labelled for TalkBack, and readable text contrast.
Future<void> expectAccessible(WidgetTester tester, String screen) async {
  await expectLater(
    tester,
    meetsGuideline(androidTapTargetGuideline),
    reason: '$screen: tap targets',
  );
  await expectLater(
    tester,
    meetsGuideline(labeledTapTargetGuideline),
    reason: '$screen: labels',
  );
  await expectLater(
    tester,
    meetsGuideline(textContrastGuideline),
    reason: '$screen: contrast',
  );
}

void main() {
  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      /// A phone-width screen tall enough to show whole pages: every
      /// element is checked, and none is clipped at the screen edge (which
      /// confuses the contrast check).
      void setView(WidgetTester tester) {
        tester.view.physicalSize = const Size(411, 2400) * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      }

      testWidgets('sign-in meets the guidelines', (tester) async {
        setView(tester);
        final semantics = tester.ensureSemantics();
        await pumpApp(tester);
        await expectAccessible(tester, 'login');
        await unmount(tester);
        semantics.dispose();
      });

      testWidgets('main tabs and forms meet the guidelines', (tester) async {
        setView(tester);
        final semantics = tester.ensureSemantics();
        await pumpWithBilling(tester);
        await expectAccessible(tester, 'dashboard');

        await tapTab(tester, 'Work');
        await expectAccessible(tester, 'work list');
        await tapAndSettle(tester, find.byKey(const Key('work_add')));
        await expectAccessible(tester, 'work log form');
        await tester.pageBack();
        await settle(tester);

        await tapTab(tester, 'Fuel');
        await expectAccessible(tester, 'fuel');
        await tapAndSettle(tester, find.byKey(const Key('fuel_add')));
        await expectAccessible(tester, 'fuel form');
        await tester.pageBack();
        await settle(tester);

        await tapTab(tester, 'Billing');
        await expectAccessible(tester, 'billing');
        await tapAndSettle(
          tester,
          find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('invoice_tile_'),
          ),
        );
        await expectAccessible(tester, 'invoice detail');
        await unmount(tester);
        semantics.dispose();
      });

      testWidgets('reports, sync and privacy meet the guidelines', (
        tester,
      ) async {
        setView(tester);
        final semantics = tester.ensureSemantics();
        await pumpWithBilling(tester);
        await tapTab(tester, 'More');
        await tapAndSettle(tester, find.byKey(const Key('more_reports')));
        await expectAccessible(tester, 'reports');
        await tapAndSettle(tester, find.byKey(const Key('report_work')));
        await expectAccessible(tester, 'work report');
        await tester.pageBack();
        await settle(tester);
        await tapAndSettle(tester, find.byKey(const Key('report_outstanding')));
        await expectAccessible(tester, 'outstanding report');
        await tester.pageBack();
        await settle(tester);
        await tapAndSettle(tester, find.byKey(const Key('report_device_sync')));
        await expectAccessible(tester, 'sync and device');
        await tester.pageBack();
        await settle(tester);
        await tester.pageBack();
        await settle(tester);

        await tapAndSettle(tester, find.byKey(const Key('more_privacy')));
        await expectAccessible(tester, 'privacy');
        await tester.pageBack();
        await settle(tester);
        await tapAndSettle(tester, find.byKey(const Key('more_license')));
        await expectAccessible(tester, 'license');
        await unmount(tester);
        semantics.dispose();
      });

      testWidgets('masters, company and users meet the guidelines', (
        tester,
      ) async {
        setView(tester);
        final semantics = tester.ensureSemantics();
        await pumpWithBilling(tester);
        await tapTab(tester, 'More');
        await expectAccessible(tester, 'more');
        await tapAndSettle(tester, find.byKey(const Key('more_master_sites')));
        await expectAccessible(tester, 'site list');
        await tapAndSettle(tester, find.byKey(const Key('master_add')));
        await expectAccessible(tester, 'site form');
        await tester.pageBack();
        await settle(tester);
        await tester.pageBack();
        await settle(tester);
        await tapAndSettle(tester, find.byKey(const Key('more_company')));
        await expectAccessible(tester, 'company profile');
        await tester.pageBack();
        await settle(tester);
        await tapAndSettle(tester, find.byKey(const Key('more_users')));
        await expectAccessible(tester, 'users');
        await unmount(tester);
        semantics.dispose();
      });
    });
  }
}
