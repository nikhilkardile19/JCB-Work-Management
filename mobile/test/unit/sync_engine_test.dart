import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/billing/data/invoice_repository.dart';
import 'package:jcb_work_management/features/billing/domain/invoice.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/fuel/data/fuel_repository.dart';
import 'package:jcb_work_management/features/fuel/domain/fuel_entry.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';
import 'package:jcb_work_management/features/sync/data/remote_store.dart';
import 'package:jcb_work_management/features/sync/data/sync_engine.dart';
import 'package:jcb_work_management/features/work/data/work_log_repository.dart';
import 'package:jcb_work_management/features/work/domain/work_log.dart';

import '../helpers/pump_app.dart';

const co = 'co';
const ownerA = WorkActor(
  companyId: co,
  userId: 'owner',
  role: CompanyRole.owner,
);
const scope = MasterScope(companyId: co, userId: 'owner');

/// One phone: its own database and engine, sharing [server].
class Device {
  Device(
    FakeRemoteStore server, {
    int pageSize = 200,
    DateTime Function()? clock,
  }) : db = memoryDatabase(),
       _clock = clock ?? DateTime.now {
    engine = SyncEngine(db, server, pageSize: pageSize, clock: _clock);
  }

  final AppDatabase db;
  final DateTime Function() _clock;
  late final SyncEngine engine;
  MastersRepository get masters => MastersRepository(db, clock: _clock);
  WorkLogRepository get logs => WorkLogRepository(db, clock: _clock);

  Future<SyncReport> sync({bool billing = true}) =>
      engine.run(companyId: co, userId: 'owner', canViewBilling: billing);
}

