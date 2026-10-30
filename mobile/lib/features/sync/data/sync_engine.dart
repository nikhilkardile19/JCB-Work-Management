import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import 'remote_store.dart';

enum ConflictPolicy {
  /// Newer `updatedAt` wins; the other version is written to the audit log.
  lastWriteWins,

  /// Financial records: never auto-merged; the user chooses.
  manual,

  /// Create-only records (audit log): an existing copy is the same record.
  appendOnly,
}

/// How one local table maps to a server sync collection.
class SyncSpec<D extends DataClass> {
  const SyncSpec({
    required this.collection,
    required this.table,
    required this.fromJson,
    required this.policy,
    required this.label,
    this.localOnly = const {},
    this.billingOnly = false,
  });

  final String collection;
  final TableInfo<Table, D> table;
  final D Function(Map<String, dynamic>) fromJson;
  final ConflictPolicy policy;

  /// Device-specific fields (photo/PDF paths) — never uploaded, and kept
  /// when the record is downloaded again.
  final Set<String> localOnly;

  /// Only synced for roles that can see billing.
  final bool billingOnly;

  /// Short human description for the Sync screen.
  final String Function(Map<String, dynamic>) label;

  GeneratedColumn<String> col(String sqlName) =>
      table.columnsByName[sqlName]! as GeneratedColumn<String>;

  bool get hasVersion => table.columnsByName.containsKey('version');
}

String _money(Object? paise) =>
    paise is int ? '₹${(paise / 100).toStringAsFixed(2)}' : '';

/// Upload/download order respects references (sites need clients, …).
List<SyncSpec<DataClass>> syncSpecs(AppDatabase db) => [
  SyncSpec<Client>(
    collection: 'clients',
    table: db.clients,
    fromJson: Client.fromJson,
    policy: ConflictPolicy.lastWriteWins,
    label: (j) => 'Client ${j['name']}',
  ),
  SyncSpec<Site>(
    collection: 'sites',
    table: db.sites,
    fromJson: Site.fromJson,
    policy: ConflictPolicy.lastWriteWins,
    label: (j) => 'Site ${j['name']}',
  ),
  SyncSpec<Machine>(
    collection: 'machines',
    table: db.machines,
    fromJson: Machine.fromJson,
    policy: ConflictPolicy.lastWriteWins,
    label: (j) => 'Machine ${j['name']}',
  ),
  SyncSpec<Operator>(
    collection: 'operators',
    table: db.operators,
    fromJson: Operator.fromJson,
    policy: ConflictPolicy.lastWriteWins,
    label: (j) => 'Operator ${j['name']}',
  ),
  SyncSpec<PetrolPump>(
    collection: 'petrolPumps',
    table: db.petrolPumps,
    fromJson: PetrolPump.fromJson,
    policy: ConflictPolicy.lastWriteWins,
    label: (j) => 'Petrol pump ${j['name']}',
  ),
  SyncSpec<WorkLog>(
    collection: 'workLogs',
    table: db.workLogs,
    fromJson: WorkLog.fromJson,
    policy: ConflictPolicy.manual,
    localOnly: {'startPhotoPath', 'endPhotoPath'},
    label: (j) => 'Work log ${j['workDate']}',
  ),
  SyncSpec<FuelEntry>(
    collection: 'fuelEntries',
    table: db.fuelEntries,
    fromJson: FuelEntry.fromJson,
    policy: ConflictPolicy.manual,
    localOnly: {'receiptPhotoPath'},
    label: (j) => 'Fuel ${j['fuelDate']} ${_money(j['totalPaise'])}',
  ),
  SyncSpec<Invoice>(
    collection: 'invoices',
    table: db.invoices,
    fromJson: Invoice.fromJson,
    policy: ConflictPolicy.manual,
    localOnly: {'pdfPath'},
    billingOnly: true,
    label: (j) =>
        'Invoice ${j['invoiceNumber'] ?? 'draft'} ${_money(j['totalPaise'])}',
  ),
  SyncSpec<Payment>(
    collection: 'payments',
    table: db.payments,
    fromJson: Payment.fromJson,
    policy: ConflictPolicy.manual,
    billingOnly: true,
    label: (j) => 'Payment ${_money(j['amountPaise'])} on ${j['paymentDate']}',
  ),
  SyncSpec<AuditLog>(
    collection: 'auditLogs',
    table: db.auditLogs,
    fromJson: AuditLog.fromJson,
    policy: ConflictPolicy.appendOnly,
    label: (j) => 'History entry ${j['action']}',
  ),
];

