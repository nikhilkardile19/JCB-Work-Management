import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/core/utils/units.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/evidence/photo_evidence.dart';
import 'package:jcb_work_management/features/fuel/data/fuel_repository.dart';
import 'package:jcb_work_management/features/fuel/domain/fuel_entry.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';
import 'package:jcb_work_management/features/work/data/work_log_repository.dart';
import 'package:jcb_work_management/features/work/domain/work_log.dart';

import '../helpers/pump_app.dart';

const owner = WorkActor(
  companyId: 'co',
  userId: 'owner',
  role: CompanyRole.owner,
);
const op = WorkActor(companyId: 'co', userId: 'op', role: CompanyRole.operator);
const op2 = WorkActor(
  companyId: 'co',
  userId: 'op2',
  role: CompanyRole.operator,
);
const accounts = WorkActor(
  companyId: 'co',
  userId: 'acc',
  role: CompanyRole.accounts,
);
const outsider = WorkActor(
  companyId: 'other',
  userId: 'x',
  role: CompanyRole.owner,
);

void main() {
  group('maths and units', () {
    test('total = litres × price, rounded half-up to the paisa', () {
      expect(
        FuelMath.total(2550, 10235),
        260993,
      ); // 25.50 L × ₹102.35 = ₹2,609.925
      expect(FuelMath.total(10000, 9000), 900000); // 100 L × ₹90
      expect(FuelMath.total(1, 1), 0); // 0.01 L × ₹0.01
      expect(FuelMath.total(50, 1), 1); // 0.5 paisa rounds up
    });

    test('litres parse and format', () {
      expect(Litres.parse('25.5'), 2550);
      expect(Litres.parse('1,200'), 120000);
      expect(Litres.parse('2.555'), isNull);
      expect(Litres.format(2550), '25.5 L');
    });

    test('average price is weighted by litres', () {
      const s = FuelSummary(
        totalPaise: 300000,
        litresCl: 3000,
        count: 2,
        byMachine: [],
      );
      expect(s.averagePricePaise, 10000);
      expect(FuelSummary.empty.averagePricePaise, isNull);
    });

    test('periods', () {
      final now = DateTime(2026, 10, 29); // Thursday
      expect(FuelPeriod.thisWeek.range(now), ('2026-10-26', '2026-10-29'));
      expect(FuelPeriod.thisMonth.range(now), ('2026-10-01', '2026-10-29'));
      expect(FuelPeriod.lastMonth.range(now), ('2026-09-01', '2026-09-30'));
      expect(FuelPeriod.lastMonth.range(DateTime(2026, 1, 15)), (
        '2025-12-01',
        '2025-12-31',
      ));
    });

    test('validation', () {
      FuelInput input({
        int? litres = 2000,
        int? price = 10000,
        String? site,
        String? client,
      }) => FuelInput(
        filledAt: DateTime(2026, 10, 29, 9),
        machineId: 'm',
        pumpId: 'p',
        litresCl: litres,
        pricePerLitrePaise: price,
        siteId: site,
        clientId: client,
      );
      expect(FuelRules.errors(input()), isEmpty);
      expect(FuelRules.errors(input(litres: 0)), contains('litres'));
      expect(FuelRules.errors(input(litres: null)), contains('litres'));
      expect(
        FuelRules.errors(input(litres: maxFuelLitresCl + 1)),
        contains('litres'),
      );
      expect(FuelRules.errors(input(price: null)), contains('price'));
      expect(
        FuelRules.errors(input(price: 0)),
        isEmpty,
        reason: 'free fuel is allowed, negative is not parseable',
      );
      expect(
        FuelRules.errors(input(price: maxPricePerLitrePaise + 1)),
        contains('price'),
      );
      expect(FuelRules.errors(input(site: 's')), contains('clientId'));
      final future = FuelInput(
        filledAt: DateTime.now().add(const Duration(days: 1)),
        machineId: 'm',
        pumpId: 'p',
        litresCl: 1,
        pricePerLitrePaise: 1,
      );
      expect(FuelRules.errors(future), contains('filledAt'));
    });
  });

  group('repository', () {
    late AppDatabase db;
    late FuelRepository repo;
    late MastersRepository masters;
    late String machine, machine2, pump, client, site;

    setUp(() async {
      db = memoryDatabase();
      repo = FuelRepository(db);
      masters = MastersRepository(db);
      const s = MasterScope(companyId: 'co', userId: 'owner');
      machine = await masters.save(MasterKind.machines, s, {
        'name': 'JCB 1',
        'initialMeterReading': 0,
      });
      machine2 = await masters.save(MasterKind.machines, s, {
        'name': 'JCB 2',
        'initialMeterReading': 0,
      });
      pump = await masters.save(MasterKind.petrolPumps, s, {
        'name': 'HP Wakad',
      });
      client = await masters.save(MasterKind.clients, s, {'name': 'Patil'});
      site = await masters.save(MasterKind.sites, s, {
        'clientId': client,
        'name': 'Yard',
      });
    });
    tearDown(() => db.close());

    FuelInput fuel({
      int litres = 5000,
      int price = 9500,
      String? m,
      DateTime? at,
      String? clientId,
      String? siteId,
      PhotoEvidence? receipt,
    }) => FuelInput(
      filledAt: at ?? DateTime(2026, 10, 29, 9, 30),
      machineId: m ?? machine,
      pumpId: pump,
      litresCl: litres,
      pricePerLitrePaise: price,
      clientId: clientId,
      siteId: siteId,
      receipt: receipt,
    );

    test(
      'saves with computed total, receipt evidence, sync and audit metadata',
      () async {
        final id = await repo.save(
          op,
          fuel(
            litres: 2550,
            price: 10235,
            clientId: client,
            siteId: site,
            receipt: const PhotoEvidence(
              photoPath: 'evidence/co/r.jpg',
              capturedAt: 5,
              locationStatus: LocationStatus.denied,
            ),
          ),
        );
        final v = (await repo.watchOne('co', id).first)!;
        expect(v.totalPaise, 260993);
        expect(v.machineName, 'JCB 1');
        expect(v.pumpName, 'HP Wakad');
        expect(v.siteName, 'Yard');
        expect(v.fuelDate, '2026-10-29');
        expect(v.receipt!.photoPath, 'evidence/co/r.jpg');
        expect(v.receipt!.locationStatus, LocationStatus.denied);
        final row = await db.select(db.fuelEntries).getSingle();
        expect(row.syncStatus, 'pending');
        expect(row.version, 1);
        expect(
          (await repo.watchHistory('co', id).first).single.action,
          'create',
        );
      },
    );

    test('rejects invalid input and foreign references', () async {
      await expectLater(
        repo.save(op, fuel(litres: 0)),
        throwsA(isA<FuelException>()),
      );
      await expectLater(
        repo.save(op, fuel(clientId: client, siteId: 'nope')),
        throwsA(
          isA<FuelException>().having((e) => e.fieldErrors.keys, 'k', [
            'siteId',
          ]),
        ),
      );
      await expectLater(
        repo.save(outsider, fuel()),
        throwsA(isA<FuelException>()),
      );
      expect(await db.select(db.fuelEntries).get(), isEmpty);
    });

    test(
      'accounts cannot record; operators edit only their own; owners edit any',
      () async {
        await expectLater(
          repo.save(accounts, fuel()),
          throwsA(isA<FuelException>()),
        );
        final id = await repo.save(op, fuel());
        await expectLater(
          repo.save(op2, fuel(litres: 1), id: id),
          throwsA(isA<FuelException>()),
        );
        await expectLater(repo.delete(op2, id), throwsA(isA<FuelException>()));
        await repo.save(op, fuel(litres: 6000), id: id);
        await repo.save(owner, fuel(litres: 6100), id: id);
        final v = (await repo.watchOne('co', id).first)!;
        expect(v.litresCl, 6100);
        expect(v.totalPaise, FuelMath.total(6100, 9500));
        final history = await repo.watchHistory('co', id).first;
        expect(history.map((h) => h.action), ['create', 'update', 'update']);
        expect(history.last.details!['litresCl'], {'from': 6000, 'to': 6100});
        final row = await db.select(db.fuelEntries).getSingle();
        expect(row.version, 3);
      },
    );

    test('delete is a pending-sync tombstone', () async {
      final id = await repo.save(op, fuel());
      await repo.delete(op, id);
      expect(await repo.watchList('co').first, isEmpty);
      final row = await db.select(db.fuelEntries).getSingle();
      expect(row.deletedAt, isNotNull);
      expect(row.syncStatus, 'pending');
    });

    test('summary by period and machine; list filtered by date', () async {
      await repo.save(
        op,
        fuel(litres: 5000, price: 9500, at: DateTime(2026, 10, 2, 8)),
      );
      await repo.save(
        op,
        fuel(
          litres: 3000,
          price: 10000,
          m: machine2,
          at: DateTime(2026, 10, 20, 8),
        ),
      );
      await repo.save(
        op,
        fuel(litres: 1000, price: 9000, at: DateTime(2026, 9, 30, 8)),
      );
      final oct = await repo
          .watchSummary('co', from: '2026-10-01', to: '2026-10-31')
          .first;
      expect(oct.count, 2);
      expect(oct.litresCl, 8000);
      expect(oct.totalPaise, 475000 + 300000);
      expect(oct.byMachine.map((m) => m.machineName), ['JCB 1', 'JCB 2']);
      expect(oct.byMachine.first.totalPaise, 475000);
      final list = await repo
          .watchList('co', from: '2026-10-01', to: '2026-10-31')
          .first;
      expect(list, hasLength(2));
      expect(list.first.machineName, 'JCB 2', reason: 'newest first');
      final empty = await repo
          .watchSummary('other', from: '2026-10-01', to: '2026-10-31')
          .first;
      expect(empty.count, 0);
    });

    test('last price at a pump', () async {
      expect(await repo.lastPrice('co', pump), isNull);
      await repo.save(op, fuel(price: 9500, at: DateTime(2026, 10, 1)));
      await repo.save(op, fuel(price: 9800, at: DateTime(2026, 10, 5)));
      expect(await repo.lastPrice('co', pump), 9800);
    });

    test('tenant isolation', () async {
      final id = await repo.save(op, fuel());
      expect(await repo.watchOne('other', id).first, isNull);
      await expectLater(repo.delete(outsider, id), throwsStateError);
    });

    test('masters used by fuel entries cannot be deleted', () async {
      await repo.save(op, fuel(clientId: client, siteId: site));
      const s = MasterScope(companyId: 'co', userId: 'owner');
      for (final (kind, id) in [
        (MasterKind.petrolPumps, pump),
        (MasterKind.machines, machine),
        (MasterKind.sites, site),
      ]) {
        await expectLater(
          masters.delete(kind, s, id),
          throwsA(isA<MasterInUseException>()),
          reason: kind.name,
        );
      }
      await expectLater(
        masters.delete(MasterKind.machines, s, machine2),
        completes,
      );
    });
  });
}