void main() {
  late FakeRemoteStore server;
  late Device a, b;

  setUp(() {
    server = FakeRemoteStore();
    a = Device(server);
    b = Device(server);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  Future<(String, String, String)> seedMasters(Device d) async {
    final c = await d.masters.save(MasterKind.clients, scope, {
      'name': 'Patil',
    });
    final s = await d.masters.save(MasterKind.sites, scope, {
      'clientId': c,
      'name': 'Yard',
      'defaultHourlyRatePaise': 150000,
    });
    final m = await d.masters.save(MasterKind.machines, scope, {
      'name': 'JCB 1',
      'initialMeterReading': 0,
    });
    return (c, s, m);
  }

  WorkLogInput log(
    (String, String, String) ids, {
    int end = 800,
    String? photo,
  }) => WorkLogInput(
    workDate: '2026-10-29',
    clientId: ids.$1,
    siteId: ids.$2,
    machineId: ids.$3,
    start: MeterCapture(
      reading: 0,
      photoPath: photo,
      capturedAt: photo == null ? null : 1,
      locationStatus: photo == null ? null : LocationStatus.denied,
    ),
    end: MeterCapture(
      reading: end,
      photoPath: photo,
      capturedAt: photo == null ? null : 1,
      locationStatus: photo == null ? null : LocationStatus.denied,
    ),
    manualReason: photo == null ? 'no camera' : null,
  );

  test('records created offline on one phone appear on another', () async {
    final ids = await seedMasters(a);
    await a.logs.submit(ownerA, log(ids));
    expect(await a.engine.watchPendingCount(co).first, greaterThan(0));

    final r1 = await a.sync();
    expect(
      r1.pushed,
      greaterThanOrEqualTo(4),
    ); // client, site, machine, log + audit entries
    expect(await a.engine.watchPendingCount(co).first, 0);
    expect(server.count(co, 'workLogs'), 1);

    final r2 = await b.sync();
    expect(r2.pulled, greaterThanOrEqualTo(4));
    final logs = await b.logs.watchList(co).first;
    expect(logs.single.workingHours, 800);
    expect(logs.single.siteName, 'Yard');
    expect(logs.single.syncStatus, 'synced');
  });

  test('re-running sync never duplicates records', () async {
    final ids = await seedMasters(a);
    await a.logs.submit(ownerA, log(ids));
    await a.sync();
    await a.sync();
    await b.sync();
    await b.sync();
    expect(server.count(co, 'workLogs'), 1);
    expect(await b.db.select(b.db.workLogs).get(), hasLength(1));
    expect(await b.db.select(b.db.clients).get(), hasLength(1));
  });

  test(
    'a lost reply is recovered without a false conflict or duplicate',
    () async {
      await a.masters.save(MasterKind.clients, scope, {'name': 'Patil'});
      server.loseNextReply = true;
      await expectLater(a.sync(), throwsA(isA<SyncUnavailable>()));
      expect(await a.engine.watchPendingCount(co).first, greaterThan(0));
      final report = await a.sync();
      expect(report.conflicts, 0);
      expect(server.count(co, 'clients'), 1);
      expect(await a.engine.watchPendingCount(co).first, 0);
    },
  );

  test('offline: nothing is lost and sync resumes later', () async {
    server.offline = true;
    await a.masters.save(MasterKind.clients, scope, {'name': 'Patil'});
    await expectLater(a.sync(), throwsA(isA<SyncUnavailable>()));
    expect(await a.db.select(a.db.clients).get(), hasLength(1));
    server.offline = false;
    await a.sync();
    expect(server.count(co, 'clients'), 1);
  });

  test('edits and tombstones propagate', () async {
    final id = await a.masters.save(MasterKind.clients, scope, {
      'name': 'Patil',
    });
    await a.sync();
    await b.sync();
    await a.masters.save(MasterKind.clients, scope, {
      'name': 'Patil Infra',
    }, id: id);
    await a.sync();
    await b.sync();
    expect((await b.db.select(b.db.clients).getSingle()).name, 'Patil Infra');
    await a.masters.delete(MasterKind.clients, scope, id);
    await a.sync();
    await b.sync();
    expect((await b.db.select(b.db.clients).getSingle()).deletedAt, isNotNull);
    expect(await b.masters.watchList(MasterKind.clients, co).first, isEmpty);
  });

  test(
    'masters conflict: newest edit wins, overwritten version is logged',
    () async {
      var t = DateTime.utc(2026, 10, 29, 9);
      final a2 = Device(server, clock: () => t);
      final b2 = Device(server, clock: () => t);
      final id = await a2.masters.save(MasterKind.clients, scope, {
        'name': 'Patil',
      });
      await a2.sync();
      await b2.sync();
      t = t.add(const Duration(minutes: 1));
      await a2.masters.save(MasterKind.clients, scope, {
        'name': 'Patil (A)',
      }, id: id);
      t = t.add(const Duration(minutes: 1));
      await b2.masters.save(MasterKind.clients, scope, {
        'name': 'Patil (B, later)',
      }, id: id);
      await a2.sync(); // A pushes first
      final rb = await b2.sync(); // B conflicts but is newer → wins
      expect(rb.autoResolved, 1);
      expect(server.read(co, 'clients', id)!['name'], 'Patil (B, later)');
      await a2.sync();
      expect(
        (await a2.db.select(a2.db.clients).getSingle()).name,
        'Patil (B, later)',
      );
      final overwrite = await (b2.db.select(
        b2.db.auditLogs,
      )..where((t) => t.action.equals('sync_overwrite'))).getSingle();
      expect(overwrite.details, contains('Patil (A)'));
      await a2.db.close();
      await b2.db.close();
    },
  );

  test('financial conflict is surfaced, not merged; user chooses', () async {
    final ids = await seedMasters(a);
    final (logId, _) = await a.logs.submit(ownerA, log(ids));
    await a.sync();
    await b.sync();
    await a.logs.correct(ownerA, logId, log(ids, end: 900), reason: 'A fix');
    await b.logs.correct(ownerA, logId, log(ids, end: 950), reason: 'B fix');
    await a.sync();
    final rb = await b.sync();
    expect(rb.conflicts, 1);
    expect(
      server.read(co, 'workLogs', logId)!['endReading'],
      900,
      reason: 'server untouched',
    );
    final issues = await b.engine.watchIssues(co).first;
    expect(issues.single.isConflict, isTrue);
    expect(issues.single.collection, 'workLogs');
    expect(
      (await b.logs.watchOne(co, logId).first)!.end.reading,
      950,
      reason: 'local untouched',
    );

    // Option 1: use the server version.
    await b.engine.useServer('workLogs', logId);
    expect((await b.logs.watchOne(co, logId).first)!.end.reading, 900);
    expect(await b.engine.watchIssues(co).first, isEmpty);
  });

  test('conflict: keep this device version overwrites the server', () async {
    final ids = await seedMasters(a);
    final (logId, _) = await a.logs.submit(ownerA, log(ids));
    await a.sync();
    await b.sync();
    await a.logs.correct(ownerA, logId, log(ids, end: 900), reason: 'A');
    await b.logs.correct(ownerA, logId, log(ids, end: 950), reason: 'B');
    await a.sync();
    await b.sync();
    await b.engine.keepLocal('workLogs', logId);
    await b.sync();
    expect(server.read(co, 'workLogs', logId)!['endReading'], 950);
    await a.sync();
    expect((await a.logs.watchOne(co, logId).first)!.end.reading, 950);
  });

  test(
    'refused records are flagged with the reason and can be retried',
    () async {
      server.rejectCollections.add('clients');
      await a.masters.save(MasterKind.clients, scope, {'name': 'Patil'});
      final r = await a.sync();
      expect(r.errors, 1);
      final issue = (await a.engine.watchIssues(co).first).single;
      expect(issue.isConflict, isFalse);
      expect(issue.message, 'Refused by server rules');
      server.rejectCollections.clear();
      await a.engine.retry('clients', issue.id);
      await a.sync();
      expect(await a.engine.watchIssues(co).first, isEmpty);
      expect(server.count(co, 'clients'), 1);
    },
  );

  test('photo and PDF paths stay on the device', () async {
    final ids = await seedMasters(a);
    final (logId, _) = await a.logs.submit(
      ownerA,
      log(ids, photo: 'evidence/co/x.jpg'),
    );
    await a.sync();
    final remote = server.read(co, 'workLogs', logId)!;
    expect(remote.containsKey('startPhotoPath'), isFalse);
    expect(remote['startCapturedAt'], 1, reason: 'metadata still syncs');
    // Pulling the record back keeps this device's local path.
    await a.db.writeSetting('sync_cursor:co:workLogs', '0|');
    await a.sync();
    expect(
      (await a.logs.watchOne(co, logId).first)!.start.photoPath,
      'evidence/co/x.jpg',
    );
    await b.sync();
    expect((await b.logs.watchOne(co, logId).first)!.start.photoPath, isNull);
  });

  test('invoices sync with their lines and payments', () async {
    final ids = await seedMasters(a);
    final (logId, _) = await a.logs.submit(ownerA, log(ids));
    final inv = InvoiceRepository(a.db);
    final id = await inv.saveDraft(
      ownerA,
      InvoiceDraftInput(
        clientId: ids.$1,
        periodFrom: '2026-10-01',
        periodTo: '2026-10-31',
        invoiceDate: '2026-11-01',
        workLogRates: {logId: 150000},
      ),
    );
    await inv.finalize(
      ownerA,
      id,
      numbers: FakeInvoiceNumbers(),
      company: const PartySnapshot(name: 'Sai'),
    );
    await inv.recordPayment(
      ownerA,
      id,
      const PaymentInput(
        paymentDate: '2026-11-02',
        amountPaise: 500000,
        method: PaymentMethod.upi,
      ),
    );
    await a.sync();
    await b.sync();
    final v = (await InvoiceRepository(b.db).watchOne(co, id).first)!;
    expect(v.invoiceNumber, 'JCB/2026-27/0001');
    expect(v.lines.single.amountPaise, 1200000);
    expect(v.paidPaise, 500000);
    expect(v.companySnapshot!.name, 'Sai');
    expect(
      (await b.logs.watchOne(co, logId).first)!.status,
      WorkLogStatus.invoiced,
    );
  });

  test('billing is not synced for roles without billing access', () async {
    final ids = await seedMasters(a);
    final (logId, _) = await a.logs.submit(ownerA, log(ids));
    await InvoiceRepository(a.db).saveDraft(
      ownerA,
      InvoiceDraftInput(
        clientId: ids.$1,
        periodFrom: '2026-10-01',
        periodTo: '2026-10-31',
        invoiceDate: '2026-11-01',
        workLogRates: {logId: 1},
      ),
    );
    await a.sync();
    await b.sync(billing: false);
    expect(await b.db.select(b.db.invoices).get(), isEmpty);
    expect(await b.db.select(b.db.workLogs).get(), hasLength(1));
  });

  test('initial download is paginated', () async {
    final small = Device(server, pageSize: 3);
    for (var i = 0; i < 10; i++) {
      await a.masters.save(MasterKind.operators, scope, {
        'name': 'Operator $i',
      });
    }
    await a.sync();
    final r = await small.sync();
    expect(await small.db.select(small.db.operators).get(), hasLength(10));
    expect(r.pulled, greaterThanOrEqualTo(10));
    // Next run fetches nothing new.
    expect((await small.sync()).pulled, 0);
    await small.db.close();
  });

  test('cursors saved before the REST server are ignored', () async {
    for (var i = 0; i < 3; i++) {
      await a.masters.save(MasterKind.operators, scope, {
        'name': 'Operator $i',
      });
    }
    await a.sync();
    // A Firestore-era cursor held a microsecond timestamp; read as a change
    // sequence number it would skip every record.
    await b.db.writeSetting(
      'sync_cursor:$co:operators',
      '${DateTime.now().microsecondsSinceEpoch}|zzz',
    );
    await b.sync();
    expect(await b.db.select(b.db.operators).get(), hasLength(3));
    expect(await b.db.readSetting('sync_cursor_v2:$co:operators'), isNotNull);
  });

  test('fuel entries sync; reconciliation counts match', () async {
    final (_, _, m) = await seedMasters(a);
    final pump = await a.masters.save(MasterKind.petrolPumps, scope, {
      'name': 'HP',
    });
    await FuelRepository(a.db).save(
      ownerA,
      FuelInput(
        filledAt: DateTime(2026, 10, 29, 9),
        machineId: m,
        pumpId: pump,
        litresCl: 5000,
        pricePerLitrePaise: 9500,
        receipt: null,
      ),
    );
    await a.sync();
    await b.sync();
    expect(
      (await b.db.select(b.db.fuelEntries).getSingle()).totalPaise,
      475000,
    );
    final counts = await b.engine.counts(co);
    for (final c in counts) {
      expect(c.synced, c.total, reason: c.collection);
    }
  });
}