class SyncReport {
  int pushed = 0;
  int pulled = 0;
  int conflicts = 0;
  int errors = 0;
  int autoResolved = 0;

  @override
  String toString() =>
      'pushed $pushed, pulled $pulled, conflicts $conflicts, errors $errors, auto-resolved $autoResolved';
}

/// A record the user has to look at: a conflict or a refused change.
class SyncIssue {
  const SyncIssue({
    required this.collection,
    required this.id,
    required this.label,
    required this.isConflict,
    this.message,
    this.serverLabel,
  });

  final String collection;
  final String id;
  final String label;
  final bool isConflict;
  final String? message;
  final String? serverLabel;
}

/// Local vs. synced record counts per collection, for reconciliation.
class SyncCount {
  const SyncCount(this.collection, this.total, this.synced);

  final String collection;
  final int total;
  final int synced;
}

/// Two-way sync between the local database and the server.
///
/// Push: every `pending` row is written under its own ID (retries can't
/// duplicate) guarded by the last server revision this device saw. A
/// revision mismatch is a conflict, handled per [ConflictPolicy]. Pull:
/// changes since a stored cursor, page by page; rows with unsynced local
/// edits are left alone (their push decides).
class SyncEngine {
  SyncEngine(
    this._db,
    this._remote, {
    DateTime Function()? clock,
    this.pageSize = 200,
  }) : _clock = clock ?? DateTime.now,
       _specs = syncSpecs(_db);

  final AppDatabase _db;
  final RemoteStore _remote;
  final DateTime Function() _clock;
  final List<SyncSpec<DataClass>> _specs;
  final int pageSize;

  static const _uuid = Uuid();

  int _now() => _clock().toUtc().millisecondsSinceEpoch;

  /// Stable per-installation ID (also used for device registration).
  Future<String> deviceId() => _db.installationId();

  SyncSpec<DataClass> _spec(String collection) =>
      _specs.firstWhere((s) => s.collection == collection);

  Iterable<SyncSpec<DataClass>> _visible(bool canViewBilling) =>
      _specs.where((s) => canViewBilling || !s.billingOnly);

  /// One full sync pass. Throws [SyncUnavailable] when the server can't be
  /// reached; everything done before that point is kept.
  Future<SyncReport> run({
    required String companyId,
    required String userId,
    required bool canViewBilling,
    bool push = true,
  }) async {
    final report = SyncReport();
    final device = await deviceId();
    // Without a valid license only downloads run; uploads would be refused.
    if (push) {
      for (final spec in _visible(canViewBilling)) {
        await _pushAll(spec, companyId, userId, device, report);
      }
    }
    for (final spec in _visible(canViewBilling)) {
      await _pullAll(spec, companyId, report);
    }
    await _db.writeSetting('last_sync_at:$companyId', '${_now()}');
    return report;
  }

  Future<int?> lastSyncAt(String companyId) async =>
      int.tryParse(await _db.readSetting('last_sync_at:$companyId') ?? '');

  // --- Push -------------------------------------------------------------------

  Future<void> _pushAll(
    SyncSpec<DataClass> spec,
    String companyId,
    String userId,
    String device,
    SyncReport report,
  ) async {
    final rows =
        await (_db.select(spec.table)..where(
              (_) =>
                  spec.col('company_id').equals(companyId) &
                  spec.col('sync_status').equals('pending'),
            ))
            .get();
    for (final row in rows) {
      final json = row.toJson();
      final id = json['id'] as String;
      final rec = await _record(spec.collection, id);
      if (rec?.nextAttemptAt != null && rec!.nextAttemptAt! > _now()) continue;
      final payload = await _toRemote(spec, json);
      final result = await _remote.push(
        companyId: companyId,
        collection: spec.collection,
        id: id,
        data: payload,
        baseRev: rec?.serverRev,
        userId: userId,
        deviceId: device,
      );
      await _handle(
        spec,
        companyId,
        json,
        payload,
        result,
        userId,
        device,
        report,
      );
    }
  }

