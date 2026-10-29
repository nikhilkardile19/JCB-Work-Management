import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../company/domain/permissions.dart';
import '../domain/work_log.dart';

/// Who is acting, where, and with which role.
class WorkActor {
  const WorkActor({
    required this.companyId,
    required this.userId,
    required this.role,
  });

  final String companyId;
  final String userId;
  final CompanyRole role;
}

/// Save refused; [fieldErrors] keys: clientId, siteId, machineId, operatorId,
/// start, end, manualReason, reason, status.
class WorkLogException implements Exception {
  const WorkLogException(this.fieldErrors);

  final Map<String, String> fieldErrors;

  @override
  String toString() => fieldErrors.values.join('; ');
}

/// Save needs the user to confirm these warnings first.
class WorkLogNeedsConfirmation implements Exception {
  const WorkLogNeedsConfirmation(this.warnings);

  final List<WorkLogWarning> warnings;
}

class WorkHistoryEntry {
  const WorkHistoryEntry({
    required this.action,
    required this.actorId,
    required this.at,
    this.details,
  });

  final String action;
  final String actorId;
  final int at;
  final Map<String, dynamic>? details;
}

class WorkLogRepository {
  WorkLogRepository(
    this._db, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final DateTime Function() _clock;
  final String Function() _newId;

  static const _entity = 'workLogs';

  int _now() => _clock().toUtc().millisecondsSinceEpoch;

  $WorkLogsTable get _logs => _db.workLogs;

  JoinedSelectStatement<HasResultSet, dynamic> _joined(String companyId) {
    final q = _db.select(_logs).join([
      innerJoin(_db.clients, _db.clients.id.equalsExp(_logs.clientId)),
      innerJoin(_db.sites, _db.sites.id.equalsExp(_logs.siteId)),
      innerJoin(_db.machines, _db.machines.id.equalsExp(_logs.machineId)),
    ])..where(_logs.companyId.equals(companyId) & _logs.deletedAt.isNull());
    return q;
  }

  WorkLogView _view(TypedResult row) {
    final l = row.readTable(_logs);
    return WorkLogView(
      id: l.id,
      workDate: l.workDate,
      clientId: l.clientId,
      clientName: row.readTable(_db.clients).name,
      siteId: l.siteId,
      siteName: row.readTable(_db.sites).name,
      machineId: l.machineId,
      machineName: row.readTable(_db.machines).name,
      operatorId: l.operatorId,
      operatorName: l.operatorName,
      start: MeterCapture(
        reading: l.startReading,
        photoPath: l.startPhotoPath,
        capturedAt: l.startCapturedAt,
        lat: l.startLat,
        lng: l.startLng,
        accuracy: l.startAccuracy,
        locationStatus: LocationStatus.parse(l.startLocationStatus),
      ),
      end: MeterCapture(
        reading: l.endReading,
        photoPath: l.endPhotoPath,
        capturedAt: l.endCapturedAt,
        lat: l.endLat,
        lng: l.endLng,
        accuracy: l.endAccuracy,
        locationStatus: LocationStatus.parse(l.endLocationStatus),
      ),
      workingHours: l.workingHours,
      entryMode: EntryMode.values.byName(l.entryMode),
      manualReason: l.manualReason,
      notes: l.notes,
      anomalyFlags: AnomalyFlag.parse(l.anomalyFlags),
      status: WorkLogStatus.parse(l.status),
      statusReason: l.statusReason,
      approvedBy: l.approvedBy,
      approvedAt: l.approvedAt,
      invoiceId: l.invoiceId,
      createdBy: l.createdBy,
      updatedAt: l.updatedAt,
      syncStatus: l.syncStatus,
    );
  }

  Stream<List<WorkLogView>> watchList(
    String companyId, {
    Set<WorkLogStatus>? statuses,
  }) {
    final q = _joined(companyId);
    if (statuses != null) {
      q.where(_logs.status.isIn(statuses.map((s) => s.name)));
    }
    q.orderBy([
      OrderingTerm.desc(_logs.workDate),
      OrderingTerm.desc(_logs.createdAt),
    ]);
    return q.watch().map((rows) => rows.map(_view).toList());
  }

  /// Logs dated [from]..[to] (inclusive, `yyyy-MM-dd`), any status.
  Stream<List<WorkLogView>> watchBetween(
    String companyId, {
    required String from,
    required String to,
  }) {
    final q = _joined(companyId)
      ..where(_logs.workDate.isBetweenValues(from, to))
      ..orderBy([
        OrderingTerm.asc(_logs.workDate),
        OrderingTerm.asc(_logs.startReading),
      ]);
    return q.watch().map((rows) => rows.map(_view).toList());
  }

  Stream<WorkLogView?> watchOne(String companyId, String id) {
    final q = _joined(companyId)..where(_logs.id.equals(id));
    return q.watchSingleOrNull().map((r) => r == null ? null : _view(r));
  }

  Future<WorkLogView?> _get(String companyId, String id) =>
      watchOne(companyId, id).first;

  /// Hours (hundredths) logged on [dateKey], excluding cancelled logs.
  Stream<int> watchHoursOn(String companyId, String dateKey) {
    final sum = _logs.workingHours.sum();
    final q = _db.selectOnly(_logs)
      ..addColumns([sum])
      ..where(
        _logs.companyId.equals(companyId) &
            _logs.deletedAt.isNull() &
            _logs.workDate.equals(dateKey) &
            _logs.status.equals(WorkLogStatus.cancelled.name).not(),
      );
    return q.watchSingle().map((r) => r.read(sum) ?? 0);
  }

  Stream<int> watchCount(String companyId, WorkLogStatus status) {
    final count = _logs.id.count();
    final q = _db.selectOnly(_logs)
      ..addColumns([count])
      ..where(
        _logs.companyId.equals(companyId) &
            _logs.deletedAt.isNull() &
            _logs.status.equals(status.name),
      );
    return q.watchSingle().map((r) => r.read(count) ?? 0);
  }

  /// Last known meter reading for [machineId] up to [dateKey], and how many
  /// other logs it has on that date.
  Future<ReadingContext> readingContext(
    String companyId,
    String machineId,
    String dateKey, {
    String? excludeId,
  }) async {
    final machine =
        await (_db.select(_db.machines)..where(
              (t) => t.id.equals(machineId) & t.companyId.equals(companyId),
            ))
            .getSingleOrNull();
    if (machine == null) return const ReadingContext();

    Expression<bool> others() {
      var e =
          _logs.companyId.equals(companyId) &
          _logs.machineId.equals(machineId) &
          _logs.deletedAt.isNull() &
          _logs.status.equals(WorkLogStatus.cancelled.name).not();
      if (excludeId != null) e = e & _logs.id.equals(excludeId).not();
      return e;
    }

    final latest = coalesce([_logs.endReading, _logs.startReading]).max();
    final maxRow =
        await (_db.selectOnly(_logs)
              ..addColumns([latest])
              ..where(others() & _logs.workDate.isSmallerOrEqualValue(dateKey)))
            .getSingle();
    final count = _logs.id.count();
    final sameDay =
        await (_db.selectOnly(_logs)
              ..addColumns([count])
              ..where(others() & _logs.workDate.equals(dateKey)))
            .getSingle();
    final fromLogs = maxRow.read(latest);
    return ReadingContext(
      lastReading: fromLogs == null || fromLogs < machine.initialMeterReading
          ? machine.initialMeterReading
          : fromLogs,
      sameDayLogs: sameDay.read(count) ?? 0,
    );
  }

  /// Saves without submitting. The end reading may still be empty.
  Future<String> saveDraft(WorkActor actor, WorkLogInput input, {String? id}) =>
      _db.transaction(() async {
        final current = id == null ? null : await _require(actor, id);
        if (current == null) {
          _ensure(WorkLogPolicy.canCreate(actor.role), 'create work logs');
        } else {
          _ensure(
            WorkLogPolicy.canEdit(actor.role, current, actor.userId) &&
                current.status != WorkLogStatus.submitted,
            'edit this work log',
          );
        }
        await _validate(actor, input, requireEnd: false);
        return _write(
          actor,
          input,
          current: current,
          status: WorkLogStatus.draft,
          action: current == null ? 'create' : 'update',
        );
      });

  /// Completes and submits. Approvers' own submissions are approved at once.
  /// Throws [WorkLogNeedsConfirmation] if warnings aren't in
  /// [WorkLogInput.anomalyFlags].
  Future<(String, WorkLogStatus)> submit(
    WorkActor actor,
    WorkLogInput input, {
    String? id,
  }) => _db.transaction(() async {
    final current = id == null ? null : await _require(actor, id);
    if (current == null) {
      _ensure(WorkLogPolicy.canCreate(actor.role), 'create work logs');
    } else {
      _ensure(
        WorkLogPolicy.canEdit(actor.role, current, actor.userId),
        'submit this work log',
      );
    }
    await _validate(actor, input, requireEnd: true, excludeId: id);
    final status = WorkLogPolicy.submitStatus(actor.role);
    final newId = await _write(
      actor,
      input,
      current: current,
      status: status,
      action: status == WorkLogStatus.approved ? 'submit_approve' : 'submit',
    );
    return (newId, status);
  });

  /// Edits an approved log. [reason] is mandatory and audited.
  Future<void> correct(
    WorkActor actor,
    String id,
    WorkLogInput input, {
    required String reason,
  }) => _db.transaction(() async {
    final current = await _require(actor, id);
    _ensure(WorkLogPolicy.canCorrect(actor.role, current), 'correct this log');
    if (reason.trim().isEmpty) {
      throw const WorkLogException({
        'reason': 'Enter a reason for the correction',
      });
    }
    await _validate(actor, input, requireEnd: true, excludeId: id);
    await _write(
      actor,
      input,
      current: current,
      status: WorkLogStatus.approved,
      action: 'correct',
      reason: reason.trim(),
    );
  });

  Future<void> approve(WorkActor actor, String id) => _transition(
    actor,
    id,
    WorkLogStatus.approved,
    'approve',
    check: WorkLogPolicy.canReview,
  );

  Future<void> reject(WorkActor actor, String id, {required String reason}) =>
      _transition(
        actor,
        id,
        WorkLogStatus.rejected,
        'reject',
        reason: reason,
        check: WorkLogPolicy.canReview,
      );

  Future<void> cancel(WorkActor actor, String id, {required String reason}) =>
      _transition(
        actor,
        id,
        WorkLogStatus.cancelled,
        'cancel',
        reason: reason,
        check: (r, l) => WorkLogPolicy.canCancel(r, l, actor.userId),
      );

  Stream<List<WorkHistoryEntry>> watchHistory(String companyId, String id) =>
      (_db.select(_db.auditLogs)
            ..where(
              (t) =>
                  t.companyId.equals(companyId) &
                  t.entityType.equals(_entity) &
                  t.entityId.equals(id),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                WorkHistoryEntry(
                  action: r.action,
                  actorId: r.actorId,
                  at: r.createdAt,
                  details: r.details == null
                      ? null
                      : jsonDecode(r.details!) as Map<String, dynamic>,
                ),
            ],
          );

  // ---------------------------------------------------------------------------

  Future<WorkLogView> _require(WorkActor actor, String id) async {
    final v = await _get(actor.companyId, id);
    if (v == null) throw StateError('Work log $id not found');
    return v;
  }

  static void _ensure(bool allowed, String what) {
    if (!allowed) {
      throw WorkLogException({'status': "You don't have permission to $what."});
    }
  }

  Future<void> _transition(
    WorkActor actor,
    String id,
    WorkLogStatus to,
    String action, {
    required bool Function(CompanyRole, WorkLogView) check,
    String? reason,
  }) => _db.transaction(() async {
    final current = await _require(actor, id);
    _ensure(check(actor.role, current), '$action this log');
    final needsReason =
        to == WorkLogStatus.rejected ||
        (to == WorkLogStatus.cancelled &&
            current.status == WorkLogStatus.approved);
    if (needsReason && (reason?.trim().isEmpty ?? true)) {
      throw const WorkLogException({'reason': 'Enter a reason'});
    }
    final now = _now();
    await (_db.update(_logs)..where((t) => t.id.equals(id))).write(
      WorkLogsCompanion(
        status: Value(to.name),
        statusReason: Value(
          reason?.trim().isEmpty ?? true ? null : reason!.trim(),
        ),
        approvedBy: to == WorkLogStatus.approved
            ? Value(actor.userId)
            : const Value.absent(),
        approvedAt: to == WorkLogStatus.approved
            ? Value(now)
            : const Value.absent(),
        updatedAt: Value(now),
        updatedBy: Value(actor.userId),
        syncStatus: const Value('pending'),
        version: Value(await _version(id) + 1),
      ),
    );
    await _audit(actor, id, action, {
      'status': {'from': current.status.name, 'to': to.name},
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  });

  Future<int> _version(String id) async => (await (_db.select(
    _logs,
  )..where((t) => t.id.equals(id))).getSingle()).version;

  Future<void> _validate(
    WorkActor actor,
    WorkLogInput input, {
    required bool requireEnd,
    String? excludeId,
  }) async {
    final errors = <String, String>{};
    final cid = actor.companyId;
    Future<bool> exists(
      TableInfo<MasterColumns, DataClass> t,
      String? id, {
      String? clientId,
    }) async {
      if (id == null) return false;
      final dsl = t.asDslTable;
      final q = _db.selectOnly(t)
        ..addColumns([dsl.id])
        ..where(
          dsl.id.equals(id) &
              dsl.companyId.equals(cid) &
              dsl.deletedAt.isNull(),
        );
      if (clientId != null) q.where(_db.sites.clientId.equals(clientId));
      return (await q.get()).isNotEmpty;
    }

    if (!await exists(_db.clients, input.clientId)) {
      errors['clientId'] = 'Select a client';
    }
    if (!await exists(_db.sites, input.siteId, clientId: input.clientId)) {
      errors['siteId'] = 'Select a site of this client';
    }
    if (!await exists(_db.machines, input.machineId)) {
      errors['machineId'] = 'Select a machine';
    }
    if (input.operatorId != null &&
        !await exists(_db.operators, input.operatorId)) {
      errors['operatorId'] = 'Select an operator from your list';
    }
    errors.addAll(WorkLogRules.readingErrors(input, requireEnd: requireEnd));
    if (errors.isNotEmpty) throw WorkLogException(errors);

    if (requireEnd) {
      final ctx = await readingContext(
        cid,
        input.machineId!,
        input.workDate,
        excludeId: excludeId,
      );
      final unconfirmed = WorkLogRules.warnings(
        input,
        ctx,
      ).where((w) => !input.anomalyFlags.contains(w.flag)).toList();
      if (unconfirmed.isNotEmpty) throw WorkLogNeedsConfirmation(unconfirmed);
    }
  }

  Future<String> _write(
    WorkActor actor,
    WorkLogInput input, {
    required WorkLogView? current,
    required WorkLogStatus status,
    required String action,
    String? reason,
  }) async {
    final now = _now();
    final id = current?.id ?? _newId();
    final operatorName = input.operatorId == null
        ? null
        : (await (_db.select(
            _db.operators,
          )..where((t) => t.id.equals(input.operatorId!))).getSingle()).name;
    final manual = input.entryMode == EntryMode.manual;
    String? clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

    final values = WorkLogsCompanion(
      workDate: Value(input.workDate),
      clientId: Value(input.clientId!),
      siteId: Value(input.siteId!),
      machineId: Value(input.machineId!),
      operatorId: Value(input.operatorId),
      operatorName: Value(operatorName),
      startReading: Value(input.start.reading!),
      startPhotoPath: Value(input.start.photoPath),
      startCapturedAt: Value(input.start.capturedAt),
      startLat: Value(input.start.lat),
      startLng: Value(input.start.lng),
      startAccuracy: Value(input.start.accuracy),
      startLocationStatus: Value(input.start.locationStatus?.name),
      endReading: Value(input.end.reading),
      endPhotoPath: Value(input.end.photoPath),
      endCapturedAt: Value(input.end.capturedAt),
      endLat: Value(input.end.lat),
      endLng: Value(input.end.lng),
      endAccuracy: Value(input.end.accuracy),
      endLocationStatus: Value(input.end.locationStatus?.name),
      workingHours: Value(input.workingHours),
      entryMode: Value(input.entryMode.name),
      manualReason: Value(manual ? clean(input.manualReason) : null),
      notes: Value(clean(input.notes)),
      anomalyFlags: Value(AnomalyFlag.encode(input.anomalyFlags)),
      status: Value(status.name),
      statusReason: const Value(null),
      approvedBy: status == WorkLogStatus.approved
          ? Value(current?.approvedBy ?? actor.userId)
          : const Value(null),
      approvedAt: status == WorkLogStatus.approved
          ? Value(current?.approvedAt ?? now)
          : const Value(null),
      updatedAt: Value(now),
      updatedBy: Value(actor.userId),
      syncStatus: const Value('pending'),
    );

    if (current == null) {
      await _db
          .into(_logs)
          .insert(
            values.copyWith(
              id: Value(id),
              companyId: Value(actor.companyId),
              createdAt: Value(now),
              createdBy: Value(actor.userId),
              version: const Value(1),
            ),
          );
      await _audit(actor, id, action, {
        'status': status.name,
        'entryMode': input.entryMode.name,
        if (manual && clean(input.manualReason) != null)
          'manualReason': clean(input.manualReason),
        'startReading': input.start.reading,
        'endReading': input.end.reading,
      });
    } else {
      await (_db.update(_logs)..where((t) => t.id.equals(id))).write(
        values.copyWith(version: Value(await _version(id) + 1)),
      );
      await _audit(actor, id, action, {
        ..._diff(current, input, operatorName),
        if (current.status != status)
          'status': {'from': current.status.name, 'to': status.name},
        'reason': ?reason,
      });
    }
    return id;
  }

  static Map<String, Object?> _diff(
    WorkLogView before,
    WorkLogInput after,
    String? operatorName,
  ) {
    final pairs = <String, (Object?, Object?)>{
      'workDate': (before.workDate, after.workDate),
      'clientId': (before.clientId, after.clientId),
      'siteId': (before.siteId, after.siteId),
      'machineId': (before.machineId, after.machineId),
      'operatorName': (before.operatorName, operatorName),
      'startReading': (before.start.reading, after.start.reading),
      'endReading': (before.end.reading, after.end.reading),
      'startPhotoPath': (before.start.photoPath, after.start.photoPath),
      'endPhotoPath': (before.end.photoPath, after.end.photoPath),
      'entryMode': (before.entryMode.name, after.entryMode.name),
      'manualReason': (before.manualReason, after.manualReason?.trim()),
      'notes': (before.notes, after.notes?.trim()),
    };
    return {
      for (final e in pairs.entries)
        if (e.value.$1 != e.value.$2 &&
            !(e.value.$1 == null && e.value.$2 == ''))
          e.key: {'from': e.value.$1, 'to': e.value.$2},
    };
  }

  Future<void> _audit(
    WorkActor actor,
    String id,
    String action,
    Map<String, Object?> details,
  ) => _db
      .into(_db.auditLogs)
      .insert(
        AuditLogsCompanion.insert(
          id: _newId(),
          companyId: Value(actor.companyId),
          actorId: actor.userId,
          action: action,
          entityType: _entity,
          entityId: id,
          details: Value(jsonEncode(details)),
          createdAt: _now(),
        ),
      );
}
