import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/masters/presentation/master_list_screen.dart';

import '../helpers/pump_app.dart';

Future<TestHarness> pumpOwner(
  WidgetTester tester, {
  bool online = false,
  CompanyRole role = CompanyRole.owner,
}) async {
  final h = TestHarness.signedIn(
    companies: [membership('co1', 'Sai Earthmovers', role: role)],
  );
  // Cache the company once, then run offline (masters must work offline).
  await pumpApp(tester, harness: h);
  if (!online) {
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
    h.remote.offline = true;
    await pumpApp(tester, harness: h, online: false);
  }
  await tapAndSettle(tester, find.text('More'));
  return h;
}

Future<void> openMaster(WidgetTester tester, String slug) =>
    tapAndSettle(tester, find.byKey(Key('more_master_$slug')));

Future<void> fill(WidgetTester tester, String key, String text) async {
  final f = find.byKey(Key('field_$key'));
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(f, 200, scrollable: pageScrollable());
  }
  await tester.enterText(f, text);
}

Future<void> addClient(WidgetTester tester, String name) async {
  await tapAndSettle(tester, find.byKey(const Key('master_add')));
  await fill(tester, 'name', name);
  await fill(tester, 'phone', '98765 43210');
  await tapAndSettle(tester, find.byKey(const Key('master_save')));
}