  Future<void> _handle(
    SyncSpec<DataClass> spec,
    String companyId,
    Map<String, dynamic> local,
    Map<String, dynamic> payload,
    PushResult result,
    String userId,
    String device,
    SyncReport report,
  ) async {
    final id = local['id'] as String;
    switch (result) {
      case PushAccepted(:final rev):
        await _markSynced(spec, companyId, local, rev);
        report.pushed++;
      case PushConflict(:final serverRev, :final serverData):
        if (sameContent(payload, serverData) ||
            spec.policy == ConflictPolicy.appendOnly) {
          // Our earlier write landed but the reply was lost, or a duplicate.
          await _markSynced(spec, companyId, local, serverRev);
          report.pushed++;
          return;
        }
        if (spec.policy == ConflictPolicy.lastWriteWins) {
          final localNewer =
              (local['updatedAt'] as int? ?? 0) >=
              (serverData['updatedAt'] as num? ?? 0).toInt();
          if (localNewer) {
            final forced = await _remote.push(
              companyId: companyId,
              collection: spec.collection,
              id: id,
              data: payload,
              baseRev: serverRev,
              userId: userId,
              deviceId: device,
            );
            if (forced is PushAccepted) {
              await _markSynced(spec, companyId, local, forced.rev);
            } else {
              await _handle(
                spec,
                companyId,
                local,
                payload,
                forced,
                userId,
                device,
                report,
              );
              return;
            }
          } else {
            await _applyRemote(
              spec,
              companyId,
              RemoteDoc(
                id: id,
                rev: serverRev,
                data: serverData,
                cursor: const SyncCursor(0, ''),
              ),
            );
          }
          await _logOverwrite(
            spec,
            companyId,
            userId,
            id,
            keptLocal: localNewer,
            lost: localNewer ? serverData : payload,
          );
          report.autoResolved++;
          return;
        }
        await _upsertRecord(
          spec.collection,
          id,
          companyId,
          conflictJson: Value(jsonEncode(serverData)),
          conflictRev: Value(serverRev),
        );
        await _setStatus(spec, id, 'conflict');
        report.conflicts++;
      case PushRejected(:final message):
        final rec = await _record(spec.collection, id);
        await _upsertRecord(
          spec.collection,
          id,
          companyId,
          lastError: Value(message),
          attempts: Value((rec?.attempts ?? 0) + 1),
        );
        await _setStatus(spec, id, 'error');
        report.errors++;
    }
  }

  /// Whether a pushed record and the server's copy hold the same business
  /// data, ignoring edit bookkeeping (`version`, `updatedAt`, `updatedBy`).
  ///
  /// Structural: map key order doesn't matter (a missing key equals null),
  /// lists compare in order, and numbers by value (`5 == 5.0`), since JSON
  /// round-trips don't preserve key order or int/double.
  @visibleForTesting
  static bool sameContent(Map<String, dynamic> a, Map<String, dynamic> b) {
    final keys = {...a.keys, ...b.keys}
      ..removeAll({'version', 'updatedAt', 'updatedBy'});
    return keys.every((k) => _deepEquals(a[k], b[k]));
  }

  static bool _deepEquals(Object? a, Object? b) => switch ((a, b)) {
    // num == compares by value across int and double.
    (final num x, final num y) => x == y,
    (final Map<Object?, Object?> x, final Map<Object?, Object?> y) => {
      ...x.keys,
      ...y.keys,
    }.every((k) => _deepEquals(x[k], y[k])),
    (final List<Object?> x, final List<Object?> y) =>
      x.length == y.length &&
          Iterable<int>.generate(x.length)
              .every((i) => _deepEquals(x[i], y[i])),
    _ => a == b,
  };

