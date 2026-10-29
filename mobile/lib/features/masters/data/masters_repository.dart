import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../domain/master_kind.dart';

/// Who is acting, in which company. Every query is scoped to [companyId].
class MasterScope {
  const MasterScope({required this.companyId, required this.userId});

  final String companyId;
  final String userId;
}

enum StatusFilter { active, inactive, all }

/// Save rejected; [fieldErrors] maps field keys to messages.
class MasterSaveException implements Exception {
  const MasterSaveException(this.fieldErrors);

  final Map<String, String> fieldErrors;

  @override
  String toString() => fieldErrors.values.join('; ');
}

/// Delete refused because other records still reference this one.
class MasterInUseException implements Exception {
  const MasterInUseException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef _MasterTable = TableInfo<MasterColumns, DataClass>;

/// Offline-first storage for all master data. Writes mark records
/// `pending` sync, bump [MasterColumns.version] and append an audit entry.
class MastersRepository {
  MastersRepository(
    this._db, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final DateTime Function() _clock;
  final String Function() _newId;

  _MasterTable _table(MasterKind kind) => switch (kind) {
    MasterKind.clients => _db.clients,
    MasterKind.sites => _db.sites,
    MasterKind.machines => _db.machines,
    MasterKind.operators => _db.operators,
    MasterKind.petrolPumps => _db.petrolPumps,
  };

  /// Raw column values typed with the concrete row class, as Drift checks
  /// the insertable's runtime type.
  static Insertable<DataClass> _raw(
    MasterKind kind,
    Map<String, Expression<Object>> values,
  ) => switch (kind) {
    MasterKind.clients => RawValuesInsertable<Client>(values),
    MasterKind.sites => RawValuesInsertable<Site>(values),
    MasterKind.machines => RawValuesInsertable<Machine>(values),
    MasterKind.operators => RawValuesInsertable<Operator>(values),
    MasterKind.petrolPumps => RawValuesInsertable<PetrolPump>(values),
  };

  static String _sqlName(String key) =>
      key.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  static GeneratedColumn<T> _col<T extends Object>(
    _MasterTable table,
    String key,
  ) => table.columnsByName[_sqlName(key)]! as GeneratedColumn<T>;

  static String _likePattern(String q) =>
      '%${q.toLowerCase().replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';

  int _now() => _clock().toUtc().millisecondsSinceEpoch;

  Stream<List<MasterRecord>> watchList(
    MasterKind kind,
    String companyId, {
    String search = '',
    StatusFilter status = StatusFilter.active,
    String? clientId,
  }) {
    final table = _table(kind);
    final q = _db.select(table)
      ..where((t) => t.companyId.equals(companyId) & t.deletedAt.isNull());
    if (status != StatusFilter.all) {
      q.where((t) => t.isActive.equals(status == StatusFilter.active));
    }
    if (clientId != null) {
      q.where((_) => _col<String>(table, 'clientId').equals(clientId));
    }
    final term = search.trim();
    if (term.isNotEmpty) {
      final pattern = _likePattern(term);
      q.where(
        (_) => kind.searchKeys
            .map(
              (k) => _col<String>(
                table,
                k,
              ).lower().like(pattern, escapeChar: r'\'),
            )
            .reduce((a, b) => a | b),
      );
    }
    q.orderBy([(t) => OrderingTerm.asc(t.name.lower())]);
    return q.watch().map(
      (rows) => [for (final r in rows) MasterRecord(kind, r.toJson())],
    );
  }

  Stream<MasterRecord?> watchOne(MasterKind kind, String companyId, String id) {
    final q = _db.select(_table(kind))
      ..where(
        (t) =>
            t.id.equals(id) &
            t.companyId.equals(companyId) &
            t.deletedAt.isNull(),
      );
    return q.watchSingleOrNull().map(
      (r) => r == null ? null : MasterRecord(kind, r.toJson()),
    );
  }

  Stream<int> watchActiveCount(MasterKind kind, String companyId) {
    final table = _table(kind);
    final t = table.asDslTable;
    final count = t.id.count();
    final q = _db.selectOnly(table)
      ..addColumns([count])
      ..where(
        t.companyId.equals(companyId) &
            t.deletedAt.isNull() &
            t.isActive.equals(true),
      );
    return q.watchSingle().map((r) => r.read(count) ?? 0);
  }

  /// Creates (when [id] is null) or updates a record. [values] holds parsed
  /// field values keyed by [FieldSpec.key]. Returns the record ID.
  Future<String> save(
    MasterKind kind,
    MasterScope scope,
    Map<String, Object?> values, {
    String? id,
  }) async {
    final clean = {
      for (final f in kind.fields)
        f.key: switch (values[f.key]) {
          final String s when s.trim().isEmpty => null,
          final String s => s.trim(),
          final v => v,
        },
    };
    final errors = await _validate(kind, scope.companyId, clean, excludeId: id);
    if (errors.isNotEmpty) throw MasterSaveException(errors);

    final table = _table(kind);
    final now = _now();
    final fieldVars = {
      for (final f in kind.fields)
        _sqlName(f.key): f.isInt
            ? Variable<int>(clean[f.key] as int?)
            : Variable<String>(clean[f.key] as String?),
    };

    return _db.transaction(() async {
      if (id == null) {
        final newId = _newId();
        await _db
            .into(table)
            .insert(
              _raw(kind, {
                'id': Variable<String>(newId),
                'company_id': Variable<String>(scope.companyId),
                'is_active': const Variable<bool>(true),
                'created_at': Variable<int>(now),
                'updated_at': Variable<int>(now),
                'created_by': Variable<String>(scope.userId),
                'updated_by': Variable<String>(scope.userId),
                'sync_status': const Variable<String>('pending'),
                'version': const Variable<int>(1),
                ...fieldVars,
              }),
            );
        await _audit(kind, scope, newId, 'create', clean);
        return newId;
      }
      final current = await _current(kind, scope.companyId, id);
      await _write(kind, scope, id, {
        ...fieldVars,
        'version': Variable<int>(current.version + 1),
      });
      await _audit(kind, scope, id, 'update', {
        for (final e in clean.entries)
          if (current[e.key] != e.value)
            e.key: {'from': current[e.key], 'to': e.value},
      });
      return id;
    });
  }

  Future<void> setActive(
    MasterKind kind,
    MasterScope scope,
    String id, {
    required bool active,
  }) => _db.transaction(() async {
    final current = await _current(kind, scope.companyId, id);
    if (current.isActive == active) return;
    await _write(kind, scope, id, {
      'is_active': Variable<bool>(active),
      'version': Variable<int>(current.version + 1),
    });
    await _audit(kind, scope, id, active ? 'activate' : 'deactivate', null);
  });

  /// How many live records point at this one. Extended as transactional
  /// modules (work logs, fuel, invoices) are added.
  Future<int> referenceCount(
    MasterKind kind,
    String companyId,
    String id,
  ) async {
    Future<int> countWhere(
      TableInfo<Table, Object?> table,
      Expression<bool> where,
    ) async {
      final count = countAll();
      final q = _db.selectOnly(table)
        ..addColumns([count])
        ..where(where);
      return (await q.getSingle()).read(count) ?? 0;
    }

    final logs = _db.workLogs;
    Future<int> logsWhere(GeneratedColumn<String> column) => countWhere(
      logs,
      logs.companyId.equals(companyId) &
          column.equals(id) &
          logs.deletedAt.isNull(),
    );
    final fuel = _db.fuelEntries;
    Future<int> fuelWhere(GeneratedColumn<String> column) => countWhere(
      fuel,
      fuel.companyId.equals(companyId) &
          column.equals(id) &
          fuel.deletedAt.isNull(),
    );

    return switch (kind) {
      MasterKind.clients =>
        await countWhere(
              _db.sites,
              _db.sites.companyId.equals(companyId) &
                  _db.sites.clientId.equals(id) &
                  _db.sites.deletedAt.isNull(),
            ) +
            await logsWhere(logs.clientId) +
            await fuelWhere(fuel.clientId),
      MasterKind.sites =>
        await logsWhere(logs.siteId) + await fuelWhere(fuel.siteId),
      MasterKind.machines =>
        await logsWhere(logs.machineId) + await fuelWhere(fuel.machineId),
      MasterKind.operators => await logsWhere(logs.operatorId),
      MasterKind.petrolPumps => await fuelWhere(fuel.pumpId),
    };
  }

  /// Deletes an unreferenced record (tombstone). Referenced records must be
  /// deactivated instead.
  Future<void> delete(MasterKind kind, MasterScope scope, String id) =>
      _db.transaction(() async {
        final current = await _current(kind, scope.companyId, id);
        final refs = await referenceCount(kind, scope.companyId, id);
        if (refs > 0) {
          throw MasterInUseException(
            '${current.name} is used by $refs '
            '${refs == 1 ? 'record' : 'records'}. Deactivate it instead.',
          );
        }
        await _write(kind, scope, id, {
          'deleted_at': Variable<int>(_now()),
          'is_active': const Variable<bool>(false),
          'version': Variable<int>(current.version + 1),
        });
        await _audit(kind, scope, id, 'delete', {'name': current.name});
      });

  Future<MasterRecord> _current(
    MasterKind kind,
    String companyId,
    String id,
  ) async {
    final r = await watchOne(kind, companyId, id).first;
    if (r == null) throw StateError('${kind.singular} $id not found');
    return r;
  }

  Future<void> _write(
    MasterKind kind,
    MasterScope scope,
    String id,
    Map<String, Variable<Object>> changes,
  ) async {
    final table = _table(kind);
    await (_db.update(table)
          ..where((t) => t.id.equals(id) & t.companyId.equals(scope.companyId)))
        .write(
          _raw(kind, {
            ...changes,
            'updated_at': Variable<int>(_now()),
            'updated_by': Variable<String>(scope.userId),
            'sync_status': const Variable<String>('pending'),
          }),
        );
  }

  Future<Map<String, String>> _validate(
    MasterKind kind,
    String companyId,
    Map<String, Object?> v, {
    String? excludeId,
  }) async {
    final errors = <String, String>{};
    for (final f in kind.fields.where((f) => f.required)) {
      if (v[f.key] == null) errors[f.key] = '${f.label} is required';
    }
    if (errors.isNotEmpty) return errors;

    final table = _table(kind);
    Future<bool> exists(String key, Object value, {String? clientId}) async {
      final q = _db.select(table)
        ..where(
          (t) =>
              t.companyId.equals(companyId) &
              t.deletedAt.isNull() &
              (value is String
                  ? _col<String>(table, key).lower().equals(value.toLowerCase())
                  : _col<Object>(table, key).equalsExp(Variable(value))),
        );
      if (excludeId != null) q.where((t) => t.id.equals(excludeId).not());
      if (clientId != null) {
        q.where((_) => _col<String>(table, 'clientId').equals(clientId));
      }
      return (await (q..limit(1)).get()).isNotEmpty;
    }

    final name = v['name']! as String;
    if (kind == MasterKind.sites) {
      final clientId = v['clientId']! as String;
      final client =
          await (_db.select(_db.clients)..where(
                (t) =>
                    t.id.equals(clientId) &
                    t.companyId.equals(companyId) &
                    t.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (client == null) {
        errors['clientId'] = 'Select a client from your list';
      } else if (await exists('name', name, clientId: clientId)) {
        errors['name'] = '${client.name} already has a site named "$name"';
      }
    } else if (await exists('name', name)) {
      errors['name'] =
          'A ${kind.singular.toLowerCase()} named "$name" already exists';
    }

    final reg = v['registrationNumber'];
    if (kind == MasterKind.machines &&
        reg is String &&
        await exists('registrationNumber', reg)) {
      errors['registrationNumber'] = 'Another machine has registration $reg';
    }
    return errors;
  }

  Future<void> _audit(
    MasterKind kind,
    MasterScope scope,
    String entityId,
    String action,
    Map<String, Object?>? details,
  ) => _db
      .into(_db.auditLogs)
      .insert(
        AuditLogsCompanion.insert(
          id: _newId(),
          companyId: Value(scope.companyId),
          actorId: scope.userId,
          action: action,
          entityType: kind.name,
          entityId: entityId,
          details: Value(details == null ? null : jsonEncode(details)),
          createdAt: _now(),
        ),
      );
}
