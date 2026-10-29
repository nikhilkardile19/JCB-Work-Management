import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
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
const op = WorkActor(companyId: 'co', userId: 'op', role: CompanyRole.operator);
const manager = WorkActor(
  companyId: 'co',
  userId: 'mgr',
  role: CompanyRole.manager,
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

const photo = MeterCapture(
  reading: 0,
  photoPath: 'p.jpg',
  capturedAt: 1,
  locationStatus: LocationStatus.denied,
);

class Ids {
  late String client, site, machine, operator, otherSite;
}

void main() {
  group('rules', () {
    WorkLogInput input({
      int? start,
      int? end,
      bool photos = false,
      String? reason,
    }) => WorkLogInput(
      workDate: '2026-10-29',
      clientId: 'c',
      siteId: 's',
      machineId: 'm',
      start: photos ? photo.withReading(start) : MeterCapture(reading: start),
      end: photos ? photo.withReading(end) : MeterCapture(reading: end),
      manualReason: reason,
    );

    test('hours = end − start', () {
      expect(input(start: 123450, end: 124300).workingHours, 850);
      expect(input(start: 100).workingHours, isNull);
      expect(WorkLogRules.hours(500, 500), 0);
    });

    test('end below start is an error; equal is fine', () {
      expect(
        WorkLogRules.readingErrors(
          input(start: 500, end: 499),
          requireEnd: false,
        ),
        contains('end'),
      );
      expect(
        WorkLogRules.readingErrors(
          input(start: 500, end: 500, photos: true),
          requireEnd: true,
        ),
        isEmpty,
      );
    });

    test('drafts may omit end; submissions may not', () {
      expect(
        WorkLogRules.readingErrors(input(start: 1), requireEnd: false),
        isEmpty,
      );
      expect(
        WorkLogRules.readingErrors(input(start: 1), requireEnd: true),
        contains('end'),
      );
      expect(
        WorkLogRules.readingErrors(input(), requireEnd: false),
        contains('start'),
      );
    });

    test('manual entries need a reason to submit', () {
      final manual = input(start: 1, end: 2);
      expect(manual.entryMode, EntryMode.manual);
      expect(
        WorkLogRules.readingErrors(manual, requireEnd: true),
        contains('manualReason'),
      );
      expect(
        WorkLogRules.readingErrors(
          input(start: 1, end: 2, reason: 'Meter glass broken'),
          requireEnd: true,
        ),
        isEmpty,
      );
      expect(input(start: 1, end: 2, photos: true).entryMode, EntryMode.photo);
    });

    test('warnings: meter backwards, high hours, same-day duplicate', () {
      final w = WorkLogRules.warnings(
        input(start: 1000, end: 2500),
        const ReadingContext(lastReading: 1200, sameDayLogs: 1),
      ).map((w) => w.flag);
      expect(w, [
        AnomalyFlag.meterBackwards,
        AnomalyFlag.highHours,
        AnomalyFlag.duplicateDay,
      ]);
      expect(
        WorkLogRules.warnings(
          input(start: 1200, end: 2000),
          const ReadingContext(lastReading: 1200),
        ),
        isEmpty,
      );
    });

    test('anomaly flags encode/decode', () {
      final f = {AnomalyFlag.highHours, AnomalyFlag.duplicateDay};
      expect(AnomalyFlag.parse(AnomalyFlag.encode(f)), f);
      expect(AnomalyFlag.encode({}), isNull);
      expect(AnomalyFlag.parse('bogus,highHours'), {AnomalyFlag.highHours});
    });
  });

  group('repository', () {
    late AppDatabase db;
    late WorkLogRepository repo;
    late MastersRepository masters;
    final ids = Ids();
    var now = DateTime.utc(2026, 10, 29, 8);

    setUp(() async {
      db = memoryDatabase();
      now = DateTime.utc(2026, 10, 29, 8);
      repo = WorkLogRepository(db, clock: () => now);
      masters = MastersRepository(db);
      const s = MasterScope(companyId: 'co', userId: 'owner');
      ids.client = await masters.save(MasterKind.clients, s, {'name': 'Patil'});
      ids.site = await masters.save(MasterKind.sites, s, {
        'clientId': ids.client,
        'name': 'Yard',
      });
      final other = await masters.save(MasterKind.clients, s, {
        'name': 'Other',
      });
      ids.otherSite = await masters.save(MasterKind.sites, s, {
        'clientId': other,
        'name': 'Other yard',
      });
      ids.machine = await masters.save(MasterKind.machines, s, {
        'name': 'JCB 1',
        'initialMeterReading': 100000,
      });
      ids.operator = await masters.save(MasterKind.operators, s, {
        'name': 'Suresh',
      });
    });
    tearDown(() => db.close());

    WorkLogInput log({
      int start = 100000,
      int? end = 100850,
      bool photos = true,
      String? reason,
      String date = '2026-10-29',
      String? site,
      Set<AnomalyFlag> flags = const {},
    }) => WorkLogInput(
      workDate: date,
      clientId: ids.client,
      siteId: site ?? ids.site,
      machineId: ids.machine,
      operatorId: ids.operator,
      start: photos ? photo.withReading(start) : MeterCapture(reading: start),
      end: photos ? photo.withReading(end) : MeterCapture(reading: end),
      manualReason: reason,
      anomalyFlags: flags,
    );

    test(
      'operator submission waits for approval; owner submission is approved',
      () async {
        final (id1, s1) = await repo.submit(op, log());
        expect(s1, WorkLogStatus.submitted);
        final (_, s2) = await repo.submit(
          owner,
          log(start: 100850, end: 101000, flags: {AnomalyFlag.duplicateDay}),
        );
        expect(s2, WorkLogStatus.approved);
        final v = (await repo.watchOne('co', id1).first)!;
        expect(v.workingHours, 850);
        expect(v.operatorName, 'Suresh');
        expect(v.machineName, 'JCB 1');
        expect(v.siteName, 'Yard');
        expect(v.entryMode, EntryMode.photo);
      },
    );

    test('draft without end reading, completed later', () async {
      final id = await repo.saveDraft(op, log(end: null));
      var v = (await repo.watchOne('co', id).first)!;
      expect(v.status, WorkLogStatus.draft);
      expect(v.inProgress, isTrue);
      expect(v.workingHours, isNull);
      await repo.submit(op, log(), id: id);
      v = (await repo.watchOne('co', id).first)!;
      expect(v.status, WorkLogStatus.submitted);
      expect(v.workingHours, 850);
    });

    test(
      'manual entries require a reason and are recorded as manual',
      () async {
        await expectLater(
          repo.submit(op, log(photos: false)),
          throwsA(
            isA<WorkLogException>().having(
              (e) => e.fieldErrors.keys,
              'k',
              contains('manualReason'),
            ),
          ),
        );
        final (id, _) = await repo.submit(
          op,
          log(photos: false, reason: 'Meter glass fogged'),
        );
        final v = (await repo.watchOne('co', id).first)!;
        expect(v.entryMode, EntryMode.manual);
        expect(v.manualReason, 'Meter glass fogged');
        final audit = await (db.select(
          db.auditLogs,
        )..where((t) => t.entityId.equals(id))).getSingle();
        expect(audit.details, contains('Meter glass fogged'));
      },
    );

    test('site must belong to the selected client', () async {
      await expectLater(
        repo.submit(op, log(site: ids.otherSite)),
        throwsA(
          isA<WorkLogException>().having((e) => e.fieldErrors.keys, 'k', [
            'siteId',
          ]),
        ),
      );
    });

    test('warnings must be confirmed before submitting', () async {
      // Below the machine's initial reading.
      await expectLater(
        repo.submit(op, log(start: 99000, end: 99500)),
        throwsA(
          isA<WorkLogNeedsConfirmation>().having(
            (e) => e.warnings.single.flag,
            'f',
            AnomalyFlag.meterBackwards,
          ),
        ),
      );
      final (id, _) = await repo.submit(
        op,
        log(start: 99000, end: 99500, flags: {AnomalyFlag.meterBackwards}),
      );
      expect((await repo.watchOne('co', id).first)!.anomalyFlags, {
        AnomalyFlag.meterBackwards,
      });
    });

    test(
      'last reading follows earlier logs; duplicates on a day are flagged',
      () async {
        await repo.submit(
          owner,
          log(start: 100000, end: 100800, date: '2026-10-28'),
        );
        final ctx = await repo.readingContext('co', ids.machine, '2026-10-29');
        expect(ctx.lastReading, 100800);
        expect(ctx.sameDayLogs, 0);
        await repo.submit(owner, log(start: 100800, end: 101000));
        final ctx2 = await repo.readingContext('co', ids.machine, '2026-10-29');
        expect(ctx2.sameDayLogs, 1);
        // A back-dated log only compares against logs up to its date.
        final back = await repo.readingContext('co', ids.machine, '2026-10-27');
        expect(back.lastReading, 100000);
      },
    );

    test(
      'approve and reject need the approver role; rejection needs a reason',
      () async {
        final (id, _) = await repo.submit(op, log());
        await expectLater(
          repo.approve(op, id),
          throwsA(isA<WorkLogException>()),
        );
        await expectLater(
          repo.approve(accounts, id),
          throwsA(isA<WorkLogException>()),
        );
        await expectLater(
          repo.reject(manager, id, reason: ' '),
          throwsA(isA<WorkLogException>()),
        );
        await repo.reject(manager, id, reason: 'Wrong site');
        var v = (await repo.watchOne('co', id).first)!;
        expect(v.status, WorkLogStatus.rejected);
        expect(v.statusReason, 'Wrong site');

        // Operator fixes and resubmits; manager approves.
        await repo.submit(op, log(), id: id);
        await repo.approve(manager, id);
        v = (await repo.watchOne('co', id).first)!;
        expect(v.status, WorkLogStatus.approved);
        expect(v.approvedBy, 'mgr');
        expect(v.statusReason, isNull);
      },
    );

    test('operators cannot edit others\' drafts or approved logs', () async {
      final id = await repo.saveDraft(manager, log(end: null));
      await expectLater(
        repo.saveDraft(op, log(end: null), id: id),
        throwsA(isA<WorkLogException>()),
      );
      final (approved, _) = await repo.submit(
        owner,
        log(start: 100850, end: 101000, flags: {AnomalyFlag.duplicateDay}),
      );
      await expectLater(
        repo.submit(op, log(), id: approved),
        throwsA(isA<WorkLogException>()),
      );
      await expectLater(
        repo.saveDraft(owner, log(), id: approved),
        throwsA(isA<WorkLogException>()),
      );
    });

    test(
      'corrections of approved logs: owner only, reason required, audited diff',
      () async {
        final (id, _) = await repo.submit(owner, log());
        await expectLater(
          repo.correct(manager, id, log(end: 100900), reason: 'typo'),
          throwsA(isA<WorkLogException>()),
        );
        await expectLater(
          repo.correct(owner, id, log(end: 100900), reason: ''),
          throwsA(isA<WorkLogException>()),
        );
        now = now.add(const Duration(hours: 2));
        await repo.correct(
          owner,
          id,
          log(end: 100900),
          reason: 'End reading misread',
        );
        final v = (await repo.watchOne('co', id).first)!;
        expect(v.status, WorkLogStatus.approved);
        expect(v.workingHours, 900);
        final history = await repo.watchHistory('co', id).first;
        expect(history.map((h) => h.action), ['submit_approve', 'correct']);
        expect(history.last.details!['reason'], 'End reading misread');
        expect(history.last.details!['endReading'], {
          'from': 100850,
          'to': 100900,
        });
        final row = await (db.select(
          db.workLogs,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(row.version, 2);
        expect(row.syncStatus, 'pending');
      },
    );

    test(
      'cancel: approved needs owner + reason; cancelled logs stop counting',
      () async {
        final (id, _) = await repo.submit(owner, log());
        expect(await repo.watchHoursOn('co', '2026-10-29').first, 850);
        await expectLater(
          repo.cancel(owner, id, reason: ''),
          throwsA(isA<WorkLogException>()),
        );
        await repo.cancel(owner, id, reason: 'Entered twice');
        expect(
          (await repo.watchOne('co', id).first)!.status,
          WorkLogStatus.cancelled,
        );
        expect(await repo.watchHoursOn('co', '2026-10-29').first, 0);
        final ctx = await repo.readingContext('co', ids.machine, '2026-10-29');
        expect(ctx.sameDayLogs, 0);
      },
    );

    test('pending count and status filter', () async {
      await repo.submit(op, log());
      await repo.saveDraft(op, log(start: 100850, end: null));
      expect(await repo.watchCount('co', WorkLogStatus.submitted).first, 1);
      final pending = await repo
          .watchList('co', statuses: {WorkLogStatus.submitted})
          .first;
      expect(pending, hasLength(1));
      expect(await repo.watchList('co').first, hasLength(2));
    });

    test('tenant isolation', () async {
      final (id, _) = await repo.submit(op, log());
      expect(await repo.watchOne('other', id).first, isNull);
      expect(await repo.watchList('other').first, isEmpty);
      await expectLater(repo.approve(outsider, id), throwsStateError);
      // Another company's masters can't be referenced.
      await expectLater(
        repo.submit(outsider, log()),
        throwsA(isA<WorkLogException>()),
      );
    });

    test('masters used by work logs cannot be deleted', () async {
      await repo.submit(op, log());
      const s = MasterScope(companyId: 'co', userId: 'owner');
      for (final (kind, id) in [
        (MasterKind.machines, ids.machine),
        (MasterKind.sites, ids.site),
        (MasterKind.operators, ids.operator),
        (MasterKind.clients, ids.client),
      ]) {
        await expectLater(
          masters.delete(kind, s, id),
          throwsA(isA<MasterInUseException>()),
          reason: kind.name,
        );
      }
    });
  });
}
