import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/fuel/data/fuel_repository.dart';
import 'package:jcb_work_management/features/fuel/domain/fuel_entry.dart';
import 'package:jcb_work_management/features/fuel/presentation/fuel_screen.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';
import 'package:jcb_work_management/features/work/data/work_log_repository.dart';
import 'package:jcb_work_management/features/work/domain/work_log.dart';

import '../helpers/pump_app.dart';

const company = 'co1';

class FuelSeed {
  late String machine, machine2, pump, client, site;
}

Future<FuelSeed> seedFuelMasters(AppDatabase db) async {
  final repo = MastersRepository(db);
  const s = MasterScope(companyId: company, userId: 'seed');
  final f = FuelSeed();
  f.machine = await repo.save(MasterKind.machines, s, {
    'name': 'JCB 3DX',
    'initialMeterReading': 0,
  });
  f.machine2 = await repo.save(MasterKind.machines, s, {
    'name': 'JCB 4DX',
    'initialMeterReading': 0,
  });
  f.pump = await repo.save(MasterKind.petrolPumps, s, {'name': 'HP Wakad'});
  f.client = await repo.save(MasterKind.clients, s, {
    'name': 'Patil Constructions',
  });
  f.site = await repo.save(MasterKind.sites, s, {
    'clientId': f.client,
    'name': 'Hinjewadi Yard',
  });
  return f;
}

Future<(TestHarness, FuelSeed)> pumpFuel(
  WidgetTester tester, {
  CompanyRole role = CompanyRole.owner,
  Future<void> Function(TestHarness, FuelSeed)? before,
}) async {
  final h = TestHarness.signedIn(
    companies: [membership(company, 'Sai Earthmovers', role: role)],
  );
  final seed = await seedFuelMasters(h.db);
  await before?.call(h, seed);
  await pumpApp(tester, harness: h, online: false);
  await tapAndSettle(tester, find.text('Fuel'));
  return (h, seed);
}

Future<void> pickDropdown(
  WidgetTester tester,
  String key,
  String option,
) async {
  await tapAndSettle(tester, find.byKey(Key(key)));
  await tapAndSettle(tester, find.text(option).last);
}