  Future<Map<String, dynamic>> _toRemote(
    SyncSpec<DataClass> spec,
    Map<String, dynamic> json,
  ) async {
    final out = Map<String, dynamic>.of(json)
      ..remove('syncStatus')
      ..removeWhere((k, _) => spec.localOnly.contains(k));
    if (spec.collection == 'invoices') {
      final lines =
          await (_db.select(_db.invoiceLines)
                ..where((t) => t.invoiceId.equals(json['id'] as String))
                ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
              .get();
      out['lines'] = [for (final l in lines) l.toJson()];
    }
    return out;
  }

  /// Marks the row synced unless it was edited again while being pushed.
  Future<void> _markSynced(
    SyncSpec<DataClass> spec,
    String companyId,
    Map<String, dynamic> pushed,
    int rev,
  ) async {
    final id = pushed['id'] as String;
    final table = spec.table.actualTableName;
    if (spec.hasVersion) {
      await _db.customUpdate(
        "UPDATE $table SET sync_status = 'synced' WHERE id = ? AND version = ? AND sync_status IN ('pending', 'conflict', 'error')",
        variables: [Variable(id), Variable(pushed['version'] as int)],
        updates: {spec.table},
      );
    } else {
      await _setStatus(spec, id, 'synced');
    }
    await _upsertRecord(
      spec.collection,
      id,
      companyId,
      serverRev: Value(rev),
      attempts: const Value(0),
      lastError: const Value(null),
      conflictJson: const Value(null),
      conflictRev: const Value(null),
      nextAttemptAt: const Value(null),
    );
  }

  Future<void> _setStatus(SyncSpec<DataClass> spec, String id, String status) =>
      _db.customUpdate(
        'UPDATE ${spec.table.actualTableName} SET sync_status = ? WHERE id = ?',
        variables: [Variable(status), Variable(id)],
        updates: {spec.table},
      );

  Future<void> _logOverwrite(
    SyncSpec<DataClass> spec,
    String companyId,
    String userId,
    String id, {
    required bool keptLocal,
    required Map<String, dynamic> lost,
  }) => _db
      .into(_db.auditLogs)
      .insert(
        AuditLogsCompanion.insert(
          id: _uuid.v4(),
          companyId: Value(companyId),
          actorId: userId,
          action: 'sync_overwrite',
          entityType: spec.collection,
          entityId: id,
          details: Value(
            jsonEncode({
              'kept': keptLocal ? 'this device' : 'server',
              'overwritten': lost,
            }),
          ),
          createdAt: _now(),
        ),
      );

  // --- Pull -------------------------------------------------------------------

  /// `v2`: cursors are now the REST server's per-company sequence numbers.
  /// Cursors saved against Firestore held microsecond timestamps and would
  /// hide every change, so they are not reused.
  String _cursorKey(String companyId, String collection) =>
      'sync_cursor_v2:$companyId:$collection';

  Future<void> _pullAll(
    SyncSpec<DataClass> spec,
    String companyId,
    SyncReport report,
  ) async {
    var cursor = SyncCursor.decode(
      await _db.readSetting(_cursorKey(companyId, spec.collection)),
    );
    while (true) {
      final docs = await _remote.pull(
        companyId: companyId,
        collection: spec.collection,
        after: cursor,
        limit: pageSize,
      );
      for (final doc in docs) {
        final local = await _row(spec, doc.id);
        final status = local?.toJson()['syncStatus'];
        if (local == null || status == 'synced') {
          await _applyRemote(spec, companyId, doc);
          report.pulled++;
        }
        // Rows with local edits are reconciled by their own push.
      }
      if (docs.isEmpty) break;
      cursor = docs.last.cursor;
      await _db.writeSetting(
        _cursorKey(companyId, spec.collection),
        cursor.encode(),
      );
      if (docs.length < pageSize) break;
    }
  }

  Future<DataClass?> _row(SyncSpec<DataClass> spec, String id) => (_db.select(
    spec.table,
  )..where((_) => spec.col('id').equals(id))).getSingleOrNull();

  Future<void> _applyRemote(
    SyncSpec<DataClass> spec,
    String companyId,
    RemoteDoc doc,
  ) async {
    final existing = (await _row(spec, doc.id))?.toJson();
    final json = Map<String, dynamic>.of(doc.data);
    final lines = json.remove('lines');
    for (final k in spec.localOnly) {
      json[k] = existing?[k];
    }
    json['syncStatus'] = 'synced';
    final row = spec.fromJson(json);
    await _db.transaction(() async {
      await _db
          .into(spec.table)
          .insertOnConflictUpdate(row as Insertable<DataClass>);
      if (spec.collection == 'invoices' && lines is List) {
        await (_db.delete(
          _db.invoiceLines,
        )..where((t) => t.invoiceId.equals(doc.id))).go();
        for (final l in lines) {
          await _db
              .into(_db.invoiceLines)
              .insert(
                InvoiceLine.fromJson(Map<String, dynamic>.from(l as Map)),
              );
        }
      }
      await _upsertRecord(
        spec.collection,
        doc.id,
        companyId,
        serverRev: Value(doc.rev),
        attempts: const Value(0),
        lastError: const Value(null),
        conflictJson: const Value(null),
        conflictRev: const Value(null),
      );
    });
  }

  // --- Issues and resolution --------------------------------------------------

  Future<SyncRecord?> _record(String entity, String id) =>
      (_db.select(_db.syncRecords)
            ..where((t) => t.entity.equals(entity) & t.entityId.equals(id)))
          .getSingleOrNull();

  Future<void> _upsertRecord(
    String entity,
    String id,
    String companyId, {
    Value<int?> serverRev = const Value.absent(),
    Value<int> attempts = const Value.absent(),
    Value<int?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<String?> conflictJson = const Value.absent(),
    Value<int?> conflictRev = const Value.absent(),
  }) async {
    final changes = SyncRecordsCompanion(
      serverRev: serverRev,
      attempts: attempts,
      nextAttemptAt: nextAttemptAt,
      lastError: lastError,
      conflictJson: conflictJson,
      conflictRev: conflictRev,
    );
    final updated =
        await (_db.update(_db.syncRecords)
              ..where((t) => t.entity.equals(entity) & t.entityId.equals(id)))
            .write(changes);
    if (updated == 0) {
      await _db
          .into(_db.syncRecords)
          .insert(
            changes.copyWith(
              entity: Value(entity),
              entityId: Value(id),
              companyId: Value(companyId),
            ),
          );
    }
  }

  /// Rows not yet on the server.
  Stream<int> watchPendingCount(String companyId) {
    final union = _specs
        .map(
          (s) =>
              "SELECT COUNT(*) AS c FROM ${s.table.actualTableName} WHERE company_id = ? AND sync_status = 'pending'",
        )
        .join(' UNION ALL ');
    return _db
        .customSelect(
          'SELECT COALESCE(SUM(c), 0) AS total FROM ($union)',
          variables: [for (final _ in _specs) Variable(companyId)],
          readsFrom: {for (final s in _specs) s.table},
        )
        .watchSingle()
        .map((r) => r.read<int>('total'));
  }

  /// Conflicts and refused records, for the Sync screen.
  Stream<List<SyncIssue>> watchIssues(String companyId) {
    final union = _specs
        .map(
          (s) =>
              "SELECT '${s.collection}' AS collection, id FROM ${s.table.actualTableName} WHERE company_id = ? AND sync_status IN ('conflict', 'error')",
        )
        .join(' UNION ALL ');
    return _db
        .customSelect(
          union,
          variables: [for (final _ in _specs) Variable(companyId)],
          readsFrom: {for (final s in _specs) s.table, _db.syncRecords},
        )
        .watch()
        .asyncMap(
          (rows) async => [
            for (final r in rows)
              await _issue(r.read<String>('collection'), r.read<String>('id')),
          ],
        );
  }

  Future<SyncIssue> _issue(String collection, String id) async {
    final spec = _spec(collection);
    final local = (await _row(spec, id))!.toJson();
    final rec = await _record(collection, id);
    final server = rec?.conflictJson == null
        ? null
        : jsonDecode(rec!.conflictJson!) as Map<String, dynamic>;
    return SyncIssue(
      collection: collection,
      id: id,
      label: spec.label(local),
      isConflict: local['syncStatus'] == 'conflict',
      message: rec?.lastError,
      serverLabel: server == null ? null : spec.label(server),
    );
  }

  /// Per-collection counts of local and synced records.
  Future<List<SyncCount>> counts(String companyId) async => [
    for (final s in _specs)
      SyncCount(
        s.collection,
        (await _db
                .customSelect(
                  'SELECT COUNT(*) AS c FROM ${s.table.actualTableName} WHERE company_id = ?',
                  variables: [Variable(companyId)],
                )
                .getSingle())
            .read<int>('c'),
        (await _db
                .customSelect(
                  "SELECT COUNT(*) AS c FROM ${s.table.actualTableName} WHERE company_id = ? AND sync_status = 'synced'",
                  variables: [Variable(companyId)],
                )
                .getSingle())
            .read<int>('c'),
      ),
  ];

  /// Conflict: overwrite the server with this device's version on next push.
  Future<void> keepLocal(String collection, String id) async {
    final spec = _spec(collection);
    final rec = await _record(collection, id);
    if (rec?.conflictRev == null) return;
    await _upsertRecord(
      collection,
      id,
      rec!.companyId,
      serverRev: Value(rec.conflictRev),
      conflictJson: const Value(null),
      conflictRev: const Value(null),
    );
    await _setStatus(spec, id, 'pending');
  }

  /// Conflict: replace this device's version with the server's.
  Future<void> useServer(String collection, String id) async {
    final spec = _spec(collection);
    final rec = await _record(collection, id);
    if (rec?.conflictJson == null) return;
    await _applyRemote(
      spec,
      rec!.companyId,
      RemoteDoc(
        id: id,
        rev: rec.conflictRev!,
        data: jsonDecode(rec.conflictJson!) as Map<String, dynamic>,
        cursor: const SyncCursor(0, ''),
      ),
    );
  }

  /// Refused record: try again (e.g. after permissions were fixed).
  Future<void> retry(String collection, String id) async {
    final rec = await _record(collection, id);
    if (rec == null) return;
    await _upsertRecord(
      collection,
      id,
      rec.companyId,
      lastError: const Value(null),
      attempts: const Value(0),
      nextAttemptAt: const Value(null),
    );
    await _setStatus(_spec(collection), id, 'pending');
  }
}