void main() {
  testWidgets(
    'owner creates, searches, edits and deactivates clients offline',
    (tester) async {
      final h = await pumpOwner(tester);
      expect(find.text('0 active'), findsNWidgets(5));
      await openMaster(tester, 'clients');
      expect(find.text('No clients yet'), findsOneWidget);

      // Validation.
      await tapAndSettle(tester, find.byKey(const Key('master_add')));
      await tapAndSettle(tester, find.byKey(const Key('master_save')));
      expect(find.text('Enter the client name'), findsOneWidget);
      await tester.pageBack();
      await settle(tester);

      await addClient(tester, 'Patil Constructions');
      await addClient(tester, 'Shinde Infra');
      expect(find.text('Client saved'), findsOneWidget);
      expect(find.byType(MasterTile), findsNWidgets(2));

      // Duplicate detection (case-insensitive) shows on the field.
      await addClient(tester, 'patil constructions');
      expect(find.textContaining('already exists'), findsOneWidget);
      await tester.pageBack();
      await settle(tester);
      await tapAndSettle(tester, find.text('Discard'));

      // Search.
      await tester.enterText(find.byKey(const Key('master_search')), 'shin');
      await settle(tester);
      expect(find.byType(MasterTile), findsOneWidget);
      await tester.enterText(find.byKey(const Key('master_search')), 'zzz');
      await settle(tester);
      expect(find.text('No matches'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('master_search')), '');
      await settle(tester);

      // Edit.
      await tapAndSettle(tester, find.text('Shinde Infra'));
      await tapAndSettle(tester, find.byKey(const Key('master_edit')));
      await fill(tester, 'name', 'Shinde Infra Projects');
      await tapAndSettle(tester, find.byKey(const Key('master_save')));
      expect(find.text('Shinde Infra Projects'), findsOneWidget);

      // Deactivate → disappears from Active, appears under Inactive.
      await tapAndSettle(tester, find.byKey(const Key('master_toggle_active')));
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, 'Deactivate'),
      );
      expect(find.text('Inactive'), findsWidgets);
      await tester.pageBack();
      await settle(tester);
      expect(find.text('Shinde Infra Projects'), findsNothing);
      await tapAndSettle(tester, find.text('Inactive').first);
      expect(find.text('Shinde Infra Projects'), findsOneWidget);

      final stored = await h.db.select(h.db.clients).get();
      expect(stored.every((c) => c.companyId == 'co1'), isTrue);
      expect(stored.every((c) => c.syncStatus == 'pending'), isTrue);
      await unmount(tester);
    },
  );

  testWidgets('sites need a client, show it, and block deleting that client', (
    tester,
  ) async {
    await pumpOwner(tester);
    await openMaster(tester, 'sites');
    await tapAndSettle(tester, find.byKey(const Key('master_add')));
    expect(find.text('Add a client first'), findsOneWidget);
    await tapAndSettle(tester, find.text('Add client'));
    await fill(tester, 'name', 'Patil Constructions');
    await tapAndSettle(tester, find.byKey(const Key('master_save')));
    // Back on the site form, now with a client to choose.
    await tapAndSettle(tester, find.byKey(const Key('field_clientId')));
    await tapAndSettle(tester, find.text('Patil Constructions').last);
    await fill(tester, 'name', 'Hinjewadi Phase 3');
    await fill(tester, 'defaultHourlyRatePaise', '1500');
    await tapAndSettle(tester, find.byKey(const Key('master_save')));
    expect(find.text('Hinjewadi Phase 3'), findsOneWidget);
    expect(find.textContaining('Patil Constructions'), findsOneWidget);

    // Detail shows the formatted rate and links to the client.
    await tapAndSettle(tester, find.text('Hinjewadi Phase 3'));
    expect(find.text('₹1,500.00 / hour'), findsOneWidget);
    await tapAndSettle(tester, find.text('Patil Constructions'));
    expect(find.text('Sites (1)'), findsOneWidget);

    // Deleting the client is refused because a site uses it.
    await tapAndSettle(tester, find.byKey(const Key('master_delete')));
    expect(find.text("Can't delete Patil Constructions"), findsOneWidget);
    await tapAndSettle(tester, find.text('Keep'));
    expect(find.text('Sites (1)'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('unreferenced machine can be deleted after confirmation', (
    tester,
  ) async {
    final h = await pumpOwner(tester);
    await openMaster(tester, 'machines');
    await tapAndSettle(tester, find.byKey(const Key('master_add')));
    await fill(tester, 'name', 'JCB 3DX');
    await fill(tester, 'registrationNumber', 'mh12ab1234');
    await fill(tester, 'initialMeterReading', '1234.5');
    await tapAndSettle(tester, find.byKey(const Key('master_save')));
    expect(find.textContaining('MH12AB1234'), findsOneWidget);

    await tapAndSettle(tester, find.text('JCB 3DX'));
    expect(find.text('1,234.5 h'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('master_delete')));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));
    expect(find.text('No machines yet'), findsOneWidget);
    final row = await h.db.select(h.db.machines).getSingle();
    expect(row.deletedAt, isNotNull);
    expect(row.initialMeterReading, 123450);
    await unmount(tester);
  });

  testWidgets('operators and pumps can be added', (tester) async {
    await pumpOwner(tester);
    await openMaster(tester, 'operators');
    await tapAndSettle(tester, find.byKey(const Key('master_add')));
    await fill(tester, 'name', 'Suresh Jadhav');
    await fill(tester, 'code', 'op-07');
    await tapAndSettle(tester, find.byKey(const Key('master_save')));
    expect(find.textContaining('OP-07'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    expect(find.text('1 active'), findsOneWidget);

    await openMaster(tester, 'petrol-pumps');
    await tapAndSettle(tester, find.byKey(const Key('master_add')));
    await fill(tester, 'name', 'HP Petrol Pump, Wakad');
    await tapAndSettle(tester, find.byKey(const Key('master_save')));
    expect(find.text('HP Petrol Pump, Wakad'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('unsaved changes ask before leaving', (tester) async {
    await pumpOwner(tester);
    await openMaster(tester, 'clients');
    await tapAndSettle(tester, find.byKey(const Key('master_add')));
    await fill(tester, 'name', 'Half typed');
    await settle(tester);
    await tester.pageBack();
    await settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    await tapAndSettle(tester, find.text('Keep editing'));
    expect(find.text('New client'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    await tapAndSettle(tester, find.text('Discard'));
    expect(find.text('No clients yet'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('operators (role) can view but not change masters', (
    tester,
  ) async {
    final h = await pumpOwner(tester, role: CompanyRole.operator);
    final repoScope = h.db; // seed a client directly
    await repoScope
        .into(repoScope.clients)
        .insert(
          ClientsCompanion.insert(
            id: 'c1',
            companyId: 'co1',
            name: 'Seeded Client',
            createdAt: 0,
            updatedAt: 0,
            createdBy: 'x',
            updatedBy: 'x',
          ),
        );
    await openMaster(tester, 'clients');
    expect(find.text('Seeded Client'), findsOneWidget);
    expect(find.byKey(const Key('master_add')), findsNothing);
    await tapAndSettle(tester, find.text('Seeded Client'));
    expect(find.byKey(const Key('master_edit')), findsNothing);
    expect(find.byKey(const Key('master_delete')), findsNothing);
    await unmount(tester);
  });

  testWidgets("another company's records are never shown", (tester) async {
    final h = await pumpOwner(tester);
    await h.db
        .into(h.db.clients)
        .insert(
          ClientsCompanion.insert(
            id: 'x1',
            companyId: 'other-co',
            name: 'Other Company Client',
            createdAt: 0,
            updatedAt: 0,
            createdBy: 'x',
            updatedBy: 'x',
          ),
        );
    await openMaster(tester, 'clients');
    expect(find.text('Other Company Client'), findsNothing);
    expect(find.text('No clients yet'), findsOneWidget);
    await unmount(tester);
  });
}