void main() {
  testWidgets(
    'record fuel offline with receipt; total, list and summary update',
    (tester) async {
      final (h, _) = await pumpFuel(tester);
      expect(find.text('No fuel this month'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const Key('fuel_add')));

      // Only one pump → preselected; two machines → choose.
      expect(find.text('HP Wakad'), findsOneWidget);
      await pickDropdown(tester, 'fuel_machine', 'JCB 4DX');
      await tester.enterText(find.byKey(const Key('fuel_litres')), '25.5');
      await tester.enterText(find.byKey(const Key('fuel_price')), '102.35');
      await settle(tester);
      expect(
        find.text('₹2,609.93'),
        findsOneWidget,
      ); // 25.5 × 102.35 = 2609.925 → half-up

      h.location.status = LocationStatus.captured;
      await tapAndSettle(tester, find.byKey(const Key('fuel_receipt_photo')));
      expect(find.textContaining('18.59120, 73.73890'), findsOneWidget);
      await pickDropdown(tester, 'fuel_client', 'Patil Constructions');
      await pickDropdown(
        tester,
        'fuel_site_${(await h.db.select(h.db.clients).getSingle()).id}',
        'Hinjewadi Yard',
      );
      await tapAndSettle(tester, find.byKey(const Key('fuel_save')));

      expect(find.text('Fuel entry saved'), findsOneWidget);
      expect(find.byType(FuelCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('fuel_summary')),
          matching: find.text('₹2,609.93'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('25.5 L · 1 fill'), findsOneWidget);

      final row = await h.db.select(h.db.fuelEntries).getSingle();
      expect(row.litresCl, 2550);
      expect(row.pricePerLitrePaise, 10235);
      expect(row.totalPaise, 260993);
      expect(row.receiptPhotoPath, startsWith('evidence/co1/'));
      expect(row.siteId, isNotNull);
      expect(row.syncStatus, 'pending');

      await tapAndSettle(tester, find.text('Dashboard'));
      expect(
        find.descendant(
          of: find.byKey(const Key('dash_fuel')),
          matching: find.text('₹2,609.93'),
        ),
        findsOneWidget,
      );
      await unmount(tester);
    },
  );

  testWidgets(
    'litres must be more than zero; price is prefilled from the last fill',
    (tester) async {
      final (h, _) = await pumpFuel(
        tester,
        before: (h, s) => FuelRepository(h.db).save(
          const WorkActor(
            companyId: company,
            userId: 'x',
            role: CompanyRole.owner,
          ),
          FuelInput(
            filledAt: DateTime.now().subtract(const Duration(days: 1)),
            machineId: s.machine,
            pumpId: s.pump,
            litresCl: 1000,
            pricePerLitrePaise: 9875,
          ),
        ),
      );
      await tapAndSettle(tester, find.byKey(const Key('fuel_add')));
      expect(find.text('98.75'), findsOneWidget);
      await pickDropdown(tester, 'fuel_machine', 'JCB 3DX');
      await tester.enterText(find.byKey(const Key('fuel_litres')), '0');
      await tapAndSettle(tester, find.byKey(const Key('fuel_save')));
      expect(find.text('Litres must be more than zero'), findsWidgets);
      expect(await h.db.select(h.db.fuelEntries).get(), hasLength(1));
      await unmount(tester);
    },
  );

  testWidgets('edit and delete own entry; history recorded', (tester) async {
    final (h, _) = await pumpFuel(tester);
    await tapAndSettle(tester, find.byKey(const Key('fuel_add')));
    await pickDropdown(tester, 'fuel_machine', 'JCB 3DX');
    await tester.enterText(find.byKey(const Key('fuel_litres')), '50');
    await tester.enterText(find.byKey(const Key('fuel_price')), '95');
    await tapAndSettle(tester, find.byKey(const Key('fuel_save')));
    expect(find.text('No receipt'), findsOneWidget);

    await tapAndSettle(tester, find.byType(FuelCard));
    expect(find.text('₹4,750.00'), findsWidgets);
    await tapAndSettle(tester, find.byKey(const Key('fuel_edit')));
    await tester.enterText(find.byKey(const Key('fuel_litres')), '60');
    await tapAndSettle(tester, find.byKey(const Key('fuel_save')));
    expect(await scrollTo(tester, find.text('₹5,700.00')), findsWidgets);
    expect(await scrollTo(tester, find.text('Edited')), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('fuel_delete')));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));
    expect(find.text('Fuel entry deleted'), findsOneWidget);
    expect(find.byType(FuelCard), findsNothing);
    expect(
      (await h.db.select(h.db.fuelEntries).getSingle()).deletedAt,
      isNotNull,
    );
    await unmount(tester);
  });

  testWidgets("operators can't edit someone else's entry; accounts can't add", (
    tester,
  ) async {
    await pumpFuel(
      tester,
      role: CompanyRole.operator,
      before: (h, s) => FuelRepository(h.db).save(
        const WorkActor(
          companyId: company,
          userId: 'someone-else',
          role: CompanyRole.operator,
        ),
        FuelInput(
          filledAt: DateTime.now(),
          machineId: s.machine,
          pumpId: s.pump,
          litresCl: 1000,
          pricePerLitrePaise: 9000,
        ),
      ),
    );
    expect(find.byKey(const Key('fuel_add')), findsOneWidget);
    await tapAndSettle(tester, find.byType(FuelCard));
    expect(find.byKey(const Key('fuel_edit')), findsNothing);
    expect(find.byKey(const Key('fuel_delete')), findsNothing);
    await unmount(tester);
  });

  testWidgets('accounts role views fuel but cannot add', (tester) async {
    await pumpFuel(tester, role: CompanyRole.accounts);
    expect(find.byKey(const Key('fuel_add')), findsNothing);
    await unmount(tester);
  });

  testWidgets('period chips switch the summary', (tester) async {
    await pumpFuel(
      tester,
      before: (h, s) async {
        final repo = FuelRepository(h.db);
        const a = WorkActor(
          companyId: company,
          userId: 'x',
          role: CompanyRole.owner,
        );
        final now = DateTime.now();
        await repo.save(
          a,
          FuelInput(
            filledAt: DateTime(now.year, now.month - 1, 10, 9),
            machineId: s.machine,
            pumpId: s.pump,
            litresCl: 1000,
            pricePerLitrePaise: 10000,
          ),
        );
      },
    );
    expect(find.text('No fuel this month'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('fuel_period_lastMonth')));
    expect(
      find.descendant(
        of: find.byKey(const Key('fuel_summary')),
        matching: find.text('₹1,000.00'),
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });
}
