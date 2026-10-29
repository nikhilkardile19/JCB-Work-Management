import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../evidence/photo_evidence.dart';
import '../../work/data/work_log_repository.dart';
import '../../work/domain/work_log.dart';
import '../domain/fuel_entry.dart';

/// Save refused; keys match [FuelRules.errors] plus `status` for permission.
class FuelException implements Exception {
  const FuelException(this.fieldErrors);

  final Map<String, String> fieldErrors;

  @override
  String toString() => fieldErrors.values.join('; ');
}

/// Offline-first fuel entries. Every write marks the row `pending` sync,
/// bumps its version and appends an audit entry.
class FuelRepository {
  FuelRepository(
    this._db, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final DateTime Function() _clock;
  final String Function() _newId;

  static const _entity = 'fuelEntries';

  $FuelEntriesTable get _fuel => _db.fuelEntries;

  int _now() => _clock().toUtc().millisecondsSinceEpoch;

  Expression<bool> _live(String companyId) =>
      _fuel.companyId.equals(companyId) & _fuel.deletedAt.isNull();

  JoinedSelectStatement<HasResultSet, dynamic> _joined(String companyId) =>
      _db.select(_fuel).join([
        innerJoin(_db.machines, _db.machines.id.equalsExp(_fuel.machineId)),
        innerJoin(_db.petrolPumps, _db.petrolPumps.id.equalsExp(_fuel.pumpId)),
        leftOuterJoin(_db.clients, _db.clients.id.equalsExp(_fuel.clientId)),
        leftOuterJoin(_db.sites, _db.sites.id.equalsExp(_fuel.siteId)),
      ])..where(_live(companyId));

  FuelView _view(TypedResult row) {
    final f = row.readTable(_fuel);
    return FuelView(
      id: f.id,
      filledAt: DateTime.fromMillisecondsSinceEpoch(f.filledAt),
      fuelDate: f.fuelDate,
      machineId: f.machineId,
      machineName: row.readTable(_db.machines).name,
      pumpId: f.pumpId,
      pumpName: row.readTable(_db.petrolPumps).name,
      clientId: f.clientId,
      clientName: row.readTableOrNull(_db.clients)?.name,
      siteId: f.siteId,
      siteName: row.readTableOrNull(_db.sites)?.name,
      litresCl: f.litresCl,
      pricePerLitrePaise: f.pricePerLitrePaise,
      totalPaise: f.totalPaise,
      receipt: f.receiptPhotoPath == null
          ? null
          : PhotoEvidence(
              photoPath: f.receiptPhotoPath!,
              capturedAt: f.receiptCapturedAt ?? f.createdAt,
              locationStatus:
                  LocationStatus.parse(f.receiptLocationStatus) ??
                  LocationStatus.unavailable,
              lat: f.receiptLat,
              lng: f.receiptLng,
              accuracy: f.receiptAccuracy,
            ),
      notes: f.notes,
      createdBy: f.createdBy,
      syncStatus: f.syncStatus,
    );
  }

  /// Entries with `fuelDate` in [from]..[to] (inclusive), newest first.
  Stream<List<FuelView>> watchList(
    String companyId, {
    String? from,
    String? to,
  }) {
    final q = _joined(companyId);
    if (from != null) q.where(_fuel.fuelDate.isBiggerOrEqualValue(from));
    if (to != null) q.where(_fuel.fuelDate.isSmallerOrEqualValue(to));
    q.orderBy([OrderingTerm.desc(_fuel.filledAt)]);
    return q.watch().map((rows) => rows.map(_view).toList());
  }

  Stream<FuelView?> watchOne(String companyId, String id) {
    final q = _joined(companyId)..where(_fuel.id.equals(id));
    return q.watchSingleOrNull().map((r) => r == null ? null : _view(r));
  }

  /// Totals for the period, with a per-machine breakdown (largest spend
  /// first).
  Stream<FuelSummary> watchSummary(
    String companyId, {
    required String from,
    required String to,
  }) {
    final litres = _fuel.litresCl.sum();
    final total = _fuel.totalPaise.sum();
    final count = _fuel.id.count();
    final q =
        _db.selectOnly(_fuel).join([
            innerJoin(_db.machines, _db.machines.id.equalsExp(_fuel.machineId)),
          ])
          ..addColumns([
            _fuel.machineId,
            _db.machines.name,
            litres,
            total,
            count,
          ])
          ..where(_live(companyId) & _fuel.fuelDate.isBetweenValues(from, to))
          ..groupBy([_fuel.machineId, _db.machines.name])
          ..orderBy([OrderingTerm.desc(total)]);
    return q.watch().map((rows) {
      final byMachine = [
        for (final r in rows)
          MachineFuel(
            machineId: r.read(_fuel.machineId)!,
            machineName: r.read(_db.machines.name)!,
            litresCl: r.read(litres) ?? 0,
            totalPaise: r.read(total) ?? 0,
          ),
      ];
      return FuelSummary(
        totalPaise: byMachine.fold(0, (a, m) => a + m.totalPaise),
        litresCl: byMachine.fold(0, (a, m) => a + m.litresCl),
        count: rows.fold(0, (a, r) => a + (r.read(count) ?? 0)),
        byMachine: byMachine,
      );
    });
  }

  /// Price paid at this pump most recently, to prefill the form.
  Future<int?> lastPrice(String companyId, String pumpId) async {
    final row =
        await (_db.select(_fuel)
              ..where(
                (t) =>
                    t.companyId.equals(companyId) &
                    t.pumpId.equals(pumpId) &
                    t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.filledAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.pricePerLitrePaise;
  }

  Future<String> save(WorkActor actor, FuelInput input, {String? id}) =>
      _db.transaction(() async {
        final current = id == null ? null : await _require(actor, id);
        final allowed = current == null
            ? FuelPolicy.canRecord(actor.role)
            : FuelPolicy.canEdit(actor.role, current, actor.userId);
        if (!allowed) {
          throw const FuelException({
            'status': "You don't have permission to change this fuel entry.",
          });
        }
        await _validate(actor.companyId, input);

        final now = _now();
        final entryId = id ?? _newId();
        String? clean(String? s) =>
            s == null || s.trim().isEmpty ? null : s.trim();
        final r = input.receipt;
        final values = FuelEntriesCompanion(
          filledAt: Value(input.filledAt.toUtc().millisecondsSinceEpoch),
          fuelDate: Value(WorkLogRules.dateKey(input.filledAt.toLocal())),
          machineId: Value(input.machineId!),
          pumpId: Value(input.pumpId!),
          clientId: Value(input.clientId),
          siteId: Value(input.siteId),
          litresCl: Value(input.litresCl!),
          pricePerLitrePaise: Value(input.pricePerLitrePaise!),
          totalPaise: Value(input.totalPaise!),
          receiptPhotoPath: Value(r?.photoPath),
          receiptCapturedAt: Value(r?.capturedAt),
          receiptLat: Value(r?.lat),
          receiptLng: Value(r?.lng),
          receiptAccuracy: Value(r?.accuracy),
          receiptLocationStatus: Value(r?.locationStatus.name),
          notes: Value(clean(input.notes)),
          updatedAt: Value(now),
          updatedBy: Value(actor.userId),
          syncStatus: const Value('pending'),
        );
        final summary = {
          'litresCl': input.litresCl,
          'pricePerLitrePaise': input.pricePerLitrePaise,
          'totalPaise': input.totalPaise,
        };
        if (current == null) {
          await _db
              .into(_fuel)
              .insert(
                values.copyWith(
                  id: Value(entryId),
                  companyId: Value(actor.companyId),
                  createdAt: Value(now),
                  createdBy: Value(actor.userId),
                  version: const Value(1),
                ),
              );
          await _audit(actor, entryId, 'create', summary);
        } else {
          await (_db.update(_fuel)..where((t) => t.id.equals(entryId))).write(
            values.copyWith(version: Value(await _version(entryId) + 1)),
          );
          await _audit(actor, entryId, 'update', {
            for (final (k, before, after) in [
              ('litresCl', current.litresCl, input.litresCl),
              (
                'pricePerLitrePaise',
                current.pricePerLitrePaise,
                input.pricePerLitrePaise,
              ),
              ('totalPaise', current.totalPaise, input.totalPaise),
              ('machineId', current.machineId, input.machineId),
              ('pumpId', current.pumpId, input.pumpId),
              (
                'fuelDate',
                current.fuelDate,
                WorkLogRules.dateKey(input.filledAt.toLocal()),
              ),
              ('receiptPhotoPath', current.receipt?.photoPath, r?.photoPath),
            ])
              if (before != after) k: {'from': before, 'to': after},
          });
        }
        return entryId;
      });

  /// Removes the entry (tombstone for sync). Receipt files are kept.
  Future<void> delete(WorkActor actor, String id) => _db.transaction(() async {
    final current = await _require(actor, id);
    if (!FuelPolicy.canEdit(actor.role, current, actor.userId)) {
      throw const FuelException({
        'status': "You don't have permission to delete this fuel entry.",
      });
    }
    final now = _now();
    await (_db.update(_fuel)..where((t) => t.id.equals(id))).write(
      FuelEntriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        updatedBy: Value(actor.userId),
        syncStatus: const Value('pending'),
        version: Value(await _version(id) + 1),
      ),
    );
    await _audit(actor, id, 'delete', {
      'litresCl': current.litresCl,
      'totalPaise': current.totalPaise,
    });
  });

  Future<FuelView> _require(WorkActor actor, String id) async {
    final v = await watchOne(actor.companyId, id).first;
    if (v == null) throw StateError('Fuel entry $id not found');
    return v;
  }

  Future<int> _version(String id) async => (await (_db.select(
    _fuel,
  )..where((t) => t.id.equals(id))).getSingle()).version;

  Future<void> _validate(String companyId, FuelInput input) async {
    final errors = FuelRules.errors(input);
    Future<bool> exists(
      TableInfo<MasterColumns, DataClass> t,
      String id,
    ) async {
      final dsl = t.asDslTable;
      final q = _db.selectOnly(t)
        ..addColumns([dsl.id])
        ..where(
          dsl.id.equals(id) &
              dsl.companyId.equals(companyId) &
              dsl.deletedAt.isNull(),
        );
      return (await q.get()).isNotEmpty;
    }

    if (input.machineId != null &&
        !await exists(_db.machines, input.machineId!)) {
      errors['machineId'] = 'Select a machine from your list';
    }
    if (input.pumpId != null && !await exists(_db.petrolPumps, input.pumpId!)) {
      errors['pumpId'] = 'Select a petrol pump from your list';
    }
    if (input.clientId != null && !await exists(_db.clients, input.clientId!)) {
      errors['clientId'] = 'Select a client from your list';
    }
    if (input.siteId != null) {
      final site =
          await (_db.select(_db.sites)..where(
                (t) =>
                    t.id.equals(input.siteId!) &
                    t.companyId.equals(companyId) &
                    t.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (site == null || site.clientId != input.clientId) {
        errors['siteId'] = 'Select a site of this client';
      }
    }
    if (errors.isNotEmpty) throw FuelException(errors);
  }

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
