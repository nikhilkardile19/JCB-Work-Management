import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jcb_work_management/core/errors/error_log.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/reports/domain/reports.dart';

import '../helpers/pump_app.dart';
import 'billing_flow_test.dart' show seedBilling;
import 'fuel_flow_test.dart' show seedFuelMasters;
import 'reports_flow_test.dart' show pumpWithBilling;
import 'work_flow_test.dart' show seedMasters;

/// Small phone, large phone and tablet; normal and 2x text scale.
const _sizes = [Size(320, 640), Size(411, 891), Size(800, 1280)];

void main() {
  for (final size in _sizes) {
    for (final scale in [1.0, 2.0]) {
      final label = '${size.width.toInt()}dp, text x$scale';

      void setView(WidgetTester tester) {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }

      testWidgets('login and setup fit at $label', (tester) async {
        setView(tester);
        await pumpApp(tester);
        expect(tester.takeException(), isNull, reason: 'login');
        await tester.enterText(
          find.byKey(const Key('login_email')),
          'owner@jcbworks.in',
        );
        await tapAndSettle(tester, find.byKey(const Key('login_submit')));
        await scrollTo(tester, find.byKey(const Key('code_submit')));
        expect(tester.takeException(), isNull, reason: 'activation code');
        await tapAndSettle(tester, find.byKey(const Key('code_change_email')));
        await tapAndSettle(tester, find.byKey(const Key('login_sign_up')));
        await scrollTo(tester, find.byKey(const Key('signup_email')));
        await scrollTo(tester, find.byKey(const Key('company_submit')));
        expect(tester.takeException(), isNull, reason: 'sign-up');
        await unmount(tester);

        await pumpApp(tester, harness: TestHarness.signedIn());
        expect(find.text('Set up your company'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'setup');
        await unmount(tester);

        await pumpApp(
          tester,
          harness: TestHarness.signedIn(
            companies: [
              membership('p', 'Pending Co', status: CompanyStatus.pending),
            ],
          ),
        );
        expect(tester.takeException(), isNull, reason: 'status');
        await unmount(tester);
      });

      testWidgets('app tabs fit at $label', (tester) async {
        setView(tester);
        await pumpApp(
          tester,
          harness: TestHarness.signedIn(
            companies: [membership('a', 'Sai Earthmovers & Infra Pvt Ltd')],
          ),
        );
        for (final tab in ['Work', 'Billing', 'More', 'Dashboard']) {
          await tapAndSettle(tester, find.text(tab).last);
          expect(tester.takeException(), isNull, reason: tab);
        }
        await tapAndSettle(tester, find.text('More').last);
        await tapAndSettle(tester, find.byKey(const Key('more_company')));
        expect(tester.takeException(), isNull, reason: 'company profile');
        await unmount(tester);
      });

      testWidgets('master screens fit at $label', (tester) async {
        setView(tester);
        final h = TestHarness.signedIn(
          companies: [membership('co1', 'Sai Earthmovers & Infra Pvt Ltd')],
        );
        await h.db
            .into(h.db.clients)
            .insert(
              ClientsCompanion.insert(
                id: 'c1',
                companyId: 'co1',
                name: 'Maharashtra State Road Development Corporation Ltd',
                createdAt: 0,
                updatedAt: 0,
                createdBy: 'x',
                updatedBy: 'x',
              ),
            );
        await h.db
            .into(h.db.sites)
            .insert(
              SitesCompanion.insert(
                id: 's1',
                companyId: 'co1',
                clientId: 'c1',
                name: 'Samruddhi Expressway Package 7, Km 312',
                createdAt: 0,
                updatedAt: 0,
                createdBy: 'x',
                updatedBy: 'x',
              ),
            );
        await pumpApp(tester, harness: h);
        await tapAndSettle(tester, find.text('More').last);
        await tapAndSettle(tester, find.byKey(const Key('more_master_sites')));
        expect(tester.takeException(), isNull, reason: 'site list');
        await tapAndSettle(tester, find.byKey(const Key('master_tile_s1')));
        expect(tester.takeException(), isNull, reason: 'site detail');
        await tapAndSettle(tester, find.byKey(const Key('master_edit')));
        expect(tester.takeException(), isNull, reason: 'site form');
        await unmount(tester);
      });

      testWidgets('work log screens fit at $label', (tester) async {
        setView(tester);
        final h = TestHarness.signedIn(
          companies: [membership('co1', 'Sai Earthmovers & Infra Pvt Ltd')],
        );
        await seedMasters(h.db);
        await pumpApp(tester, harness: h);
        await tapAndSettle(tester, find.text('Work').last);
        await tapAndSettle(tester, find.byKey(const Key('work_add')));
        expect(tester.takeException(), isNull, reason: 'form');
        await tapAndSettle(
          tester,
          find.descendant(
            of: find.byKey(const Key('start_reading')),
            matching: find.byKey(const Key('reading_take_photo')),
          ),
        );
        await tapAndSettle(tester, find.byKey(const Key('reading_use_last')));
        await tapAndSettle(tester, find.byKey(const Key('work_save_draft')));
        expect(tester.takeException(), isNull, reason: 'list');
        await tapAndSettle(tester, find.text('Running'));
        expect(tester.takeException(), isNull, reason: 'detail');
        await unmount(tester);
      });

      testWidgets('fuel screens fit at $label', (tester) async {
        setView(tester);
        final h = TestHarness.signedIn(
          companies: [membership('co1', 'Sai Earthmovers & Infra Pvt Ltd')],
        );
        await seedFuelMasters(h.db);
        await pumpApp(tester, harness: h);
        await tapAndSettle(tester, find.text('Fuel').last);
        expect(tester.takeException(), isNull, reason: 'fuel tab');
        await tapAndSettle(tester, find.byKey(const Key('fuel_add')));
        expect(tester.takeException(), isNull, reason: 'fuel form');
        await tester.enterText(find.byKey(const Key('fuel_litres')), '1234.56');
        await tester.enterText(find.byKey(const Key('fuel_price')), '102.35');
        await tapAndSettle(tester, find.byKey(const Key('fuel_machine')));
        await tapAndSettle(tester, find.text('JCB 3DX').last);
        await tapAndSettle(tester, find.byKey(const Key('fuel_save')));
        expect(tester.takeException(), isNull, reason: 'fuel list');
        await tapAndSettle(tester, find.byType(Card).last);
        expect(tester.takeException(), isNull, reason: 'fuel detail');
        await unmount(tester);
      });

      testWidgets('billing screens fit at $label', (tester) async {
        setView(tester);
        final h = TestHarness.signedIn(
          companies: [membership('co1', 'Sai Earthmovers & Infra Pvt Ltd')],
        );
        await seedBilling(h.db);
        await pumpApp(tester, harness: h);
        await tapAndSettle(tester, find.text('Billing').last);
        expect(tester.takeException(), isNull, reason: 'billing tab');
        await tapAndSettle(tester, find.byKey(const Key('invoice_add')));
        await tapAndSettle(tester, find.byKey(const Key('invoice_client')));
        await tapAndSettle(tester, find.text('Patil Constructions').last);
        expect(tester.takeException(), isNull, reason: 'builder');
        await tapAndSettle(tester, find.byKey(const Key('invoice_save')));
        expect(tester.takeException(), isNull, reason: 'detail');
        await tapAndSettle(tester, find.byKey(const Key('invoice_finalize')));
        await tapAndSettle(tester, find.text('Finalize').last);
        await tapAndSettle(
          tester,
          find.byKey(const Key('invoice_record_payment')),
        );
        expect(tester.takeException(), isNull, reason: 'payment sheet');
        await unmount(tester);
      });

      testWidgets('license screens fit at $label', (tester) async {
        setView(tester);
        final h = TestHarness.signedIn(
          companies: [membership('co1', 'Sai Earthmovers & Infra Pvt Ltd')],
          licensed: false,
        );
        await pumpApp(tester, harness: h);
        expect(find.text('Activate this phone'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'activation');
        await tester.enterText(
          find.byKey(const Key('activation_code')),
          validActivationCode,
        );
        await tapAndSettle(tester, find.byKey(const Key('activation_submit')));
        await tapTab(tester, 'More');
        await tapAndSettle(tester, find.byKey(const Key('more_license')));
        expect(tester.takeException(), isNull, reason: 'license screen');
        await unmount(tester);
      });

      testWidgets('replacement and users screens fit at $label', (
        tester,
      ) async {
        setView(tester);
        final h = TestHarness.signedIn(
          companies: [membership('co1', 'Sai Earthmovers & Infra Pvt Ltd')],
          licensed: false,
        );
        h.licenses.deny = 'device_limit';
        await pumpApp(tester, harness: h);
        await tester.enterText(
          find.byKey(const Key('activation_code')),
          validActivationCode,
        );
        await tapAndSettle(tester, find.byKey(const Key('activation_submit')));
        await tapAndSettle(
          tester,
          find.byKey(const Key('activation_request_replacement')),
        );
        expect(tester.takeException(), isNull, reason: 'replacement form');
        await tapAndSettle(
          tester,
          find.byKey(const Key('replacement_reason_Phone lost')),
        );
        await tapAndSettle(tester, find.byKey(const Key('replacement_submit')));
        expect(tester.takeException(), isNull, reason: 'replacement pending');
        h.licenses.deny = null;
        h.replacements.decision = 'approved';
        await tapAndSettle(tester, find.text('Check again'));
        await tapTab(tester, 'More');
        await tapAndSettle(tester, find.byKey(const Key('more_users')));
        expect(tester.takeException(), isNull, reason: 'users');
        await tapAndSettle(tester, find.byKey(const Key('users_invite')));
        expect(tester.takeException(), isNull, reason: 'invite sheet');
        await unmount(tester);
      });

      testWidgets('reports, sync and privacy fit at $label', (tester) async {
        setView(tester);
        final (h, _) = await pumpWithBilling(tester);
        await tester.runAsync(
          () => ErrorLog(h.db).record(
            StateError('Unexpected response from the server ' * 5),
            StackTrace.current,
            context: 'Sync',
          ),
        );
        await tapTab(tester, 'More');
        await tapAndSettle(tester, find.byKey(const Key('more_reports')));
        expect(tester.takeException(), isNull, reason: 'reports');
        for (final kind in ReportKind.values) {
          await tapAndSettle(tester, find.byKey(Key('report_${kind.name}')));
          expect(tester.takeException(), isNull, reason: kind.name);
          await tester.pageBack();
          await settle(tester);
        }
        await tapAndSettle(tester, find.byKey(const Key('report_device_sync')));
        await tapAndSettle(tester, find.byKey(const Key('sync_error_0')));
        expect(tester.takeException(), isNull, reason: 'sync and errors');
        await tester.pageBack();
        await settle(tester);
        await tester.pageBack();
        await settle(tester);
        await tapAndSettle(tester, find.byKey(const Key('more_privacy')));
        expect(tester.takeException(), isNull, reason: 'privacy');
        await unmount(tester);
      });
    }
  }
}
