import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/core/utils/units.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/billing/data/invoice_repository.dart';
import 'package:jcb_work_management/features/billing/domain/invoice.dart';
import 'package:jcb_work_management/features/billing/presentation/invoice_pdf.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/fuel/data/fuel_repository.dart';
import 'package:jcb_work_management/features/fuel/domain/fuel_entry.dart';
import 'package:jcb_work_management/features/masters/data/masters_repository.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';
import 'package:jcb_work_management/features/reports/domain/reports.dart';
import 'package:jcb_work_management/features/reports/presentation/report_document.dart';
import 'package:jcb_work_management/features/work/data/work_log_repository.dart';
import 'package:jcb_work_management/features/work/domain/work_log.dart';
import 'package:pdf/widgets.dart' as pw;

import '../helpers/pump_app.dart';

const owner = WorkActor(
  companyId: 'co',
  userId: 'owner',
  role: CompanyRole.owner,
);
const operator = WorkActor(
  companyId: 'co',
  userId: 'op',
  role: CompanyRole.operator,
);
const october = ReportRange('2026-10-01', '2026-10-31');
const company = PartySnapshot(name: 'Sai Earthmovers');

InvoicePdfFonts loadFonts() {
  pw.Font load(String f) => pw.Font.ttf(
    ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync()),
  );
  return InvoicePdfFonts(
    regular: load('NotoSans-Regular.ttf'),
    bold: load('NotoSans-Bold.ttf'),
  );
}

Future<void> expectPdf(ReportDocument doc) async {
  final bytes = await buildReportPdf(
    doc,
    fonts: loadFonts(),
    companyName: 'Sai Earthmovers',
    generatedAt: DateTime(2026, 11, 25, 10),
  );
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: doc.title);
  expect(bytes.length, greaterThan(1000));
}

/// Sum of one integer column over [sql] (a FROM … WHERE … clause).
Future<int> sqlSum(AppDatabase db, String column, String sql) async =>
    (await db
            .customSelect('SELECT COALESCE(SUM($column), 0) AS s $sql')
            .getSingle())
        .read<int>('s');

