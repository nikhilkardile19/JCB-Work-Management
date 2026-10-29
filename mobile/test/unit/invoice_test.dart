import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/billing/data/invoice_number_service.dart';
import 'package:jcb_work_management/features/billing/data/invoice_repository.dart';
import 'package:jcb_work_management/features/billing/domain/invoice.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
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
const accounts = WorkActor(
  companyId: 'co',
  userId: 'acc',
  role: CompanyRole.accounts,
);
const manager = WorkActor(
  companyId: 'co',
  userId: 'mgr',
  role: CompanyRole.manager,
);
const outsider = WorkActor(
  companyId: 'other',
  userId: 'x',
  role: CompanyRole.owner,
);
const company = PartySnapshot(
  name: 'Sai Earthmovers',
  address: 'Pune',
  gstin: '27ABCDE1234F1Z5',
);

void main() {
  group('maths', () {
    test('line amount = hours × rate, half-up', () {
      expect(InvoiceMath.lineAmount(850, 150000), 1275000); // 8.5 h × ₹1,500
      expect(
        InvoiceMath.lineAmount(725, 133333),
        966664,
      ); // 7.25 × 1333.33 = 9666.64
      expect(InvoiceMath.lineAmount(1, 50), 1); // 0.5 paisa rounds up
    });

    test('Indian financial year and due date', () {
      expect(InvoiceMath.financialYear('2026-10-29'), '2026-27');
      expect(InvoiceMath.financialYear('2027-03-31'), '2026-27');
      expect(InvoiceMath.financialYear('2027-04-01'), '2027-28');
      expect(InvoiceMath.financialYear('2099-06-01'), '2099-00');
      expect(InvoiceMath.addDays('2026-10-29', 15), '2026-11-13');
    });

    test('derived payment state', () {
      InvoiceState s(
        InvoiceStatus st,
        int paid, {
        String today = '2026-11-01',
      }) => InvoiceMath.state(
        status: st,
        totalPaise: 1000,
        paidPaise: paid,
        dueDate: '2026-11-10',
        today: today,
      );
      expect(s(InvoiceStatus.draft, 0), InvoiceState.draft);
      expect(s(InvoiceStatus.finalized, 0), InvoiceState.unpaid);
      expect(s(InvoiceStatus.finalized, 400), InvoiceState.partiallyPaid);
      expect(s(InvoiceStatus.finalized, 1000), InvoiceState.paid);
      expect(
        s(InvoiceStatus.finalized, 400, today: '2026-11-11'),
        InvoiceState.overdue,
      );
      expect(
        s(InvoiceStatus.finalized, 1000, today: '2026-12-01'),
        InvoiceState.paid,
      );
      expect(s(InvoiceStatus.cancelled, 0), InvoiceState.cancelled);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late InvoiceRepository repo;
    late WorkLogRepository logs;
    late FakeInvoiceNumbers numbers;
    late String client, client2, site, site2, machine;
    final logIds = <String>[];

    setUp(() async {
      db = memoryDatabase();
      repo = InvoiceRepository(db);
      logs = WorkLogRepository(db);
      numbers = FakeInvoiceNumbers();
      final m = MastersRepository(db);
      const s = MasterScope(companyId: 'co', userId: 'owner');
      client = await m.save(MasterKind.clients, s, {
        'name': 'Patil',
        'billingAddress': 'Hinjewadi, Pune',
        'gstin': '27AAAAA0000A1Z5',
      });
      client2 = await m.save(MasterKind.clients, s, {'name': 'Shinde'});
      site = await m.save(MasterKind.sites, s, {
        'clientId': client,
        'name': 'Yard',
        'defaultHourlyRatePaise': 150000,
      });
      site2 = await m.save(MasterKind.sites, s, {
        'clientId': client2,
        'name': 'Road',
      });
      machine = await m.save(MasterKind.machines, s, {
        'name': 'JCB 1',
        'initialMeterReading': 0,
      });
      logIds.clear();
      var reading = 0;
      for (final (date, hours, siteId, clientId) in [
        ('2026-10-05', 800, site, client),
        ('2026-10-06', 850, site, client),
        ('2026-10-07', 700, site2, client2),
        ('2026-11-02', 600, site, client),
      ]) {
        final (id, _) = await logs.submit(
          owner,
          WorkLogInput(
            workDate: date,
            clientId: clientId,
            siteId: siteId,
            machineId: machine,
            start: MeterCapture(reading: reading),
            end: MeterCapture(reading: reading + hours),
            manualReason: 'test',
          ),
        );
        reading += hours;
        logIds.add(id);
      }
    });
    tearDown(() => db.close());

    Future<List<String>> candidates({
      String? invoiceId,
      String c = 'client',
    }) async =>
        (await repo
                .watchCandidates(
                  'co',
                  clientId: c == 'client' ? client : client2,
                  from: '2026-10-01',
                  to: '2026-10-31',
                  invoiceId: invoiceId,
                )
                .first)
            .map((l) => l.id)
            .toList();

    InvoiceDraftInput draft(Map<String, int> rates, {int discount = 0}) =>
        InvoiceDraftInput(
          clientId: client,
          periodFrom: '2026-10-01',
          periodTo: '2026-10-31',
          invoiceDate: '2026-11-01',
          workLogRates: rates,
          discountPaise: discount,
        );

    test('candidates: approved logs of the client within the period', () async {
      expect(await candidates(), [logIds[0], logIds[1]]);
      expect(await candidates(c: 'client2'), [logIds[2]]);
    });

    test(
      'draft computes lines, subtotal, discount and reserves logs',
      () async {
        final id = await repo.saveDraft(
          owner,
          draft({logIds[0]: 150000, logIds[1]: 160000}, discount: 50000),
        );
        final v = (await repo.watchOne('co', id).first)!;
        expect(v.status, InvoiceStatus.draft);
        expect(v.displayNumber, 'Draft');
        expect(v.lines.map((l) => l.amountPaise), [1200000, 1360000]);
        expect(v.subtotalPaise, 2560000);
        expect(v.totalPaise, 2510000);
        expect(v.dueDate, '2026-11-16');
        expect(v.lines.first.siteName, 'Yard');
        // Reserved: no longer offered to a new invoice.
        expect(await candidates(), isEmpty);
        expect(await candidates(invoiceId: id), [logIds[0], logIds[1]]);
        final log = (await logs.watchOne('co', logIds[0]).first)!;
        expect(log.invoiceId, id);
        expect(log.status, WorkLogStatus.approved);
      },
    );

    test('rate override never changes the site master', () async {
      await repo.saveDraft(owner, draft({logIds[0]: 999900}));
      final s = await (db.select(
        db.sites,
      )..where((t) => t.id.equals(site))).getSingle();
      expect(s.defaultHourlyRatePaise, 150000);
    });

    test('a work log cannot be on two invoices', () async {
      await repo.saveDraft(owner, draft({logIds[0]: 150000}));
      await expectLater(
        repo.saveDraft(owner, draft({logIds[0]: 150000, logIds[1]: 150000})),
        throwsA(
          isA<InvoiceException>().having((e) => e.fieldErrors.keys, 'k', [
            'workLogs',
          ]),
        ),
      );
    });

    test(
      'logs of another client, outside the period or not approved are refused',
      () async {
        for (final rates in [
          {logIds[2]: 1000}, // other client
          {logIds[3]: 1000}, // November
        ]) {
          await expectLater(
            repo.saveDraft(owner, draft(rates)),
            throwsA(isA<InvoiceException>()),
          );
        }
        await expectLater(
          repo.saveDraft(owner, draft({})),
          throwsA(isA<InvoiceException>()),
        );
        await expectLater(
          repo.saveDraft(owner, draft({logIds[0]: 150000}, discount: 99999999)),
          throwsA(
            isA<InvoiceException>().having((e) => e.fieldErrors.keys, 'k', [
              'discount',
            ]),
          ),
        );
      },
    );

    test(
      'editing a draft releases removed logs; deleting a draft releases all',
      () async {
        final id = await repo.saveDraft(
          owner,
          draft({logIds[0]: 150000, logIds[1]: 150000}),
        );
        await repo.saveDraft(owner, draft({logIds[1]: 150000}), id: id);
        expect(await candidates(), [logIds[0]]);
        expect((await repo.watchOne('co', id).first)!.lines, hasLength(1));
        await repo.deleteDraft(owner, id);
        expect(await candidates(), [logIds[0], logIds[1]]);
        expect(await repo.watchList('co').first, isEmpty);
      },
    );

    test(
      'finalize: server number, snapshots, logs invoiced and locked',
      () async {
        final id = await repo.saveDraft(
          owner,
          draft({logIds[0]: 150000, logIds[1]: 150000}),
        );
        final number = await repo.finalize(
          owner,
          id,
          numbers: numbers,
          company: company,
        );
        expect(number, 'JCB/2026-27/0001');
        final v = (await repo.watchOne('co', id).first)!;
        expect(v.status, InvoiceStatus.finalized);
        expect(v.invoiceNumber, number);
        expect(v.companySnapshot!.gstin, '27ABCDE1234F1Z5');
        expect(v.clientSnapshot!.address, 'Hinjewadi, Pune');
        expect(v.stateOn('2026-11-02'), InvoiceState.unpaid);
        final log = (await logs.watchOne('co', logIds[0]).first)!;
        expect(log.status, WorkLogStatus.invoiced);
        expect(WorkLogPolicy.canCorrect(CompanyRole.owner, log), isFalse);

        // Snapshot is preserved even if the client master changes later.
        await MastersRepository(db).save(
          MasterKind.clients,
          const MasterScope(companyId: 'co', userId: 'owner'),
          {'name': 'Patil Renamed', 'billingAddress': 'Elsewhere'},
          id: client,
        );
        expect(
          (await repo.watchOne('co', id).first)!.clientSnapshot!.name,
          'Patil',
        );

        // Finalized invoices are immutable.
        await expectLater(
          repo.saveDraft(owner, draft({logIds[0]: 1}), id: id),
          throwsA(isA<InvoiceException>()),
        );
        await expectLater(
          repo.deleteDraft(owner, id),
          throwsA(isA<InvoiceException>()),
        );
        await expectLater(
          repo.finalize(owner, id, numbers: numbers, company: company),
          throwsA(isA<InvoiceException>()),
        );
      },
    );

    test(
      'finalize offline keeps the draft; missing rates are refused',
      () async {
        final id = await repo.saveDraft(owner, draft({logIds[0]: 0}));
        await expectLater(
          repo.finalize(owner, id, numbers: numbers, company: company),
          throwsA(
            isA<InvoiceException>().having((e) => e.fieldErrors.keys, 'k', [
              'rates',
            ]),
          ),
        );
        await repo.saveDraft(owner, draft({logIds[0]: 150000}), id: id);
        numbers.offline = true;
        await expectLater(
          repo.finalize(owner, id, numbers: numbers, company: company),
          throwsA(isA<InvoiceNumberUnavailable>()),
        );
        expect(
          (await repo.watchOne('co', id).first)!.status,
          InvoiceStatus.draft,
        );
        numbers.offline = false;
        expect(
          await repo.finalize(owner, id, numbers: numbers, company: company),
          'JCB/2026-27/0001',
        );
        // The server checks this phone's activation before issuing numbers.
        expect(numbers.deviceIds, {await db.installationId()});
      },
    );

    test('partial payments, overpayment blocked, reversal audited', () async {
      final id = await repo.saveDraft(
        owner,
        draft({logIds[0]: 150000}),
      ); // ₹12,000
      await expectLater(
        repo.recordPayment(
          accounts,
          id,
          const PaymentInput(
            paymentDate: '2026-11-03',
            amountPaise: 100,
            method: PaymentMethod.cash,
          ),
        ),
        throwsA(isA<InvoiceException>()),
        reason: 'drafts cannot be paid',
      );
      await repo.finalize(owner, id, numbers: numbers, company: company);
      final p1 = await repo.recordPayment(
        accounts,
        id,
        const PaymentInput(
          paymentDate: '2026-11-03',
          amountPaise: 500000,
          method: PaymentMethod.upi,
          reference: 'UTR123',
        ),
      );
      var v = (await repo.watchOne('co', id).first)!;
      expect(v.paidPaise, 500000);
      expect(v.outstandingPaise, 700000);
      expect(v.stateOn('2026-11-04'), InvoiceState.partiallyPaid);

      await expectLater(
        repo.recordPayment(
          accounts,
          id,
          const PaymentInput(
            paymentDate: '2026-11-04',
            amountPaise: 700001,
            method: PaymentMethod.cash,
          ),
        ),
        throwsA(
          isA<InvoiceException>().having((e) => e.fieldErrors.keys, 'k', [
            'amount',
          ]),
        ),
      );
      await expectLater(
        repo.recordPayment(
          accounts,
          id,
          const PaymentInput(
            paymentDate: '2026-11-04',
            amountPaise: 0,
            method: PaymentMethod.cash,
          ),
        ),
        throwsA(isA<InvoiceException>()),
      );
      await repo.recordPayment(
        accounts,
        id,
        const PaymentInput(
          paymentDate: '2026-11-05',
          amountPaise: 700000,
          method: PaymentMethod.bank,
        ),
      );
      v = (await repo.watchOne('co', id).first)!;
      expect(v.stateOn('2026-12-31'), InvoiceState.paid);
      expect(v.outstandingPaise, 0);

      await expectLater(
        repo.reversePayment(accounts, p1, reason: ''),
        throwsA(isA<InvoiceException>()),
      );
      await repo.reversePayment(accounts, p1, reason: 'Cheque bounced');
      v = (await repo.watchOne('co', id).first)!;
      expect(v.paidPaise, 700000);
      expect(v.payments, hasLength(2));
      expect(v.payments.first.isValid, isFalse);
      expect(v.payments.first.reverseReason, 'Cheque bounced');
      final history = await repo.watchHistory('co', id).first;
      expect(history.map((h) => h.action), [
        'create',
        'finalize',
        'payment',
        'payment',
        'payment_reverse',
      ]);
      expect(
        await repo
            .watchReceived('co', from: '2026-11-01', to: '2026-11-30')
            .first,
        700000,
      );
    });

    test('cancel: reason required, blocked with payments, keeps number, frees logs', () async {
      final id = await repo.saveDraft(owner, draft({logIds[0]: 150000}));
      await repo.finalize(owner, id, numbers: numbers, company: company);
      final pay = await repo.recordPayment(
        owner,
        id,
        const PaymentInput(
          paymentDate: '2026-11-03',
          amountPaise: 1000,
          method: PaymentMethod.cash,
        ),
      );
      await expectLater(
        repo.cancel(owner, id, reason: 'Wrong rate'),
        throwsA(isA<InvoiceException>()),
      );
      await repo.reversePayment(owner, pay, reason: 'Entered by mistake');
      await expectLater(
        repo.cancel(owner, id, reason: ' '),
        throwsA(isA<InvoiceException>()),
      );
      await repo.cancel(owner, id, reason: 'Wrong rate');
      final v = (await repo.watchOne('co', id).first)!;
      expect(v.status, InvoiceStatus.cancelled);
      expect(v.invoiceNumber, 'JCB/2026-27/0001');
      expect(v.cancelReason, 'Wrong rate');
      expect(await candidates(), [logIds[0], logIds[1]]);
      expect(
        (await logs.watchOne('co', logIds[0]).first)!.status,
        WorkLogStatus.approved,
      );
      // Re-billed invoices get the next number.
      final id2 = await repo.saveDraft(owner, draft({logIds[0]: 160000}));
      expect(
        await repo.finalize(owner, id2, numbers: numbers, company: company),
        'JCB/2026-27/0002',
      );
    });

    test('reserved logs cannot be corrected or cancelled', () async {
      await repo.saveDraft(owner, draft({logIds[0]: 150000}));
      final log = (await logs.watchOne('co', logIds[0]).first)!;
      expect(WorkLogPolicy.canCorrect(CompanyRole.owner, log), isFalse);
      expect(WorkLogPolicy.canCancel(CompanyRole.owner, log, 'owner'), isFalse);
      await expectLater(
        logs.cancel(owner, logIds[0], reason: 'x'),
        throwsA(isA<WorkLogException>()),
      );
    });

    test('permissions and tenant isolation', () async {
      await expectLater(
        repo.saveDraft(manager, draft({logIds[0]: 150000})),
        throwsA(isA<InvoiceException>()),
      );
      final id = await repo.saveDraft(accounts, draft({logIds[0]: 150000}));
      expect(await repo.watchOne('other', id).first, isNull);
      await expectLater(
        repo.deleteDraft(outsider, id),
        throwsStateError, // another company's invoice is invisible
      );
      expect(await repo.watchList('other').first, isEmpty);
    });
  });
}