void main() {
  group('report ranges', () {
    test('presets', () {
      final now = DateTime(2026, 10, 29, 15);
      String r(ReportPreset p) {
        final x = ReportRange.preset(p, now);
        return '${x.from}..${x.to}';
      }

      expect(r(ReportPreset.today), '2026-10-29..2026-10-29');
      expect(r(ReportPreset.thisWeek), '2026-10-26..2026-10-29');
      expect(r(ReportPreset.thisMonth), '2026-10-01..2026-10-29');
      expect(r(ReportPreset.lastMonth), '2026-09-01..2026-09-30');
      expect(r(ReportPreset.financialYear), '2026-04-01..2026-10-29');
      expect(
        ReportRange.preset(
          ReportPreset.financialYear,
          DateTime(2027, 2, 3),
        ).from,
        '2026-04-01',
        reason: 'Jan–Mar belong to the year that started last April',
      );
      expect(
        ReportRange.preset(ReportPreset.lastMonth, DateTime(2027, 1, 15)).from,
        '2026-12-01',
      );
    });

    test('aging buckets', () {
      expect(AgingBucket.of(0), AgingBucket.notDue);
      expect(AgingBucket.of(1), AgingBucket.d1to30);
      expect(AgingBucket.of(30), AgingBucket.d1to30);
      expect(AgingBucket.of(31), AgingBucket.d31to60);
      expect(AgingBucket.of(90), AgingBucket.d61to90);
      expect(AgingBucket.of(91), AgingBucket.over90);
    });
  });

  group('reports reconcile to source records', () {
    late AppDatabase db;
    late WorkLogRepository logs;
    late InvoiceRepository invoices;
    late FuelRepository fuel;
    late String yard, road, patil, shinde, jcb1, jcb2, ramesh, hp, bpcl;
    final ids = <String, String>{};

    Future<String> log(
      WorkActor who,
      String key,
      String date,
      String machine,
      int start,
      int end, {
      bool photos = true,
      bool submit = true,
      String? site,
      Set<AnomalyFlag> flags = const {},
    }) async {
      final input = WorkLogInput(
        workDate: date,
        clientId: site == road ? shinde : patil,
        siteId: site ?? yard,
        machineId: machine,
        operatorId: ramesh,
        start: MeterCapture(reading: start, photoPath: photos ? 's.jpg' : null),
        end: MeterCapture(reading: end, photoPath: photos ? 'e.jpg' : null),
        manualReason: photos ? null : 'Meter glass broken',
        anomalyFlags: flags,
      );
      final id = submit
          ? (await logs.submit(who, input)).$1
          : await logs.saveDraft(who, input);
      return ids[key] = id;
    }

    setUp(() async {
      db = memoryDatabase();
      logs = WorkLogRepository(db);
      invoices = InvoiceRepository(db);
      fuel = FuelRepository(db);
      final m = MastersRepository(db);
      const s = MasterScope(companyId: 'co', userId: 'owner');
      patil = await m.save(MasterKind.clients, s, {'name': 'Patil'});
      shinde = await m.save(MasterKind.clients, s, {'name': 'Shinde'});
      yard = await m.save(MasterKind.sites, s, {
        'clientId': patil,
        'name': 'Yard',
      });
      road = await m.save(MasterKind.sites, s, {
        'clientId': shinde,
        'name': 'Road',
      });
      jcb1 = await m.save(MasterKind.machines, s, {
        'name': 'JCB 1',
        'initialMeterReading': 0,
      });
      jcb2 = await m.save(MasterKind.machines, s, {
        'name': 'JCB 2',
        'initialMeterReading': 0,
      });
      ramesh = await m.save(MasterKind.operators, s, {'name': 'Ramesh'});
      hp = await m.save(MasterKind.petrolPumps, s, {'name': 'HP Wakad'});
      bpcl = await m.save(MasterKind.petrolPumps, s, {'name': 'BPCL Aundh'});

      // JCB 1: 0→800, 900→1750 (1 h not logged), 1700→2200 (0.5 h overlap).
      await log(owner, 'a1', '2026-10-05', jcb1, 0, 800);
      await log(owner, 'a2', '2026-10-06', jcb1, 900, 1750, photos: false);
      await log(
        operator,
        'a3',
        '2026-10-08',
        jcb1,
        1700,
        2200,
        flags: {AnomalyFlag.meterBackwards},
      );
      await log(owner, 'b1', '2026-10-07', jcb2, 0, 700, site: road);
      await log(
        owner,
        'b2',
        '2026-10-12',
        jcb2,
        700,
        2500,
        flags: {AnomalyFlag.highHours},
        site: road,
      );
      // Outside October, cancelled, and still in progress: not counted.
      await log(owner, 'sep', '2026-09-30', jcb1, 0, 0);
      await log(owner, 'x', '2026-10-10', jcb2, 2500, 2800);
      await logs.cancel(owner, ids['x']!, reason: 'Duplicate');
      await log(operator, 'd', '2026-10-15', jcb1, 2200, 2300, submit: false);

      // Invoice 1 (Patil, a1 + a2), paid in part; one payment reversed.
      final i1 = await invoices.saveDraft(
        owner,
        InvoiceDraftInput(
          clientId: patil,
          periodFrom: '2026-10-01',
          periodTo: '2026-10-31',
          invoiceDate: '2026-10-20',
          paymentTermsDays: 30,
          workLogRates: {ids['a1']!: 150000, ids['a2']!: 150000},
        ),
      );
      await invoices.finalize(
        owner,
        i1,
        numbers: FakeInvoiceNumbers(),
        company: company,
      );
      ids['i1'] = i1;
      await invoices.recordPayment(
        owner,
        i1,
        const PaymentInput(
          paymentDate: '2026-10-25',
          amountPaise: 500000,
          method: PaymentMethod.upi,
          reference: 'UTR123',
        ),
      );
      final bounced = await invoices.recordPayment(
        owner,
        i1,
        const PaymentInput(
          paymentDate: '2026-10-26',
          amountPaise: 100000,
          method: PaymentMethod.cheque,
        ),
      );
      await invoices.reversePayment(owner, bounced, reason: 'Cheque bounced');

      // Invoice 2 (Shinde, b1), due on the invoice date, unpaid.
      final i2 = await invoices.saveDraft(
        owner,
        InvoiceDraftInput(
          clientId: shinde,
          periodFrom: '2026-10-01',
          periodTo: '2026-10-31',
          invoiceDate: '2026-10-21',
          paymentTermsDays: 0,
          workLogRates: {ids['b1']!: 120000},
        ),
      );
      await invoices.finalize(
        owner,
        i2,
        numbers: FakeInvoiceNumbers()..issued[i2] = 'JCB/2026-27/0002',
        company: company,
      );
      ids['i2'] = i2;

      // A draft dated in October is counted separately, never as invoiced.
      await invoices.saveDraft(
        owner,
        InvoiceDraftInput(
          clientId: shinde,
          periodFrom: '2026-10-01',
          periodTo: '2026-10-31',
          invoiceDate: '2026-10-28',
          workLogRates: {ids['b2']!: 120000},
        ),
      );

      for (final (day, machine, pump, litres, price) in [
        (3, jcb1, hp, 5000, 10235),
        (15, jcb2, hp, 2550, 10100),
        (18, jcb1, bpcl, 1000, 9999),
      ]) {
        await fuel.save(
          owner,
          FuelInput(
            filledAt: DateTime(2026, 10, day, 9),
            machineId: machine,
            pumpId: pump,
            litresCl: litres,
            pricePerLitrePaise: price,
            siteId: day == 15 ? road : null,
            clientId: day == 15 ? shinde : null,
          ),
        );
      }
      await fuel.save(
        owner,
        FuelInput(
          filledAt: DateTime(2026, 9, 28, 9),
          machineId: jcb1,
          pumpId: hp,
          litresCl: 9999,
          pricePerLitrePaise: 10000,
        ),
      );
    });
    tearDown(() => db.close());

    Future<List<WorkLogView>> october_() =>
        logs.watchBetween('co', from: october.from, to: october.to).first;

    test('work hours equal the approved and invoiced logs', () async {
      final r = WorkReport.from(await october_(), october);
      const where =
          "FROM work_logs WHERE status IN ('approved', 'invoiced') "
          "AND work_date BETWEEN '2026-10-01' AND '2026-10-31'";
      expect(r.hours, await sqlSum(db, 'working_hours', where));
      expect(r.hours, 800 + 850 + 700 + 1800);
      expect(r.counted.map((l) => l.id), isNot(contains(ids['sep'])));
      expect(r.counted.map((l) => l.id), isNot(contains(ids['x'])));
      // Every breakdown adds back up to the total.
      for (final g in WorkGrouping.values) {
        expect(r.by(g).fold(0, (a, x) => a + x.value), r.hours, reason: '$g');
      }
      expect(r.by(WorkGrouping.machine).first.label, 'JCB 2');
      expect(r.by(WorkGrouping.site).map((g) => g.detail), ['Shinde', 'Patil']);
      expect(r.by(WorkGrouping.day).map((g) => g.key).toList(), [
        '2026-10-05',
        '2026-10-06',
        '2026-10-07',
        '2026-10-12',
      ]);
      // Billed hours are exactly the hours on finalized invoice lines.
      expect(
        r.invoicedHours,
        await sqlSum(
          db,
          'l.working_hours',
          'FROM invoice_lines l JOIN invoices i ON i.id = l.invoice_id '
              "WHERE i.status = 'finalized'",
        ),
      );
      expect(r.unbilledHours, 1800);
      expect(r.pending.single.id, ids['a3']);
      expect(r.pendingHours, 500);
      expect(r.inProgress.single.id, ids['d']);
      expect(r.manualCount, 1);
    });

    test('meter readings show gaps and overlaps between logs', () async {
      final r = MeterReport.from(await october_(), october);
      final jcb1Meter = r.machines.firstWhere((m) => m.machineId == jcb1);
      expect(jcb1Meter.entries.map((e) => e.gap), [null, 100, -50]);
      expect(jcb1Meter.firstReading, 0);
      expect(jcb1Meter.lastReading, 2200);
      final jcb2Meter = r.machines.firstWhere((m) => m.machineId == jcb2);
      expect(jcb2Meter.entries.map((e) => e.log.id), [
        ids['b1'],
        ids['b2'],
      ], reason: 'cancelled log left out');
      expect(
        jcb1Meter.entries.map((e) => e.log.id),
        isNot(contains(ids['d'])),
        reason: 'drafts are not checked readings yet',
      );
      expect(r.gapCount, 2);
    });

    test('fuel equals the entries and the Fuel tab summary', () async {
      final entries = await fuel
          .watchList('co', from: october.from, to: october.to)
          .first;
      final r = FuelReport(entries);
      final tab = await fuel
          .watchSummary('co', from: october.from, to: october.to)
          .first;
      expect(r.totalPaise, tab.totalPaise);
      expect(r.litresCl, tab.litresCl);
      expect(r.averagePricePaise, tab.averagePricePaise);
      expect(
        r.totalPaise,
        await sqlSum(
          db,
          'total_paise',
          "FROM fuel_entries WHERE fuel_date BETWEEN '2026-10-01' AND '2026-10-31'",
        ),
      );
      expect(r.count, 3);
      for (final groups in [r.byMachine, r.byPump, r.bySite]) {
        expect(groups.fold(0, (a, g) => a + g.value), r.totalPaise);
        expect(groups.fold(0, (a, g) => a + g.extra), r.litresCl);
      }
      expect(r.bySite.map((g) => g.label), ['Not allocated to a site', 'Road']);
    });

    test(
      'invoice and payment registers agree with invoices and payments',
      () async {
        final all = await invoices.watchList('co').first;
        final reg = InvoiceRegister.from(all, october);
        expect(reg.rows.map((i) => i.id), [ids['i1'], ids['i2']]);
        expect(reg.draftCount, 1);
        expect(
          reg.invoicedPaise,
          await sqlSum(
            db,
            'total_paise',
            "FROM invoices WHERE status = 'finalized' "
                "AND invoice_date BETWEEN '2026-10-01' AND '2026-10-31'",
          ),
        );
        expect(reg.invoicedPaise, 2475000 + 840000);
        expect(reg.receivedPaise, 500000);
        expect(reg.outstandingPaise, reg.invoicedPaise - reg.receivedPaise);
        expect(reg.byClient.fold(0, (a, g) => a + g.value), reg.invoicedPaise);

        final pay = PaymentRegister(
          await invoices
              .watchPaymentRecords('co', from: october.from, to: october.to)
              .first,
        );
        // Same figure the dashboard shows as "received".
        final received = await invoices
            .watchReceived('co', from: october.from, to: october.to)
            .first;
        expect(pay.totalPaise, received);
        expect(pay.totalPaise, 500000);
        expect(pay.valid.single.reference, 'UTR123');
        expect(pay.reversed.single.reverseReason, 'Cheque bounced');
        expect(pay.byMethod.single.label, PaymentMethod.upi.label);
        expect(pay.byClient.single.label, 'Patil');
      },
    );

    test('outstanding and aging add up to the unpaid invoices', () async {
      final all = await invoices.watchList('co').first;
      final r = OutstandingReport.from(all, '2026-11-25');
      expect(r.totalPaise, all.fold(0, (a, i) => a + i.outstandingPaise));
      expect(r.totalPaise, 2475000 - 500000 + 840000);
      expect(r.buckets.values.fold(0, (a, v) => a + v), r.totalPaise);
      // i2 was due 21 Oct: 35 days overdue. i1 is due 19 Nov: 6 days.
      expect(r.rows.map((a) => (a.invoice.id, a.daysOverdue)), [
        (ids['i2'], 35),
        (ids['i1'], 6),
      ]);
      expect(r.buckets[AgingBucket.d31to60], 840000);
      expect(r.buckets[AgingBucket.d1to30], 1975000);
      // Same overdue rule as the invoice list and the dashboard.
      expect(
        r.overduePaise,
        all
            .where((i) => i.stateOn('2026-11-25') == InvoiceState.overdue)
            .fold(0, (a, i) => a + i.outstandingPaise),
      );
      expect(r.byClient.fold(0, (a, g) => a + g.value), r.totalPaise);
      final early = OutstandingReport.from(all, '2026-10-21');
      expect(early.overduePaise, 0, reason: 'due today is not overdue');
    });

    test('every report exports to PDF with the same totals', () async {
      final oct = await october_();
      final all = await invoices.watchList('co').first;
      final work = workDocument(WorkReport.from(oct, october), october);
      final docs = [
        work,
        meterDocument(MeterReport.from(oct, october), october),
        fuelDocument(
          FuelReport(
            await fuel
                .watchList('co', from: october.from, to: october.to)
                .first,
          ),
          october,
        ),
        invoiceDocument(
          InvoiceRegister.from(all, october),
          october,
          '2026-11-25',
        ),
        paymentDocument(
          PaymentRegister(
            await invoices
                .watchPaymentRecords('co', from: october.from, to: october.to)
                .first,
          ),
          october,
        ),
        outstandingDocument(OutstandingReport.from(all, '2026-11-25')),
        manualDocument(ManualReport.from(oct, october), october),
        // Empty periods still export.
        workDocument(WorkReport.from(const [], october), october),
      ];
      for (final d in docs) {
        await expectPdf(d);
      }
      expect(work.period, '1 Oct 2026 – 31 Oct 2026');
      expect(work.summary.first, ('Approved hours', MeterReading.format(4150)));
      final byMachine = work.tables.first;
      expect(byMachine.rows.map((r) => r.first), ['JCB 2', 'JCB 1']);
      expect(docs[5].period, 'As of 25 Nov 2026');
    });

    test('manual-entry report lists manual and flagged logs only', () async {
      final r = ManualReport.from(await october_(), october);
      expect(r.rows.map((l) => l.id), [ids['b2'], ids['a3'], ids['a2']]);
      expect(r.manualCount, 1);
      expect(r.manualHours, 850);
      expect(r.flaggedCount, 2);
      expect(r.rows.last.manualReason, 'Meter glass broken');
    });
  });

  test('reports stay fast with a year of data', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final m = MastersRepository(db);
    const s = MasterScope(companyId: 'co', userId: 'owner');
    final client = await m.save(MasterKind.clients, s, {'name': 'Patil'});
    final site = await m.save(MasterKind.sites, s, {
      'clientId': client,
      'name': 'Yard',
    });
    final machines = [
      for (var i = 0; i < 10; i++)
        await m.save(MasterKind.machines, s, {
          'name': 'JCB $i',
          'initialMeterReading': 0,
        }),
    ];
    // 10 machines × 365 days = 3,650 approved logs.
    await db.batch((b) {
      for (var day = 0; day < 365; day++) {
        final date = WorkLogRules.dateKey(
          DateTime(2026, 4).add(Duration(days: day)),
        );
        for (final (i, machine) in machines.indexed) {
          b.insert(
            db.workLogs,
            WorkLogsCompanion.insert(
              id: 'w$day-$i',
              companyId: 'co',
              workDate: date,
              clientId: client,
              siteId: site,
              machineId: machine,
              startReading: day * 800,
              endReading: Value(day * 800 + 750),
              workingHours: const Value(750),
              entryMode: 'photo',
              status: 'approved',
              createdAt: 0,
              updatedAt: 0,
              createdBy: 'owner',
              updatedBy: 'owner',
            ),
          );
        }
      }
    });
    const year = ReportRange('2026-04-01', '2027-03-31');
    final watch = Stopwatch()..start();
    final rows = await WorkLogRepository(db)
        .watchBetween('co', from: year.from, to: year.to)
        .first;
    final work = WorkReport.from(rows, year);
    final meter = MeterReport.from(rows, year);
    for (final g in WorkGrouping.values) {
      work.by(g);
    }
    watch.stop();
    expect(work.hours, 3650 * 750);
    expect(meter.gapCount, 10 * 364, reason: '0.5 h unlogged between days');
    expect(
      watch.elapsed,
      lessThan(const Duration(seconds: 3)),
      reason: 'query + all breakdowns for a year of logs',
    );
    // A year of one machine's readings spans many PDF pages.
    await expectPdf(
      meterDocument(
        MeterReport.from(
          rows.where((l) => l.machineId == machines.first),
          year,
        ),
        year,
      ),
    );
  });
}
