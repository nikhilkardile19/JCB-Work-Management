// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTable extends AuditLogs
    with TableInfo<$AuditLogsTable, AuditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    actorId,
    action,
    entityType,
    entityId,
    details,
    createdAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actorIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $AuditLogsTable createAlias(String alias) {
    return $AuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLog extends DataClass implements Insertable<AuditLog> {
  final String id;
  final String? companyId;
  final String actorId;
  final String action;
  final String entityType;
  final String entityId;

  /// JSON-encoded details (before/after values, reason).
  final String? details;

  /// UTC epoch milliseconds.
  final int createdAt;
  final String syncStatus;
  const AuditLog({
    required this.id,
    this.companyId,
    required this.actorId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    required this.createdAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    map['actor_id'] = Variable<String>(actorId);
    map['action'] = Variable<String>(action);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      id: Value(id),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      actorId: Value(actorId),
      action: Value(action),
      entityType: Value(entityType),
      entityId: Value(entityId),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory AuditLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLog(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      actorId: serializer.fromJson<String>(json['actorId']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      details: serializer.fromJson<String?>(json['details']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String?>(companyId),
      'actorId': serializer.toJson<String>(actorId),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'details': serializer.toJson<String?>(details),
      'createdAt': serializer.toJson<int>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  AuditLog copyWith({
    String? id,
    Value<String?> companyId = const Value.absent(),
    String? actorId,
    String? action,
    String? entityType,
    String? entityId,
    Value<String?> details = const Value.absent(),
    int? createdAt,
    String? syncStatus,
  }) => AuditLog(
    id: id ?? this.id,
    companyId: companyId.present ? companyId.value : this.companyId,
    actorId: actorId ?? this.actorId,
    action: action ?? this.action,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    details: details.present ? details.value : this.details,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  AuditLog copyWithCompanion(AuditLogsCompanion data) {
    return AuditLog(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      action: data.action.present ? data.action.value : this.action,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      details: data.details.present ? data.details.value : this.details,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLog(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('actorId: $actorId, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('details: $details, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    actorId,
    action,
    entityType,
    entityId,
    details,
    createdAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLog &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.actorId == this.actorId &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.details == this.details &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLog> {
  final Value<String> id;
  final Value<String?> companyId;
  final Value<String> actorId;
  final Value<String> action;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String?> details;
  final Value<int> createdAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const AuditLogsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.actorId = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.details = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    required String id,
    this.companyId = const Value.absent(),
    required String actorId,
    required String action,
    required String entityType,
    required String entityId,
    this.details = const Value.absent(),
    required int createdAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       actorId = Value(actorId),
       action = Value(action),
       entityType = Value(entityType),
       entityId = Value(entityId),
       createdAt = Value(createdAt);
  static Insertable<AuditLog> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? actorId,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? details,
    Expression<int>? createdAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (actorId != null) 'actor_id': actorId,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (details != null) 'details': details,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsCompanion copyWith({
    Value<String>? id,
    Value<String?>? companyId,
    Value<String>? actorId,
    Value<String>? action,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String?>? details,
    Value<int>? createdAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return AuditLogsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      actorId: actorId ?? this.actorId,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('actorId: $actorId, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('details: $details, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCompaniesTable extends CachedCompanies
    with TableInfo<$CachedCompaniesTable, CachedCompany> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCompaniesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUidMeta = const VerificationMeta(
    'ownerUid',
  );
  @override
  late final GeneratedColumn<String> ownerUid = GeneratedColumn<String>(
    'owner_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactPersonMeta = const VerificationMeta(
    'contactPerson',
  );
  @override
  late final GeneratedColumn<String> contactPerson = GeneratedColumn<String>(
    'contact_person',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gstinMeta = const VerificationMeta('gstin');
  @override
  late final GeneratedColumn<String> gstin = GeneratedColumn<String>(
    'gstin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoicePrefixMeta = const VerificationMeta(
    'invoicePrefix',
  );
  @override
  late final GeneratedColumn<String> invoicePrefix = GeneratedColumn<String>(
    'invoice_prefix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    companyId,
    role,
    status,
    ownerUid,
    name,
    contactPerson,
    phone,
    email,
    address,
    gstin,
    invoicePrefix,
    currency,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_companies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCompany> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('owner_uid')) {
      context.handle(
        _ownerUidMeta,
        ownerUid.isAcceptableOrUnknown(data['owner_uid']!, _ownerUidMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerUidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('contact_person')) {
      context.handle(
        _contactPersonMeta,
        contactPerson.isAcceptableOrUnknown(
          data['contact_person']!,
          _contactPersonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactPersonMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('gstin')) {
      context.handle(
        _gstinMeta,
        gstin.isAcceptableOrUnknown(data['gstin']!, _gstinMeta),
      );
    }
    if (data.containsKey('invoice_prefix')) {
      context.handle(
        _invoicePrefixMeta,
        invoicePrefix.isAcceptableOrUnknown(
          data['invoice_prefix']!,
          _invoicePrefixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoicePrefixMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, companyId};
  @override
  CachedCompany map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCompany(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      ownerUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_uid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      contactPerson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_person'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      gstin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gstin'],
      ),
      invoicePrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_prefix'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedCompaniesTable createAlias(String alias) {
    return $CachedCompaniesTable(attachedDatabase, alias);
  }
}

class CachedCompany extends DataClass implements Insertable<CachedCompany> {
  final String userId;
  final String companyId;
  final String role;
  final String status;
  final String ownerUid;
  final String name;
  final String contactPerson;
  final String phone;
  final String? email;
  final String address;
  final String? gstin;
  final String invoicePrefix;
  final String currency;

  /// UTC epoch milliseconds of the last successful server refresh.
  final int cachedAt;
  const CachedCompany({
    required this.userId,
    required this.companyId,
    required this.role,
    required this.status,
    required this.ownerUid,
    required this.name,
    required this.contactPerson,
    required this.phone,
    this.email,
    required this.address,
    this.gstin,
    required this.invoicePrefix,
    required this.currency,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['company_id'] = Variable<String>(companyId);
    map['role'] = Variable<String>(role);
    map['status'] = Variable<String>(status);
    map['owner_uid'] = Variable<String>(ownerUid);
    map['name'] = Variable<String>(name);
    map['contact_person'] = Variable<String>(contactPerson);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['address'] = Variable<String>(address);
    if (!nullToAbsent || gstin != null) {
      map['gstin'] = Variable<String>(gstin);
    }
    map['invoice_prefix'] = Variable<String>(invoicePrefix);
    map['currency'] = Variable<String>(currency);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  CachedCompaniesCompanion toCompanion(bool nullToAbsent) {
    return CachedCompaniesCompanion(
      userId: Value(userId),
      companyId: Value(companyId),
      role: Value(role),
      status: Value(status),
      ownerUid: Value(ownerUid),
      name: Value(name),
      contactPerson: Value(contactPerson),
      phone: Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: Value(address),
      gstin: gstin == null && nullToAbsent
          ? const Value.absent()
          : Value(gstin),
      invoicePrefix: Value(invoicePrefix),
      currency: Value(currency),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedCompany.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCompany(
      userId: serializer.fromJson<String>(json['userId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      role: serializer.fromJson<String>(json['role']),
      status: serializer.fromJson<String>(json['status']),
      ownerUid: serializer.fromJson<String>(json['ownerUid']),
      name: serializer.fromJson<String>(json['name']),
      contactPerson: serializer.fromJson<String>(json['contactPerson']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String>(json['address']),
      gstin: serializer.fromJson<String?>(json['gstin']),
      invoicePrefix: serializer.fromJson<String>(json['invoicePrefix']),
      currency: serializer.fromJson<String>(json['currency']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'companyId': serializer.toJson<String>(companyId),
      'role': serializer.toJson<String>(role),
      'status': serializer.toJson<String>(status),
      'ownerUid': serializer.toJson<String>(ownerUid),
      'name': serializer.toJson<String>(name),
      'contactPerson': serializer.toJson<String>(contactPerson),
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String>(address),
      'gstin': serializer.toJson<String?>(gstin),
      'invoicePrefix': serializer.toJson<String>(invoicePrefix),
      'currency': serializer.toJson<String>(currency),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  CachedCompany copyWith({
    String? userId,
    String? companyId,
    String? role,
    String? status,
    String? ownerUid,
    String? name,
    String? contactPerson,
    String? phone,
    Value<String?> email = const Value.absent(),
    String? address,
    Value<String?> gstin = const Value.absent(),
    String? invoicePrefix,
    String? currency,
    int? cachedAt,
  }) => CachedCompany(
    userId: userId ?? this.userId,
    companyId: companyId ?? this.companyId,
    role: role ?? this.role,
    status: status ?? this.status,
    ownerUid: ownerUid ?? this.ownerUid,
    name: name ?? this.name,
    contactPerson: contactPerson ?? this.contactPerson,
    phone: phone ?? this.phone,
    email: email.present ? email.value : this.email,
    address: address ?? this.address,
    gstin: gstin.present ? gstin.value : this.gstin,
    invoicePrefix: invoicePrefix ?? this.invoicePrefix,
    currency: currency ?? this.currency,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedCompany copyWithCompanion(CachedCompaniesCompanion data) {
    return CachedCompany(
      userId: data.userId.present ? data.userId.value : this.userId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      role: data.role.present ? data.role.value : this.role,
      status: data.status.present ? data.status.value : this.status,
      ownerUid: data.ownerUid.present ? data.ownerUid.value : this.ownerUid,
      name: data.name.present ? data.name.value : this.name,
      contactPerson: data.contactPerson.present
          ? data.contactPerson.value
          : this.contactPerson,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      gstin: data.gstin.present ? data.gstin.value : this.gstin,
      invoicePrefix: data.invoicePrefix.present
          ? data.invoicePrefix.value
          : this.invoicePrefix,
      currency: data.currency.present ? data.currency.value : this.currency,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCompany(')
          ..write('userId: $userId, ')
          ..write('companyId: $companyId, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('name: $name, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('gstin: $gstin, ')
          ..write('invoicePrefix: $invoicePrefix, ')
          ..write('currency: $currency, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    companyId,
    role,
    status,
    ownerUid,
    name,
    contactPerson,
    phone,
    email,
    address,
    gstin,
    invoicePrefix,
    currency,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCompany &&
          other.userId == this.userId &&
          other.companyId == this.companyId &&
          other.role == this.role &&
          other.status == this.status &&
          other.ownerUid == this.ownerUid &&
          other.name == this.name &&
          other.contactPerson == this.contactPerson &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.gstin == this.gstin &&
          other.invoicePrefix == this.invoicePrefix &&
          other.currency == this.currency &&
          other.cachedAt == this.cachedAt);
}

class CachedCompaniesCompanion extends UpdateCompanion<CachedCompany> {
  final Value<String> userId;
  final Value<String> companyId;
  final Value<String> role;
  final Value<String> status;
  final Value<String> ownerUid;
  final Value<String> name;
  final Value<String> contactPerson;
  final Value<String> phone;
  final Value<String?> email;
  final Value<String> address;
  final Value<String?> gstin;
  final Value<String> invoicePrefix;
  final Value<String> currency;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const CachedCompaniesCompanion({
    this.userId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.ownerUid = const Value.absent(),
    this.name = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.gstin = const Value.absent(),
    this.invoicePrefix = const Value.absent(),
    this.currency = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCompaniesCompanion.insert({
    required String userId,
    required String companyId,
    required String role,
    required String status,
    required String ownerUid,
    required String name,
    required String contactPerson,
    required String phone,
    this.email = const Value.absent(),
    required String address,
    this.gstin = const Value.absent(),
    required String invoicePrefix,
    required String currency,
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       companyId = Value(companyId),
       role = Value(role),
       status = Value(status),
       ownerUid = Value(ownerUid),
       name = Value(name),
       contactPerson = Value(contactPerson),
       phone = Value(phone),
       address = Value(address),
       invoicePrefix = Value(invoicePrefix),
       currency = Value(currency),
       cachedAt = Value(cachedAt);
  static Insertable<CachedCompany> custom({
    Expression<String>? userId,
    Expression<String>? companyId,
    Expression<String>? role,
    Expression<String>? status,
    Expression<String>? ownerUid,
    Expression<String>? name,
    Expression<String>? contactPerson,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? gstin,
    Expression<String>? invoicePrefix,
    Expression<String>? currency,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (companyId != null) 'company_id': companyId,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (ownerUid != null) 'owner_uid': ownerUid,
      if (name != null) 'name': name,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (gstin != null) 'gstin': gstin,
      if (invoicePrefix != null) 'invoice_prefix': invoicePrefix,
      if (currency != null) 'currency': currency,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCompaniesCompanion copyWith({
    Value<String>? userId,
    Value<String>? companyId,
    Value<String>? role,
    Value<String>? status,
    Value<String>? ownerUid,
    Value<String>? name,
    Value<String>? contactPerson,
    Value<String>? phone,
    Value<String?>? email,
    Value<String>? address,
    Value<String?>? gstin,
    Value<String>? invoicePrefix,
    Value<String>? currency,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedCompaniesCompanion(
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      role: role ?? this.role,
      status: status ?? this.status,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      currency: currency ?? this.currency,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (ownerUid.present) {
      map['owner_uid'] = Variable<String>(ownerUid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contactPerson.present) {
      map['contact_person'] = Variable<String>(contactPerson.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (gstin.present) {
      map['gstin'] = Variable<String>(gstin.value);
    }
    if (invoicePrefix.present) {
      map['invoice_prefix'] = Variable<String>(invoicePrefix.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCompaniesCompanion(')
          ..write('userId: $userId, ')
          ..write('companyId: $companyId, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('ownerUid: $ownerUid, ')
          ..write('name: $name, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('gstin: $gstin, ')
          ..write('invoicePrefix: $invoicePrefix, ')
          ..write('currency: $currency, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientsTable extends Clients with TableInfo<$ClientsTable, Client> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _contactPersonMeta = const VerificationMeta(
    'contactPerson',
  );
  @override
  late final GeneratedColumn<String> contactPerson = GeneratedColumn<String>(
    'contact_person',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billingAddressMeta = const VerificationMeta(
    'billingAddress',
  );
  @override
  late final GeneratedColumn<String> billingAddress = GeneratedColumn<String>(
    'billing_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gstinMeta = const VerificationMeta('gstin');
  @override
  late final GeneratedColumn<String> gstin = GeneratedColumn<String>(
    'gstin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    contactPerson,
    phone,
    email,
    billingAddress,
    gstin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Client> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('contact_person')) {
      context.handle(
        _contactPersonMeta,
        contactPerson.isAcceptableOrUnknown(
          data['contact_person']!,
          _contactPersonMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('billing_address')) {
      context.handle(
        _billingAddressMeta,
        billingAddress.isAcceptableOrUnknown(
          data['billing_address']!,
          _billingAddressMeta,
        ),
      );
    }
    if (data.containsKey('gstin')) {
      context.handle(
        _gstinMeta,
        gstin.isAcceptableOrUnknown(data['gstin']!, _gstinMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Client map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Client(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      contactPerson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_person'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      billingAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}billing_address'],
      ),
      gstin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gstin'],
      ),
    );
  }

  @override
  $ClientsTable createAlias(String alias) {
    return $ClientsTable(attachedDatabase, alias);
  }
}

class Client extends DataClass implements Insertable<Client> {
  final String id;
  final String companyId;
  final String name;
  final String? notes;
  final bool isActive;

  /// UTC epoch milliseconds.
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String createdBy;
  final String updatedBy;

  /// `pending` until the sync engine uploads it, then `synced`.
  final String syncStatus;

  /// Incremented on every local change; used for conflict detection.
  final int version;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? billingAddress;
  final String? gstin;
  const Client({
    required this.id,
    required this.companyId,
    required this.name,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncStatus,
    required this.version,
    this.contactPerson,
    this.phone,
    this.email,
    this.billingAddress,
    this.gstin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['updated_by'] = Variable<String>(updatedBy);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || contactPerson != null) {
      map['contact_person'] = Variable<String>(contactPerson);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || billingAddress != null) {
      map['billing_address'] = Variable<String>(billingAddress);
    }
    if (!nullToAbsent || gstin != null) {
      map['gstin'] = Variable<String>(gstin);
    }
    return map;
  }

  ClientsCompanion toCompanion(bool nullToAbsent) {
    return ClientsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: Value(createdBy),
      updatedBy: Value(updatedBy),
      syncStatus: Value(syncStatus),
      version: Value(version),
      contactPerson: contactPerson == null && nullToAbsent
          ? const Value.absent()
          : Value(contactPerson),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      billingAddress: billingAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(billingAddress),
      gstin: gstin == null && nullToAbsent
          ? const Value.absent()
          : Value(gstin),
    );
  }

  factory Client.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Client(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      contactPerson: serializer.fromJson<String?>(json['contactPerson']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      billingAddress: serializer.fromJson<String?>(json['billingAddress']),
      gstin: serializer.fromJson<String?>(json['gstin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'contactPerson': serializer.toJson<String?>(contactPerson),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'billingAddress': serializer.toJson<String?>(billingAddress),
      'gstin': serializer.toJson<String?>(gstin),
    };
  }

  Client copyWith({
    String? id,
    String? companyId,
    String? name,
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? createdBy,
    String? updatedBy,
    String? syncStatus,
    int? version,
    Value<String?> contactPerson = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> billingAddress = const Value.absent(),
    Value<String?> gstin = const Value.absent(),
  }) => Client(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    contactPerson: contactPerson.present
        ? contactPerson.value
        : this.contactPerson,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    billingAddress: billingAddress.present
        ? billingAddress.value
        : this.billingAddress,
    gstin: gstin.present ? gstin.value : this.gstin,
  );
  Client copyWithCompanion(ClientsCompanion data) {
    return Client(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      contactPerson: data.contactPerson.present
          ? data.contactPerson.value
          : this.contactPerson,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      billingAddress: data.billingAddress.present
          ? data.billingAddress.value
          : this.billingAddress,
      gstin: data.gstin.present ? data.gstin.value : this.gstin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Client(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('billingAddress: $billingAddress, ')
          ..write('gstin: $gstin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    contactPerson,
    phone,
    email,
    billingAddress,
    gstin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Client &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.contactPerson == this.contactPerson &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.billingAddress == this.billingAddress &&
          other.gstin == this.gstin);
}

class ClientsCompanion extends UpdateCompanion<Client> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> name;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> createdBy;
  final Value<String> updatedBy;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<String?> contactPerson;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> billingAddress;
  final Value<String?> gstin;
  final Value<int> rowid;
  const ClientsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.billingAddress = const Value.absent(),
    this.gstin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsCompanion.insert({
    required String id,
    required String companyId,
    required String name,
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String createdBy,
    required String updatedBy,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.billingAddress = const Value.absent(),
    this.gstin = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy),
       updatedBy = Value(updatedBy);
  static Insertable<Client> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<String>? contactPerson,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? billingAddress,
    Expression<String>? gstin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (billingAddress != null) 'billing_address': billingAddress,
      if (gstin != null) 'gstin': gstin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? name,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? createdBy,
    Value<String>? updatedBy,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<String?>? contactPerson,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? billingAddress,
    Value<String?>? gstin,
    Value<int>? rowid,
  }) {
    return ClientsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      billingAddress: billingAddress ?? this.billingAddress,
      gstin: gstin ?? this.gstin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (contactPerson.present) {
      map['contact_person'] = Variable<String>(contactPerson.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (billingAddress.present) {
      map['billing_address'] = Variable<String>(billingAddress.value);
    }
    if (gstin.present) {
      map['gstin'] = Variable<String>(gstin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('billingAddress: $billingAddress, ')
          ..write('gstin: $gstin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SitesTable extends Sites with TableInfo<$SitesTable, Site> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clients (id)',
    ),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactPersonMeta = const VerificationMeta(
    'contactPerson',
  );
  @override
  late final GeneratedColumn<String> contactPerson = GeneratedColumn<String>(
    'contact_person',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultHourlyRatePaiseMeta =
      const VerificationMeta('defaultHourlyRatePaise');
  @override
  late final GeneratedColumn<int> defaultHourlyRatePaise = GeneratedColumn<int>(
    'default_hourly_rate_paise',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    clientId,
    address,
    contactPerson,
    phone,
    defaultHourlyRatePaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Site> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('contact_person')) {
      context.handle(
        _contactPersonMeta,
        contactPerson.isAcceptableOrUnknown(
          data['contact_person']!,
          _contactPersonMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('default_hourly_rate_paise')) {
      context.handle(
        _defaultHourlyRatePaiseMeta,
        defaultHourlyRatePaise.isAcceptableOrUnknown(
          data['default_hourly_rate_paise']!,
          _defaultHourlyRatePaiseMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Site map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Site(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      contactPerson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_person'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      defaultHourlyRatePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_hourly_rate_paise'],
      ),
    );
  }

  @override
  $SitesTable createAlias(String alias) {
    return $SitesTable(attachedDatabase, alias);
  }
}

class Site extends DataClass implements Insertable<Site> {
  final String id;
  final String companyId;
  final String name;
  final String? notes;
  final bool isActive;

  /// UTC epoch milliseconds.
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String createdBy;
  final String updatedBy;

  /// `pending` until the sync engine uploads it, then `synced`.
  final String syncStatus;

  /// Incremented on every local change; used for conflict detection.
  final int version;
  final String clientId;
  final String? address;
  final String? contactPerson;
  final String? phone;

  /// Suggested rate in paise per hour. Invoices may override it.
  final int? defaultHourlyRatePaise;
  const Site({
    required this.id,
    required this.companyId,
    required this.name,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncStatus,
    required this.version,
    required this.clientId,
    this.address,
    this.contactPerson,
    this.phone,
    this.defaultHourlyRatePaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['updated_by'] = Variable<String>(updatedBy);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || contactPerson != null) {
      map['contact_person'] = Variable<String>(contactPerson);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || defaultHourlyRatePaise != null) {
      map['default_hourly_rate_paise'] = Variable<int>(defaultHourlyRatePaise);
    }
    return map;
  }

  SitesCompanion toCompanion(bool nullToAbsent) {
    return SitesCompanion(
      id: Value(id),
      companyId: Value(companyId),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: Value(createdBy),
      updatedBy: Value(updatedBy),
      syncStatus: Value(syncStatus),
      version: Value(version),
      clientId: Value(clientId),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      contactPerson: contactPerson == null && nullToAbsent
          ? const Value.absent()
          : Value(contactPerson),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      defaultHourlyRatePaise: defaultHourlyRatePaise == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultHourlyRatePaise),
    );
  }

  factory Site.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Site(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      clientId: serializer.fromJson<String>(json['clientId']),
      address: serializer.fromJson<String?>(json['address']),
      contactPerson: serializer.fromJson<String?>(json['contactPerson']),
      phone: serializer.fromJson<String?>(json['phone']),
      defaultHourlyRatePaise: serializer.fromJson<int?>(
        json['defaultHourlyRatePaise'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'clientId': serializer.toJson<String>(clientId),
      'address': serializer.toJson<String?>(address),
      'contactPerson': serializer.toJson<String?>(contactPerson),
      'phone': serializer.toJson<String?>(phone),
      'defaultHourlyRatePaise': serializer.toJson<int?>(defaultHourlyRatePaise),
    };
  }

  Site copyWith({
    String? id,
    String? companyId,
    String? name,
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? createdBy,
    String? updatedBy,
    String? syncStatus,
    int? version,
    String? clientId,
    Value<String?> address = const Value.absent(),
    Value<String?> contactPerson = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<int?> defaultHourlyRatePaise = const Value.absent(),
  }) => Site(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    clientId: clientId ?? this.clientId,
    address: address.present ? address.value : this.address,
    contactPerson: contactPerson.present
        ? contactPerson.value
        : this.contactPerson,
    phone: phone.present ? phone.value : this.phone,
    defaultHourlyRatePaise: defaultHourlyRatePaise.present
        ? defaultHourlyRatePaise.value
        : this.defaultHourlyRatePaise,
  );
  Site copyWithCompanion(SitesCompanion data) {
    return Site(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      address: data.address.present ? data.address.value : this.address,
      contactPerson: data.contactPerson.present
          ? data.contactPerson.value
          : this.contactPerson,
      phone: data.phone.present ? data.phone.value : this.phone,
      defaultHourlyRatePaise: data.defaultHourlyRatePaise.present
          ? data.defaultHourlyRatePaise.value
          : this.defaultHourlyRatePaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Site(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('clientId: $clientId, ')
          ..write('address: $address, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('phone: $phone, ')
          ..write('defaultHourlyRatePaise: $defaultHourlyRatePaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    clientId,
    address,
    contactPerson,
    phone,
    defaultHourlyRatePaise,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Site &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.clientId == this.clientId &&
          other.address == this.address &&
          other.contactPerson == this.contactPerson &&
          other.phone == this.phone &&
          other.defaultHourlyRatePaise == this.defaultHourlyRatePaise);
}

class SitesCompanion extends UpdateCompanion<Site> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> name;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> createdBy;
  final Value<String> updatedBy;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<String> clientId;
  final Value<String?> address;
  final Value<String?> contactPerson;
  final Value<String?> phone;
  final Value<int?> defaultHourlyRatePaise;
  final Value<int> rowid;
  const SitesCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.clientId = const Value.absent(),
    this.address = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.phone = const Value.absent(),
    this.defaultHourlyRatePaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SitesCompanion.insert({
    required String id,
    required String companyId,
    required String name,
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String createdBy,
    required String updatedBy,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    required String clientId,
    this.address = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.phone = const Value.absent(),
    this.defaultHourlyRatePaise = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy),
       updatedBy = Value(updatedBy),
       clientId = Value(clientId);
  static Insertable<Site> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<String>? clientId,
    Expression<String>? address,
    Expression<String>? contactPerson,
    Expression<String>? phone,
    Expression<int>? defaultHourlyRatePaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (clientId != null) 'client_id': clientId,
      if (address != null) 'address': address,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (phone != null) 'phone': phone,
      if (defaultHourlyRatePaise != null)
        'default_hourly_rate_paise': defaultHourlyRatePaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SitesCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? name,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? createdBy,
    Value<String>? updatedBy,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<String>? clientId,
    Value<String?>? address,
    Value<String?>? contactPerson,
    Value<String?>? phone,
    Value<int?>? defaultHourlyRatePaise,
    Value<int>? rowid,
  }) {
    return SitesCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      clientId: clientId ?? this.clientId,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      defaultHourlyRatePaise:
          defaultHourlyRatePaise ?? this.defaultHourlyRatePaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (contactPerson.present) {
      map['contact_person'] = Variable<String>(contactPerson.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (defaultHourlyRatePaise.present) {
      map['default_hourly_rate_paise'] = Variable<int>(
        defaultHourlyRatePaise.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SitesCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('clientId: $clientId, ')
          ..write('address: $address, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('phone: $phone, ')
          ..write('defaultHourlyRatePaise: $defaultHourlyRatePaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MachinesTable extends Machines with TableInfo<$MachinesTable, Machine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MachinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _registrationNumberMeta =
      const VerificationMeta('registrationNumber');
  @override
  late final GeneratedColumn<String> registrationNumber =
      GeneratedColumn<String>(
        'registration_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initialMeterReadingMeta =
      const VerificationMeta('initialMeterReading');
  @override
  late final GeneratedColumn<int> initialMeterReading = GeneratedColumn<int>(
    'initial_meter_reading',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meterUnitMeta = const VerificationMeta(
    'meterUnit',
  );
  @override
  late final GeneratedColumn<String> meterUnit = GeneratedColumn<String>(
    'meter_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('hours'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    registrationNumber,
    serialNumber,
    model,
    initialMeterReading,
    meterUnit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'machines';
  @override
  VerificationContext validateIntegrity(
    Insertable<Machine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('registration_number')) {
      context.handle(
        _registrationNumberMeta,
        registrationNumber.isAcceptableOrUnknown(
          data['registration_number']!,
          _registrationNumberMeta,
        ),
      );
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('initial_meter_reading')) {
      context.handle(
        _initialMeterReadingMeta,
        initialMeterReading.isAcceptableOrUnknown(
          data['initial_meter_reading']!,
          _initialMeterReadingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialMeterReadingMeta);
    }
    if (data.containsKey('meter_unit')) {
      context.handle(
        _meterUnitMeta,
        meterUnit.isAcceptableOrUnknown(data['meter_unit']!, _meterUnitMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Machine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Machine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      registrationNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_number'],
      ),
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      initialMeterReading: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_meter_reading'],
      )!,
      meterUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meter_unit'],
      )!,
    );
  }

  @override
  $MachinesTable createAlias(String alias) {
    return $MachinesTable(attachedDatabase, alias);
  }
}

class Machine extends DataClass implements Insertable<Machine> {
  final String id;
  final String companyId;
  final String name;
  final String? notes;
  final bool isActive;

  /// UTC epoch milliseconds.
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String createdBy;
  final String updatedBy;

  /// `pending` until the sync engine uploads it, then `synced`.
  final String syncStatus;

  /// Incremented on every local change; used for conflict detection.
  final int version;
  final String? registrationNumber;
  final String? serialNumber;
  final String? model;

  /// Hour-meter reading when the machine was added, in hundredths of an hour.
  final int initialMeterReading;
  final String meterUnit;
  const Machine({
    required this.id,
    required this.companyId,
    required this.name,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncStatus,
    required this.version,
    this.registrationNumber,
    this.serialNumber,
    this.model,
    required this.initialMeterReading,
    required this.meterUnit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['updated_by'] = Variable<String>(updatedBy);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || registrationNumber != null) {
      map['registration_number'] = Variable<String>(registrationNumber);
    }
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    map['initial_meter_reading'] = Variable<int>(initialMeterReading);
    map['meter_unit'] = Variable<String>(meterUnit);
    return map;
  }

  MachinesCompanion toCompanion(bool nullToAbsent) {
    return MachinesCompanion(
      id: Value(id),
      companyId: Value(companyId),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: Value(createdBy),
      updatedBy: Value(updatedBy),
      syncStatus: Value(syncStatus),
      version: Value(version),
      registrationNumber: registrationNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(registrationNumber),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      initialMeterReading: Value(initialMeterReading),
      meterUnit: Value(meterUnit),
    );
  }

  factory Machine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Machine(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      registrationNumber: serializer.fromJson<String?>(
        json['registrationNumber'],
      ),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      model: serializer.fromJson<String?>(json['model']),
      initialMeterReading: serializer.fromJson<int>(
        json['initialMeterReading'],
      ),
      meterUnit: serializer.fromJson<String>(json['meterUnit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'registrationNumber': serializer.toJson<String?>(registrationNumber),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'model': serializer.toJson<String?>(model),
      'initialMeterReading': serializer.toJson<int>(initialMeterReading),
      'meterUnit': serializer.toJson<String>(meterUnit),
    };
  }

  Machine copyWith({
    String? id,
    String? companyId,
    String? name,
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? createdBy,
    String? updatedBy,
    String? syncStatus,
    int? version,
    Value<String?> registrationNumber = const Value.absent(),
    Value<String?> serialNumber = const Value.absent(),
    Value<String?> model = const Value.absent(),
    int? initialMeterReading,
    String? meterUnit,
  }) => Machine(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    registrationNumber: registrationNumber.present
        ? registrationNumber.value
        : this.registrationNumber,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    model: model.present ? model.value : this.model,
    initialMeterReading: initialMeterReading ?? this.initialMeterReading,
    meterUnit: meterUnit ?? this.meterUnit,
  );
  Machine copyWithCompanion(MachinesCompanion data) {
    return Machine(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      registrationNumber: data.registrationNumber.present
          ? data.registrationNumber.value
          : this.registrationNumber,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      model: data.model.present ? data.model.value : this.model,
      initialMeterReading: data.initialMeterReading.present
          ? data.initialMeterReading.value
          : this.initialMeterReading,
      meterUnit: data.meterUnit.present ? data.meterUnit.value : this.meterUnit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Machine(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('model: $model, ')
          ..write('initialMeterReading: $initialMeterReading, ')
          ..write('meterUnit: $meterUnit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    registrationNumber,
    serialNumber,
    model,
    initialMeterReading,
    meterUnit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Machine &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.registrationNumber == this.registrationNumber &&
          other.serialNumber == this.serialNumber &&
          other.model == this.model &&
          other.initialMeterReading == this.initialMeterReading &&
          other.meterUnit == this.meterUnit);
}

class MachinesCompanion extends UpdateCompanion<Machine> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> name;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> createdBy;
  final Value<String> updatedBy;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<String?> registrationNumber;
  final Value<String?> serialNumber;
  final Value<String?> model;
  final Value<int> initialMeterReading;
  final Value<String> meterUnit;
  final Value<int> rowid;
  const MachinesCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.registrationNumber = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.model = const Value.absent(),
    this.initialMeterReading = const Value.absent(),
    this.meterUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MachinesCompanion.insert({
    required String id,
    required String companyId,
    required String name,
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String createdBy,
    required String updatedBy,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.registrationNumber = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.model = const Value.absent(),
    required int initialMeterReading,
    this.meterUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy),
       updatedBy = Value(updatedBy),
       initialMeterReading = Value(initialMeterReading);
  static Insertable<Machine> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<String>? registrationNumber,
    Expression<String>? serialNumber,
    Expression<String>? model,
    Expression<int>? initialMeterReading,
    Expression<String>? meterUnit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (model != null) 'model': model,
      if (initialMeterReading != null)
        'initial_meter_reading': initialMeterReading,
      if (meterUnit != null) 'meter_unit': meterUnit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MachinesCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? name,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? createdBy,
    Value<String>? updatedBy,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<String?>? registrationNumber,
    Value<String?>? serialNumber,
    Value<String?>? model,
    Value<int>? initialMeterReading,
    Value<String>? meterUnit,
    Value<int>? rowid,
  }) {
    return MachinesCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      model: model ?? this.model,
      initialMeterReading: initialMeterReading ?? this.initialMeterReading,
      meterUnit: meterUnit ?? this.meterUnit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (registrationNumber.present) {
      map['registration_number'] = Variable<String>(registrationNumber.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (initialMeterReading.present) {
      map['initial_meter_reading'] = Variable<int>(initialMeterReading.value);
    }
    if (meterUnit.present) {
      map['meter_unit'] = Variable<String>(meterUnit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MachinesCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('model: $model, ')
          ..write('initialMeterReading: $initialMeterReading, ')
          ..write('meterUnit: $meterUnit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperatorsTable extends Operators
    with TableInfo<$OperatorsTable, Operator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperatorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    phone,
    code,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operators';
  @override
  VerificationContext validateIntegrity(
    Insertable<Operator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Operator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Operator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
    );
  }

  @override
  $OperatorsTable createAlias(String alias) {
    return $OperatorsTable(attachedDatabase, alias);
  }
}

class Operator extends DataClass implements Insertable<Operator> {
  final String id;
  final String companyId;
  final String name;
  final String? notes;
  final bool isActive;

  /// UTC epoch milliseconds.
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String createdBy;
  final String updatedBy;

  /// `pending` until the sync engine uploads it, then `synced`.
  final String syncStatus;

  /// Incremented on every local change; used for conflict detection.
  final int version;
  final String? phone;
  final String? code;
  const Operator({
    required this.id,
    required this.companyId,
    required this.name,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncStatus,
    required this.version,
    this.phone,
    this.code,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['updated_by'] = Variable<String>(updatedBy);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    return map;
  }

  OperatorsCompanion toCompanion(bool nullToAbsent) {
    return OperatorsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: Value(createdBy),
      updatedBy: Value(updatedBy),
      syncStatus: Value(syncStatus),
      version: Value(version),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
    );
  }

  factory Operator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Operator(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      phone: serializer.fromJson<String?>(json['phone']),
      code: serializer.fromJson<String?>(json['code']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'phone': serializer.toJson<String?>(phone),
      'code': serializer.toJson<String?>(code),
    };
  }

  Operator copyWith({
    String? id,
    String? companyId,
    String? name,
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? createdBy,
    String? updatedBy,
    String? syncStatus,
    int? version,
    Value<String?> phone = const Value.absent(),
    Value<String?> code = const Value.absent(),
  }) => Operator(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    phone: phone.present ? phone.value : this.phone,
    code: code.present ? code.value : this.code,
  );
  Operator copyWithCompanion(OperatorsCompanion data) {
    return Operator(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      phone: data.phone.present ? data.phone.value : this.phone,
      code: data.code.present ? data.code.value : this.code,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Operator(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('phone: $phone, ')
          ..write('code: $code')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    phone,
    code,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Operator &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.phone == this.phone &&
          other.code == this.code);
}

class OperatorsCompanion extends UpdateCompanion<Operator> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> name;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> createdBy;
  final Value<String> updatedBy;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<String?> phone;
  final Value<String?> code;
  final Value<int> rowid;
  const OperatorsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.phone = const Value.absent(),
    this.code = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperatorsCompanion.insert({
    required String id,
    required String companyId,
    required String name,
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String createdBy,
    required String updatedBy,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.phone = const Value.absent(),
    this.code = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy),
       updatedBy = Value(updatedBy);
  static Insertable<Operator> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<String>? phone,
    Expression<String>? code,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (phone != null) 'phone': phone,
      if (code != null) 'code': code,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperatorsCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? name,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? createdBy,
    Value<String>? updatedBy,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<String?>? phone,
    Value<String?>? code,
    Value<int>? rowid,
  }) {
    return OperatorsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      phone: phone ?? this.phone,
      code: code ?? this.code,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperatorsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('phone: $phone, ')
          ..write('code: $code, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PetrolPumpsTable extends PetrolPumps
    with TableInfo<$PetrolPumpsTable, PetrolPump> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PetrolPumpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    phone,
    address,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'petrol_pumps';
  @override
  VerificationContext validateIntegrity(
    Insertable<PetrolPump> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PetrolPump map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PetrolPump(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
    );
  }

  @override
  $PetrolPumpsTable createAlias(String alias) {
    return $PetrolPumpsTable(attachedDatabase, alias);
  }
}

class PetrolPump extends DataClass implements Insertable<PetrolPump> {
  final String id;
  final String companyId;
  final String name;
  final String? notes;
  final bool isActive;

  /// UTC epoch milliseconds.
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String createdBy;
  final String updatedBy;

  /// `pending` until the sync engine uploads it, then `synced`.
  final String syncStatus;

  /// Incremented on every local change; used for conflict detection.
  final int version;
  final String? phone;
  final String? address;
  const PetrolPump({
    required this.id,
    required this.companyId,
    required this.name,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncStatus,
    required this.version,
    this.phone,
    this.address,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['updated_by'] = Variable<String>(updatedBy);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    return map;
  }

  PetrolPumpsCompanion toCompanion(bool nullToAbsent) {
    return PetrolPumpsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: Value(createdBy),
      updatedBy: Value(updatedBy),
      syncStatus: Value(syncStatus),
      version: Value(version),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
    );
  }

  factory PetrolPump.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PetrolPump(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
    };
  }

  PetrolPump copyWith({
    String? id,
    String? companyId,
    String? name,
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? createdBy,
    String? updatedBy,
    String? syncStatus,
    int? version,
    Value<String?> phone = const Value.absent(),
    Value<String?> address = const Value.absent(),
  }) => PetrolPump(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    phone: phone.present ? phone.value : this.phone,
    address: address.present ? address.value : this.address,
  );
  PetrolPump copyWithCompanion(PetrolPumpsCompanion data) {
    return PetrolPump(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PetrolPump(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('phone: $phone, ')
          ..write('address: $address')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    name,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
    phone,
    address,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PetrolPump &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.phone == this.phone &&
          other.address == this.address);
}

class PetrolPumpsCompanion extends UpdateCompanion<PetrolPump> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> name;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> createdBy;
  final Value<String> updatedBy;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<int> rowid;
  const PetrolPumpsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PetrolPumpsCompanion.insert({
    required String id,
    required String companyId,
    required String name,
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String createdBy,
    required String updatedBy,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy),
       updatedBy = Value(updatedBy);
  static Insertable<PetrolPump> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PetrolPumpsCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? name,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? createdBy,
    Value<String>? updatedBy,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<String?>? phone,
    Value<String?>? address,
    Value<int>? rowid,
  }) {
    return PetrolPumpsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PetrolPumpsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkLogsTable extends WorkLogs with TableInfo<$WorkLogsTable, WorkLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workDateMeta = const VerificationMeta(
    'workDate',
  );
  @override
  late final GeneratedColumn<String> workDate = GeneratedColumn<String>(
    'work_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clients (id)',
    ),
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sites (id)',
    ),
  );
  static const VerificationMeta _machineIdMeta = const VerificationMeta(
    'machineId',
  );
  @override
  late final GeneratedColumn<String> machineId = GeneratedColumn<String>(
    'machine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES machines (id)',
    ),
  );
  static const VerificationMeta _operatorIdMeta = const VerificationMeta(
    'operatorId',
  );
  @override
  late final GeneratedColumn<String> operatorId = GeneratedColumn<String>(
    'operator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES operators (id)',
    ),
  );
  static const VerificationMeta _operatorNameMeta = const VerificationMeta(
    'operatorName',
  );
  @override
  late final GeneratedColumn<String> operatorName = GeneratedColumn<String>(
    'operator_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startReadingMeta = const VerificationMeta(
    'startReading',
  );
  @override
  late final GeneratedColumn<int> startReading = GeneratedColumn<int>(
    'start_reading',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPhotoPathMeta = const VerificationMeta(
    'startPhotoPath',
  );
  @override
  late final GeneratedColumn<String> startPhotoPath = GeneratedColumn<String>(
    'start_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startCapturedAtMeta = const VerificationMeta(
    'startCapturedAt',
  );
  @override
  late final GeneratedColumn<int> startCapturedAt = GeneratedColumn<int>(
    'start_captured_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startLatMeta = const VerificationMeta(
    'startLat',
  );
  @override
  late final GeneratedColumn<double> startLat = GeneratedColumn<double>(
    'start_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startLngMeta = const VerificationMeta(
    'startLng',
  );
  @override
  late final GeneratedColumn<double> startLng = GeneratedColumn<double>(
    'start_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startAccuracyMeta = const VerificationMeta(
    'startAccuracy',
  );
  @override
  late final GeneratedColumn<double> startAccuracy = GeneratedColumn<double>(
    'start_accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startLocationStatusMeta =
      const VerificationMeta('startLocationStatus');
  @override
  late final GeneratedColumn<String> startLocationStatus =
      GeneratedColumn<String>(
        'start_location_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _endReadingMeta = const VerificationMeta(
    'endReading',
  );
  @override
  late final GeneratedColumn<int> endReading = GeneratedColumn<int>(
    'end_reading',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endPhotoPathMeta = const VerificationMeta(
    'endPhotoPath',
  );
  @override
  late final GeneratedColumn<String> endPhotoPath = GeneratedColumn<String>(
    'end_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endCapturedAtMeta = const VerificationMeta(
    'endCapturedAt',
  );
  @override
  late final GeneratedColumn<int> endCapturedAt = GeneratedColumn<int>(
    'end_captured_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endLatMeta = const VerificationMeta('endLat');
  @override
  late final GeneratedColumn<double> endLat = GeneratedColumn<double>(
    'end_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endLngMeta = const VerificationMeta('endLng');
  @override
  late final GeneratedColumn<double> endLng = GeneratedColumn<double>(
    'end_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endAccuracyMeta = const VerificationMeta(
    'endAccuracy',
  );
  @override
  late final GeneratedColumn<double> endAccuracy = GeneratedColumn<double>(
    'end_accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endLocationStatusMeta = const VerificationMeta(
    'endLocationStatus',
  );
  @override
  late final GeneratedColumn<String> endLocationStatus =
      GeneratedColumn<String>(
        'end_location_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _workingHoursMeta = const VerificationMeta(
    'workingHours',
  );
  @override
  late final GeneratedColumn<int> workingHours = GeneratedColumn<int>(
    'working_hours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entryModeMeta = const VerificationMeta(
    'entryMode',
  );
  @override
  late final GeneratedColumn<String> entryMode = GeneratedColumn<String>(
    'entry_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manualReasonMeta = const VerificationMeta(
    'manualReason',
  );
  @override
  late final GeneratedColumn<String> manualReason = GeneratedColumn<String>(
    'manual_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anomalyFlagsMeta = const VerificationMeta(
    'anomalyFlags',
  );
  @override
  late final GeneratedColumn<String> anomalyFlags = GeneratedColumn<String>(
    'anomaly_flags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusReasonMeta = const VerificationMeta(
    'statusReason',
  );
  @override
  late final GeneratedColumn<String> statusReason = GeneratedColumn<String>(
    'status_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedAtMeta = const VerificationMeta(
    'approvedAt',
  );
  @override
  late final GeneratedColumn<int> approvedAt = GeneratedColumn<int>(
    'approved_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    workDate,
    clientId,
    siteId,
    machineId,
    operatorId,
    operatorName,
    startReading,
    startPhotoPath,
    startCapturedAt,
    startLat,
    startLng,
    startAccuracy,
    startLocationStatus,
    endReading,
    endPhotoPath,
    endCapturedAt,
    endLat,
    endLng,
    endAccuracy,
    endLocationStatus,
    workingHours,
    entryMode,
    manualReason,
    notes,
    anomalyFlags,
    status,
    statusReason,
    approvedBy,
    approvedAt,
    invoiceId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('work_date')) {
      context.handle(
        _workDateMeta,
        workDate.isAcceptableOrUnknown(data['work_date']!, _workDateMeta),
      );
    } else if (isInserting) {
      context.missing(_workDateMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('machine_id')) {
      context.handle(
        _machineIdMeta,
        machineId.isAcceptableOrUnknown(data['machine_id']!, _machineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_machineIdMeta);
    }
    if (data.containsKey('operator_id')) {
      context.handle(
        _operatorIdMeta,
        operatorId.isAcceptableOrUnknown(data['operator_id']!, _operatorIdMeta),
      );
    }
    if (data.containsKey('operator_name')) {
      context.handle(
        _operatorNameMeta,
        operatorName.isAcceptableOrUnknown(
          data['operator_name']!,
          _operatorNameMeta,
        ),
      );
    }
    if (data.containsKey('start_reading')) {
      context.handle(
        _startReadingMeta,
        startReading.isAcceptableOrUnknown(
          data['start_reading']!,
          _startReadingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startReadingMeta);
    }
    if (data.containsKey('start_photo_path')) {
      context.handle(
        _startPhotoPathMeta,
        startPhotoPath.isAcceptableOrUnknown(
          data['start_photo_path']!,
          _startPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('start_captured_at')) {
      context.handle(
        _startCapturedAtMeta,
        startCapturedAt.isAcceptableOrUnknown(
          data['start_captured_at']!,
          _startCapturedAtMeta,
        ),
      );
    }
    if (data.containsKey('start_lat')) {
      context.handle(
        _startLatMeta,
        startLat.isAcceptableOrUnknown(data['start_lat']!, _startLatMeta),
      );
    }
    if (data.containsKey('start_lng')) {
      context.handle(
        _startLngMeta,
        startLng.isAcceptableOrUnknown(data['start_lng']!, _startLngMeta),
      );
    }
    if (data.containsKey('start_accuracy')) {
      context.handle(
        _startAccuracyMeta,
        startAccuracy.isAcceptableOrUnknown(
          data['start_accuracy']!,
          _startAccuracyMeta,
        ),
      );
    }
    if (data.containsKey('start_location_status')) {
      context.handle(
        _startLocationStatusMeta,
        startLocationStatus.isAcceptableOrUnknown(
          data['start_location_status']!,
          _startLocationStatusMeta,
        ),
      );
    }
    if (data.containsKey('end_reading')) {
      context.handle(
        _endReadingMeta,
        endReading.isAcceptableOrUnknown(data['end_reading']!, _endReadingMeta),
      );
    }
    if (data.containsKey('end_photo_path')) {
      context.handle(
        _endPhotoPathMeta,
        endPhotoPath.isAcceptableOrUnknown(
          data['end_photo_path']!,
          _endPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('end_captured_at')) {
      context.handle(
        _endCapturedAtMeta,
        endCapturedAt.isAcceptableOrUnknown(
          data['end_captured_at']!,
          _endCapturedAtMeta,
        ),
      );
    }
    if (data.containsKey('end_lat')) {
      context.handle(
        _endLatMeta,
        endLat.isAcceptableOrUnknown(data['end_lat']!, _endLatMeta),
      );
    }
    if (data.containsKey('end_lng')) {
      context.handle(
        _endLngMeta,
        endLng.isAcceptableOrUnknown(data['end_lng']!, _endLngMeta),
      );
    }
    if (data.containsKey('end_accuracy')) {
      context.handle(
        _endAccuracyMeta,
        endAccuracy.isAcceptableOrUnknown(
          data['end_accuracy']!,
          _endAccuracyMeta,
        ),
      );
    }
    if (data.containsKey('end_location_status')) {
      context.handle(
        _endLocationStatusMeta,
        endLocationStatus.isAcceptableOrUnknown(
          data['end_location_status']!,
          _endLocationStatusMeta,
        ),
      );
    }
    if (data.containsKey('working_hours')) {
      context.handle(
        _workingHoursMeta,
        workingHours.isAcceptableOrUnknown(
          data['working_hours']!,
          _workingHoursMeta,
        ),
      );
    }
    if (data.containsKey('entry_mode')) {
      context.handle(
        _entryModeMeta,
        entryMode.isAcceptableOrUnknown(data['entry_mode']!, _entryModeMeta),
      );
    } else if (isInserting) {
      context.missing(_entryModeMeta);
    }
    if (data.containsKey('manual_reason')) {
      context.handle(
        _manualReasonMeta,
        manualReason.isAcceptableOrUnknown(
          data['manual_reason']!,
          _manualReasonMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('anomaly_flags')) {
      context.handle(
        _anomalyFlagsMeta,
        anomalyFlags.isAcceptableOrUnknown(
          data['anomaly_flags']!,
          _anomalyFlagsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('status_reason')) {
      context.handle(
        _statusReasonMeta,
        statusReason.isAcceptableOrUnknown(
          data['status_reason']!,
          _statusReasonMeta,
        ),
      );
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('approved_at')) {
      context.handle(
        _approvedAtMeta,
        approvedAt.isAcceptableOrUnknown(data['approved_at']!, _approvedAtMeta),
      );
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      workDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_date'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      machineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_id'],
      )!,
      operatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_id'],
      ),
      operatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_name'],
      ),
      startReading: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_reading'],
      )!,
      startPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_photo_path'],
      ),
      startCapturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_captured_at'],
      ),
      startLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lat'],
      ),
      startLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lng'],
      ),
      startAccuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_accuracy'],
      ),
      startLocationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_location_status'],
      ),
      endReading: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_reading'],
      ),
      endPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_photo_path'],
      ),
      endCapturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_captured_at'],
      ),
      endLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lat'],
      ),
      endLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lng'],
      ),
      endAccuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_accuracy'],
      ),
      endLocationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_location_status'],
      ),
      workingHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}working_hours'],
      ),
      entryMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_mode'],
      )!,
      manualReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_reason'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      anomalyFlags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anomaly_flags'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      statusReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_reason'],
      ),
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      approvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}approved_at'],
      ),
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $WorkLogsTable createAlias(String alias) {
    return $WorkLogsTable(attachedDatabase, alias);
  }
}

class WorkLog extends DataClass implements Insertable<WorkLog> {
  final String id;
  final String companyId;

  /// Local calendar date, `yyyy-MM-dd`.
  final String workDate;
  final String clientId;
  final String siteId;
  final String machineId;
  final String? operatorId;

  /// Operator name as recorded, kept even if the operator master changes.
  final String? operatorName;
  final int startReading;
  final String? startPhotoPath;
  final int? startCapturedAt;
  final double? startLat;
  final double? startLng;
  final double? startAccuracy;
  final String? startLocationStatus;
  final int? endReading;
  final String? endPhotoPath;
  final int? endCapturedAt;
  final double? endLat;
  final double? endLng;
  final double? endAccuracy;
  final String? endLocationStatus;

  /// endReading − startReading, once both are known.
  final int? workingHours;

  /// `photo` when both readings have photos, otherwise `manual`.
  final String entryMode;
  final String? manualReason;
  final String? notes;

  /// Comma-separated anomaly flags confirmed by the user (see WorkLogRules).
  final String? anomalyFlags;

  /// draft, submitted, approved, rejected, invoiced, cancelled.
  final String status;
  final String? statusReason;
  final String? approvedBy;
  final int? approvedAt;
  final String? invoiceId;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String createdBy;
  final String updatedBy;
  final String syncStatus;
  final int version;
  const WorkLog({
    required this.id,
    required this.companyId,
    required this.workDate,
    required this.clientId,
    required this.siteId,
    required this.machineId,
    this.operatorId,
    this.operatorName,
    required this.startReading,
    this.startPhotoPath,
    this.startCapturedAt,
    this.startLat,
    this.startLng,
    this.startAccuracy,
    this.startLocationStatus,
    this.endReading,
    this.endPhotoPath,
    this.endCapturedAt,
    this.endLat,
    this.endLng,
    this.endAccuracy,
    this.endLocationStatus,
    this.workingHours,
    required this.entryMode,
    this.manualReason,
    this.notes,
    this.anomalyFlags,
    required this.status,
    this.statusReason,
    this.approvedBy,
    this.approvedAt,
    this.invoiceId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncStatus,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['work_date'] = Variable<String>(workDate);
    map['client_id'] = Variable<String>(clientId);
    map['site_id'] = Variable<String>(siteId);
    map['machine_id'] = Variable<String>(machineId);
    if (!nullToAbsent || operatorId != null) {
      map['operator_id'] = Variable<String>(operatorId);
    }
    if (!nullToAbsent || operatorName != null) {
      map['operator_name'] = Variable<String>(operatorName);
    }
    map['start_reading'] = Variable<int>(startReading);
    if (!nullToAbsent || startPhotoPath != null) {
      map['start_photo_path'] = Variable<String>(startPhotoPath);
    }
    if (!nullToAbsent || startCapturedAt != null) {
      map['start_captured_at'] = Variable<int>(startCapturedAt);
    }
    if (!nullToAbsent || startLat != null) {
      map['start_lat'] = Variable<double>(startLat);
    }
    if (!nullToAbsent || startLng != null) {
      map['start_lng'] = Variable<double>(startLng);
    }
    if (!nullToAbsent || startAccuracy != null) {
      map['start_accuracy'] = Variable<double>(startAccuracy);
    }
    if (!nullToAbsent || startLocationStatus != null) {
      map['start_location_status'] = Variable<String>(startLocationStatus);
    }
    if (!nullToAbsent || endReading != null) {
      map['end_reading'] = Variable<int>(endReading);
    }
    if (!nullToAbsent || endPhotoPath != null) {
      map['end_photo_path'] = Variable<String>(endPhotoPath);
    }
    if (!nullToAbsent || endCapturedAt != null) {
      map['end_captured_at'] = Variable<int>(endCapturedAt);
    }
    if (!nullToAbsent || endLat != null) {
      map['end_lat'] = Variable<double>(endLat);
    }
    if (!nullToAbsent || endLng != null) {
      map['end_lng'] = Variable<double>(endLng);
    }
    if (!nullToAbsent || endAccuracy != null) {
      map['end_accuracy'] = Variable<double>(endAccuracy);
    }
    if (!nullToAbsent || endLocationStatus != null) {
      map['end_location_status'] = Variable<String>(endLocationStatus);
    }
    if (!nullToAbsent || workingHours != null) {
      map['working_hours'] = Variable<int>(workingHours);
    }
    map['entry_mode'] = Variable<String>(entryMode);
    if (!nullToAbsent || manualReason != null) {
      map['manual_reason'] = Variable<String>(manualReason);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || anomalyFlags != null) {
      map['anomaly_flags'] = Variable<String>(anomalyFlags);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || statusReason != null) {
      map['status_reason'] = Variable<String>(statusReason);
    }
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    if (!nullToAbsent || approvedAt != null) {
      map['approved_at'] = Variable<int>(approvedAt);
    }
    if (!nullToAbsent || invoiceId != null) {
      map['invoice_id'] = Variable<String>(invoiceId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['updated_by'] = Variable<String>(updatedBy);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    return map;
  }

  WorkLogsCompanion toCompanion(bool nullToAbsent) {
    return WorkLogsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      workDate: Value(workDate),
      clientId: Value(clientId),
      siteId: Value(siteId),
      machineId: Value(machineId),
      operatorId: operatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(operatorId),
      operatorName: operatorName == null && nullToAbsent
          ? const Value.absent()
          : Value(operatorName),
      startReading: Value(startReading),
      startPhotoPath: startPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(startPhotoPath),
      startCapturedAt: startCapturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startCapturedAt),
      startLat: startLat == null && nullToAbsent
          ? const Value.absent()
          : Value(startLat),
      startLng: startLng == null && nullToAbsent
          ? const Value.absent()
          : Value(startLng),
      startAccuracy: startAccuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(startAccuracy),
      startLocationStatus: startLocationStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(startLocationStatus),
      endReading: endReading == null && nullToAbsent
          ? const Value.absent()
          : Value(endReading),
      endPhotoPath: endPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(endPhotoPath),
      endCapturedAt: endCapturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endCapturedAt),
      endLat: endLat == null && nullToAbsent
          ? const Value.absent()
          : Value(endLat),
      endLng: endLng == null && nullToAbsent
          ? const Value.absent()
          : Value(endLng),
      endAccuracy: endAccuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(endAccuracy),
      endLocationStatus: endLocationStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(endLocationStatus),
      workingHours: workingHours == null && nullToAbsent
          ? const Value.absent()
          : Value(workingHours),
      entryMode: Value(entryMode),
      manualReason: manualReason == null && nullToAbsent
          ? const Value.absent()
          : Value(manualReason),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      anomalyFlags: anomalyFlags == null && nullToAbsent
          ? const Value.absent()
          : Value(anomalyFlags),
      status: Value(status),
      statusReason: statusReason == null && nullToAbsent
          ? const Value.absent()
          : Value(statusReason),
      approvedBy: approvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedBy),
      approvedAt: approvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedAt),
      invoiceId: invoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: Value(createdBy),
      updatedBy: Value(updatedBy),
      syncStatus: Value(syncStatus),
      version: Value(version),
    );
  }

  factory WorkLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkLog(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      workDate: serializer.fromJson<String>(json['workDate']),
      clientId: serializer.fromJson<String>(json['clientId']),
      siteId: serializer.fromJson<String>(json['siteId']),
      machineId: serializer.fromJson<String>(json['machineId']),
      operatorId: serializer.fromJson<String?>(json['operatorId']),
      operatorName: serializer.fromJson<String?>(json['operatorName']),
      startReading: serializer.fromJson<int>(json['startReading']),
      startPhotoPath: serializer.fromJson<String?>(json['startPhotoPath']),
      startCapturedAt: serializer.fromJson<int?>(json['startCapturedAt']),
      startLat: serializer.fromJson<double?>(json['startLat']),
      startLng: serializer.fromJson<double?>(json['startLng']),
      startAccuracy: serializer.fromJson<double?>(json['startAccuracy']),
      startLocationStatus: serializer.fromJson<String?>(
        json['startLocationStatus'],
      ),
      endReading: serializer.fromJson<int?>(json['endReading']),
      endPhotoPath: serializer.fromJson<String?>(json['endPhotoPath']),
      endCapturedAt: serializer.fromJson<int?>(json['endCapturedAt']),
      endLat: serializer.fromJson<double?>(json['endLat']),
      endLng: serializer.fromJson<double?>(json['endLng']),
      endAccuracy: serializer.fromJson<double?>(json['endAccuracy']),
      endLocationStatus: serializer.fromJson<String?>(
        json['endLocationStatus'],
      ),
      workingHours: serializer.fromJson<int?>(json['workingHours']),
      entryMode: serializer.fromJson<String>(json['entryMode']),
      manualReason: serializer.fromJson<String?>(json['manualReason']),
      notes: serializer.fromJson<String?>(json['notes']),
      anomalyFlags: serializer.fromJson<String?>(json['anomalyFlags']),
      status: serializer.fromJson<String>(json['status']),
      statusReason: serializer.fromJson<String?>(json['statusReason']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      approvedAt: serializer.fromJson<int?>(json['approvedAt']),
      invoiceId: serializer.fromJson<String?>(json['invoiceId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'workDate': serializer.toJson<String>(workDate),
      'clientId': serializer.toJson<String>(clientId),
      'siteId': serializer.toJson<String>(siteId),
      'machineId': serializer.toJson<String>(machineId),
      'operatorId': serializer.toJson<String?>(operatorId),
      'operatorName': serializer.toJson<String?>(operatorName),
      'startReading': serializer.toJson<int>(startReading),
      'startPhotoPath': serializer.toJson<String?>(startPhotoPath),
      'startCapturedAt': serializer.toJson<int?>(startCapturedAt),
      'startLat': serializer.toJson<double?>(startLat),
      'startLng': serializer.toJson<double?>(startLng),
      'startAccuracy': serializer.toJson<double?>(startAccuracy),
      'startLocationStatus': serializer.toJson<String?>(startLocationStatus),
      'endReading': serializer.toJson<int?>(endReading),
      'endPhotoPath': serializer.toJson<String?>(endPhotoPath),
      'endCapturedAt': serializer.toJson<int?>(endCapturedAt),
      'endLat': serializer.toJson<double?>(endLat),
      'endLng': serializer.toJson<double?>(endLng),
      'endAccuracy': serializer.toJson<double?>(endAccuracy),
      'endLocationStatus': serializer.toJson<String?>(endLocationStatus),
      'workingHours': serializer.toJson<int?>(workingHours),
      'entryMode': serializer.toJson<String>(entryMode),
      'manualReason': serializer.toJson<String?>(manualReason),
      'notes': serializer.toJson<String?>(notes),
      'anomalyFlags': serializer.toJson<String?>(anomalyFlags),
      'status': serializer.toJson<String>(status),
      'statusReason': serializer.toJson<String?>(statusReason),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'approvedAt': serializer.toJson<int?>(approvedAt),
      'invoiceId': serializer.toJson<String?>(invoiceId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
    };
  }

  WorkLog copyWith({
    String? id,
    String? companyId,
    String? workDate,
    String? clientId,
    String? siteId,
    String? machineId,
    Value<String?> operatorId = const Value.absent(),
    Value<String?> operatorName = const Value.absent(),
    int? startReading,
    Value<String?> startPhotoPath = const Value.absent(),
    Value<int?> startCapturedAt = const Value.absent(),
    Value<double?> startLat = const Value.absent(),
    Value<double?> startLng = const Value.absent(),
    Value<double?> startAccuracy = const Value.absent(),
    Value<String?> startLocationStatus = const Value.absent(),
    Value<int?> endReading = const Value.absent(),
    Value<String?> endPhotoPath = const Value.absent(),
    Value<int?> endCapturedAt = const Value.absent(),
    Value<double?> endLat = const Value.absent(),
    Value<double?> endLng = const Value.absent(),
    Value<double?> endAccuracy = const Value.absent(),
    Value<String?> endLocationStatus = const Value.absent(),
    Value<int?> workingHours = const Value.absent(),
    String? entryMode,
    Value<String?> manualReason = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> anomalyFlags = const Value.absent(),
    String? status,
    Value<String?> statusReason = const Value.absent(),
    Value<String?> approvedBy = const Value.absent(),
    Value<int?> approvedAt = const Value.absent(),
    Value<String?> invoiceId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? createdBy,
    String? updatedBy,
    String? syncStatus,
    int? version,
  }) => WorkLog(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    workDate: workDate ?? this.workDate,
    clientId: clientId ?? this.clientId,
    siteId: siteId ?? this.siteId,
    machineId: machineId ?? this.machineId,
    operatorId: operatorId.present ? operatorId.value : this.operatorId,
    operatorName: operatorName.present ? operatorName.value : this.operatorName,
    startReading: startReading ?? this.startReading,
    startPhotoPath: startPhotoPath.present
        ? startPhotoPath.value
        : this.startPhotoPath,
    startCapturedAt: startCapturedAt.present
        ? startCapturedAt.value
        : this.startCapturedAt,
    startLat: startLat.present ? startLat.value : this.startLat,
    startLng: startLng.present ? startLng.value : this.startLng,
    startAccuracy: startAccuracy.present
        ? startAccuracy.value
        : this.startAccuracy,
    startLocationStatus: startLocationStatus.present
        ? startLocationStatus.value
        : this.startLocationStatus,
    endReading: endReading.present ? endReading.value : this.endReading,
    endPhotoPath: endPhotoPath.present ? endPhotoPath.value : this.endPhotoPath,
    endCapturedAt: endCapturedAt.present
        ? endCapturedAt.value
        : this.endCapturedAt,
    endLat: endLat.present ? endLat.value : this.endLat,
    endLng: endLng.present ? endLng.value : this.endLng,
    endAccuracy: endAccuracy.present ? endAccuracy.value : this.endAccuracy,
    endLocationStatus: endLocationStatus.present
        ? endLocationStatus.value
        : this.endLocationStatus,
    workingHours: workingHours.present ? workingHours.value : this.workingHours,
    entryMode: entryMode ?? this.entryMode,
    manualReason: manualReason.present ? manualReason.value : this.manualReason,
    notes: notes.present ? notes.value : this.notes,
    anomalyFlags: anomalyFlags.present ? anomalyFlags.value : this.anomalyFlags,
    status: status ?? this.status,
    statusReason: statusReason.present ? statusReason.value : this.statusReason,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    approvedAt: approvedAt.present ? approvedAt.value : this.approvedAt,
    invoiceId: invoiceId.present ? invoiceId.value : this.invoiceId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
  );
  WorkLog copyWithCompanion(WorkLogsCompanion data) {
    return WorkLog(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      workDate: data.workDate.present ? data.workDate.value : this.workDate,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      operatorId: data.operatorId.present
          ? data.operatorId.value
          : this.operatorId,
      operatorName: data.operatorName.present
          ? data.operatorName.value
          : this.operatorName,
      startReading: data.startReading.present
          ? data.startReading.value
          : this.startReading,
      startPhotoPath: data.startPhotoPath.present
          ? data.startPhotoPath.value
          : this.startPhotoPath,
      startCapturedAt: data.startCapturedAt.present
          ? data.startCapturedAt.value
          : this.startCapturedAt,
      startLat: data.startLat.present ? data.startLat.value : this.startLat,
      startLng: data.startLng.present ? data.startLng.value : this.startLng,
      startAccuracy: data.startAccuracy.present
          ? data.startAccuracy.value
          : this.startAccuracy,
      startLocationStatus: data.startLocationStatus.present
          ? data.startLocationStatus.value
          : this.startLocationStatus,
      endReading: data.endReading.present
          ? data.endReading.value
          : this.endReading,
      endPhotoPath: data.endPhotoPath.present
          ? data.endPhotoPath.value
          : this.endPhotoPath,
      endCapturedAt: data.endCapturedAt.present
          ? data.endCapturedAt.value
          : this.endCapturedAt,
      endLat: data.endLat.present ? data.endLat.value : this.endLat,
      endLng: data.endLng.present ? data.endLng.value : this.endLng,
      endAccuracy: data.endAccuracy.present
          ? data.endAccuracy.value
          : this.endAccuracy,
      endLocationStatus: data.endLocationStatus.present
          ? data.endLocationStatus.value
          : this.endLocationStatus,
      workingHours: data.workingHours.present
          ? data.workingHours.value
          : this.workingHours,
      entryMode: data.entryMode.present ? data.entryMode.value : this.entryMode,
      manualReason: data.manualReason.present
          ? data.manualReason.value
          : this.manualReason,
      notes: data.notes.present ? data.notes.value : this.notes,
      anomalyFlags: data.anomalyFlags.present
          ? data.anomalyFlags.value
          : this.anomalyFlags,
      status: data.status.present ? data.status.value : this.status,
      statusReason: data.statusReason.present
          ? data.statusReason.value
          : this.statusReason,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
      approvedAt: data.approvedAt.present
          ? data.approvedAt.value
          : this.approvedAt,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkLog(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('workDate: $workDate, ')
          ..write('clientId: $clientId, ')
          ..write('siteId: $siteId, ')
          ..write('machineId: $machineId, ')
          ..write('operatorId: $operatorId, ')
          ..write('operatorName: $operatorName, ')
          ..write('startReading: $startReading, ')
          ..write('startPhotoPath: $startPhotoPath, ')
          ..write('startCapturedAt: $startCapturedAt, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('startAccuracy: $startAccuracy, ')
          ..write('startLocationStatus: $startLocationStatus, ')
          ..write('endReading: $endReading, ')
          ..write('endPhotoPath: $endPhotoPath, ')
          ..write('endCapturedAt: $endCapturedAt, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('endAccuracy: $endAccuracy, ')
          ..write('endLocationStatus: $endLocationStatus, ')
          ..write('workingHours: $workingHours, ')
          ..write('entryMode: $entryMode, ')
          ..write('manualReason: $manualReason, ')
          ..write('notes: $notes, ')
          ..write('anomalyFlags: $anomalyFlags, ')
          ..write('status: $status, ')
          ..write('statusReason: $statusReason, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    companyId,
    workDate,
    clientId,
    siteId,
    machineId,
    operatorId,
    operatorName,
    startReading,
    startPhotoPath,
    startCapturedAt,
    startLat,
    startLng,
    startAccuracy,
    startLocationStatus,
    endReading,
    endPhotoPath,
    endCapturedAt,
    endLat,
    endLng,
    endAccuracy,
    endLocationStatus,
    workingHours,
    entryMode,
    manualReason,
    notes,
    anomalyFlags,
    status,
    statusReason,
    approvedBy,
    approvedAt,
    invoiceId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkLog &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.workDate == this.workDate &&
          other.clientId == this.clientId &&
          other.siteId == this.siteId &&
          other.machineId == this.machineId &&
          other.operatorId == this.operatorId &&
          other.operatorName == this.operatorName &&
          other.startReading == this.startReading &&
          other.startPhotoPath == this.startPhotoPath &&
          other.startCapturedAt == this.startCapturedAt &&
          other.startLat == this.startLat &&
          other.startLng == this.startLng &&
          other.startAccuracy == this.startAccuracy &&
          other.startLocationStatus == this.startLocationStatus &&
          other.endReading == this.endReading &&
          other.endPhotoPath == this.endPhotoPath &&
          other.endCapturedAt == this.endCapturedAt &&
          other.endLat == this.endLat &&
          other.endLng == this.endLng &&
          other.endAccuracy == this.endAccuracy &&
          other.endLocationStatus == this.endLocationStatus &&
          other.workingHours == this.workingHours &&
          other.entryMode == this.entryMode &&
          other.manualReason == this.manualReason &&
          other.notes == this.notes &&
          other.anomalyFlags == this.anomalyFlags &&
          other.status == this.status &&
          other.statusReason == this.statusReason &&
          other.approvedBy == this.approvedBy &&
          other.approvedAt == this.approvedAt &&
          other.invoiceId == this.invoiceId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version);
}

class WorkLogsCompanion extends UpdateCompanion<WorkLog> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> workDate;
  final Value<String> clientId;
  final Value<String> siteId;
  final Value<String> machineId;
  final Value<String?> operatorId;
  final Value<String?> operatorName;
  final Value<int> startReading;
  final Value<String?> startPhotoPath;
  final Value<int?> startCapturedAt;
  final Value<double?> startLat;
  final Value<double?> startLng;
  final Value<double?> startAccuracy;
  final Value<String?> startLocationStatus;
  final Value<int?> endReading;
  final Value<String?> endPhotoPath;
  final Value<int?> endCapturedAt;
  final Value<double?> endLat;
  final Value<double?> endLng;
  final Value<double?> endAccuracy;
  final Value<String?> endLocationStatus;
  final Value<int?> workingHours;
  final Value<String> entryMode;
  final Value<String?> manualReason;
  final Value<String?> notes;
  final Value<String?> anomalyFlags;
  final Value<String> status;
  final Value<String?> statusReason;
  final Value<String?> approvedBy;
  final Value<int?> approvedAt;
  final Value<String?> invoiceId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> createdBy;
  final Value<String> updatedBy;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<int> rowid;
  const WorkLogsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.workDate = const Value.absent(),
    this.clientId = const Value.absent(),
    this.siteId = const Value.absent(),
    this.machineId = const Value.absent(),
    this.operatorId = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.startReading = const Value.absent(),
    this.startPhotoPath = const Value.absent(),
    this.startCapturedAt = const Value.absent(),
    this.startLat = const Value.absent(),
    this.startLng = const Value.absent(),
    this.startAccuracy = const Value.absent(),
    this.startLocationStatus = const Value.absent(),
    this.endReading = const Value.absent(),
    this.endPhotoPath = const Value.absent(),
    this.endCapturedAt = const Value.absent(),
    this.endLat = const Value.absent(),
    this.endLng = const Value.absent(),
    this.endAccuracy = const Value.absent(),
    this.endLocationStatus = const Value.absent(),
    this.workingHours = const Value.absent(),
    this.entryMode = const Value.absent(),
    this.manualReason = const Value.absent(),
    this.notes = const Value.absent(),
    this.anomalyFlags = const Value.absent(),
    this.status = const Value.absent(),
    this.statusReason = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkLogsCompanion.insert({
    required String id,
    required String companyId,
    required String workDate,
    required String clientId,
    required String siteId,
    required String machineId,
    this.operatorId = const Value.absent(),
    this.operatorName = const Value.absent(),
    required int startReading,
    this.startPhotoPath = const Value.absent(),
    this.startCapturedAt = const Value.absent(),
    this.startLat = const Value.absent(),
    this.startLng = const Value.absent(),
    this.startAccuracy = const Value.absent(),
    this.startLocationStatus = const Value.absent(),
    this.endReading = const Value.absent(),
    this.endPhotoPath = const Value.absent(),
    this.endCapturedAt = const Value.absent(),
    this.endLat = const Value.absent(),
    this.endLng = const Value.absent(),
    this.endAccuracy = const Value.absent(),
    this.endLocationStatus = const Value.absent(),
    this.workingHours = const Value.absent(),
    required String entryMode,
    this.manualReason = const Value.absent(),
    this.notes = const Value.absent(),
    this.anomalyFlags = const Value.absent(),
    required String status,
    this.statusReason = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.invoiceId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String createdBy,
    required String updatedBy,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       workDate = Value(workDate),
       clientId = Value(clientId),
       siteId = Value(siteId),
       machineId = Value(machineId),
       startReading = Value(startReading),
       entryMode = Value(entryMode),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy),
       updatedBy = Value(updatedBy);
  static Insertable<WorkLog> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? workDate,
    Expression<String>? clientId,
    Expression<String>? siteId,
    Expression<String>? machineId,
    Expression<String>? operatorId,
    Expression<String>? operatorName,
    Expression<int>? startReading,
    Expression<String>? startPhotoPath,
    Expression<int>? startCapturedAt,
    Expression<double>? startLat,
    Expression<double>? startLng,
    Expression<double>? startAccuracy,
    Expression<String>? startLocationStatus,
    Expression<int>? endReading,
    Expression<String>? endPhotoPath,
    Expression<int>? endCapturedAt,
    Expression<double>? endLat,
    Expression<double>? endLng,
    Expression<double>? endAccuracy,
    Expression<String>? endLocationStatus,
    Expression<int>? workingHours,
    Expression<String>? entryMode,
    Expression<String>? manualReason,
    Expression<String>? notes,
    Expression<String>? anomalyFlags,
    Expression<String>? status,
    Expression<String>? statusReason,
    Expression<String>? approvedBy,
    Expression<int>? approvedAt,
    Expression<String>? invoiceId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (workDate != null) 'work_date': workDate,
      if (clientId != null) 'client_id': clientId,
      if (siteId != null) 'site_id': siteId,
      if (machineId != null) 'machine_id': machineId,
      if (operatorId != null) 'operator_id': operatorId,
      if (operatorName != null) 'operator_name': operatorName,
      if (startReading != null) 'start_reading': startReading,
      if (startPhotoPath != null) 'start_photo_path': startPhotoPath,
      if (startCapturedAt != null) 'start_captured_at': startCapturedAt,
      if (startLat != null) 'start_lat': startLat,
      if (startLng != null) 'start_lng': startLng,
      if (startAccuracy != null) 'start_accuracy': startAccuracy,
      if (startLocationStatus != null)
        'start_location_status': startLocationStatus,
      if (endReading != null) 'end_reading': endReading,
      if (endPhotoPath != null) 'end_photo_path': endPhotoPath,
      if (endCapturedAt != null) 'end_captured_at': endCapturedAt,
      if (endLat != null) 'end_lat': endLat,
      if (endLng != null) 'end_lng': endLng,
      if (endAccuracy != null) 'end_accuracy': endAccuracy,
      if (endLocationStatus != null) 'end_location_status': endLocationStatus,
      if (workingHours != null) 'working_hours': workingHours,
      if (entryMode != null) 'entry_mode': entryMode,
      if (manualReason != null) 'manual_reason': manualReason,
      if (notes != null) 'notes': notes,
      if (anomalyFlags != null) 'anomaly_flags': anomalyFlags,
      if (status != null) 'status': status,
      if (statusReason != null) 'status_reason': statusReason,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? workDate,
    Value<String>? clientId,
    Value<String>? siteId,
    Value<String>? machineId,
    Value<String?>? operatorId,
    Value<String?>? operatorName,
    Value<int>? startReading,
    Value<String?>? startPhotoPath,
    Value<int?>? startCapturedAt,
    Value<double?>? startLat,
    Value<double?>? startLng,
    Value<double?>? startAccuracy,
    Value<String?>? startLocationStatus,
    Value<int?>? endReading,
    Value<String?>? endPhotoPath,
    Value<int?>? endCapturedAt,
    Value<double?>? endLat,
    Value<double?>? endLng,
    Value<double?>? endAccuracy,
    Value<String?>? endLocationStatus,
    Value<int?>? workingHours,
    Value<String>? entryMode,
    Value<String?>? manualReason,
    Value<String?>? notes,
    Value<String?>? anomalyFlags,
    Value<String>? status,
    Value<String?>? statusReason,
    Value<String?>? approvedBy,
    Value<int?>? approvedAt,
    Value<String?>? invoiceId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? createdBy,
    Value<String>? updatedBy,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return WorkLogsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      workDate: workDate ?? this.workDate,
      clientId: clientId ?? this.clientId,
      siteId: siteId ?? this.siteId,
      machineId: machineId ?? this.machineId,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      startReading: startReading ?? this.startReading,
      startPhotoPath: startPhotoPath ?? this.startPhotoPath,
      startCapturedAt: startCapturedAt ?? this.startCapturedAt,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      startAccuracy: startAccuracy ?? this.startAccuracy,
      startLocationStatus: startLocationStatus ?? this.startLocationStatus,
      endReading: endReading ?? this.endReading,
      endPhotoPath: endPhotoPath ?? this.endPhotoPath,
      endCapturedAt: endCapturedAt ?? this.endCapturedAt,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      endAccuracy: endAccuracy ?? this.endAccuracy,
      endLocationStatus: endLocationStatus ?? this.endLocationStatus,
      workingHours: workingHours ?? this.workingHours,
      entryMode: entryMode ?? this.entryMode,
      manualReason: manualReason ?? this.manualReason,
      notes: notes ?? this.notes,
      anomalyFlags: anomalyFlags ?? this.anomalyFlags,
      status: status ?? this.status,
      statusReason: statusReason ?? this.statusReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      invoiceId: invoiceId ?? this.invoiceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (workDate.present) {
      map['work_date'] = Variable<String>(workDate.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (machineId.present) {
      map['machine_id'] = Variable<String>(machineId.value);
    }
    if (operatorId.present) {
      map['operator_id'] = Variable<String>(operatorId.value);
    }
    if (operatorName.present) {
      map['operator_name'] = Variable<String>(operatorName.value);
    }
    if (startReading.present) {
      map['start_reading'] = Variable<int>(startReading.value);
    }
    if (startPhotoPath.present) {
      map['start_photo_path'] = Variable<String>(startPhotoPath.value);
    }
    if (startCapturedAt.present) {
      map['start_captured_at'] = Variable<int>(startCapturedAt.value);
    }
    if (startLat.present) {
      map['start_lat'] = Variable<double>(startLat.value);
    }
    if (startLng.present) {
      map['start_lng'] = Variable<double>(startLng.value);
    }
    if (startAccuracy.present) {
      map['start_accuracy'] = Variable<double>(startAccuracy.value);
    }
    if (startLocationStatus.present) {
      map['start_location_status'] = Variable<String>(
        startLocationStatus.value,
      );
    }
    if (endReading.present) {
      map['end_reading'] = Variable<int>(endReading.value);
    }
    if (endPhotoPath.present) {
      map['end_photo_path'] = Variable<String>(endPhotoPath.value);
    }
    if (endCapturedAt.present) {
      map['end_captured_at'] = Variable<int>(endCapturedAt.value);
    }
    if (endLat.present) {
      map['end_lat'] = Variable<double>(endLat.value);
    }
    if (endLng.present) {
      map['end_lng'] = Variable<double>(endLng.value);
    }
    if (endAccuracy.present) {
      map['end_accuracy'] = Variable<double>(endAccuracy.value);
    }
    if (endLocationStatus.present) {
      map['end_location_status'] = Variable<String>(endLocationStatus.value);
    }
    if (workingHours.present) {
      map['working_hours'] = Variable<int>(workingHours.value);
    }
    if (entryMode.present) {
      map['entry_mode'] = Variable<String>(entryMode.value);
    }
    if (manualReason.present) {
      map['manual_reason'] = Variable<String>(manualReason.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (anomalyFlags.present) {
      map['anomaly_flags'] = Variable<String>(anomalyFlags.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (statusReason.present) {
      map['status_reason'] = Variable<String>(statusReason.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<int>(approvedAt.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkLogsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('workDate: $workDate, ')
          ..write('clientId: $clientId, ')
          ..write('siteId: $siteId, ')
          ..write('machineId: $machineId, ')
          ..write('operatorId: $operatorId, ')
          ..write('operatorName: $operatorName, ')
          ..write('startReading: $startReading, ')
          ..write('startPhotoPath: $startPhotoPath, ')
          ..write('startCapturedAt: $startCapturedAt, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('startAccuracy: $startAccuracy, ')
          ..write('startLocationStatus: $startLocationStatus, ')
          ..write('endReading: $endReading, ')
          ..write('endPhotoPath: $endPhotoPath, ')
          ..write('endCapturedAt: $endCapturedAt, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('endAccuracy: $endAccuracy, ')
          ..write('endLocationStatus: $endLocationStatus, ')
          ..write('workingHours: $workingHours, ')
          ..write('entryMode: $entryMode, ')
          ..write('manualReason: $manualReason, ')
          ..write('notes: $notes, ')
          ..write('anomalyFlags: $anomalyFlags, ')
          ..write('status: $status, ')
          ..write('statusReason: $statusReason, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FuelEntriesTable extends FuelEntries
    with TableInfo<$FuelEntriesTable, FuelEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FuelEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filledAtMeta = const VerificationMeta(
    'filledAt',
  );
  @override
  late final GeneratedColumn<int> filledAt = GeneratedColumn<int>(
    'filled_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fuelDateMeta = const VerificationMeta(
    'fuelDate',
  );
  @override
  late final GeneratedColumn<String> fuelDate = GeneratedColumn<String>(
    'fuel_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _machineIdMeta = const VerificationMeta(
    'machineId',
  );
  @override
  late final GeneratedColumn<String> machineId = GeneratedColumn<String>(
    'machine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES machines (id)',
    ),
  );
  static const VerificationMeta _pumpIdMeta = const VerificationMeta('pumpId');
  @override
  late final GeneratedColumn<String> pumpId = GeneratedColumn<String>(
    'pump_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES petrol_pumps (id)',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clients (id)',
    ),
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sites (id)',
    ),
  );
  static const VerificationMeta _litresClMeta = const VerificationMeta(
    'litresCl',
  );
  @override
  late final GeneratedColumn<int> litresCl = GeneratedColumn<int>(
    'litres_cl',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerLitrePaiseMeta =
      const VerificationMeta('pricePerLitrePaise');
  @override
  late final GeneratedColumn<int> pricePerLitrePaise = GeneratedColumn<int>(
    'price_per_litre_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPaiseMeta = const VerificationMeta(
    'totalPaise',
  );
  @override
  late final GeneratedColumn<int> totalPaise = GeneratedColumn<int>(
    'total_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptPhotoPathMeta = const VerificationMeta(
    'receiptPhotoPath',
  );
  @override
  late final GeneratedColumn<String> receiptPhotoPath = GeneratedColumn<String>(
    'receipt_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptCapturedAtMeta = const VerificationMeta(
    'receiptCapturedAt',
  );
  @override
  late final GeneratedColumn<int> receiptCapturedAt = GeneratedColumn<int>(
    'receipt_captured_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptLatMeta = const VerificationMeta(
    'receiptLat',
  );
  @override
  late final GeneratedColumn<double> receiptLat = GeneratedColumn<double>(
    'receipt_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptLngMeta = const VerificationMeta(
    'receiptLng',
  );
  @override
  late final GeneratedColumn<double> receiptLng = GeneratedColumn<double>(
    'receipt_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptAccuracyMeta = const VerificationMeta(
    'receiptAccuracy',
  );
  @override
  late final GeneratedColumn<double> receiptAccuracy = GeneratedColumn<double>(
    'receipt_accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptLocationStatusMeta =
      const VerificationMeta('receiptLocationStatus');
  @override
  late final GeneratedColumn<String> receiptLocationStatus =
      GeneratedColumn<String>(
        'receipt_location_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    filledAt,
    fuelDate,
    machineId,
    pumpId,
    clientId,
    siteId,
    litresCl,
    pricePerLitrePaise,
    totalPaise,
    receiptPhotoPath,
    receiptCapturedAt,
    receiptLat,
    receiptLng,
    receiptAccuracy,
    receiptLocationStatus,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fuel_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FuelEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('filled_at')) {
      context.handle(
        _filledAtMeta,
        filledAt.isAcceptableOrUnknown(data['filled_at']!, _filledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_filledAtMeta);
    }
    if (data.containsKey('fuel_date')) {
      context.handle(
        _fuelDateMeta,
        fuelDate.isAcceptableOrUnknown(data['fuel_date']!, _fuelDateMeta),
      );
    } else if (isInserting) {
      context.missing(_fuelDateMeta);
    }
    if (data.containsKey('machine_id')) {
      context.handle(
        _machineIdMeta,
        machineId.isAcceptableOrUnknown(data['machine_id']!, _machineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_machineIdMeta);
    }
    if (data.containsKey('pump_id')) {
      context.handle(
        _pumpIdMeta,
        pumpId.isAcceptableOrUnknown(data['pump_id']!, _pumpIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pumpIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    }
    if (data.containsKey('litres_cl')) {
      context.handle(
        _litresClMeta,
        litresCl.isAcceptableOrUnknown(data['litres_cl']!, _litresClMeta),
      );
    } else if (isInserting) {
      context.missing(_litresClMeta);
    }
    if (data.containsKey('price_per_litre_paise')) {
      context.handle(
        _pricePerLitrePaiseMeta,
        pricePerLitrePaise.isAcceptableOrUnknown(
          data['price_per_litre_paise']!,
          _pricePerLitrePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerLitrePaiseMeta);
    }
    if (data.containsKey('total_paise')) {
      context.handle(
        _totalPaiseMeta,
        totalPaise.isAcceptableOrUnknown(data['total_paise']!, _totalPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPaiseMeta);
    }
    if (data.containsKey('receipt_photo_path')) {
      context.handle(
        _receiptPhotoPathMeta,
        receiptPhotoPath.isAcceptableOrUnknown(
          data['receipt_photo_path']!,
          _receiptPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('receipt_captured_at')) {
      context.handle(
        _receiptCapturedAtMeta,
        receiptCapturedAt.isAcceptableOrUnknown(
          data['receipt_captured_at']!,
          _receiptCapturedAtMeta,
        ),
      );
    }
    if (data.containsKey('receipt_lat')) {
      context.handle(
        _receiptLatMeta,
        receiptLat.isAcceptableOrUnknown(data['receipt_lat']!, _receiptLatMeta),
      );
    }
    if (data.containsKey('receipt_lng')) {
      context.handle(
        _receiptLngMeta,
        receiptLng.isAcceptableOrUnknown(data['receipt_lng']!, _receiptLngMeta),
      );
    }
    if (data.containsKey('receipt_accuracy')) {
      context.handle(
        _receiptAccuracyMeta,
        receiptAccuracy.isAcceptableOrUnknown(
          data['receipt_accuracy']!,
          _receiptAccuracyMeta,
        ),
      );
    }
    if (data.containsKey('receipt_location_status')) {
      context.handle(
        _receiptLocationStatusMeta,
        receiptLocationStatus.isAcceptableOrUnknown(
          data['receipt_location_status']!,
          _receiptLocationStatusMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FuelEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FuelEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      filledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}filled_at'],
      )!,
      fuelDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_date'],
      )!,
      machineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_id'],
      )!,
      pumpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pump_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      ),
      litresCl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}litres_cl'],
      )!,
      pricePerLitrePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_per_litre_paise'],
      )!,
      totalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_paise'],
      )!,
      receiptPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_photo_path'],
      ),
      receiptCapturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_captured_at'],
      ),
      receiptLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}receipt_lat'],
      ),
      receiptLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}receipt_lng'],
      ),
      receiptAccuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}receipt_accuracy'],
      ),
      receiptLocationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_location_status'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $FuelEntriesTable createAlias(String alias) {
    return $FuelEntriesTable(attachedDatabase, alias);
  }
}

class FuelEntry extends DataClass implements Insertable<FuelEntry> {
  final String id;
  final String companyId;

  /// When fuel was filled, UTC epoch ms.
  final int filledAt;

  /// Local calendar date of [filledAt], `yyyy-MM-dd` (for grouping/reports).
  final String fuelDate;
  final String machineId;
  final String pumpId;
  final String? clientId;
  final String? siteId;
  final int litresCl;
  final int pricePerLitrePaise;
  final int totalPaise;

  /// Receipt photo, relative to the app documents directory; device-only.
  final String? receiptPhotoPath;
  final int? receiptCapturedAt;
  final double? receiptLat;
  final double? receiptLng;
  final double? receiptAccuracy;
  final String? receiptLocationStatus;
  final String? notes;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String createdBy;
  final String updatedBy;
  final String syncStatus;
  final int version;
  const FuelEntry({
    required this.id,
    required this.companyId,
    required this.filledAt,
    required this.fuelDate,
    required this.machineId,
    required this.pumpId,
    this.clientId,
    this.siteId,
    required this.litresCl,
    required this.pricePerLitrePaise,
    required this.totalPaise,
    this.receiptPhotoPath,
    this.receiptCapturedAt,
    this.receiptLat,
    this.receiptLng,
    this.receiptAccuracy,
    this.receiptLocationStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncStatus,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['filled_at'] = Variable<int>(filledAt);
    map['fuel_date'] = Variable<String>(fuelDate);
    map['machine_id'] = Variable<String>(machineId);
    map['pump_id'] = Variable<String>(pumpId);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || siteId != null) {
      map['site_id'] = Variable<String>(siteId);
    }
    map['litres_cl'] = Variable<int>(litresCl);
    map['price_per_litre_paise'] = Variable<int>(pricePerLitrePaise);
    map['total_paise'] = Variable<int>(totalPaise);
    if (!nullToAbsent || receiptPhotoPath != null) {
      map['receipt_photo_path'] = Variable<String>(receiptPhotoPath);
    }
    if (!nullToAbsent || receiptCapturedAt != null) {
      map['receipt_captured_at'] = Variable<int>(receiptCapturedAt);
    }
    if (!nullToAbsent || receiptLat != null) {
      map['receipt_lat'] = Variable<double>(receiptLat);
    }
    if (!nullToAbsent || receiptLng != null) {
      map['receipt_lng'] = Variable<double>(receiptLng);
    }
    if (!nullToAbsent || receiptAccuracy != null) {
      map['receipt_accuracy'] = Variable<double>(receiptAccuracy);
    }
    if (!nullToAbsent || receiptLocationStatus != null) {
      map['receipt_location_status'] = Variable<String>(receiptLocationStatus);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['updated_by'] = Variable<String>(updatedBy);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    return map;
  }

  FuelEntriesCompanion toCompanion(bool nullToAbsent) {
    return FuelEntriesCompanion(
      id: Value(id),
      companyId: Value(companyId),
      filledAt: Value(filledAt),
      fuelDate: Value(fuelDate),
      machineId: Value(machineId),
      pumpId: Value(pumpId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      siteId: siteId == null && nullToAbsent
          ? const Value.absent()
          : Value(siteId),
      litresCl: Value(litresCl),
      pricePerLitrePaise: Value(pricePerLitrePaise),
      totalPaise: Value(totalPaise),
      receiptPhotoPath: receiptPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptPhotoPath),
      receiptCapturedAt: receiptCapturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptCapturedAt),
      receiptLat: receiptLat == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptLat),
      receiptLng: receiptLng == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptLng),
      receiptAccuracy: receiptAccuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptAccuracy),
      receiptLocationStatus: receiptLocationStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptLocationStatus),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: Value(createdBy),
      updatedBy: Value(updatedBy),
      syncStatus: Value(syncStatus),
      version: Value(version),
    );
  }

  factory FuelEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FuelEntry(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      filledAt: serializer.fromJson<int>(json['filledAt']),
      fuelDate: serializer.fromJson<String>(json['fuelDate']),
      machineId: serializer.fromJson<String>(json['machineId']),
      pumpId: serializer.fromJson<String>(json['pumpId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      siteId: serializer.fromJson<String?>(json['siteId']),
      litresCl: serializer.fromJson<int>(json['litresCl']),
      pricePerLitrePaise: serializer.fromJson<int>(json['pricePerLitrePaise']),
      totalPaise: serializer.fromJson<int>(json['totalPaise']),
      receiptPhotoPath: serializer.fromJson<String?>(json['receiptPhotoPath']),
      receiptCapturedAt: serializer.fromJson<int?>(json['receiptCapturedAt']),
      receiptLat: serializer.fromJson<double?>(json['receiptLat']),
      receiptLng: serializer.fromJson<double?>(json['receiptLng']),
      receiptAccuracy: serializer.fromJson<double?>(json['receiptAccuracy']),
      receiptLocationStatus: serializer.fromJson<String?>(
        json['receiptLocationStatus'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'filledAt': serializer.toJson<int>(filledAt),
      'fuelDate': serializer.toJson<String>(fuelDate),
      'machineId': serializer.toJson<String>(machineId),
      'pumpId': serializer.toJson<String>(pumpId),
      'clientId': serializer.toJson<String?>(clientId),
      'siteId': serializer.toJson<String?>(siteId),
      'litresCl': serializer.toJson<int>(litresCl),
      'pricePerLitrePaise': serializer.toJson<int>(pricePerLitrePaise),
      'totalPaise': serializer.toJson<int>(totalPaise),
      'receiptPhotoPath': serializer.toJson<String?>(receiptPhotoPath),
      'receiptCapturedAt': serializer.toJson<int?>(receiptCapturedAt),
      'receiptLat': serializer.toJson<double?>(receiptLat),
      'receiptLng': serializer.toJson<double?>(receiptLng),
      'receiptAccuracy': serializer.toJson<double?>(receiptAccuracy),
      'receiptLocationStatus': serializer.toJson<String?>(
        receiptLocationStatus,
      ),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
    };
  }

  FuelEntry copyWith({
    String? id,
    String? companyId,
    int? filledAt,
    String? fuelDate,
    String? machineId,
    String? pumpId,
    Value<String?> clientId = const Value.absent(),
    Value<String?> siteId = const Value.absent(),
    int? litresCl,
    int? pricePerLitrePaise,
    int? totalPaise,
    Value<String?> receiptPhotoPath = const Value.absent(),
    Value<int?> receiptCapturedAt = const Value.absent(),
    Value<double?> receiptLat = const Value.absent(),
    Value<double?> receiptLng = const Value.absent(),
    Value<double?> receiptAccuracy = const Value.absent(),
    Value<String?> receiptLocationStatus = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? createdBy,
    String? updatedBy,
    String? syncStatus,
    int? version,
  }) => FuelEntry(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    filledAt: filledAt ?? this.filledAt,
    fuelDate: fuelDate ?? this.fuelDate,
    machineId: machineId ?? this.machineId,
    pumpId: pumpId ?? this.pumpId,
    clientId: clientId.present ? clientId.value : this.clientId,
    siteId: siteId.present ? siteId.value : this.siteId,
    litresCl: litresCl ?? this.litresCl,
    pricePerLitrePaise: pricePerLitrePaise ?? this.pricePerLitrePaise,
    totalPaise: totalPaise ?? this.totalPaise,
    receiptPhotoPath: receiptPhotoPath.present
        ? receiptPhotoPath.value
        : this.receiptPhotoPath,
    receiptCapturedAt: receiptCapturedAt.present
        ? receiptCapturedAt.value
        : this.receiptCapturedAt,
    receiptLat: receiptLat.present ? receiptLat.value : this.receiptLat,
    receiptLng: receiptLng.present ? receiptLng.value : this.receiptLng,
    receiptAccuracy: receiptAccuracy.present
        ? receiptAccuracy.value
        : this.receiptAccuracy,
    receiptLocationStatus: receiptLocationStatus.present
        ? receiptLocationStatus.value
        : this.receiptLocationStatus,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
  );
  FuelEntry copyWithCompanion(FuelEntriesCompanion data) {
    return FuelEntry(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      filledAt: data.filledAt.present ? data.filledAt.value : this.filledAt,
      fuelDate: data.fuelDate.present ? data.fuelDate.value : this.fuelDate,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      pumpId: data.pumpId.present ? data.pumpId.value : this.pumpId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      litresCl: data.litresCl.present ? data.litresCl.value : this.litresCl,
      pricePerLitrePaise: data.pricePerLitrePaise.present
          ? data.pricePerLitrePaise.value
          : this.pricePerLitrePaise,
      totalPaise: data.totalPaise.present
          ? data.totalPaise.value
          : this.totalPaise,
      receiptPhotoPath: data.receiptPhotoPath.present
          ? data.receiptPhotoPath.value
          : this.receiptPhotoPath,
      receiptCapturedAt: data.receiptCapturedAt.present
          ? data.receiptCapturedAt.value
          : this.receiptCapturedAt,
      receiptLat: data.receiptLat.present
          ? data.receiptLat.value
          : this.receiptLat,
      receiptLng: data.receiptLng.present
          ? data.receiptLng.value
          : this.receiptLng,
      receiptAccuracy: data.receiptAccuracy.present
          ? data.receiptAccuracy.value
          : this.receiptAccuracy,
      receiptLocationStatus: data.receiptLocationStatus.present
          ? data.receiptLocationStatus.value
          : this.receiptLocationStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FuelEntry(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('filledAt: $filledAt, ')
          ..write('fuelDate: $fuelDate, ')
          ..write('machineId: $machineId, ')
          ..write('pumpId: $pumpId, ')
          ..write('clientId: $clientId, ')
          ..write('siteId: $siteId, ')
          ..write('litresCl: $litresCl, ')
          ..write('pricePerLitrePaise: $pricePerLitrePaise, ')
          ..write('totalPaise: $totalPaise, ')
          ..write('receiptPhotoPath: $receiptPhotoPath, ')
          ..write('receiptCapturedAt: $receiptCapturedAt, ')
          ..write('receiptLat: $receiptLat, ')
          ..write('receiptLng: $receiptLng, ')
          ..write('receiptAccuracy: $receiptAccuracy, ')
          ..write('receiptLocationStatus: $receiptLocationStatus, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    companyId,
    filledAt,
    fuelDate,
    machineId,
    pumpId,
    clientId,
    siteId,
    litresCl,
    pricePerLitrePaise,
    totalPaise,
    receiptPhotoPath,
    receiptCapturedAt,
    receiptLat,
    receiptLng,
    receiptAccuracy,
    receiptLocationStatus,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelEntry &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.filledAt == this.filledAt &&
          other.fuelDate == this.fuelDate &&
          other.machineId == this.machineId &&
          other.pumpId == this.pumpId &&
          other.clientId == this.clientId &&
          other.siteId == this.siteId &&
          other.litresCl == this.litresCl &&
          other.pricePerLitrePaise == this.pricePerLitrePaise &&
          other.totalPaise == this.totalPaise &&
          other.receiptPhotoPath == this.receiptPhotoPath &&
          other.receiptCapturedAt == this.receiptCapturedAt &&
          other.receiptLat == this.receiptLat &&
          other.receiptLng == this.receiptLng &&
          other.receiptAccuracy == this.receiptAccuracy &&
          other.receiptLocationStatus == this.receiptLocationStatus &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version);
}

class FuelEntriesCompanion extends UpdateCompanion<FuelEntry> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<int> filledAt;
  final Value<String> fuelDate;
  final Value<String> machineId;
  final Value<String> pumpId;
  final Value<String?> clientId;
  final Value<String?> siteId;
  final Value<int> litresCl;
  final Value<int> pricePerLitrePaise;
  final Value<int> totalPaise;
  final Value<String?> receiptPhotoPath;
  final Value<int?> receiptCapturedAt;
  final Value<double?> receiptLat;
  final Value<double?> receiptLng;
  final Value<double?> receiptAccuracy;
  final Value<String?> receiptLocationStatus;
  final Value<String?> notes;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> createdBy;
  final Value<String> updatedBy;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<int> rowid;
  const FuelEntriesCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.filledAt = const Value.absent(),
    this.fuelDate = const Value.absent(),
    this.machineId = const Value.absent(),
    this.pumpId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.siteId = const Value.absent(),
    this.litresCl = const Value.absent(),
    this.pricePerLitrePaise = const Value.absent(),
    this.totalPaise = const Value.absent(),
    this.receiptPhotoPath = const Value.absent(),
    this.receiptCapturedAt = const Value.absent(),
    this.receiptLat = const Value.absent(),
    this.receiptLng = const Value.absent(),
    this.receiptAccuracy = const Value.absent(),
    this.receiptLocationStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FuelEntriesCompanion.insert({
    required String id,
    required String companyId,
    required int filledAt,
    required String fuelDate,
    required String machineId,
    required String pumpId,
    this.clientId = const Value.absent(),
    this.siteId = const Value.absent(),
    required int litresCl,
    required int pricePerLitrePaise,
    required int totalPaise,
    this.receiptPhotoPath = const Value.absent(),
    this.receiptCapturedAt = const Value.absent(),
    this.receiptLat = const Value.absent(),
    this.receiptLng = const Value.absent(),
    this.receiptAccuracy = const Value.absent(),
    this.receiptLocationStatus = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String createdBy,
    required String updatedBy,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       filledAt = Value(filledAt),
       fuelDate = Value(fuelDate),
       machineId = Value(machineId),
       pumpId = Value(pumpId),
       litresCl = Value(litresCl),
       pricePerLitrePaise = Value(pricePerLitrePaise),
       totalPaise = Value(totalPaise),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy),
       updatedBy = Value(updatedBy);
  static Insertable<FuelEntry> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<int>? filledAt,
    Expression<String>? fuelDate,
    Expression<String>? machineId,
    Expression<String>? pumpId,
    Expression<String>? clientId,
    Expression<String>? siteId,
    Expression<int>? litresCl,
    Expression<int>? pricePerLitrePaise,
    Expression<int>? totalPaise,
    Expression<String>? receiptPhotoPath,
    Expression<int>? receiptCapturedAt,
    Expression<double>? receiptLat,
    Expression<double>? receiptLng,
    Expression<double>? receiptAccuracy,
    Expression<String>? receiptLocationStatus,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (filledAt != null) 'filled_at': filledAt,
      if (fuelDate != null) 'fuel_date': fuelDate,
      if (machineId != null) 'machine_id': machineId,
      if (pumpId != null) 'pump_id': pumpId,
      if (clientId != null) 'client_id': clientId,
      if (siteId != null) 'site_id': siteId,
      if (litresCl != null) 'litres_cl': litresCl,
      if (pricePerLitrePaise != null)
        'price_per_litre_paise': pricePerLitrePaise,
      if (totalPaise != null) 'total_paise': totalPaise,
      if (receiptPhotoPath != null) 'receipt_photo_path': receiptPhotoPath,
      if (receiptCapturedAt != null) 'receipt_captured_at': receiptCapturedAt,
      if (receiptLat != null) 'receipt_lat': receiptLat,
      if (receiptLng != null) 'receipt_lng': receiptLng,
      if (receiptAccuracy != null) 'receipt_accuracy': receiptAccuracy,
      if (receiptLocationStatus != null)
        'receipt_location_status': receiptLocationStatus,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FuelEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<int>? filledAt,
    Value<String>? fuelDate,
    Value<String>? machineId,
    Value<String>? pumpId,
    Value<String?>? clientId,
    Value<String?>? siteId,
    Value<int>? litresCl,
    Value<int>? pricePerLitrePaise,
    Value<int>? totalPaise,
    Value<String?>? receiptPhotoPath,
    Value<int?>? receiptCapturedAt,
    Value<double?>? receiptLat,
    Value<double?>? receiptLng,
    Value<double?>? receiptAccuracy,
    Value<String?>? receiptLocationStatus,
    Value<String?>? notes,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? createdBy,
    Value<String>? updatedBy,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return FuelEntriesCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      filledAt: filledAt ?? this.filledAt,
      fuelDate: fuelDate ?? this.fuelDate,
      machineId: machineId ?? this.machineId,
      pumpId: pumpId ?? this.pumpId,
      clientId: clientId ?? this.clientId,
      siteId: siteId ?? this.siteId,
      litresCl: litresCl ?? this.litresCl,
      pricePerLitrePaise: pricePerLitrePaise ?? this.pricePerLitrePaise,
      totalPaise: totalPaise ?? this.totalPaise,
      receiptPhotoPath: receiptPhotoPath ?? this.receiptPhotoPath,
      receiptCapturedAt: receiptCapturedAt ?? this.receiptCapturedAt,
      receiptLat: receiptLat ?? this.receiptLat,
      receiptLng: receiptLng ?? this.receiptLng,
      receiptAccuracy: receiptAccuracy ?? this.receiptAccuracy,
      receiptLocationStatus:
          receiptLocationStatus ?? this.receiptLocationStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (filledAt.present) {
      map['filled_at'] = Variable<int>(filledAt.value);
    }
    if (fuelDate.present) {
      map['fuel_date'] = Variable<String>(fuelDate.value);
    }
    if (machineId.present) {
      map['machine_id'] = Variable<String>(machineId.value);
    }
    if (pumpId.present) {
      map['pump_id'] = Variable<String>(pumpId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (litresCl.present) {
      map['litres_cl'] = Variable<int>(litresCl.value);
    }
    if (pricePerLitrePaise.present) {
      map['price_per_litre_paise'] = Variable<int>(pricePerLitrePaise.value);
    }
    if (totalPaise.present) {
      map['total_paise'] = Variable<int>(totalPaise.value);
    }
    if (receiptPhotoPath.present) {
      map['receipt_photo_path'] = Variable<String>(receiptPhotoPath.value);
    }
    if (receiptCapturedAt.present) {
      map['receipt_captured_at'] = Variable<int>(receiptCapturedAt.value);
    }
    if (receiptLat.present) {
      map['receipt_lat'] = Variable<double>(receiptLat.value);
    }
    if (receiptLng.present) {
      map['receipt_lng'] = Variable<double>(receiptLng.value);
    }
    if (receiptAccuracy.present) {
      map['receipt_accuracy'] = Variable<double>(receiptAccuracy.value);
    }
    if (receiptLocationStatus.present) {
      map['receipt_location_status'] = Variable<String>(
        receiptLocationStatus.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FuelEntriesCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('filledAt: $filledAt, ')
          ..write('fuelDate: $fuelDate, ')
          ..write('machineId: $machineId, ')
          ..write('pumpId: $pumpId, ')
          ..write('clientId: $clientId, ')
          ..write('siteId: $siteId, ')
          ..write('litresCl: $litresCl, ')
          ..write('pricePerLitrePaise: $pricePerLitrePaise, ')
          ..write('totalPaise: $totalPaise, ')
          ..write('receiptPhotoPath: $receiptPhotoPath, ')
          ..write('receiptCapturedAt: $receiptCapturedAt, ')
          ..write('receiptLat: $receiptLat, ')
          ..write('receiptLng: $receiptLng, ')
          ..write('receiptAccuracy: $receiptAccuracy, ')
          ..write('receiptLocationStatus: $receiptLocationStatus, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices with TableInfo<$InvoicesTable, Invoice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clients (id)',
    ),
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceDateMeta = const VerificationMeta(
    'invoiceDate',
  );
  @override
  late final GeneratedColumn<String> invoiceDate = GeneratedColumn<String>(
    'invoice_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodFromMeta = const VerificationMeta(
    'periodFrom',
  );
  @override
  late final GeneratedColumn<String> periodFrom = GeneratedColumn<String>(
    'period_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodToMeta = const VerificationMeta(
    'periodTo',
  );
  @override
  late final GeneratedColumn<String> periodTo = GeneratedColumn<String>(
    'period_to',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentTermsDaysMeta = const VerificationMeta(
    'paymentTermsDays',
  );
  @override
  late final GeneratedColumn<int> paymentTermsDays = GeneratedColumn<int>(
    'payment_terms_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalPaiseMeta = const VerificationMeta(
    'subtotalPaise',
  );
  @override
  late final GeneratedColumn<int> subtotalPaise = GeneratedColumn<int>(
    'subtotal_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountPaiseMeta = const VerificationMeta(
    'discountPaise',
  );
  @override
  late final GeneratedColumn<int> discountPaise = GeneratedColumn<int>(
    'discount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPaiseMeta = const VerificationMeta(
    'totalPaise',
  );
  @override
  late final GeneratedColumn<int> totalPaise = GeneratedColumn<int>(
    'total_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companySnapshotMeta = const VerificationMeta(
    'companySnapshot',
  );
  @override
  late final GeneratedColumn<String> companySnapshot = GeneratedColumn<String>(
    'company_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientSnapshotMeta = const VerificationMeta(
    'clientSnapshot',
  );
  @override
  late final GeneratedColumn<String> clientSnapshot = GeneratedColumn<String>(
    'client_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalizedAtMeta = const VerificationMeta(
    'finalizedAt',
  );
  @override
  late final GeneratedColumn<int> finalizedAt = GeneratedColumn<int>(
    'finalized_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalizedByMeta = const VerificationMeta(
    'finalizedBy',
  );
  @override
  late final GeneratedColumn<String> finalizedBy = GeneratedColumn<String>(
    'finalized_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelledAtMeta = const VerificationMeta(
    'cancelledAt',
  );
  @override
  late final GeneratedColumn<int> cancelledAt = GeneratedColumn<int>(
    'cancelled_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelledByMeta = const VerificationMeta(
    'cancelledBy',
  );
  @override
  late final GeneratedColumn<String> cancelledBy = GeneratedColumn<String>(
    'cancelled_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelReasonMeta = const VerificationMeta(
    'cancelReason',
  );
  @override
  late final GeneratedColumn<String> cancelReason = GeneratedColumn<String>(
    'cancel_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfPathMeta = const VerificationMeta(
    'pdfPath',
  );
  @override
  late final GeneratedColumn<String> pdfPath = GeneratedColumn<String>(
    'pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    clientId,
    invoiceNumber,
    status,
    invoiceDate,
    periodFrom,
    periodTo,
    paymentTermsDays,
    dueDate,
    notes,
    subtotalPaise,
    discountPaise,
    totalPaise,
    companySnapshot,
    clientSnapshot,
    finalizedAt,
    finalizedBy,
    cancelledAt,
    cancelledBy,
    cancelReason,
    pdfPath,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Invoice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('invoice_date')) {
      context.handle(
        _invoiceDateMeta,
        invoiceDate.isAcceptableOrUnknown(
          data['invoice_date']!,
          _invoiceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceDateMeta);
    }
    if (data.containsKey('period_from')) {
      context.handle(
        _periodFromMeta,
        periodFrom.isAcceptableOrUnknown(data['period_from']!, _periodFromMeta),
      );
    } else if (isInserting) {
      context.missing(_periodFromMeta);
    }
    if (data.containsKey('period_to')) {
      context.handle(
        _periodToMeta,
        periodTo.isAcceptableOrUnknown(data['period_to']!, _periodToMeta),
      );
    } else if (isInserting) {
      context.missing(_periodToMeta);
    }
    if (data.containsKey('payment_terms_days')) {
      context.handle(
        _paymentTermsDaysMeta,
        paymentTermsDays.isAcceptableOrUnknown(
          data['payment_terms_days']!,
          _paymentTermsDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentTermsDaysMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('subtotal_paise')) {
      context.handle(
        _subtotalPaiseMeta,
        subtotalPaise.isAcceptableOrUnknown(
          data['subtotal_paise']!,
          _subtotalPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subtotalPaiseMeta);
    }
    if (data.containsKey('discount_paise')) {
      context.handle(
        _discountPaiseMeta,
        discountPaise.isAcceptableOrUnknown(
          data['discount_paise']!,
          _discountPaiseMeta,
        ),
      );
    }
    if (data.containsKey('total_paise')) {
      context.handle(
        _totalPaiseMeta,
        totalPaise.isAcceptableOrUnknown(data['total_paise']!, _totalPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPaiseMeta);
    }
    if (data.containsKey('company_snapshot')) {
      context.handle(
        _companySnapshotMeta,
        companySnapshot.isAcceptableOrUnknown(
          data['company_snapshot']!,
          _companySnapshotMeta,
        ),
      );
    }
    if (data.containsKey('client_snapshot')) {
      context.handle(
        _clientSnapshotMeta,
        clientSnapshot.isAcceptableOrUnknown(
          data['client_snapshot']!,
          _clientSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('finalized_at')) {
      context.handle(
        _finalizedAtMeta,
        finalizedAt.isAcceptableOrUnknown(
          data['finalized_at']!,
          _finalizedAtMeta,
        ),
      );
    }
    if (data.containsKey('finalized_by')) {
      context.handle(
        _finalizedByMeta,
        finalizedBy.isAcceptableOrUnknown(
          data['finalized_by']!,
          _finalizedByMeta,
        ),
      );
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(
        _cancelledAtMeta,
        cancelledAt.isAcceptableOrUnknown(
          data['cancelled_at']!,
          _cancelledAtMeta,
        ),
      );
    }
    if (data.containsKey('cancelled_by')) {
      context.handle(
        _cancelledByMeta,
        cancelledBy.isAcceptableOrUnknown(
          data['cancelled_by']!,
          _cancelledByMeta,
        ),
      );
    }
    if (data.containsKey('cancel_reason')) {
      context.handle(
        _cancelReasonMeta,
        cancelReason.isAcceptableOrUnknown(
          data['cancel_reason']!,
          _cancelReasonMeta,
        ),
      );
    }
    if (data.containsKey('pdf_path')) {
      context.handle(
        _pdfPathMeta,
        pdfPath.isAcceptableOrUnknown(data['pdf_path']!, _pdfPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invoice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invoice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      invoiceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_date'],
      )!,
      periodFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_from'],
      )!,
      periodTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_to'],
      )!,
      paymentTermsDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_terms_days'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      subtotalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_paise'],
      )!,
      discountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_paise'],
      )!,
      totalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_paise'],
      )!,
      companySnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_snapshot'],
      ),
      clientSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_snapshot'],
      ),
      finalizedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finalized_at'],
      ),
      finalizedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finalized_by'],
      ),
      cancelledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cancelled_at'],
      ),
      cancelledBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancelled_by'],
      ),
      cancelReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancel_reason'],
      ),
      pdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class Invoice extends DataClass implements Insertable<Invoice> {
  final String id;
  final String companyId;
  final String clientId;

  /// Official number, issued by the server when finalized.
  final String? invoiceNumber;

  /// draft, finalized, cancelled. Payment state is derived from payments.
  final String status;
  final String invoiceDate;
  final String periodFrom;
  final String periodTo;
  final int paymentTermsDays;
  final String dueDate;
  final String? notes;
  final int subtotalPaise;
  final int discountPaise;
  final int totalPaise;

  /// JSON snapshots captured at finalization.
  final String? companySnapshot;
  final String? clientSnapshot;
  final int? finalizedAt;
  final String? finalizedBy;
  final int? cancelledAt;
  final String? cancelledBy;
  final String? cancelReason;

  /// Last generated PDF, relative to the documents directory; device-only.
  final String? pdfPath;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final String createdBy;
  final String updatedBy;
  final String syncStatus;
  final int version;
  const Invoice({
    required this.id,
    required this.companyId,
    required this.clientId,
    this.invoiceNumber,
    required this.status,
    required this.invoiceDate,
    required this.periodFrom,
    required this.periodTo,
    required this.paymentTermsDays,
    required this.dueDate,
    this.notes,
    required this.subtotalPaise,
    required this.discountPaise,
    required this.totalPaise,
    this.companySnapshot,
    this.clientSnapshot,
    this.finalizedAt,
    this.finalizedBy,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason,
    this.pdfPath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncStatus,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    map['status'] = Variable<String>(status);
    map['invoice_date'] = Variable<String>(invoiceDate);
    map['period_from'] = Variable<String>(periodFrom);
    map['period_to'] = Variable<String>(periodTo);
    map['payment_terms_days'] = Variable<int>(paymentTermsDays);
    map['due_date'] = Variable<String>(dueDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['subtotal_paise'] = Variable<int>(subtotalPaise);
    map['discount_paise'] = Variable<int>(discountPaise);
    map['total_paise'] = Variable<int>(totalPaise);
    if (!nullToAbsent || companySnapshot != null) {
      map['company_snapshot'] = Variable<String>(companySnapshot);
    }
    if (!nullToAbsent || clientSnapshot != null) {
      map['client_snapshot'] = Variable<String>(clientSnapshot);
    }
    if (!nullToAbsent || finalizedAt != null) {
      map['finalized_at'] = Variable<int>(finalizedAt);
    }
    if (!nullToAbsent || finalizedBy != null) {
      map['finalized_by'] = Variable<String>(finalizedBy);
    }
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<int>(cancelledAt);
    }
    if (!nullToAbsent || cancelledBy != null) {
      map['cancelled_by'] = Variable<String>(cancelledBy);
    }
    if (!nullToAbsent || cancelReason != null) {
      map['cancel_reason'] = Variable<String>(cancelReason);
    }
    if (!nullToAbsent || pdfPath != null) {
      map['pdf_path'] = Variable<String>(pdfPath);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['updated_by'] = Variable<String>(updatedBy);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      companyId: Value(companyId),
      clientId: Value(clientId),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      status: Value(status),
      invoiceDate: Value(invoiceDate),
      periodFrom: Value(periodFrom),
      periodTo: Value(periodTo),
      paymentTermsDays: Value(paymentTermsDays),
      dueDate: Value(dueDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      subtotalPaise: Value(subtotalPaise),
      discountPaise: Value(discountPaise),
      totalPaise: Value(totalPaise),
      companySnapshot: companySnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(companySnapshot),
      clientSnapshot: clientSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(clientSnapshot),
      finalizedAt: finalizedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finalizedAt),
      finalizedBy: finalizedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(finalizedBy),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
      cancelledBy: cancelledBy == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledBy),
      cancelReason: cancelReason == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelReason),
      pdfPath: pdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: Value(createdBy),
      updatedBy: Value(updatedBy),
      syncStatus: Value(syncStatus),
      version: Value(version),
    );
  }

  factory Invoice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invoice(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      status: serializer.fromJson<String>(json['status']),
      invoiceDate: serializer.fromJson<String>(json['invoiceDate']),
      periodFrom: serializer.fromJson<String>(json['periodFrom']),
      periodTo: serializer.fromJson<String>(json['periodTo']),
      paymentTermsDays: serializer.fromJson<int>(json['paymentTermsDays']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      subtotalPaise: serializer.fromJson<int>(json['subtotalPaise']),
      discountPaise: serializer.fromJson<int>(json['discountPaise']),
      totalPaise: serializer.fromJson<int>(json['totalPaise']),
      companySnapshot: serializer.fromJson<String?>(json['companySnapshot']),
      clientSnapshot: serializer.fromJson<String?>(json['clientSnapshot']),
      finalizedAt: serializer.fromJson<int?>(json['finalizedAt']),
      finalizedBy: serializer.fromJson<String?>(json['finalizedBy']),
      cancelledAt: serializer.fromJson<int?>(json['cancelledAt']),
      cancelledBy: serializer.fromJson<String?>(json['cancelledBy']),
      cancelReason: serializer.fromJson<String?>(json['cancelReason']),
      pdfPath: serializer.fromJson<String?>(json['pdfPath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'clientId': serializer.toJson<String>(clientId),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'status': serializer.toJson<String>(status),
      'invoiceDate': serializer.toJson<String>(invoiceDate),
      'periodFrom': serializer.toJson<String>(periodFrom),
      'periodTo': serializer.toJson<String>(periodTo),
      'paymentTermsDays': serializer.toJson<int>(paymentTermsDays),
      'dueDate': serializer.toJson<String>(dueDate),
      'notes': serializer.toJson<String?>(notes),
      'subtotalPaise': serializer.toJson<int>(subtotalPaise),
      'discountPaise': serializer.toJson<int>(discountPaise),
      'totalPaise': serializer.toJson<int>(totalPaise),
      'companySnapshot': serializer.toJson<String?>(companySnapshot),
      'clientSnapshot': serializer.toJson<String?>(clientSnapshot),
      'finalizedAt': serializer.toJson<int?>(finalizedAt),
      'finalizedBy': serializer.toJson<String?>(finalizedBy),
      'cancelledAt': serializer.toJson<int?>(cancelledAt),
      'cancelledBy': serializer.toJson<String?>(cancelledBy),
      'cancelReason': serializer.toJson<String?>(cancelReason),
      'pdfPath': serializer.toJson<String?>(pdfPath),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
    };
  }

  Invoice copyWith({
    String? id,
    String? companyId,
    String? clientId,
    Value<String?> invoiceNumber = const Value.absent(),
    String? status,
    String? invoiceDate,
    String? periodFrom,
    String? periodTo,
    int? paymentTermsDays,
    String? dueDate,
    Value<String?> notes = const Value.absent(),
    int? subtotalPaise,
    int? discountPaise,
    int? totalPaise,
    Value<String?> companySnapshot = const Value.absent(),
    Value<String?> clientSnapshot = const Value.absent(),
    Value<int?> finalizedAt = const Value.absent(),
    Value<String?> finalizedBy = const Value.absent(),
    Value<int?> cancelledAt = const Value.absent(),
    Value<String?> cancelledBy = const Value.absent(),
    Value<String?> cancelReason = const Value.absent(),
    Value<String?> pdfPath = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? createdBy,
    String? updatedBy,
    String? syncStatus,
    int? version,
  }) => Invoice(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    clientId: clientId ?? this.clientId,
    invoiceNumber: invoiceNumber.present
        ? invoiceNumber.value
        : this.invoiceNumber,
    status: status ?? this.status,
    invoiceDate: invoiceDate ?? this.invoiceDate,
    periodFrom: periodFrom ?? this.periodFrom,
    periodTo: periodTo ?? this.periodTo,
    paymentTermsDays: paymentTermsDays ?? this.paymentTermsDays,
    dueDate: dueDate ?? this.dueDate,
    notes: notes.present ? notes.value : this.notes,
    subtotalPaise: subtotalPaise ?? this.subtotalPaise,
    discountPaise: discountPaise ?? this.discountPaise,
    totalPaise: totalPaise ?? this.totalPaise,
    companySnapshot: companySnapshot.present
        ? companySnapshot.value
        : this.companySnapshot,
    clientSnapshot: clientSnapshot.present
        ? clientSnapshot.value
        : this.clientSnapshot,
    finalizedAt: finalizedAt.present ? finalizedAt.value : this.finalizedAt,
    finalizedBy: finalizedBy.present ? finalizedBy.value : this.finalizedBy,
    cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
    cancelledBy: cancelledBy.present ? cancelledBy.value : this.cancelledBy,
    cancelReason: cancelReason.present ? cancelReason.value : this.cancelReason,
    pdfPath: pdfPath.present ? pdfPath.value : this.pdfPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
  );
  Invoice copyWithCompanion(InvoicesCompanion data) {
    return Invoice(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      status: data.status.present ? data.status.value : this.status,
      invoiceDate: data.invoiceDate.present
          ? data.invoiceDate.value
          : this.invoiceDate,
      periodFrom: data.periodFrom.present
          ? data.periodFrom.value
          : this.periodFrom,
      periodTo: data.periodTo.present ? data.periodTo.value : this.periodTo,
      paymentTermsDays: data.paymentTermsDays.present
          ? data.paymentTermsDays.value
          : this.paymentTermsDays,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      subtotalPaise: data.subtotalPaise.present
          ? data.subtotalPaise.value
          : this.subtotalPaise,
      discountPaise: data.discountPaise.present
          ? data.discountPaise.value
          : this.discountPaise,
      totalPaise: data.totalPaise.present
          ? data.totalPaise.value
          : this.totalPaise,
      companySnapshot: data.companySnapshot.present
          ? data.companySnapshot.value
          : this.companySnapshot,
      clientSnapshot: data.clientSnapshot.present
          ? data.clientSnapshot.value
          : this.clientSnapshot,
      finalizedAt: data.finalizedAt.present
          ? data.finalizedAt.value
          : this.finalizedAt,
      finalizedBy: data.finalizedBy.present
          ? data.finalizedBy.value
          : this.finalizedBy,
      cancelledAt: data.cancelledAt.present
          ? data.cancelledAt.value
          : this.cancelledAt,
      cancelledBy: data.cancelledBy.present
          ? data.cancelledBy.value
          : this.cancelledBy,
      cancelReason: data.cancelReason.present
          ? data.cancelReason.value
          : this.cancelReason,
      pdfPath: data.pdfPath.present ? data.pdfPath.value : this.pdfPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invoice(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('clientId: $clientId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('status: $status, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('periodFrom: $periodFrom, ')
          ..write('periodTo: $periodTo, ')
          ..write('paymentTermsDays: $paymentTermsDays, ')
          ..write('dueDate: $dueDate, ')
          ..write('notes: $notes, ')
          ..write('subtotalPaise: $subtotalPaise, ')
          ..write('discountPaise: $discountPaise, ')
          ..write('totalPaise: $totalPaise, ')
          ..write('companySnapshot: $companySnapshot, ')
          ..write('clientSnapshot: $clientSnapshot, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('finalizedBy: $finalizedBy, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('cancelledBy: $cancelledBy, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    companyId,
    clientId,
    invoiceNumber,
    status,
    invoiceDate,
    periodFrom,
    periodTo,
    paymentTermsDays,
    dueDate,
    notes,
    subtotalPaise,
    discountPaise,
    totalPaise,
    companySnapshot,
    clientSnapshot,
    finalizedAt,
    finalizedBy,
    cancelledAt,
    cancelledBy,
    cancelReason,
    pdfPath,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invoice &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.clientId == this.clientId &&
          other.invoiceNumber == this.invoiceNumber &&
          other.status == this.status &&
          other.invoiceDate == this.invoiceDate &&
          other.periodFrom == this.periodFrom &&
          other.periodTo == this.periodTo &&
          other.paymentTermsDays == this.paymentTermsDays &&
          other.dueDate == this.dueDate &&
          other.notes == this.notes &&
          other.subtotalPaise == this.subtotalPaise &&
          other.discountPaise == this.discountPaise &&
          other.totalPaise == this.totalPaise &&
          other.companySnapshot == this.companySnapshot &&
          other.clientSnapshot == this.clientSnapshot &&
          other.finalizedAt == this.finalizedAt &&
          other.finalizedBy == this.finalizedBy &&
          other.cancelledAt == this.cancelledAt &&
          other.cancelledBy == this.cancelledBy &&
          other.cancelReason == this.cancelReason &&
          other.pdfPath == this.pdfPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version);
}

class InvoicesCompanion extends UpdateCompanion<Invoice> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> clientId;
  final Value<String?> invoiceNumber;
  final Value<String> status;
  final Value<String> invoiceDate;
  final Value<String> periodFrom;
  final Value<String> periodTo;
  final Value<int> paymentTermsDays;
  final Value<String> dueDate;
  final Value<String?> notes;
  final Value<int> subtotalPaise;
  final Value<int> discountPaise;
  final Value<int> totalPaise;
  final Value<String?> companySnapshot;
  final Value<String?> clientSnapshot;
  final Value<int?> finalizedAt;
  final Value<String?> finalizedBy;
  final Value<int?> cancelledAt;
  final Value<String?> cancelledBy;
  final Value<String?> cancelReason;
  final Value<String?> pdfPath;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> createdBy;
  final Value<String> updatedBy;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<int> rowid;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.invoiceDate = const Value.absent(),
    this.periodFrom = const Value.absent(),
    this.periodTo = const Value.absent(),
    this.paymentTermsDays = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.subtotalPaise = const Value.absent(),
    this.discountPaise = const Value.absent(),
    this.totalPaise = const Value.absent(),
    this.companySnapshot = const Value.absent(),
    this.clientSnapshot = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    this.finalizedBy = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.cancelledBy = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesCompanion.insert({
    required String id,
    required String companyId,
    required String clientId,
    this.invoiceNumber = const Value.absent(),
    required String status,
    required String invoiceDate,
    required String periodFrom,
    required String periodTo,
    required int paymentTermsDays,
    required String dueDate,
    this.notes = const Value.absent(),
    required int subtotalPaise,
    this.discountPaise = const Value.absent(),
    required int totalPaise,
    this.companySnapshot = const Value.absent(),
    this.clientSnapshot = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    this.finalizedBy = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.cancelledBy = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.pdfPath = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String createdBy,
    required String updatedBy,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       clientId = Value(clientId),
       status = Value(status),
       invoiceDate = Value(invoiceDate),
       periodFrom = Value(periodFrom),
       periodTo = Value(periodTo),
       paymentTermsDays = Value(paymentTermsDays),
       dueDate = Value(dueDate),
       subtotalPaise = Value(subtotalPaise),
       totalPaise = Value(totalPaise),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy),
       updatedBy = Value(updatedBy);
  static Insertable<Invoice> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? clientId,
    Expression<String>? invoiceNumber,
    Expression<String>? status,
    Expression<String>? invoiceDate,
    Expression<String>? periodFrom,
    Expression<String>? periodTo,
    Expression<int>? paymentTermsDays,
    Expression<String>? dueDate,
    Expression<String>? notes,
    Expression<int>? subtotalPaise,
    Expression<int>? discountPaise,
    Expression<int>? totalPaise,
    Expression<String>? companySnapshot,
    Expression<String>? clientSnapshot,
    Expression<int>? finalizedAt,
    Expression<String>? finalizedBy,
    Expression<int>? cancelledAt,
    Expression<String>? cancelledBy,
    Expression<String>? cancelReason,
    Expression<String>? pdfPath,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (clientId != null) 'client_id': clientId,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (status != null) 'status': status,
      if (invoiceDate != null) 'invoice_date': invoiceDate,
      if (periodFrom != null) 'period_from': periodFrom,
      if (periodTo != null) 'period_to': periodTo,
      if (paymentTermsDays != null) 'payment_terms_days': paymentTermsDays,
      if (dueDate != null) 'due_date': dueDate,
      if (notes != null) 'notes': notes,
      if (subtotalPaise != null) 'subtotal_paise': subtotalPaise,
      if (discountPaise != null) 'discount_paise': discountPaise,
      if (totalPaise != null) 'total_paise': totalPaise,
      if (companySnapshot != null) 'company_snapshot': companySnapshot,
      if (clientSnapshot != null) 'client_snapshot': clientSnapshot,
      if (finalizedAt != null) 'finalized_at': finalizedAt,
      if (finalizedBy != null) 'finalized_by': finalizedBy,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (cancelledBy != null) 'cancelled_by': cancelledBy,
      if (cancelReason != null) 'cancel_reason': cancelReason,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? clientId,
    Value<String?>? invoiceNumber,
    Value<String>? status,
    Value<String>? invoiceDate,
    Value<String>? periodFrom,
    Value<String>? periodTo,
    Value<int>? paymentTermsDays,
    Value<String>? dueDate,
    Value<String?>? notes,
    Value<int>? subtotalPaise,
    Value<int>? discountPaise,
    Value<int>? totalPaise,
    Value<String?>? companySnapshot,
    Value<String?>? clientSnapshot,
    Value<int?>? finalizedAt,
    Value<String?>? finalizedBy,
    Value<int?>? cancelledAt,
    Value<String?>? cancelledBy,
    Value<String?>? cancelReason,
    Value<String?>? pdfPath,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? createdBy,
    Value<String>? updatedBy,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return InvoicesCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      clientId: clientId ?? this.clientId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      status: status ?? this.status,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      periodFrom: periodFrom ?? this.periodFrom,
      periodTo: periodTo ?? this.periodTo,
      paymentTermsDays: paymentTermsDays ?? this.paymentTermsDays,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
      discountPaise: discountPaise ?? this.discountPaise,
      totalPaise: totalPaise ?? this.totalPaise,
      companySnapshot: companySnapshot ?? this.companySnapshot,
      clientSnapshot: clientSnapshot ?? this.clientSnapshot,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      finalizedBy: finalizedBy ?? this.finalizedBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelReason: cancelReason ?? this.cancelReason,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (invoiceDate.present) {
      map['invoice_date'] = Variable<String>(invoiceDate.value);
    }
    if (periodFrom.present) {
      map['period_from'] = Variable<String>(periodFrom.value);
    }
    if (periodTo.present) {
      map['period_to'] = Variable<String>(periodTo.value);
    }
    if (paymentTermsDays.present) {
      map['payment_terms_days'] = Variable<int>(paymentTermsDays.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (subtotalPaise.present) {
      map['subtotal_paise'] = Variable<int>(subtotalPaise.value);
    }
    if (discountPaise.present) {
      map['discount_paise'] = Variable<int>(discountPaise.value);
    }
    if (totalPaise.present) {
      map['total_paise'] = Variable<int>(totalPaise.value);
    }
    if (companySnapshot.present) {
      map['company_snapshot'] = Variable<String>(companySnapshot.value);
    }
    if (clientSnapshot.present) {
      map['client_snapshot'] = Variable<String>(clientSnapshot.value);
    }
    if (finalizedAt.present) {
      map['finalized_at'] = Variable<int>(finalizedAt.value);
    }
    if (finalizedBy.present) {
      map['finalized_by'] = Variable<String>(finalizedBy.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<int>(cancelledAt.value);
    }
    if (cancelledBy.present) {
      map['cancelled_by'] = Variable<String>(cancelledBy.value);
    }
    if (cancelReason.present) {
      map['cancel_reason'] = Variable<String>(cancelReason.value);
    }
    if (pdfPath.present) {
      map['pdf_path'] = Variable<String>(pdfPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('clientId: $clientId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('status: $status, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('periodFrom: $periodFrom, ')
          ..write('periodTo: $periodTo, ')
          ..write('paymentTermsDays: $paymentTermsDays, ')
          ..write('dueDate: $dueDate, ')
          ..write('notes: $notes, ')
          ..write('subtotalPaise: $subtotalPaise, ')
          ..write('discountPaise: $discountPaise, ')
          ..write('totalPaise: $totalPaise, ')
          ..write('companySnapshot: $companySnapshot, ')
          ..write('clientSnapshot: $clientSnapshot, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('finalizedBy: $finalizedBy, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('cancelledBy: $cancelledBy, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoiceLinesTable extends InvoiceLines
    with TableInfo<$InvoiceLinesTable, InvoiceLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id)',
    ),
  );
  static const VerificationMeta _workLogIdMeta = const VerificationMeta(
    'workLogId',
  );
  @override
  late final GeneratedColumn<String> workLogId = GeneratedColumn<String>(
    'work_log_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES work_logs (id)',
    ),
  );
  static const VerificationMeta _workDateMeta = const VerificationMeta(
    'workDate',
  );
  @override
  late final GeneratedColumn<String> workDate = GeneratedColumn<String>(
    'work_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteNameMeta = const VerificationMeta(
    'siteName',
  );
  @override
  late final GeneratedColumn<String> siteName = GeneratedColumn<String>(
    'site_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _machineIdMeta = const VerificationMeta(
    'machineId',
  );
  @override
  late final GeneratedColumn<String> machineId = GeneratedColumn<String>(
    'machine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _machineNameMeta = const VerificationMeta(
    'machineName',
  );
  @override
  late final GeneratedColumn<String> machineName = GeneratedColumn<String>(
    'machine_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startReadingMeta = const VerificationMeta(
    'startReading',
  );
  @override
  late final GeneratedColumn<int> startReading = GeneratedColumn<int>(
    'start_reading',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endReadingMeta = const VerificationMeta(
    'endReading',
  );
  @override
  late final GeneratedColumn<int> endReading = GeneratedColumn<int>(
    'end_reading',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workingHoursMeta = const VerificationMeta(
    'workingHours',
  );
  @override
  late final GeneratedColumn<int> workingHours = GeneratedColumn<int>(
    'working_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratePaiseMeta = const VerificationMeta(
    'ratePaise',
  );
  @override
  late final GeneratedColumn<int> ratePaise = GeneratedColumn<int>(
    'rate_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    invoiceId,
    workLogId,
    workDate,
    siteId,
    siteName,
    machineId,
    machineName,
    startReading,
    endReading,
    workingHours,
    ratePaise,
    amountPaise,
    description,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('work_log_id')) {
      context.handle(
        _workLogIdMeta,
        workLogId.isAcceptableOrUnknown(data['work_log_id']!, _workLogIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workLogIdMeta);
    }
    if (data.containsKey('work_date')) {
      context.handle(
        _workDateMeta,
        workDate.isAcceptableOrUnknown(data['work_date']!, _workDateMeta),
      );
    } else if (isInserting) {
      context.missing(_workDateMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('site_name')) {
      context.handle(
        _siteNameMeta,
        siteName.isAcceptableOrUnknown(data['site_name']!, _siteNameMeta),
      );
    } else if (isInserting) {
      context.missing(_siteNameMeta);
    }
    if (data.containsKey('machine_id')) {
      context.handle(
        _machineIdMeta,
        machineId.isAcceptableOrUnknown(data['machine_id']!, _machineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_machineIdMeta);
    }
    if (data.containsKey('machine_name')) {
      context.handle(
        _machineNameMeta,
        machineName.isAcceptableOrUnknown(
          data['machine_name']!,
          _machineNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_machineNameMeta);
    }
    if (data.containsKey('start_reading')) {
      context.handle(
        _startReadingMeta,
        startReading.isAcceptableOrUnknown(
          data['start_reading']!,
          _startReadingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startReadingMeta);
    }
    if (data.containsKey('end_reading')) {
      context.handle(
        _endReadingMeta,
        endReading.isAcceptableOrUnknown(data['end_reading']!, _endReadingMeta),
      );
    } else if (isInserting) {
      context.missing(_endReadingMeta);
    }
    if (data.containsKey('working_hours')) {
      context.handle(
        _workingHoursMeta,
        workingHours.isAcceptableOrUnknown(
          data['working_hours']!,
          _workingHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workingHoursMeta);
    }
    if (data.containsKey('rate_paise')) {
      context.handle(
        _ratePaiseMeta,
        ratePaise.isAcceptableOrUnknown(data['rate_paise']!, _ratePaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_ratePaiseMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      workLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_log_id'],
      )!,
      workDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_date'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      siteName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_name'],
      )!,
      machineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_id'],
      )!,
      machineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_name'],
      )!,
      startReading: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_reading'],
      )!,
      endReading: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_reading'],
      )!,
      workingHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}working_hours'],
      )!,
      ratePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_paise'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $InvoiceLinesTable createAlias(String alias) {
    return $InvoiceLinesTable(attachedDatabase, alias);
  }
}

class InvoiceLine extends DataClass implements Insertable<InvoiceLine> {
  final String id;
  final String companyId;
  final String invoiceId;
  final String workLogId;
  final String workDate;
  final String siteId;
  final String siteName;
  final String machineId;
  final String machineName;
  final int startReading;
  final int endReading;
  final int workingHours;

  /// Rate for this invoice only; never written back to the site.
  final int ratePaise;
  final int amountPaise;
  final String? description;
  final int sortOrder;
  const InvoiceLine({
    required this.id,
    required this.companyId,
    required this.invoiceId,
    required this.workLogId,
    required this.workDate,
    required this.siteId,
    required this.siteName,
    required this.machineId,
    required this.machineName,
    required this.startReading,
    required this.endReading,
    required this.workingHours,
    required this.ratePaise,
    required this.amountPaise,
    this.description,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['work_log_id'] = Variable<String>(workLogId);
    map['work_date'] = Variable<String>(workDate);
    map['site_id'] = Variable<String>(siteId);
    map['site_name'] = Variable<String>(siteName);
    map['machine_id'] = Variable<String>(machineId);
    map['machine_name'] = Variable<String>(machineName);
    map['start_reading'] = Variable<int>(startReading);
    map['end_reading'] = Variable<int>(endReading);
    map['working_hours'] = Variable<int>(workingHours);
    map['rate_paise'] = Variable<int>(ratePaise);
    map['amount_paise'] = Variable<int>(amountPaise);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  InvoiceLinesCompanion toCompanion(bool nullToAbsent) {
    return InvoiceLinesCompanion(
      id: Value(id),
      companyId: Value(companyId),
      invoiceId: Value(invoiceId),
      workLogId: Value(workLogId),
      workDate: Value(workDate),
      siteId: Value(siteId),
      siteName: Value(siteName),
      machineId: Value(machineId),
      machineName: Value(machineName),
      startReading: Value(startReading),
      endReading: Value(endReading),
      workingHours: Value(workingHours),
      ratePaise: Value(ratePaise),
      amountPaise: Value(amountPaise),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      sortOrder: Value(sortOrder),
    );
  }

  factory InvoiceLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceLine(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      workLogId: serializer.fromJson<String>(json['workLogId']),
      workDate: serializer.fromJson<String>(json['workDate']),
      siteId: serializer.fromJson<String>(json['siteId']),
      siteName: serializer.fromJson<String>(json['siteName']),
      machineId: serializer.fromJson<String>(json['machineId']),
      machineName: serializer.fromJson<String>(json['machineName']),
      startReading: serializer.fromJson<int>(json['startReading']),
      endReading: serializer.fromJson<int>(json['endReading']),
      workingHours: serializer.fromJson<int>(json['workingHours']),
      ratePaise: serializer.fromJson<int>(json['ratePaise']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      description: serializer.fromJson<String?>(json['description']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'workLogId': serializer.toJson<String>(workLogId),
      'workDate': serializer.toJson<String>(workDate),
      'siteId': serializer.toJson<String>(siteId),
      'siteName': serializer.toJson<String>(siteName),
      'machineId': serializer.toJson<String>(machineId),
      'machineName': serializer.toJson<String>(machineName),
      'startReading': serializer.toJson<int>(startReading),
      'endReading': serializer.toJson<int>(endReading),
      'workingHours': serializer.toJson<int>(workingHours),
      'ratePaise': serializer.toJson<int>(ratePaise),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'description': serializer.toJson<String?>(description),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  InvoiceLine copyWith({
    String? id,
    String? companyId,
    String? invoiceId,
    String? workLogId,
    String? workDate,
    String? siteId,
    String? siteName,
    String? machineId,
    String? machineName,
    int? startReading,
    int? endReading,
    int? workingHours,
    int? ratePaise,
    int? amountPaise,
    Value<String?> description = const Value.absent(),
    int? sortOrder,
  }) => InvoiceLine(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    invoiceId: invoiceId ?? this.invoiceId,
    workLogId: workLogId ?? this.workLogId,
    workDate: workDate ?? this.workDate,
    siteId: siteId ?? this.siteId,
    siteName: siteName ?? this.siteName,
    machineId: machineId ?? this.machineId,
    machineName: machineName ?? this.machineName,
    startReading: startReading ?? this.startReading,
    endReading: endReading ?? this.endReading,
    workingHours: workingHours ?? this.workingHours,
    ratePaise: ratePaise ?? this.ratePaise,
    amountPaise: amountPaise ?? this.amountPaise,
    description: description.present ? description.value : this.description,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  InvoiceLine copyWithCompanion(InvoiceLinesCompanion data) {
    return InvoiceLine(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      workLogId: data.workLogId.present ? data.workLogId.value : this.workLogId,
      workDate: data.workDate.present ? data.workDate.value : this.workDate,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      siteName: data.siteName.present ? data.siteName.value : this.siteName,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      machineName: data.machineName.present
          ? data.machineName.value
          : this.machineName,
      startReading: data.startReading.present
          ? data.startReading.value
          : this.startReading,
      endReading: data.endReading.present
          ? data.endReading.value
          : this.endReading,
      workingHours: data.workingHours.present
          ? data.workingHours.value
          : this.workingHours,
      ratePaise: data.ratePaise.present ? data.ratePaise.value : this.ratePaise,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      description: data.description.present
          ? data.description.value
          : this.description,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceLine(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('workLogId: $workLogId, ')
          ..write('workDate: $workDate, ')
          ..write('siteId: $siteId, ')
          ..write('siteName: $siteName, ')
          ..write('machineId: $machineId, ')
          ..write('machineName: $machineName, ')
          ..write('startReading: $startReading, ')
          ..write('endReading: $endReading, ')
          ..write('workingHours: $workingHours, ')
          ..write('ratePaise: $ratePaise, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    invoiceId,
    workLogId,
    workDate,
    siteId,
    siteName,
    machineId,
    machineName,
    startReading,
    endReading,
    workingHours,
    ratePaise,
    amountPaise,
    description,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceLine &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.invoiceId == this.invoiceId &&
          other.workLogId == this.workLogId &&
          other.workDate == this.workDate &&
          other.siteId == this.siteId &&
          other.siteName == this.siteName &&
          other.machineId == this.machineId &&
          other.machineName == this.machineName &&
          other.startReading == this.startReading &&
          other.endReading == this.endReading &&
          other.workingHours == this.workingHours &&
          other.ratePaise == this.ratePaise &&
          other.amountPaise == this.amountPaise &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder);
}

class InvoiceLinesCompanion extends UpdateCompanion<InvoiceLine> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> invoiceId;
  final Value<String> workLogId;
  final Value<String> workDate;
  final Value<String> siteId;
  final Value<String> siteName;
  final Value<String> machineId;
  final Value<String> machineName;
  final Value<int> startReading;
  final Value<int> endReading;
  final Value<int> workingHours;
  final Value<int> ratePaise;
  final Value<int> amountPaise;
  final Value<String?> description;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const InvoiceLinesCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.workLogId = const Value.absent(),
    this.workDate = const Value.absent(),
    this.siteId = const Value.absent(),
    this.siteName = const Value.absent(),
    this.machineId = const Value.absent(),
    this.machineName = const Value.absent(),
    this.startReading = const Value.absent(),
    this.endReading = const Value.absent(),
    this.workingHours = const Value.absent(),
    this.ratePaise = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoiceLinesCompanion.insert({
    required String id,
    required String companyId,
    required String invoiceId,
    required String workLogId,
    required String workDate,
    required String siteId,
    required String siteName,
    required String machineId,
    required String machineName,
    required int startReading,
    required int endReading,
    required int workingHours,
    required int ratePaise,
    required int amountPaise,
    this.description = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       invoiceId = Value(invoiceId),
       workLogId = Value(workLogId),
       workDate = Value(workDate),
       siteId = Value(siteId),
       siteName = Value(siteName),
       machineId = Value(machineId),
       machineName = Value(machineName),
       startReading = Value(startReading),
       endReading = Value(endReading),
       workingHours = Value(workingHours),
       ratePaise = Value(ratePaise),
       amountPaise = Value(amountPaise),
       sortOrder = Value(sortOrder);
  static Insertable<InvoiceLine> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? invoiceId,
    Expression<String>? workLogId,
    Expression<String>? workDate,
    Expression<String>? siteId,
    Expression<String>? siteName,
    Expression<String>? machineId,
    Expression<String>? machineName,
    Expression<int>? startReading,
    Expression<int>? endReading,
    Expression<int>? workingHours,
    Expression<int>? ratePaise,
    Expression<int>? amountPaise,
    Expression<String>? description,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (workLogId != null) 'work_log_id': workLogId,
      if (workDate != null) 'work_date': workDate,
      if (siteId != null) 'site_id': siteId,
      if (siteName != null) 'site_name': siteName,
      if (machineId != null) 'machine_id': machineId,
      if (machineName != null) 'machine_name': machineName,
      if (startReading != null) 'start_reading': startReading,
      if (endReading != null) 'end_reading': endReading,
      if (workingHours != null) 'working_hours': workingHours,
      if (ratePaise != null) 'rate_paise': ratePaise,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoiceLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? invoiceId,
    Value<String>? workLogId,
    Value<String>? workDate,
    Value<String>? siteId,
    Value<String>? siteName,
    Value<String>? machineId,
    Value<String>? machineName,
    Value<int>? startReading,
    Value<int>? endReading,
    Value<int>? workingHours,
    Value<int>? ratePaise,
    Value<int>? amountPaise,
    Value<String?>? description,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return InvoiceLinesCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      invoiceId: invoiceId ?? this.invoiceId,
      workLogId: workLogId ?? this.workLogId,
      workDate: workDate ?? this.workDate,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      startReading: startReading ?? this.startReading,
      endReading: endReading ?? this.endReading,
      workingHours: workingHours ?? this.workingHours,
      ratePaise: ratePaise ?? this.ratePaise,
      amountPaise: amountPaise ?? this.amountPaise,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (workLogId.present) {
      map['work_log_id'] = Variable<String>(workLogId.value);
    }
    if (workDate.present) {
      map['work_date'] = Variable<String>(workDate.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (siteName.present) {
      map['site_name'] = Variable<String>(siteName.value);
    }
    if (machineId.present) {
      map['machine_id'] = Variable<String>(machineId.value);
    }
    if (machineName.present) {
      map['machine_name'] = Variable<String>(machineName.value);
    }
    if (startReading.present) {
      map['start_reading'] = Variable<int>(startReading.value);
    }
    if (endReading.present) {
      map['end_reading'] = Variable<int>(endReading.value);
    }
    if (workingHours.present) {
      map['working_hours'] = Variable<int>(workingHours.value);
    }
    if (ratePaise.present) {
      map['rate_paise'] = Variable<int>(ratePaise.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceLinesCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('workLogId: $workLogId, ')
          ..write('workDate: $workDate, ')
          ..write('siteId: $siteId, ')
          ..write('siteName: $siteName, ')
          ..write('machineId: $machineId, ')
          ..write('machineName: $machineName, ')
          ..write('startReading: $startReading, ')
          ..write('endReading: $endReading, ')
          ..write('workingHours: $workingHours, ')
          ..write('ratePaise: $ratePaise, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id)',
    ),
  );
  static const VerificationMeta _paymentDateMeta = const VerificationMeta(
    'paymentDate',
  );
  @override
  late final GeneratedColumn<String> paymentDate = GeneratedColumn<String>(
    'payment_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reversedAtMeta = const VerificationMeta(
    'reversedAt',
  );
  @override
  late final GeneratedColumn<int> reversedAt = GeneratedColumn<int>(
    'reversed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reversedByMeta = const VerificationMeta(
    'reversedBy',
  );
  @override
  late final GeneratedColumn<String> reversedBy = GeneratedColumn<String>(
    'reversed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reverseReasonMeta = const VerificationMeta(
    'reverseReason',
  );
  @override
  late final GeneratedColumn<String> reverseReason = GeneratedColumn<String>(
    'reverse_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    invoiceId,
    paymentDate,
    amountPaise,
    method,
    reference,
    notes,
    reversedAt,
    reversedBy,
    reverseReason,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Payment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('payment_date')) {
      context.handle(
        _paymentDateMeta,
        paymentDate.isAcceptableOrUnknown(
          data['payment_date']!,
          _paymentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('reversed_at')) {
      context.handle(
        _reversedAtMeta,
        reversedAt.isAcceptableOrUnknown(data['reversed_at']!, _reversedAtMeta),
      );
    }
    if (data.containsKey('reversed_by')) {
      context.handle(
        _reversedByMeta,
        reversedBy.isAcceptableOrUnknown(data['reversed_by']!, _reversedByMeta),
      );
    }
    if (data.containsKey('reverse_reason')) {
      context.handle(
        _reverseReasonMeta,
        reverseReason.isAcceptableOrUnknown(
          data['reverse_reason']!,
          _reverseReasonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      paymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_date'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      reversedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reversed_at'],
      ),
      reversedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reversed_by'],
      ),
      reverseReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reverse_reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final String id;
  final String companyId;
  final String invoiceId;
  final String paymentDate;
  final int amountPaise;

  /// cash, bank, upi, cheque, other.
  final String method;
  final String? reference;
  final String? notes;

  /// Reversed payments are kept for the audit trail but not counted.
  final int? reversedAt;
  final String? reversedBy;
  final String? reverseReason;
  final int createdAt;
  final int updatedAt;
  final String createdBy;
  final String updatedBy;
  final String syncStatus;
  final int version;
  const Payment({
    required this.id,
    required this.companyId,
    required this.invoiceId,
    required this.paymentDate,
    required this.amountPaise,
    required this.method,
    this.reference,
    this.notes,
    this.reversedAt,
    this.reversedBy,
    this.reverseReason,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncStatus,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['payment_date'] = Variable<String>(paymentDate);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || reversedAt != null) {
      map['reversed_at'] = Variable<int>(reversedAt);
    }
    if (!nullToAbsent || reversedBy != null) {
      map['reversed_by'] = Variable<String>(reversedBy);
    }
    if (!nullToAbsent || reverseReason != null) {
      map['reverse_reason'] = Variable<String>(reverseReason);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['created_by'] = Variable<String>(createdBy);
    map['updated_by'] = Variable<String>(updatedBy);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      invoiceId: Value(invoiceId),
      paymentDate: Value(paymentDate),
      amountPaise: Value(amountPaise),
      method: Value(method),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      reversedAt: reversedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reversedAt),
      reversedBy: reversedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reversedBy),
      reverseReason: reverseReason == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseReason),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: Value(createdBy),
      updatedBy: Value(updatedBy),
      syncStatus: Value(syncStatus),
      version: Value(version),
    );
  }

  factory Payment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      paymentDate: serializer.fromJson<String>(json['paymentDate']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      method: serializer.fromJson<String>(json['method']),
      reference: serializer.fromJson<String?>(json['reference']),
      notes: serializer.fromJson<String?>(json['notes']),
      reversedAt: serializer.fromJson<int?>(json['reversedAt']),
      reversedBy: serializer.fromJson<String?>(json['reversedBy']),
      reverseReason: serializer.fromJson<String?>(json['reverseReason']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'paymentDate': serializer.toJson<String>(paymentDate),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'method': serializer.toJson<String>(method),
      'reference': serializer.toJson<String?>(reference),
      'notes': serializer.toJson<String?>(notes),
      'reversedAt': serializer.toJson<int?>(reversedAt),
      'reversedBy': serializer.toJson<String?>(reversedBy),
      'reverseReason': serializer.toJson<String?>(reverseReason),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
    };
  }

  Payment copyWith({
    String? id,
    String? companyId,
    String? invoiceId,
    String? paymentDate,
    int? amountPaise,
    String? method,
    Value<String?> reference = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> reversedAt = const Value.absent(),
    Value<String?> reversedBy = const Value.absent(),
    Value<String?> reverseReason = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? syncStatus,
    int? version,
  }) => Payment(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    invoiceId: invoiceId ?? this.invoiceId,
    paymentDate: paymentDate ?? this.paymentDate,
    amountPaise: amountPaise ?? this.amountPaise,
    method: method ?? this.method,
    reference: reference.present ? reference.value : this.reference,
    notes: notes.present ? notes.value : this.notes,
    reversedAt: reversedAt.present ? reversedAt.value : this.reversedAt,
    reversedBy: reversedBy.present ? reversedBy.value : this.reversedBy,
    reverseReason: reverseReason.present
        ? reverseReason.value
        : this.reverseReason,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
  );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      method: data.method.present ? data.method.value : this.method,
      reference: data.reference.present ? data.reference.value : this.reference,
      notes: data.notes.present ? data.notes.value : this.notes,
      reversedAt: data.reversedAt.present
          ? data.reversedAt.value
          : this.reversedAt,
      reversedBy: data.reversedBy.present
          ? data.reversedBy.value
          : this.reversedBy,
      reverseReason: data.reverseReason.present
          ? data.reverseReason.value
          : this.reverseReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('method: $method, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('reversedAt: $reversedAt, ')
          ..write('reversedBy: $reversedBy, ')
          ..write('reverseReason: $reverseReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    invoiceId,
    paymentDate,
    amountPaise,
    method,
    reference,
    notes,
    reversedAt,
    reversedBy,
    reverseReason,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    syncStatus,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.invoiceId == this.invoiceId &&
          other.paymentDate == this.paymentDate &&
          other.amountPaise == this.amountPaise &&
          other.method == this.method &&
          other.reference == this.reference &&
          other.notes == this.notes &&
          other.reversedAt == this.reversedAt &&
          other.reversedBy == this.reversedBy &&
          other.reverseReason == this.reverseReason &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> invoiceId;
  final Value<String> paymentDate;
  final Value<int> amountPaise;
  final Value<String> method;
  final Value<String?> reference;
  final Value<String?> notes;
  final Value<int?> reversedAt;
  final Value<String?> reversedBy;
  final Value<String?> reverseReason;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> createdBy;
  final Value<String> updatedBy;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.method = const Value.absent(),
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    this.reversedAt = const Value.absent(),
    this.reversedBy = const Value.absent(),
    this.reverseReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String companyId,
    required String invoiceId,
    required String paymentDate,
    required int amountPaise,
    required String method,
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    this.reversedAt = const Value.absent(),
    this.reversedBy = const Value.absent(),
    this.reverseReason = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    required String createdBy,
    required String updatedBy,
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       invoiceId = Value(invoiceId),
       paymentDate = Value(paymentDate),
       amountPaise = Value(amountPaise),
       method = Value(method),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy),
       updatedBy = Value(updatedBy);
  static Insertable<Payment> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? invoiceId,
    Expression<String>? paymentDate,
    Expression<int>? amountPaise,
    Expression<String>? method,
    Expression<String>? reference,
    Expression<String>? notes,
    Expression<int>? reversedAt,
    Expression<String>? reversedBy,
    Expression<String>? reverseReason,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (method != null) 'method': method,
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (reversedAt != null) 'reversed_at': reversedAt,
      if (reversedBy != null) 'reversed_by': reversedBy,
      if (reverseReason != null) 'reverse_reason': reverseReason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? invoiceId,
    Value<String>? paymentDate,
    Value<int>? amountPaise,
    Value<String>? method,
    Value<String?>? reference,
    Value<String?>? notes,
    Value<int?>? reversedAt,
    Value<String?>? reversedBy,
    Value<String?>? reverseReason,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? createdBy,
    Value<String>? updatedBy,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      invoiceId: invoiceId ?? this.invoiceId,
      paymentDate: paymentDate ?? this.paymentDate,
      amountPaise: amountPaise ?? this.amountPaise,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      reversedAt: reversedAt ?? this.reversedAt,
      reversedBy: reversedBy ?? this.reversedBy,
      reverseReason: reverseReason ?? this.reverseReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<String>(paymentDate.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (reversedAt.present) {
      map['reversed_at'] = Variable<int>(reversedAt.value);
    }
    if (reversedBy.present) {
      map['reversed_by'] = Variable<String>(reversedBy.value);
    }
    if (reverseReason.present) {
      map['reverse_reason'] = Variable<String>(reverseReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('method: $method, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('reversedAt: $reversedAt, ')
          ..write('reversedBy: $reversedBy, ')
          ..write('reverseReason: $reverseReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncRecordsTable extends SyncRecords
    with TableInfo<$SyncRecordsTable, SyncRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverRevMeta = const VerificationMeta(
    'serverRev',
  );
  @override
  late final GeneratedColumn<int> serverRev = GeneratedColumn<int>(
    'server_rev',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conflictJsonMeta = const VerificationMeta(
    'conflictJson',
  );
  @override
  late final GeneratedColumn<String> conflictJson = GeneratedColumn<String>(
    'conflict_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conflictRevMeta = const VerificationMeta(
    'conflictRev',
  );
  @override
  late final GeneratedColumn<int> conflictRev = GeneratedColumn<int>(
    'conflict_rev',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entity,
    entityId,
    companyId,
    serverRev,
    attempts,
    nextAttemptAt,
    lastError,
    conflictJson,
    conflictRev,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('server_rev')) {
      context.handle(
        _serverRevMeta,
        serverRev.isAcceptableOrUnknown(data['server_rev']!, _serverRevMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('conflict_json')) {
      context.handle(
        _conflictJsonMeta,
        conflictJson.isAcceptableOrUnknown(
          data['conflict_json']!,
          _conflictJsonMeta,
        ),
      );
    }
    if (data.containsKey('conflict_rev')) {
      context.handle(
        _conflictRevMeta,
        conflictRev.isAcceptableOrUnknown(
          data['conflict_rev']!,
          _conflictRevMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, entityId};
  @override
  SyncRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRecord(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      serverRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_rev'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      conflictJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_json'],
      ),
      conflictRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conflict_rev'],
      ),
    );
  }

  @override
  $SyncRecordsTable createAlias(String alias) {
    return $SyncRecordsTable(attachedDatabase, alias);
  }
}

class SyncRecord extends DataClass implements Insertable<SyncRecord> {
  /// Firestore collection, e.g. `workLogs`.
  final String entity;
  final String entityId;
  final String companyId;
  final int? serverRev;

  /// Consecutive failed attempts and when to try again (UTC ms).
  final int attempts;
  final int? nextAttemptAt;

  /// Why the server refused the record (shown on the Sync screen).
  final String? lastError;

  /// Server copy (JSON) when the record is in conflict.
  final String? conflictJson;
  final int? conflictRev;
  const SyncRecord({
    required this.entity,
    required this.entityId,
    required this.companyId,
    this.serverRev,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
    this.conflictJson,
    this.conflictRev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['company_id'] = Variable<String>(companyId);
    if (!nullToAbsent || serverRev != null) {
      map['server_rev'] = Variable<int>(serverRev);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || conflictJson != null) {
      map['conflict_json'] = Variable<String>(conflictJson);
    }
    if (!nullToAbsent || conflictRev != null) {
      map['conflict_rev'] = Variable<int>(conflictRev);
    }
    return map;
  }

  SyncRecordsCompanion toCompanion(bool nullToAbsent) {
    return SyncRecordsCompanion(
      entity: Value(entity),
      entityId: Value(entityId),
      companyId: Value(companyId),
      serverRev: serverRev == null && nullToAbsent
          ? const Value.absent()
          : Value(serverRev),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      conflictJson: conflictJson == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictJson),
      conflictRev: conflictRev == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictRev),
    );
  }

  factory SyncRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRecord(
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      serverRev: serializer.fromJson<int?>(json['serverRev']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      conflictJson: serializer.fromJson<String?>(json['conflictJson']),
      conflictRev: serializer.fromJson<int?>(json['conflictRev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'companyId': serializer.toJson<String>(companyId),
      'serverRev': serializer.toJson<int?>(serverRev),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<int?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'conflictJson': serializer.toJson<String?>(conflictJson),
      'conflictRev': serializer.toJson<int?>(conflictRev),
    };
  }

  SyncRecord copyWith({
    String? entity,
    String? entityId,
    String? companyId,
    Value<int?> serverRev = const Value.absent(),
    int? attempts,
    Value<int?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<String?> conflictJson = const Value.absent(),
    Value<int?> conflictRev = const Value.absent(),
  }) => SyncRecord(
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    companyId: companyId ?? this.companyId,
    serverRev: serverRev.present ? serverRev.value : this.serverRev,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    conflictJson: conflictJson.present ? conflictJson.value : this.conflictJson,
    conflictRev: conflictRev.present ? conflictRev.value : this.conflictRev,
  );
  SyncRecord copyWithCompanion(SyncRecordsCompanion data) {
    return SyncRecord(
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      serverRev: data.serverRev.present ? data.serverRev.value : this.serverRev,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      conflictJson: data.conflictJson.present
          ? data.conflictJson.value
          : this.conflictJson,
      conflictRev: data.conflictRev.present
          ? data.conflictRev.value
          : this.conflictRev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecord(')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('companyId: $companyId, ')
          ..write('serverRev: $serverRev, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('conflictJson: $conflictJson, ')
          ..write('conflictRev: $conflictRev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entity,
    entityId,
    companyId,
    serverRev,
    attempts,
    nextAttemptAt,
    lastError,
    conflictJson,
    conflictRev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRecord &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.companyId == this.companyId &&
          other.serverRev == this.serverRev &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.conflictJson == this.conflictJson &&
          other.conflictRev == this.conflictRev);
}

class SyncRecordsCompanion extends UpdateCompanion<SyncRecord> {
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> companyId;
  final Value<int?> serverRev;
  final Value<int> attempts;
  final Value<int?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<String?> conflictJson;
  final Value<int?> conflictRev;
  final Value<int> rowid;
  const SyncRecordsCompanion({
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.serverRev = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.conflictJson = const Value.absent(),
    this.conflictRev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncRecordsCompanion.insert({
    required String entity,
    required String entityId,
    required String companyId,
    this.serverRev = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.conflictJson = const Value.absent(),
    this.conflictRev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       entityId = Value(entityId),
       companyId = Value(companyId);
  static Insertable<SyncRecord> custom({
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? companyId,
    Expression<int>? serverRev,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<String>? conflictJson,
    Expression<int>? conflictRev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (companyId != null) 'company_id': companyId,
      if (serverRev != null) 'server_rev': serverRev,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (conflictJson != null) 'conflict_json': conflictJson,
      if (conflictRev != null) 'conflict_rev': conflictRev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncRecordsCompanion copyWith({
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? companyId,
    Value<int?>? serverRev,
    Value<int>? attempts,
    Value<int?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<String?>? conflictJson,
    Value<int?>? conflictRev,
    Value<int>? rowid,
  }) {
    return SyncRecordsCompanion(
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      companyId: companyId ?? this.companyId,
      serverRev: serverRev ?? this.serverRev,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      conflictJson: conflictJson ?? this.conflictJson,
      conflictRev: conflictRev ?? this.conflictRev,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (serverRev.present) {
      map['server_rev'] = Variable<int>(serverRev.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (conflictJson.present) {
      map['conflict_json'] = Variable<String>(conflictJson.value);
    }
    if (conflictRev.present) {
      map['conflict_rev'] = Variable<int>(conflictRev.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecordsCompanion(')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('companyId: $companyId, ')
          ..write('serverRev: $serverRev, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('conflictJson: $conflictJson, ')
          ..write('conflictRev: $conflictRev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AuditLogsTable auditLogs = $AuditLogsTable(this);
  late final $CachedCompaniesTable cachedCompanies = $CachedCompaniesTable(
    this,
  );
  late final $ClientsTable clients = $ClientsTable(this);
  late final $SitesTable sites = $SitesTable(this);
  late final $MachinesTable machines = $MachinesTable(this);
  late final $OperatorsTable operators = $OperatorsTable(this);
  late final $PetrolPumpsTable petrolPumps = $PetrolPumpsTable(this);
  late final $WorkLogsTable workLogs = $WorkLogsTable(this);
  late final $FuelEntriesTable fuelEntries = $FuelEntriesTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $InvoiceLinesTable invoiceLines = $InvoiceLinesTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $SyncRecordsTable syncRecords = $SyncRecordsTable(this);
  late final Index clientsCompanyName = Index(
    'clients_company_name',
    'CREATE INDEX clients_company_name ON clients (company_id, name)',
  );
  late final Index sitesCompanyClient = Index(
    'sites_company_client',
    'CREATE INDEX sites_company_client ON sites (company_id, client_id)',
  );
  late final Index machinesCompanyName = Index(
    'machines_company_name',
    'CREATE INDEX machines_company_name ON machines (company_id, name)',
  );
  late final Index operatorsCompanyName = Index(
    'operators_company_name',
    'CREATE INDEX operators_company_name ON operators (company_id, name)',
  );
  late final Index petrolPumpsCompanyName = Index(
    'petrol_pumps_company_name',
    'CREATE INDEX petrol_pumps_company_name ON petrol_pumps (company_id, name)',
  );
  late final Index workLogsCompanyDate = Index(
    'work_logs_company_date',
    'CREATE INDEX work_logs_company_date ON work_logs (company_id, work_date)',
  );
  late final Index workLogsCompanyMachine = Index(
    'work_logs_company_machine',
    'CREATE INDEX work_logs_company_machine ON work_logs (company_id, machine_id)',
  );
  late final Index fuelCompanyDate = Index(
    'fuel_company_date',
    'CREATE INDEX fuel_company_date ON fuel_entries (company_id, fuel_date)',
  );
  late final Index invoicesCompanyClient = Index(
    'invoices_company_client',
    'CREATE INDEX invoices_company_client ON invoices (company_id, client_id)',
  );
  late final Index invoiceLinesInvoice = Index(
    'invoice_lines_invoice',
    'CREATE INDEX invoice_lines_invoice ON invoice_lines (invoice_id)',
  );
  late final Index paymentsInvoice = Index(
    'payments_invoice',
    'CREATE INDEX payments_invoice ON payments (company_id, invoice_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    auditLogs,
    cachedCompanies,
    clients,
    sites,
    machines,
    operators,
    petrolPumps,
    workLogs,
    fuelEntries,
    invoices,
    invoiceLines,
    payments,
    syncRecords,
    clientsCompanyName,
    sitesCompanyClient,
    machinesCompanyName,
    operatorsCompanyName,
    petrolPumpsCompanyName,
    workLogsCompanyDate,
    workLogsCompanyMachine,
    fuelCompanyDate,
    invoicesCompanyClient,
    invoiceLinesInvoice,
    paymentsInvoice,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$AuditLogsTableCreateCompanionBuilder = AuditLogsCompanion Function({
  required String id,
  Value<String?> companyId,
  required String actorId,
  required String action,
  required String entityType,
  required String entityId,
  Value<String?> details,
  required int createdAt,
  Value<String> syncStatus,
  Value<int> rowid,
});
typedef $$AuditLogsTableUpdateCompanionBuilder = AuditLogsCompanion Function({
  Value<String> id,
  Value<String?> companyId,
  Value<String> actorId,
  Value<String> action,
  Value<String> entityType,
  Value<String> entityId,
  Value<String?> details,
  Value<int> createdAt,
  Value<String> syncStatus,
  Value<int> rowid,
});

class $$AuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$AuditLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogsTable,
          AuditLog,
          $$AuditLogsTableFilterComposer,
          $$AuditLogsTableOrderingComposer,
          $$AuditLogsTableAnnotationComposer,
          $$AuditLogsTableCreateCompanionBuilder,
          $$AuditLogsTableUpdateCompanionBuilder,
          (AuditLog, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog>),
          AuditLog,
          PrefetchHooks Function()
        > {
  $$AuditLogsTableTableManager(_$AppDatabase db, $AuditLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> actorId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsCompanion(
                id: id,
                companyId: companyId,
                actorId: actorId,
                action: action,
                entityType: entityType,
                entityId: entityId,
                details: details,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> companyId = const Value.absent(),
                required String actorId,
                required String action,
                required String entityType,
                required String entityId,
                Value<String?> details = const Value.absent(),
                required int createdAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsCompanion.insert(
                id: id,
                companyId: companyId,
                actorId: actorId,
                action: action,
                entityType: entityType,
                entityId: entityId,
                details: details,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditLogsTable, AuditLog>(table),
                  BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogsTable,
      AuditLog,
      $$AuditLogsTableFilterComposer,
      $$AuditLogsTableOrderingComposer,
      $$AuditLogsTableAnnotationComposer,
      $$AuditLogsTableCreateCompanionBuilder,
      $$AuditLogsTableUpdateCompanionBuilder,
      (AuditLog, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog>),
      AuditLog,
      PrefetchHooks Function()
    >;
typedef $$CachedCompaniesTableCreateCompanionBuilder =
    CachedCompaniesCompanion Function({
      required String userId,
      required String companyId,
      required String role,
      required String status,
      required String ownerUid,
      required String name,
      required String contactPerson,
      required String phone,
      Value<String?> email,
      required String address,
      Value<String?> gstin,
      required String invoicePrefix,
      required String currency,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$CachedCompaniesTableUpdateCompanionBuilder =
    CachedCompaniesCompanion Function({
      Value<String> userId,
      Value<String> companyId,
      Value<String> role,
      Value<String> status,
      Value<String> ownerUid,
      Value<String> name,
      Value<String> contactPerson,
      Value<String> phone,
      Value<String?> email,
      Value<String> address,
      Value<String?> gstin,
      Value<String> invoicePrefix,
      Value<String> currency,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$CachedCompaniesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCompaniesTable> {
  $$CachedCompaniesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoicePrefix => $composableBuilder(
    column: $table.invoicePrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCompaniesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCompaniesTable> {
  $$CachedCompaniesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUid => $composableBuilder(
    column: $table.ownerUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoicePrefix => $composableBuilder(
    column: $table.invoicePrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCompaniesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCompaniesTable> {
  $$CachedCompaniesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get ownerUid =>
      $composableBuilder(column: $table.ownerUid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get gstin =>
      $composableBuilder(column: $table.gstin, builder: (column) => column);

  GeneratedColumn<String> get invoicePrefix => $composableBuilder(
    column: $table.invoicePrefix,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedCompaniesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCompaniesTable,
          CachedCompany,
          $$CachedCompaniesTableFilterComposer,
          $$CachedCompaniesTableOrderingComposer,
          $$CachedCompaniesTableAnnotationComposer,
          $$CachedCompaniesTableCreateCompanionBuilder,
          $$CachedCompaniesTableUpdateCompanionBuilder,
          (
            CachedCompany,
            BaseReferences<_$AppDatabase, $CachedCompaniesTable, CachedCompany>,
          ),
          CachedCompany,
          PrefetchHooks Function()
        > {
  $$CachedCompaniesTableTableManager(
    _$AppDatabase db,
    $CachedCompaniesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCompaniesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCompaniesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCompaniesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> ownerUid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> contactPerson = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String?> gstin = const Value.absent(),
                Value<String> invoicePrefix = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCompaniesCompanion(
                userId: userId,
                companyId: companyId,
                role: role,
                status: status,
                ownerUid: ownerUid,
                name: name,
                contactPerson: contactPerson,
                phone: phone,
                email: email,
                address: address,
                gstin: gstin,
                invoicePrefix: invoicePrefix,
                currency: currency,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String companyId,
                required String role,
                required String status,
                required String ownerUid,
                required String name,
                required String contactPerson,
                required String phone,
                Value<String?> email = const Value.absent(),
                required String address,
                Value<String?> gstin = const Value.absent(),
                required String invoicePrefix,
                required String currency,
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCompaniesCompanion.insert(
                userId: userId,
                companyId: companyId,
                role: role,
                status: status,
                ownerUid: ownerUid,
                name: name,
                contactPerson: contactPerson,
                phone: phone,
                email: email,
                address: address,
                gstin: gstin,
                invoicePrefix: invoicePrefix,
                currency: currency,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedCompaniesTable, CachedCompany>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedCompaniesTable,
                    CachedCompany
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCompaniesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCompaniesTable,
      CachedCompany,
      $$CachedCompaniesTableFilterComposer,
      $$CachedCompaniesTableOrderingComposer,
      $$CachedCompaniesTableAnnotationComposer,
      $$CachedCompaniesTableCreateCompanionBuilder,
      $$CachedCompaniesTableUpdateCompanionBuilder,
      (
        CachedCompany,
        BaseReferences<_$AppDatabase, $CachedCompaniesTable, CachedCompany>,
      ),
      CachedCompany,
      PrefetchHooks Function()
    >;
typedef $$ClientsTableCreateCompanionBuilder = ClientsCompanion Function({
  required String id,
  required String companyId,
  required String name,
  Value<String?> notes,
  Value<bool> isActive,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String createdBy,
  required String updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<String?> contactPerson,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> billingAddress,
  Value<String?> gstin,
  Value<int> rowid,
});
typedef $$ClientsTableUpdateCompanionBuilder = ClientsCompanion Function({
  Value<String> id,
  Value<String> companyId,
  Value<String> name,
  Value<String?> notes,
  Value<bool> isActive,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> createdBy,
  Value<String> updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<String?> contactPerson,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> billingAddress,
  Value<String?> gstin,
  Value<int> rowid,
});

final class $$ClientsTableReferences
    extends BaseReferences<_$AppDatabase, $ClientsTable, Client> {
  $$ClientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SitesTable, List<Site>> _sitesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sites,
    aliasName: 'clients__id__sites__client_id',
  );

  $$SitesTableProcessedTableManager get sitesRefs {
    final manager = $$SitesTableTableManager(
      $_db,
      $_db.sites,
    ).filter((f) => f.clientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sitesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkLogsTable, List<WorkLog>> _workLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.workLogs,
    aliasName: 'clients__id__work_logs__client_id',
  );

  $$WorkLogsTableProcessedTableManager get workLogsRefs {
    final manager = $$WorkLogsTableTableManager(
      $_db,
      $_db.workLogs,
    ).filter((f) => f.clientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FuelEntriesTable, List<FuelEntry>>
  _fuelEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fuelEntries,
    aliasName: 'clients__id__fuel_entries__client_id',
  );

  $$FuelEntriesTableProcessedTableManager get fuelEntriesRefs {
    final manager = $$FuelEntriesTableTableManager(
      $_db,
      $_db.fuelEntries,
    ).filter((f) => f.clientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fuelEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InvoicesTable, List<Invoice>> _invoicesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.invoices,
    aliasName: 'clients__id__invoices__client_id',
  );

  $$InvoicesTableProcessedTableManager get invoicesRefs {
    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.clientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClientsTableFilterComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billingAddress => $composableBuilder(
    column: $table.billingAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sitesRefs(
    Expression<bool> Function($$SitesTableFilterComposer f) f,
  ) {
    final $$SitesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.clientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableFilterComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workLogsRefs(
    Expression<bool> Function($$WorkLogsTableFilterComposer f) f,
  ) {
    final $$WorkLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.clientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableFilterComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fuelEntriesRefs(
    Expression<bool> Function($$FuelEntriesTableFilterComposer f) f,
  ) {
    final $$FuelEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelEntries,
      getReferencedColumn: (t) => t.clientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelEntriesTableFilterComposer(
            $db: $db,
            $table: $db.fuelEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> invoicesRefs(
    Expression<bool> Function($$InvoicesTableFilterComposer f) f,
  ) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.clientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClientsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billingAddress => $composableBuilder(
    column: $table.billingAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get billingAddress => $composableBuilder(
    column: $table.billingAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gstin =>
      $composableBuilder(column: $table.gstin, builder: (column) => column);

  Expression<T> sitesRefs<T extends Object>(
    Expression<T> Function($$SitesTableAnnotationComposer a) f,
  ) {
    final $$SitesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.clientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableAnnotationComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workLogsRefs<T extends Object>(
    Expression<T> Function($$WorkLogsTableAnnotationComposer a) f,
  ) {
    final $$WorkLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.clientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fuelEntriesRefs<T extends Object>(
    Expression<T> Function($$FuelEntriesTableAnnotationComposer a) f,
  ) {
    final $$FuelEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelEntries,
      getReferencedColumn: (t) => t.clientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.fuelEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> invoicesRefs<T extends Object>(
    Expression<T> Function($$InvoicesTableAnnotationComposer a) f,
  ) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.clientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientsTable,
          Client,
          $$ClientsTableFilterComposer,
          $$ClientsTableOrderingComposer,
          $$ClientsTableAnnotationComposer,
          $$ClientsTableCreateCompanionBuilder,
          $$ClientsTableUpdateCompanionBuilder,
          (Client, $$ClientsTableReferences),
          Client,
          PrefetchHooks Function({
            bool sitesRefs,
            bool workLogsRefs,
            bool fuelEntriesRefs,
            bool invoicesRefs,
          })
        > {
  $$ClientsTableTableManager(_$AppDatabase db, $ClientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> contactPerson = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> billingAddress = const Value.absent(),
                Value<String?> gstin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                contactPerson: contactPerson,
                phone: phone,
                email: email,
                billingAddress: billingAddress,
                gstin: gstin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String createdBy,
                required String updatedBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> contactPerson = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> billingAddress = const Value.absent(),
                Value<String?> gstin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion.insert(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                contactPerson: contactPerson,
                phone: phone,
                email: email,
                billingAddress: billingAddress,
                gstin: gstin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClientsTable, Client>(table),
                  $$ClientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sitesRefs = false,
                workLogsRefs = false,
                fuelEntriesRefs = false,
                invoicesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sitesRefs) db.sites,
                    if (workLogsRefs) db.workLogs,
                    if (fuelEntriesRefs) db.fuelEntries,
                    if (invoicesRefs) db.invoices,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sitesRefs)
                        await $_getPrefetchedDataByColumns<
                          Client,
                          $ClientsTable,
                          Site,
                          $SitesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ClientsTableReferences
                              ._sitesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClientsTableReferences(db, table, p0).sitesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'client_id',
                          typedResults: items,
                        ),
                      if (workLogsRefs)
                        await $_getPrefetchedDataByColumns<
                          Client,
                          $ClientsTable,
                          WorkLog,
                          $WorkLogsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ClientsTableReferences
                              ._workLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClientsTableReferences(
                                db,
                                table,
                                p0,
                              ).workLogsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'client_id',
                          typedResults: items,
                        ),
                      if (fuelEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          Client,
                          $ClientsTable,
                          FuelEntry,
                          $FuelEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ClientsTableReferences
                              ._fuelEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClientsTableReferences(
                                db,
                                table,
                                p0,
                              ).fuelEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'client_id',
                          typedResults: items,
                        ),
                      if (invoicesRefs)
                        await $_getPrefetchedDataByColumns<
                          Client,
                          $ClientsTable,
                          Invoice,
                          $InvoicesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ClientsTableReferences
                              ._invoicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClientsTableReferences(
                                db,
                                table,
                                p0,
                              ).invoicesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'client_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ClientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientsTable,
      Client,
      $$ClientsTableFilterComposer,
      $$ClientsTableOrderingComposer,
      $$ClientsTableAnnotationComposer,
      $$ClientsTableCreateCompanionBuilder,
      $$ClientsTableUpdateCompanionBuilder,
      (Client, $$ClientsTableReferences),
      Client,
      PrefetchHooks Function({
        bool sitesRefs,
        bool workLogsRefs,
        bool fuelEntriesRefs,
        bool invoicesRefs,
      })
    >;
typedef $$SitesTableCreateCompanionBuilder = SitesCompanion Function({
  required String id,
  required String companyId,
  required String name,
  Value<String?> notes,
  Value<bool> isActive,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String createdBy,
  required String updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  required String clientId,
  Value<String?> address,
  Value<String?> contactPerson,
  Value<String?> phone,
  Value<int?> defaultHourlyRatePaise,
  Value<int> rowid,
});
typedef $$SitesTableUpdateCompanionBuilder = SitesCompanion Function({
  Value<String> id,
  Value<String> companyId,
  Value<String> name,
  Value<String?> notes,
  Value<bool> isActive,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> createdBy,
  Value<String> updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<String> clientId,
  Value<String?> address,
  Value<String?> contactPerson,
  Value<String?> phone,
  Value<int?> defaultHourlyRatePaise,
  Value<int> rowid,
});

final class $$SitesTableReferences
    extends BaseReferences<_$AppDatabase, $SitesTable, Site> {
  $$SitesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClientsTable _clientIdTable(_$AppDatabase db) =>
      db.clients.createAlias('sites__client_id__clients__id');

  $$ClientsTableProcessedTableManager get clientId {
    final $_column = $_itemColumn<String>('client_id')!;

    final manager = $$ClientsTableTableManager(
      $_db,
      $_db.clients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkLogsTable, List<WorkLog>> _workLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.workLogs,
    aliasName: 'sites__id__work_logs__site_id',
  );

  $$WorkLogsTableProcessedTableManager get workLogsRefs {
    final manager = $$WorkLogsTableTableManager(
      $_db,
      $_db.workLogs,
    ).filter((f) => f.siteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FuelEntriesTable, List<FuelEntry>>
  _fuelEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fuelEntries,
    aliasName: 'sites__id__fuel_entries__site_id',
  );

  $$FuelEntriesTableProcessedTableManager get fuelEntriesRefs {
    final manager = $$FuelEntriesTableTableManager(
      $_db,
      $_db.fuelEntries,
    ).filter((f) => f.siteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fuelEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SitesTableFilterComposer extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultHourlyRatePaise => $composableBuilder(
    column: $table.defaultHourlyRatePaise,
    builder: (column) => ColumnFilters(column),
  );

  $$ClientsTableFilterComposer get clientId {
    final $$ClientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableFilterComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workLogsRefs(
    Expression<bool> Function($$WorkLogsTableFilterComposer f) f,
  ) {
    final $$WorkLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.siteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableFilterComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fuelEntriesRefs(
    Expression<bool> Function($$FuelEntriesTableFilterComposer f) f,
  ) {
    final $$FuelEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelEntries,
      getReferencedColumn: (t) => t.siteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelEntriesTableFilterComposer(
            $db: $db,
            $table: $db.fuelEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SitesTableOrderingComposer
    extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultHourlyRatePaise => $composableBuilder(
    column: $table.defaultHourlyRatePaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClientsTableOrderingComposer get clientId {
    final $$ClientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableOrderingComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SitesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<int> get defaultHourlyRatePaise => $composableBuilder(
    column: $table.defaultHourlyRatePaise,
    builder: (column) => column,
  );

  $$ClientsTableAnnotationComposer get clientId {
    final $$ClientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableAnnotationComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workLogsRefs<T extends Object>(
    Expression<T> Function($$WorkLogsTableAnnotationComposer a) f,
  ) {
    final $$WorkLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.siteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fuelEntriesRefs<T extends Object>(
    Expression<T> Function($$FuelEntriesTableAnnotationComposer a) f,
  ) {
    final $$FuelEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelEntries,
      getReferencedColumn: (t) => t.siteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.fuelEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SitesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SitesTable,
          Site,
          $$SitesTableFilterComposer,
          $$SitesTableOrderingComposer,
          $$SitesTableAnnotationComposer,
          $$SitesTableCreateCompanionBuilder,
          $$SitesTableUpdateCompanionBuilder,
          (Site, $$SitesTableReferences),
          Site,
          PrefetchHooks Function({
            bool clientId,
            bool workLogsRefs,
            bool fuelEntriesRefs,
          })
        > {
  $$SitesTableTableManager(_$AppDatabase db, $SitesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> contactPerson = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<int?> defaultHourlyRatePaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SitesCompanion(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                clientId: clientId,
                address: address,
                contactPerson: contactPerson,
                phone: phone,
                defaultHourlyRatePaise: defaultHourlyRatePaise,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String createdBy,
                required String updatedBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                required String clientId,
                Value<String?> address = const Value.absent(),
                Value<String?> contactPerson = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<int?> defaultHourlyRatePaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SitesCompanion.insert(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                clientId: clientId,
                address: address,
                contactPerson: contactPerson,
                phone: phone,
                defaultHourlyRatePaise: defaultHourlyRatePaise,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SitesTable, Site>(table),
                  $$SitesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                clientId = false,
                workLogsRefs = false,
                fuelEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workLogsRefs) db.workLogs,
                    if (fuelEntriesRefs) db.fuelEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (clientId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.clientId,
                            referencedTable: $$SitesTableReferences
                                ._clientIdTable(db),
                            referencedColumn: $$SitesTableReferences
                                ._clientIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workLogsRefs)
                        await $_getPrefetchedDataByColumns<
                          Site,
                          $SitesTable,
                          WorkLog,
                          $WorkLogsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SitesTableReferences
                              ._workLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SitesTableReferences(
                                db,
                                table,
                                p0,
                              ).workLogsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'site_id',
                          typedResults: items,
                        ),
                      if (fuelEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          Site,
                          $SitesTable,
                          FuelEntry,
                          $FuelEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SitesTableReferences
                              ._fuelEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SitesTableReferences(
                                db,
                                table,
                                p0,
                              ).fuelEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'site_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SitesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SitesTable,
      Site,
      $$SitesTableFilterComposer,
      $$SitesTableOrderingComposer,
      $$SitesTableAnnotationComposer,
      $$SitesTableCreateCompanionBuilder,
      $$SitesTableUpdateCompanionBuilder,
      (Site, $$SitesTableReferences),
      Site,
      PrefetchHooks Function({
        bool clientId,
        bool workLogsRefs,
        bool fuelEntriesRefs,
      })
    >;
typedef $$MachinesTableCreateCompanionBuilder = MachinesCompanion Function({
  required String id,
  required String companyId,
  required String name,
  Value<String?> notes,
  Value<bool> isActive,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String createdBy,
  required String updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<String?> registrationNumber,
  Value<String?> serialNumber,
  Value<String?> model,
  required int initialMeterReading,
  Value<String> meterUnit,
  Value<int> rowid,
});
typedef $$MachinesTableUpdateCompanionBuilder = MachinesCompanion Function({
  Value<String> id,
  Value<String> companyId,
  Value<String> name,
  Value<String?> notes,
  Value<bool> isActive,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> createdBy,
  Value<String> updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<String?> registrationNumber,
  Value<String?> serialNumber,
  Value<String?> model,
  Value<int> initialMeterReading,
  Value<String> meterUnit,
  Value<int> rowid,
});

final class $$MachinesTableReferences
    extends BaseReferences<_$AppDatabase, $MachinesTable, Machine> {
  $$MachinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkLogsTable, List<WorkLog>> _workLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.workLogs,
    aliasName: 'machines__id__work_logs__machine_id',
  );

  $$WorkLogsTableProcessedTableManager get workLogsRefs {
    final manager = $$WorkLogsTableTableManager(
      $_db,
      $_db.workLogs,
    ).filter((f) => f.machineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FuelEntriesTable, List<FuelEntry>>
  _fuelEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fuelEntries,
    aliasName: 'machines__id__fuel_entries__machine_id',
  );

  $$FuelEntriesTableProcessedTableManager get fuelEntriesRefs {
    final manager = $$FuelEntriesTableTableManager(
      $_db,
      $_db.fuelEntries,
    ).filter((f) => f.machineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fuelEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MachinesTableFilterComposer
    extends Composer<_$AppDatabase, $MachinesTable> {
  $$MachinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialMeterReading => $composableBuilder(
    column: $table.initialMeterReading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meterUnit => $composableBuilder(
    column: $table.meterUnit,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workLogsRefs(
    Expression<bool> Function($$WorkLogsTableFilterComposer f) f,
  ) {
    final $$WorkLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableFilterComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fuelEntriesRefs(
    Expression<bool> Function($$FuelEntriesTableFilterComposer f) f,
  ) {
    final $$FuelEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelEntries,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelEntriesTableFilterComposer(
            $db: $db,
            $table: $db.fuelEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MachinesTableOrderingComposer
    extends Composer<_$AppDatabase, $MachinesTable> {
  $$MachinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialMeterReading => $composableBuilder(
    column: $table.initialMeterReading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meterUnit => $composableBuilder(
    column: $table.meterUnit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MachinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MachinesTable> {
  $$MachinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get initialMeterReading => $composableBuilder(
    column: $table.initialMeterReading,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meterUnit =>
      $composableBuilder(column: $table.meterUnit, builder: (column) => column);

  Expression<T> workLogsRefs<T extends Object>(
    Expression<T> Function($$WorkLogsTableAnnotationComposer a) f,
  ) {
    final $$WorkLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fuelEntriesRefs<T extends Object>(
    Expression<T> Function($$FuelEntriesTableAnnotationComposer a) f,
  ) {
    final $$FuelEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelEntries,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.fuelEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MachinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MachinesTable,
          Machine,
          $$MachinesTableFilterComposer,
          $$MachinesTableOrderingComposer,
          $$MachinesTableAnnotationComposer,
          $$MachinesTableCreateCompanionBuilder,
          $$MachinesTableUpdateCompanionBuilder,
          (Machine, $$MachinesTableReferences),
          Machine,
          PrefetchHooks Function({bool workLogsRefs, bool fuelEntriesRefs})
        > {
  $$MachinesTableTableManager(_$AppDatabase db, $MachinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MachinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MachinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MachinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> registrationNumber = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int> initialMeterReading = const Value.absent(),
                Value<String> meterUnit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MachinesCompanion(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                registrationNumber: registrationNumber,
                serialNumber: serialNumber,
                model: model,
                initialMeterReading: initialMeterReading,
                meterUnit: meterUnit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String createdBy,
                required String updatedBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> registrationNumber = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> model = const Value.absent(),
                required int initialMeterReading,
                Value<String> meterUnit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MachinesCompanion.insert(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                registrationNumber: registrationNumber,
                serialNumber: serialNumber,
                model: model,
                initialMeterReading: initialMeterReading,
                meterUnit: meterUnit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MachinesTable, Machine>(table),
                  $$MachinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workLogsRefs = false, fuelEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workLogsRefs) db.workLogs,
                    if (fuelEntriesRefs) db.fuelEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workLogsRefs)
                        await $_getPrefetchedDataByColumns<
                          Machine,
                          $MachinesTable,
                          WorkLog,
                          $WorkLogsTable
                        >(
                          currentTable: table,
                          referencedTable: $$MachinesTableReferences
                              ._workLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MachinesTableReferences(
                                db,
                                table,
                                p0,
                              ).workLogsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'machine_id',
                          typedResults: items,
                        ),
                      if (fuelEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          Machine,
                          $MachinesTable,
                          FuelEntry,
                          $FuelEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MachinesTableReferences
                              ._fuelEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MachinesTableReferences(
                                db,
                                table,
                                p0,
                              ).fuelEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'machine_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MachinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MachinesTable,
      Machine,
      $$MachinesTableFilterComposer,
      $$MachinesTableOrderingComposer,
      $$MachinesTableAnnotationComposer,
      $$MachinesTableCreateCompanionBuilder,
      $$MachinesTableUpdateCompanionBuilder,
      (Machine, $$MachinesTableReferences),
      Machine,
      PrefetchHooks Function({bool workLogsRefs, bool fuelEntriesRefs})
    >;
typedef $$OperatorsTableCreateCompanionBuilder = OperatorsCompanion Function({
  required String id,
  required String companyId,
  required String name,
  Value<String?> notes,
  Value<bool> isActive,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String createdBy,
  required String updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<String?> phone,
  Value<String?> code,
  Value<int> rowid,
});
typedef $$OperatorsTableUpdateCompanionBuilder = OperatorsCompanion Function({
  Value<String> id,
  Value<String> companyId,
  Value<String> name,
  Value<String?> notes,
  Value<bool> isActive,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> createdBy,
  Value<String> updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<String?> phone,
  Value<String?> code,
  Value<int> rowid,
});

final class $$OperatorsTableReferences
    extends BaseReferences<_$AppDatabase, $OperatorsTable, Operator> {
  $$OperatorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkLogsTable, List<WorkLog>> _workLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.workLogs,
    aliasName: 'operators__id__work_logs__operator_id',
  );

  $$WorkLogsTableProcessedTableManager get workLogsRefs {
    final manager = $$WorkLogsTableTableManager(
      $_db,
      $_db.workLogs,
    ).filter((f) => f.operatorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OperatorsTableFilterComposer
    extends Composer<_$AppDatabase, $OperatorsTable> {
  $$OperatorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workLogsRefs(
    Expression<bool> Function($$WorkLogsTableFilterComposer f) f,
  ) {
    final $$WorkLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.operatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableFilterComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OperatorsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperatorsTable> {
  $$OperatorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OperatorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperatorsTable> {
  $$OperatorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  Expression<T> workLogsRefs<T extends Object>(
    Expression<T> Function($$WorkLogsTableAnnotationComposer a) f,
  ) {
    final $$WorkLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.operatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OperatorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperatorsTable,
          Operator,
          $$OperatorsTableFilterComposer,
          $$OperatorsTableOrderingComposer,
          $$OperatorsTableAnnotationComposer,
          $$OperatorsTableCreateCompanionBuilder,
          $$OperatorsTableUpdateCompanionBuilder,
          (Operator, $$OperatorsTableReferences),
          Operator,
          PrefetchHooks Function({bool workLogsRefs})
        > {
  $$OperatorsTableTableManager(_$AppDatabase db, $OperatorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperatorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperatorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperatorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperatorsCompanion(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                phone: phone,
                code: code,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String createdBy,
                required String updatedBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperatorsCompanion.insert(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                phone: phone,
                code: code,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OperatorsTable, Operator>(table),
                  $$OperatorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (workLogsRefs) db.workLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workLogsRefs)
                    await $_getPrefetchedDataByColumns<
                      Operator,
                      $OperatorsTable,
                      WorkLog,
                      $WorkLogsTable
                    >(
                      currentTable: table,
                      referencedTable: $$OperatorsTableReferences
                          ._workLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$OperatorsTableReferences(
                            db,
                            table,
                            p0,
                          ).workLogsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'operator_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$OperatorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperatorsTable,
      Operator,
      $$OperatorsTableFilterComposer,
      $$OperatorsTableOrderingComposer,
      $$OperatorsTableAnnotationComposer,
      $$OperatorsTableCreateCompanionBuilder,
      $$OperatorsTableUpdateCompanionBuilder,
      (Operator, $$OperatorsTableReferences),
      Operator,
      PrefetchHooks Function({bool workLogsRefs})
    >;
typedef $$PetrolPumpsTableCreateCompanionBuilder =
    PetrolPumpsCompanion Function({
      required String id,
      required String companyId,
      required String name,
      Value<String?> notes,
      Value<bool> isActive,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String createdBy,
      required String updatedBy,
      Value<String> syncStatus,
      Value<int> version,
      Value<String?> phone,
      Value<String?> address,
      Value<int> rowid,
    });
typedef $$PetrolPumpsTableUpdateCompanionBuilder =
    PetrolPumpsCompanion Function({
      Value<String> id,
      Value<String> companyId,
      Value<String> name,
      Value<String?> notes,
      Value<bool> isActive,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> createdBy,
      Value<String> updatedBy,
      Value<String> syncStatus,
      Value<int> version,
      Value<String?> phone,
      Value<String?> address,
      Value<int> rowid,
    });

final class $$PetrolPumpsTableReferences
    extends BaseReferences<_$AppDatabase, $PetrolPumpsTable, PetrolPump> {
  $$PetrolPumpsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FuelEntriesTable, List<FuelEntry>>
  _fuelEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fuelEntries,
    aliasName: 'petrol_pumps__id__fuel_entries__pump_id',
  );

  $$FuelEntriesTableProcessedTableManager get fuelEntriesRefs {
    final manager = $$FuelEntriesTableTableManager(
      $_db,
      $_db.fuelEntries,
    ).filter((f) => f.pumpId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fuelEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PetrolPumpsTableFilterComposer
    extends Composer<_$AppDatabase, $PetrolPumpsTable> {
  $$PetrolPumpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> fuelEntriesRefs(
    Expression<bool> Function($$FuelEntriesTableFilterComposer f) f,
  ) {
    final $$FuelEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelEntries,
      getReferencedColumn: (t) => t.pumpId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelEntriesTableFilterComposer(
            $db: $db,
            $table: $db.fuelEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PetrolPumpsTableOrderingComposer
    extends Composer<_$AppDatabase, $PetrolPumpsTable> {
  $$PetrolPumpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PetrolPumpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PetrolPumpsTable> {
  $$PetrolPumpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  Expression<T> fuelEntriesRefs<T extends Object>(
    Expression<T> Function($$FuelEntriesTableAnnotationComposer a) f,
  ) {
    final $$FuelEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelEntries,
      getReferencedColumn: (t) => t.pumpId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.fuelEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PetrolPumpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PetrolPumpsTable,
          PetrolPump,
          $$PetrolPumpsTableFilterComposer,
          $$PetrolPumpsTableOrderingComposer,
          $$PetrolPumpsTableAnnotationComposer,
          $$PetrolPumpsTableCreateCompanionBuilder,
          $$PetrolPumpsTableUpdateCompanionBuilder,
          (PetrolPump, $$PetrolPumpsTableReferences),
          PetrolPump,
          PrefetchHooks Function({bool fuelEntriesRefs})
        > {
  $$PetrolPumpsTableTableManager(_$AppDatabase db, $PetrolPumpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PetrolPumpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PetrolPumpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PetrolPumpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PetrolPumpsCompanion(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                phone: phone,
                address: address,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String createdBy,
                required String updatedBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PetrolPumpsCompanion.insert(
                id: id,
                companyId: companyId,
                name: name,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                phone: phone,
                address: address,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PetrolPumpsTable, PetrolPump>(table),
                  $$PetrolPumpsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fuelEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (fuelEntriesRefs) db.fuelEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fuelEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      PetrolPump,
                      $PetrolPumpsTable,
                      FuelEntry,
                      $FuelEntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$PetrolPumpsTableReferences
                          ._fuelEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PetrolPumpsTableReferences(
                            db,
                            table,
                            p0,
                          ).fuelEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'pump_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PetrolPumpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PetrolPumpsTable,
      PetrolPump,
      $$PetrolPumpsTableFilterComposer,
      $$PetrolPumpsTableOrderingComposer,
      $$PetrolPumpsTableAnnotationComposer,
      $$PetrolPumpsTableCreateCompanionBuilder,
      $$PetrolPumpsTableUpdateCompanionBuilder,
      (PetrolPump, $$PetrolPumpsTableReferences),
      PetrolPump,
      PrefetchHooks Function({bool fuelEntriesRefs})
    >;
typedef $$WorkLogsTableCreateCompanionBuilder = WorkLogsCompanion Function({
  required String id,
  required String companyId,
  required String workDate,
  required String clientId,
  required String siteId,
  required String machineId,
  Value<String?> operatorId,
  Value<String?> operatorName,
  required int startReading,
  Value<String?> startPhotoPath,
  Value<int?> startCapturedAt,
  Value<double?> startLat,
  Value<double?> startLng,
  Value<double?> startAccuracy,
  Value<String?> startLocationStatus,
  Value<int?> endReading,
  Value<String?> endPhotoPath,
  Value<int?> endCapturedAt,
  Value<double?> endLat,
  Value<double?> endLng,
  Value<double?> endAccuracy,
  Value<String?> endLocationStatus,
  Value<int?> workingHours,
  required String entryMode,
  Value<String?> manualReason,
  Value<String?> notes,
  Value<String?> anomalyFlags,
  required String status,
  Value<String?> statusReason,
  Value<String?> approvedBy,
  Value<int?> approvedAt,
  Value<String?> invoiceId,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String createdBy,
  required String updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<int> rowid,
});
typedef $$WorkLogsTableUpdateCompanionBuilder = WorkLogsCompanion Function({
  Value<String> id,
  Value<String> companyId,
  Value<String> workDate,
  Value<String> clientId,
  Value<String> siteId,
  Value<String> machineId,
  Value<String?> operatorId,
  Value<String?> operatorName,
  Value<int> startReading,
  Value<String?> startPhotoPath,
  Value<int?> startCapturedAt,
  Value<double?> startLat,
  Value<double?> startLng,
  Value<double?> startAccuracy,
  Value<String?> startLocationStatus,
  Value<int?> endReading,
  Value<String?> endPhotoPath,
  Value<int?> endCapturedAt,
  Value<double?> endLat,
  Value<double?> endLng,
  Value<double?> endAccuracy,
  Value<String?> endLocationStatus,
  Value<int?> workingHours,
  Value<String> entryMode,
  Value<String?> manualReason,
  Value<String?> notes,
  Value<String?> anomalyFlags,
  Value<String> status,
  Value<String?> statusReason,
  Value<String?> approvedBy,
  Value<int?> approvedAt,
  Value<String?> invoiceId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> createdBy,
  Value<String> updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<int> rowid,
});

final class $$WorkLogsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkLogsTable, WorkLog> {
  $$WorkLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClientsTable _clientIdTable(_$AppDatabase db) =>
      db.clients.createAlias('work_logs__client_id__clients__id');

  $$ClientsTableProcessedTableManager get clientId {
    final $_column = $_itemColumn<String>('client_id')!;

    final manager = $$ClientsTableTableManager(
      $_db,
      $_db.clients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SitesTable _siteIdTable(_$AppDatabase db) =>
      db.sites.createAlias('work_logs__site_id__sites__id');

  $$SitesTableProcessedTableManager get siteId {
    final $_column = $_itemColumn<String>('site_id')!;

    final manager = $$SitesTableTableManager(
      $_db,
      $_db.sites,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_siteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MachinesTable _machineIdTable(_$AppDatabase db) =>
      db.machines.createAlias('work_logs__machine_id__machines__id');

  $$MachinesTableProcessedTableManager get machineId {
    final $_column = $_itemColumn<String>('machine_id')!;

    final manager = $$MachinesTableTableManager(
      $_db,
      $_db.machines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_machineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $OperatorsTable _operatorIdTable(_$AppDatabase db) =>
      db.operators.createAlias('work_logs__operator_id__operators__id');

  $$OperatorsTableProcessedTableManager? get operatorId {
    final $_column = $_itemColumn<String>('operator_id');
    if ($_column == null) return null;
    final manager = $$OperatorsTableTableManager(
      $_db,
      $_db.operators,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operatorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InvoiceLinesTable, List<InvoiceLine>>
  _invoiceLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invoiceLines,
    aliasName: 'work_logs__id__invoice_lines__work_log_id',
  );

  $$InvoiceLinesTableProcessedTableManager get invoiceLinesRefs {
    final manager = $$InvoiceLinesTableTableManager(
      $_db,
      $_db.invoiceLines,
    ).filter((f) => f.workLogId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkLogsTable> {
  $$WorkLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workDate => $composableBuilder(
    column: $table.workDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startReading => $composableBuilder(
    column: $table.startReading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startPhotoPath => $composableBuilder(
    column: $table.startPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startCapturedAt => $composableBuilder(
    column: $table.startCapturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startAccuracy => $composableBuilder(
    column: $table.startAccuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startLocationStatus => $composableBuilder(
    column: $table.startLocationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endReading => $composableBuilder(
    column: $table.endReading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endPhotoPath => $composableBuilder(
    column: $table.endPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endCapturedAt => $composableBuilder(
    column: $table.endCapturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endAccuracy => $composableBuilder(
    column: $table.endAccuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endLocationStatus => $composableBuilder(
    column: $table.endLocationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workingHours => $composableBuilder(
    column: $table.workingHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryMode => $composableBuilder(
    column: $table.entryMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manualReason => $composableBuilder(
    column: $table.manualReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anomalyFlags => $composableBuilder(
    column: $table.anomalyFlags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusReason => $composableBuilder(
    column: $table.statusReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceId => $composableBuilder(
    column: $table.invoiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  $$ClientsTableFilterComposer get clientId {
    final $$ClientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableFilterComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SitesTableFilterComposer get siteId {
    final $$SitesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableFilterComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MachinesTableFilterComposer get machineId {
    final $$MachinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.machines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MachinesTableFilterComposer(
            $db: $db,
            $table: $db.machines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OperatorsTableFilterComposer get operatorId {
    final $$OperatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operatorId,
      referencedTable: $db.operators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperatorsTableFilterComposer(
            $db: $db,
            $table: $db.operators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> invoiceLinesRefs(
    Expression<bool> Function($$InvoiceLinesTableFilterComposer f) f,
  ) {
    final $$InvoiceLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceLines,
      getReferencedColumn: (t) => t.workLogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceLinesTableFilterComposer(
            $db: $db,
            $table: $db.invoiceLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkLogsTable> {
  $$WorkLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workDate => $composableBuilder(
    column: $table.workDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startReading => $composableBuilder(
    column: $table.startReading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startPhotoPath => $composableBuilder(
    column: $table.startPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startCapturedAt => $composableBuilder(
    column: $table.startCapturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startAccuracy => $composableBuilder(
    column: $table.startAccuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startLocationStatus => $composableBuilder(
    column: $table.startLocationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endReading => $composableBuilder(
    column: $table.endReading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endPhotoPath => $composableBuilder(
    column: $table.endPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endCapturedAt => $composableBuilder(
    column: $table.endCapturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endAccuracy => $composableBuilder(
    column: $table.endAccuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endLocationStatus => $composableBuilder(
    column: $table.endLocationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workingHours => $composableBuilder(
    column: $table.workingHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryMode => $composableBuilder(
    column: $table.entryMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manualReason => $composableBuilder(
    column: $table.manualReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anomalyFlags => $composableBuilder(
    column: $table.anomalyFlags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusReason => $composableBuilder(
    column: $table.statusReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceId => $composableBuilder(
    column: $table.invoiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClientsTableOrderingComposer get clientId {
    final $$ClientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableOrderingComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SitesTableOrderingComposer get siteId {
    final $$SitesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableOrderingComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MachinesTableOrderingComposer get machineId {
    final $$MachinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.machines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MachinesTableOrderingComposer(
            $db: $db,
            $table: $db.machines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OperatorsTableOrderingComposer get operatorId {
    final $$OperatorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operatorId,
      referencedTable: $db.operators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperatorsTableOrderingComposer(
            $db: $db,
            $table: $db.operators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkLogsTable> {
  $$WorkLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get workDate =>
      $composableBuilder(column: $table.workDate, builder: (column) => column);

  GeneratedColumn<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startReading => $composableBuilder(
    column: $table.startReading,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startPhotoPath => $composableBuilder(
    column: $table.startPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startCapturedAt => $composableBuilder(
    column: $table.startCapturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get startLat =>
      $composableBuilder(column: $table.startLat, builder: (column) => column);

  GeneratedColumn<double> get startLng =>
      $composableBuilder(column: $table.startLng, builder: (column) => column);

  GeneratedColumn<double> get startAccuracy => $composableBuilder(
    column: $table.startAccuracy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startLocationStatus => $composableBuilder(
    column: $table.startLocationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endReading => $composableBuilder(
    column: $table.endReading,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endPhotoPath => $composableBuilder(
    column: $table.endPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endCapturedAt => $composableBuilder(
    column: $table.endCapturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get endLat =>
      $composableBuilder(column: $table.endLat, builder: (column) => column);

  GeneratedColumn<double> get endLng =>
      $composableBuilder(column: $table.endLng, builder: (column) => column);

  GeneratedColumn<double> get endAccuracy => $composableBuilder(
    column: $table.endAccuracy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endLocationStatus => $composableBuilder(
    column: $table.endLocationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workingHours => $composableBuilder(
    column: $table.workingHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryMode =>
      $composableBuilder(column: $table.entryMode, builder: (column) => column);

  GeneratedColumn<String> get manualReason => $composableBuilder(
    column: $table.manualReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get anomalyFlags => $composableBuilder(
    column: $table.anomalyFlags,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get statusReason => $composableBuilder(
    column: $table.statusReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceId =>
      $composableBuilder(column: $table.invoiceId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  $$ClientsTableAnnotationComposer get clientId {
    final $$ClientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableAnnotationComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SitesTableAnnotationComposer get siteId {
    final $$SitesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableAnnotationComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MachinesTableAnnotationComposer get machineId {
    final $$MachinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.machines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MachinesTableAnnotationComposer(
            $db: $db,
            $table: $db.machines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OperatorsTableAnnotationComposer get operatorId {
    final $$OperatorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operatorId,
      referencedTable: $db.operators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperatorsTableAnnotationComposer(
            $db: $db,
            $table: $db.operators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> invoiceLinesRefs<T extends Object>(
    Expression<T> Function($$InvoiceLinesTableAnnotationComposer a) f,
  ) {
    final $$InvoiceLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceLines,
      getReferencedColumn: (t) => t.workLogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkLogsTable,
          WorkLog,
          $$WorkLogsTableFilterComposer,
          $$WorkLogsTableOrderingComposer,
          $$WorkLogsTableAnnotationComposer,
          $$WorkLogsTableCreateCompanionBuilder,
          $$WorkLogsTableUpdateCompanionBuilder,
          (WorkLog, $$WorkLogsTableReferences),
          WorkLog,
          PrefetchHooks Function({
            bool clientId,
            bool siteId,
            bool machineId,
            bool operatorId,
            bool invoiceLinesRefs,
          })
        > {
  $$WorkLogsTableTableManager(_$AppDatabase db, $WorkLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> workDate = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> machineId = const Value.absent(),
                Value<String?> operatorId = const Value.absent(),
                Value<String?> operatorName = const Value.absent(),
                Value<int> startReading = const Value.absent(),
                Value<String?> startPhotoPath = const Value.absent(),
                Value<int?> startCapturedAt = const Value.absent(),
                Value<double?> startLat = const Value.absent(),
                Value<double?> startLng = const Value.absent(),
                Value<double?> startAccuracy = const Value.absent(),
                Value<String?> startLocationStatus = const Value.absent(),
                Value<int?> endReading = const Value.absent(),
                Value<String?> endPhotoPath = const Value.absent(),
                Value<int?> endCapturedAt = const Value.absent(),
                Value<double?> endLat = const Value.absent(),
                Value<double?> endLng = const Value.absent(),
                Value<double?> endAccuracy = const Value.absent(),
                Value<String?> endLocationStatus = const Value.absent(),
                Value<int?> workingHours = const Value.absent(),
                Value<String> entryMode = const Value.absent(),
                Value<String?> manualReason = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> anomalyFlags = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> statusReason = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<int?> approvedAt = const Value.absent(),
                Value<String?> invoiceId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkLogsCompanion(
                id: id,
                companyId: companyId,
                workDate: workDate,
                clientId: clientId,
                siteId: siteId,
                machineId: machineId,
                operatorId: operatorId,
                operatorName: operatorName,
                startReading: startReading,
                startPhotoPath: startPhotoPath,
                startCapturedAt: startCapturedAt,
                startLat: startLat,
                startLng: startLng,
                startAccuracy: startAccuracy,
                startLocationStatus: startLocationStatus,
                endReading: endReading,
                endPhotoPath: endPhotoPath,
                endCapturedAt: endCapturedAt,
                endLat: endLat,
                endLng: endLng,
                endAccuracy: endAccuracy,
                endLocationStatus: endLocationStatus,
                workingHours: workingHours,
                entryMode: entryMode,
                manualReason: manualReason,
                notes: notes,
                anomalyFlags: anomalyFlags,
                status: status,
                statusReason: statusReason,
                approvedBy: approvedBy,
                approvedAt: approvedAt,
                invoiceId: invoiceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String workDate,
                required String clientId,
                required String siteId,
                required String machineId,
                Value<String?> operatorId = const Value.absent(),
                Value<String?> operatorName = const Value.absent(),
                required int startReading,
                Value<String?> startPhotoPath = const Value.absent(),
                Value<int?> startCapturedAt = const Value.absent(),
                Value<double?> startLat = const Value.absent(),
                Value<double?> startLng = const Value.absent(),
                Value<double?> startAccuracy = const Value.absent(),
                Value<String?> startLocationStatus = const Value.absent(),
                Value<int?> endReading = const Value.absent(),
                Value<String?> endPhotoPath = const Value.absent(),
                Value<int?> endCapturedAt = const Value.absent(),
                Value<double?> endLat = const Value.absent(),
                Value<double?> endLng = const Value.absent(),
                Value<double?> endAccuracy = const Value.absent(),
                Value<String?> endLocationStatus = const Value.absent(),
                Value<int?> workingHours = const Value.absent(),
                required String entryMode,
                Value<String?> manualReason = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> anomalyFlags = const Value.absent(),
                required String status,
                Value<String?> statusReason = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<int?> approvedAt = const Value.absent(),
                Value<String?> invoiceId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String createdBy,
                required String updatedBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkLogsCompanion.insert(
                id: id,
                companyId: companyId,
                workDate: workDate,
                clientId: clientId,
                siteId: siteId,
                machineId: machineId,
                operatorId: operatorId,
                operatorName: operatorName,
                startReading: startReading,
                startPhotoPath: startPhotoPath,
                startCapturedAt: startCapturedAt,
                startLat: startLat,
                startLng: startLng,
                startAccuracy: startAccuracy,
                startLocationStatus: startLocationStatus,
                endReading: endReading,
                endPhotoPath: endPhotoPath,
                endCapturedAt: endCapturedAt,
                endLat: endLat,
                endLng: endLng,
                endAccuracy: endAccuracy,
                endLocationStatus: endLocationStatus,
                workingHours: workingHours,
                entryMode: entryMode,
                manualReason: manualReason,
                notes: notes,
                anomalyFlags: anomalyFlags,
                status: status,
                statusReason: statusReason,
                approvedBy: approvedBy,
                approvedAt: approvedAt,
                invoiceId: invoiceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkLogsTable, WorkLog>(table),
                  $$WorkLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                clientId = false,
                siteId = false,
                machineId = false,
                operatorId = false,
                invoiceLinesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (invoiceLinesRefs) db.invoiceLines,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (clientId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.clientId,
                            referencedTable: $$WorkLogsTableReferences
                                ._clientIdTable(db),
                            referencedColumn: $$WorkLogsTableReferences
                                ._clientIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (siteId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.siteId,
                            referencedTable: $$WorkLogsTableReferences
                                ._siteIdTable(db),
                            referencedColumn: $$WorkLogsTableReferences
                                ._siteIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (machineId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.machineId,
                            referencedTable: $$WorkLogsTableReferences
                                ._machineIdTable(db),
                            referencedColumn: $$WorkLogsTableReferences
                                ._machineIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (operatorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.operatorId,
                            referencedTable: $$WorkLogsTableReferences
                                ._operatorIdTable(db),
                            referencedColumn: $$WorkLogsTableReferences
                                ._operatorIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (invoiceLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkLog,
                          $WorkLogsTable,
                          InvoiceLine,
                          $InvoiceLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkLogsTableReferences
                              ._invoiceLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkLogsTableReferences(
                                db,
                                table,
                                p0,
                              ).invoiceLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'work_log_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkLogsTable,
      WorkLog,
      $$WorkLogsTableFilterComposer,
      $$WorkLogsTableOrderingComposer,
      $$WorkLogsTableAnnotationComposer,
      $$WorkLogsTableCreateCompanionBuilder,
      $$WorkLogsTableUpdateCompanionBuilder,
      (WorkLog, $$WorkLogsTableReferences),
      WorkLog,
      PrefetchHooks Function({
        bool clientId,
        bool siteId,
        bool machineId,
        bool operatorId,
        bool invoiceLinesRefs,
      })
    >;
typedef $$FuelEntriesTableCreateCompanionBuilder =
    FuelEntriesCompanion Function({
      required String id,
      required String companyId,
      required int filledAt,
      required String fuelDate,
      required String machineId,
      required String pumpId,
      Value<String?> clientId,
      Value<String?> siteId,
      required int litresCl,
      required int pricePerLitrePaise,
      required int totalPaise,
      Value<String?> receiptPhotoPath,
      Value<int?> receiptCapturedAt,
      Value<double?> receiptLat,
      Value<double?> receiptLng,
      Value<double?> receiptAccuracy,
      Value<String?> receiptLocationStatus,
      Value<String?> notes,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      required String createdBy,
      required String updatedBy,
      Value<String> syncStatus,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$FuelEntriesTableUpdateCompanionBuilder =
    FuelEntriesCompanion Function({
      Value<String> id,
      Value<String> companyId,
      Value<int> filledAt,
      Value<String> fuelDate,
      Value<String> machineId,
      Value<String> pumpId,
      Value<String?> clientId,
      Value<String?> siteId,
      Value<int> litresCl,
      Value<int> pricePerLitrePaise,
      Value<int> totalPaise,
      Value<String?> receiptPhotoPath,
      Value<int?> receiptCapturedAt,
      Value<double?> receiptLat,
      Value<double?> receiptLng,
      Value<double?> receiptAccuracy,
      Value<String?> receiptLocationStatus,
      Value<String?> notes,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> createdBy,
      Value<String> updatedBy,
      Value<String> syncStatus,
      Value<int> version,
      Value<int> rowid,
    });

final class $$FuelEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $FuelEntriesTable, FuelEntry> {
  $$FuelEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MachinesTable _machineIdTable(_$AppDatabase db) =>
      db.machines.createAlias('fuel_entries__machine_id__machines__id');

  $$MachinesTableProcessedTableManager get machineId {
    final $_column = $_itemColumn<String>('machine_id')!;

    final manager = $$MachinesTableTableManager(
      $_db,
      $_db.machines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_machineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PetrolPumpsTable _pumpIdTable(_$AppDatabase db) =>
      db.petrolPumps.createAlias('fuel_entries__pump_id__petrol_pumps__id');

  $$PetrolPumpsTableProcessedTableManager get pumpId {
    final $_column = $_itemColumn<String>('pump_id')!;

    final manager = $$PetrolPumpsTableTableManager(
      $_db,
      $_db.petrolPumps,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pumpIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ClientsTable _clientIdTable(_$AppDatabase db) =>
      db.clients.createAlias('fuel_entries__client_id__clients__id');

  $$ClientsTableProcessedTableManager? get clientId {
    final $_column = $_itemColumn<String>('client_id');
    if ($_column == null) return null;
    final manager = $$ClientsTableTableManager(
      $_db,
      $_db.clients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SitesTable _siteIdTable(_$AppDatabase db) =>
      db.sites.createAlias('fuel_entries__site_id__sites__id');

  $$SitesTableProcessedTableManager? get siteId {
    final $_column = $_itemColumn<String>('site_id');
    if ($_column == null) return null;
    final manager = $$SitesTableTableManager(
      $_db,
      $_db.sites,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_siteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FuelEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FuelEntriesTable> {
  $$FuelEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get filledAt => $composableBuilder(
    column: $table.filledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fuelDate => $composableBuilder(
    column: $table.fuelDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get litresCl => $composableBuilder(
    column: $table.litresCl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pricePerLitrePaise => $composableBuilder(
    column: $table.pricePerLitrePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptPhotoPath => $composableBuilder(
    column: $table.receiptPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receiptCapturedAt => $composableBuilder(
    column: $table.receiptCapturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get receiptLat => $composableBuilder(
    column: $table.receiptLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get receiptLng => $composableBuilder(
    column: $table.receiptLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get receiptAccuracy => $composableBuilder(
    column: $table.receiptAccuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptLocationStatus => $composableBuilder(
    column: $table.receiptLocationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  $$MachinesTableFilterComposer get machineId {
    final $$MachinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.machines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MachinesTableFilterComposer(
            $db: $db,
            $table: $db.machines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PetrolPumpsTableFilterComposer get pumpId {
    final $$PetrolPumpsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pumpId,
      referencedTable: $db.petrolPumps,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetrolPumpsTableFilterComposer(
            $db: $db,
            $table: $db.petrolPumps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClientsTableFilterComposer get clientId {
    final $$ClientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableFilterComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SitesTableFilterComposer get siteId {
    final $$SitesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableFilterComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FuelEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FuelEntriesTable> {
  $$FuelEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get filledAt => $composableBuilder(
    column: $table.filledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelDate => $composableBuilder(
    column: $table.fuelDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get litresCl => $composableBuilder(
    column: $table.litresCl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pricePerLitrePaise => $composableBuilder(
    column: $table.pricePerLitrePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptPhotoPath => $composableBuilder(
    column: $table.receiptPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receiptCapturedAt => $composableBuilder(
    column: $table.receiptCapturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get receiptLat => $composableBuilder(
    column: $table.receiptLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get receiptLng => $composableBuilder(
    column: $table.receiptLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get receiptAccuracy => $composableBuilder(
    column: $table.receiptAccuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptLocationStatus => $composableBuilder(
    column: $table.receiptLocationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  $$MachinesTableOrderingComposer get machineId {
    final $$MachinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.machines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MachinesTableOrderingComposer(
            $db: $db,
            $table: $db.machines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PetrolPumpsTableOrderingComposer get pumpId {
    final $$PetrolPumpsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pumpId,
      referencedTable: $db.petrolPumps,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetrolPumpsTableOrderingComposer(
            $db: $db,
            $table: $db.petrolPumps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClientsTableOrderingComposer get clientId {
    final $$ClientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableOrderingComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SitesTableOrderingComposer get siteId {
    final $$SitesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableOrderingComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FuelEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FuelEntriesTable> {
  $$FuelEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<int> get filledAt =>
      $composableBuilder(column: $table.filledAt, builder: (column) => column);

  GeneratedColumn<String> get fuelDate =>
      $composableBuilder(column: $table.fuelDate, builder: (column) => column);

  GeneratedColumn<int> get litresCl =>
      $composableBuilder(column: $table.litresCl, builder: (column) => column);

  GeneratedColumn<int> get pricePerLitrePaise => $composableBuilder(
    column: $table.pricePerLitrePaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptPhotoPath => $composableBuilder(
    column: $table.receiptPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receiptCapturedAt => $composableBuilder(
    column: $table.receiptCapturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get receiptLat => $composableBuilder(
    column: $table.receiptLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get receiptLng => $composableBuilder(
    column: $table.receiptLng,
    builder: (column) => column,
  );

  GeneratedColumn<double> get receiptAccuracy => $composableBuilder(
    column: $table.receiptAccuracy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptLocationStatus => $composableBuilder(
    column: $table.receiptLocationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  $$MachinesTableAnnotationComposer get machineId {
    final $$MachinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.machines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MachinesTableAnnotationComposer(
            $db: $db,
            $table: $db.machines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PetrolPumpsTableAnnotationComposer get pumpId {
    final $$PetrolPumpsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pumpId,
      referencedTable: $db.petrolPumps,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetrolPumpsTableAnnotationComposer(
            $db: $db,
            $table: $db.petrolPumps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClientsTableAnnotationComposer get clientId {
    final $$ClientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableAnnotationComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SitesTableAnnotationComposer get siteId {
    final $$SitesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.siteId,
      referencedTable: $db.sites,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SitesTableAnnotationComposer(
            $db: $db,
            $table: $db.sites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FuelEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FuelEntriesTable,
          FuelEntry,
          $$FuelEntriesTableFilterComposer,
          $$FuelEntriesTableOrderingComposer,
          $$FuelEntriesTableAnnotationComposer,
          $$FuelEntriesTableCreateCompanionBuilder,
          $$FuelEntriesTableUpdateCompanionBuilder,
          (FuelEntry, $$FuelEntriesTableReferences),
          FuelEntry,
          PrefetchHooks Function({
            bool machineId,
            bool pumpId,
            bool clientId,
            bool siteId,
          })
        > {
  $$FuelEntriesTableTableManager(_$AppDatabase db, $FuelEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FuelEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FuelEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FuelEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<int> filledAt = const Value.absent(),
                Value<String> fuelDate = const Value.absent(),
                Value<String> machineId = const Value.absent(),
                Value<String> pumpId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> siteId = const Value.absent(),
                Value<int> litresCl = const Value.absent(),
                Value<int> pricePerLitrePaise = const Value.absent(),
                Value<int> totalPaise = const Value.absent(),
                Value<String?> receiptPhotoPath = const Value.absent(),
                Value<int?> receiptCapturedAt = const Value.absent(),
                Value<double?> receiptLat = const Value.absent(),
                Value<double?> receiptLng = const Value.absent(),
                Value<double?> receiptAccuracy = const Value.absent(),
                Value<String?> receiptLocationStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FuelEntriesCompanion(
                id: id,
                companyId: companyId,
                filledAt: filledAt,
                fuelDate: fuelDate,
                machineId: machineId,
                pumpId: pumpId,
                clientId: clientId,
                siteId: siteId,
                litresCl: litresCl,
                pricePerLitrePaise: pricePerLitrePaise,
                totalPaise: totalPaise,
                receiptPhotoPath: receiptPhotoPath,
                receiptCapturedAt: receiptCapturedAt,
                receiptLat: receiptLat,
                receiptLng: receiptLng,
                receiptAccuracy: receiptAccuracy,
                receiptLocationStatus: receiptLocationStatus,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required int filledAt,
                required String fuelDate,
                required String machineId,
                required String pumpId,
                Value<String?> clientId = const Value.absent(),
                Value<String?> siteId = const Value.absent(),
                required int litresCl,
                required int pricePerLitrePaise,
                required int totalPaise,
                Value<String?> receiptPhotoPath = const Value.absent(),
                Value<int?> receiptCapturedAt = const Value.absent(),
                Value<double?> receiptLat = const Value.absent(),
                Value<double?> receiptLng = const Value.absent(),
                Value<double?> receiptAccuracy = const Value.absent(),
                Value<String?> receiptLocationStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String createdBy,
                required String updatedBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FuelEntriesCompanion.insert(
                id: id,
                companyId: companyId,
                filledAt: filledAt,
                fuelDate: fuelDate,
                machineId: machineId,
                pumpId: pumpId,
                clientId: clientId,
                siteId: siteId,
                litresCl: litresCl,
                pricePerLitrePaise: pricePerLitrePaise,
                totalPaise: totalPaise,
                receiptPhotoPath: receiptPhotoPath,
                receiptCapturedAt: receiptCapturedAt,
                receiptLat: receiptLat,
                receiptLng: receiptLng,
                receiptAccuracy: receiptAccuracy,
                receiptLocationStatus: receiptLocationStatus,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FuelEntriesTable, FuelEntry>(table),
                  $$FuelEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                machineId = false,
                pumpId = false,
                clientId = false,
                siteId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (machineId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.machineId,
                            referencedTable: $$FuelEntriesTableReferences
                                ._machineIdTable(db),
                            referencedColumn: $$FuelEntriesTableReferences
                                ._machineIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (pumpId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.pumpId,
                            referencedTable: $$FuelEntriesTableReferences
                                ._pumpIdTable(db),
                            referencedColumn: $$FuelEntriesTableReferences
                                ._pumpIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (clientId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.clientId,
                            referencedTable: $$FuelEntriesTableReferences
                                ._clientIdTable(db),
                            referencedColumn: $$FuelEntriesTableReferences
                                ._clientIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (siteId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.siteId,
                            referencedTable: $$FuelEntriesTableReferences
                                ._siteIdTable(db),
                            referencedColumn: $$FuelEntriesTableReferences
                                ._siteIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$FuelEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FuelEntriesTable,
      FuelEntry,
      $$FuelEntriesTableFilterComposer,
      $$FuelEntriesTableOrderingComposer,
      $$FuelEntriesTableAnnotationComposer,
      $$FuelEntriesTableCreateCompanionBuilder,
      $$FuelEntriesTableUpdateCompanionBuilder,
      (FuelEntry, $$FuelEntriesTableReferences),
      FuelEntry,
      PrefetchHooks Function({
        bool machineId,
        bool pumpId,
        bool clientId,
        bool siteId,
      })
    >;
typedef $$InvoicesTableCreateCompanionBuilder = InvoicesCompanion Function({
  required String id,
  required String companyId,
  required String clientId,
  Value<String?> invoiceNumber,
  required String status,
  required String invoiceDate,
  required String periodFrom,
  required String periodTo,
  required int paymentTermsDays,
  required String dueDate,
  Value<String?> notes,
  required int subtotalPaise,
  Value<int> discountPaise,
  required int totalPaise,
  Value<String?> companySnapshot,
  Value<String?> clientSnapshot,
  Value<int?> finalizedAt,
  Value<String?> finalizedBy,
  Value<int?> cancelledAt,
  Value<String?> cancelledBy,
  Value<String?> cancelReason,
  Value<String?> pdfPath,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  required String createdBy,
  required String updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<int> rowid,
});
typedef $$InvoicesTableUpdateCompanionBuilder = InvoicesCompanion Function({
  Value<String> id,
  Value<String> companyId,
  Value<String> clientId,
  Value<String?> invoiceNumber,
  Value<String> status,
  Value<String> invoiceDate,
  Value<String> periodFrom,
  Value<String> periodTo,
  Value<int> paymentTermsDays,
  Value<String> dueDate,
  Value<String?> notes,
  Value<int> subtotalPaise,
  Value<int> discountPaise,
  Value<int> totalPaise,
  Value<String?> companySnapshot,
  Value<String?> clientSnapshot,
  Value<int?> finalizedAt,
  Value<String?> finalizedBy,
  Value<int?> cancelledAt,
  Value<String?> cancelledBy,
  Value<String?> cancelReason,
  Value<String?> pdfPath,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String> createdBy,
  Value<String> updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<int> rowid,
});

final class $$InvoicesTableReferences
    extends BaseReferences<_$AppDatabase, $InvoicesTable, Invoice> {
  $$InvoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClientsTable _clientIdTable(_$AppDatabase db) =>
      db.clients.createAlias('invoices__client_id__clients__id');

  $$ClientsTableProcessedTableManager get clientId {
    final $_column = $_itemColumn<String>('client_id')!;

    final manager = $$ClientsTableTableManager(
      $_db,
      $_db.clients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InvoiceLinesTable, List<InvoiceLine>>
  _invoiceLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invoiceLines,
    aliasName: 'invoices__id__invoice_lines__invoice_id',
  );

  $$InvoiceLinesTableProcessedTableManager get invoiceLinesRefs {
    final manager = $$InvoiceLinesTableTableManager(
      $_db,
      $_db.invoiceLines,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentsTable, List<Payment>> _paymentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.payments,
    aliasName: 'invoices__id__payments__invoice_id',
  );

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager(
      $_db,
      $_db.payments,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodFrom => $composableBuilder(
    column: $table.periodFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodTo => $composableBuilder(
    column: $table.periodTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentTermsDays => $composableBuilder(
    column: $table.paymentTermsDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalPaise => $composableBuilder(
    column: $table.subtotalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountPaise => $composableBuilder(
    column: $table.discountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companySnapshot => $composableBuilder(
    column: $table.companySnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientSnapshot => $composableBuilder(
    column: $table.clientSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalizedBy => $composableBuilder(
    column: $table.finalizedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelledBy => $composableBuilder(
    column: $table.cancelledBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  $$ClientsTableFilterComposer get clientId {
    final $$ClientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableFilterComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> invoiceLinesRefs(
    Expression<bool> Function($$InvoiceLinesTableFilterComposer f) f,
  ) {
    final $$InvoiceLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceLines,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceLinesTableFilterComposer(
            $db: $db,
            $table: $db.invoiceLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentsRefs(
    Expression<bool> Function($$PaymentsTableFilterComposer f) f,
  ) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableFilterComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodFrom => $composableBuilder(
    column: $table.periodFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodTo => $composableBuilder(
    column: $table.periodTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentTermsDays => $composableBuilder(
    column: $table.paymentTermsDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalPaise => $composableBuilder(
    column: $table.subtotalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountPaise => $composableBuilder(
    column: $table.discountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companySnapshot => $composableBuilder(
    column: $table.companySnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientSnapshot => $composableBuilder(
    column: $table.clientSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalizedBy => $composableBuilder(
    column: $table.finalizedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelledBy => $composableBuilder(
    column: $table.cancelledBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClientsTableOrderingComposer get clientId {
    final $$ClientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableOrderingComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodFrom => $composableBuilder(
    column: $table.periodFrom,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodTo =>
      $composableBuilder(column: $table.periodTo, builder: (column) => column);

  GeneratedColumn<int> get paymentTermsDays => $composableBuilder(
    column: $table.paymentTermsDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get subtotalPaise => $composableBuilder(
    column: $table.subtotalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountPaise => $composableBuilder(
    column: $table.discountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companySnapshot => $composableBuilder(
    column: $table.companySnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientSnapshot => $composableBuilder(
    column: $table.clientSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalizedBy => $composableBuilder(
    column: $table.finalizedBy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cancelledBy => $composableBuilder(
    column: $table.cancelledBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pdfPath =>
      $composableBuilder(column: $table.pdfPath, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  $$ClientsTableAnnotationComposer get clientId {
    final $$ClientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientId,
      referencedTable: $db.clients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientsTableAnnotationComposer(
            $db: $db,
            $table: $db.clients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> invoiceLinesRefs<T extends Object>(
    Expression<T> Function($$InvoiceLinesTableAnnotationComposer a) f,
  ) {
    final $$InvoiceLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceLines,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoicesTable,
          Invoice,
          $$InvoicesTableFilterComposer,
          $$InvoicesTableOrderingComposer,
          $$InvoicesTableAnnotationComposer,
          $$InvoicesTableCreateCompanionBuilder,
          $$InvoicesTableUpdateCompanionBuilder,
          (Invoice, $$InvoicesTableReferences),
          Invoice,
          PrefetchHooks Function({
            bool clientId,
            bool invoiceLinesRefs,
            bool paymentsRefs,
          })
        > {
  $$InvoicesTableTableManager(_$AppDatabase db, $InvoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> invoiceDate = const Value.absent(),
                Value<String> periodFrom = const Value.absent(),
                Value<String> periodTo = const Value.absent(),
                Value<int> paymentTermsDays = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> subtotalPaise = const Value.absent(),
                Value<int> discountPaise = const Value.absent(),
                Value<int> totalPaise = const Value.absent(),
                Value<String?> companySnapshot = const Value.absent(),
                Value<String?> clientSnapshot = const Value.absent(),
                Value<int?> finalizedAt = const Value.absent(),
                Value<String?> finalizedBy = const Value.absent(),
                Value<int?> cancelledAt = const Value.absent(),
                Value<String?> cancelledBy = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesCompanion(
                id: id,
                companyId: companyId,
                clientId: clientId,
                invoiceNumber: invoiceNumber,
                status: status,
                invoiceDate: invoiceDate,
                periodFrom: periodFrom,
                periodTo: periodTo,
                paymentTermsDays: paymentTermsDays,
                dueDate: dueDate,
                notes: notes,
                subtotalPaise: subtotalPaise,
                discountPaise: discountPaise,
                totalPaise: totalPaise,
                companySnapshot: companySnapshot,
                clientSnapshot: clientSnapshot,
                finalizedAt: finalizedAt,
                finalizedBy: finalizedBy,
                cancelledAt: cancelledAt,
                cancelledBy: cancelledBy,
                cancelReason: cancelReason,
                pdfPath: pdfPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String clientId,
                Value<String?> invoiceNumber = const Value.absent(),
                required String status,
                required String invoiceDate,
                required String periodFrom,
                required String periodTo,
                required int paymentTermsDays,
                required String dueDate,
                Value<String?> notes = const Value.absent(),
                required int subtotalPaise,
                Value<int> discountPaise = const Value.absent(),
                required int totalPaise,
                Value<String?> companySnapshot = const Value.absent(),
                Value<String?> clientSnapshot = const Value.absent(),
                Value<int?> finalizedAt = const Value.absent(),
                Value<String?> finalizedBy = const Value.absent(),
                Value<int?> cancelledAt = const Value.absent(),
                Value<String?> cancelledBy = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String createdBy,
                required String updatedBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesCompanion.insert(
                id: id,
                companyId: companyId,
                clientId: clientId,
                invoiceNumber: invoiceNumber,
                status: status,
                invoiceDate: invoiceDate,
                periodFrom: periodFrom,
                periodTo: periodTo,
                paymentTermsDays: paymentTermsDays,
                dueDate: dueDate,
                notes: notes,
                subtotalPaise: subtotalPaise,
                discountPaise: discountPaise,
                totalPaise: totalPaise,
                companySnapshot: companySnapshot,
                clientSnapshot: clientSnapshot,
                finalizedAt: finalizedAt,
                finalizedBy: finalizedBy,
                cancelledAt: cancelledAt,
                cancelledBy: cancelledBy,
                cancelReason: cancelReason,
                pdfPath: pdfPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvoicesTable, Invoice>(table),
                  $$InvoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                clientId = false,
                invoiceLinesRefs = false,
                paymentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (invoiceLinesRefs) db.invoiceLines,
                    if (paymentsRefs) db.payments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (clientId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.clientId,
                            referencedTable: $$InvoicesTableReferences
                                ._clientIdTable(db),
                            referencedColumn: $$InvoicesTableReferences
                                ._clientIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (invoiceLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          Invoice,
                          $InvoicesTable,
                          InvoiceLine,
                          $InvoiceLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
                              ._invoiceLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).invoiceLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'invoice_id',
                          typedResults: items,
                        ),
                      if (paymentsRefs)
                        await $_getPrefetchedDataByColumns<
                          Invoice,
                          $InvoicesTable,
                          Payment,
                          $PaymentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
                              ._paymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'invoice_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$InvoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoicesTable,
      Invoice,
      $$InvoicesTableFilterComposer,
      $$InvoicesTableOrderingComposer,
      $$InvoicesTableAnnotationComposer,
      $$InvoicesTableCreateCompanionBuilder,
      $$InvoicesTableUpdateCompanionBuilder,
      (Invoice, $$InvoicesTableReferences),
      Invoice,
      PrefetchHooks Function({
        bool clientId,
        bool invoiceLinesRefs,
        bool paymentsRefs,
      })
    >;
typedef $$InvoiceLinesTableCreateCompanionBuilder =
    InvoiceLinesCompanion Function({
      required String id,
      required String companyId,
      required String invoiceId,
      required String workLogId,
      required String workDate,
      required String siteId,
      required String siteName,
      required String machineId,
      required String machineName,
      required int startReading,
      required int endReading,
      required int workingHours,
      required int ratePaise,
      required int amountPaise,
      Value<String?> description,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$InvoiceLinesTableUpdateCompanionBuilder =
    InvoiceLinesCompanion Function({
      Value<String> id,
      Value<String> companyId,
      Value<String> invoiceId,
      Value<String> workLogId,
      Value<String> workDate,
      Value<String> siteId,
      Value<String> siteName,
      Value<String> machineId,
      Value<String> machineName,
      Value<int> startReading,
      Value<int> endReading,
      Value<int> workingHours,
      Value<int> ratePaise,
      Value<int> amountPaise,
      Value<String?> description,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$InvoiceLinesTableReferences
    extends BaseReferences<_$AppDatabase, $InvoiceLinesTable, InvoiceLine> {
  $$InvoiceLinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias('invoice_lines__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WorkLogsTable _workLogIdTable(_$AppDatabase db) =>
      db.workLogs.createAlias('invoice_lines__work_log_id__work_logs__id');

  $$WorkLogsTableProcessedTableManager get workLogId {
    final $_column = $_itemColumn<String>('work_log_id')!;

    final manager = $$WorkLogsTableTableManager(
      $_db,
      $_db.workLogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvoiceLinesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceLinesTable> {
  $$InvoiceLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workDate => $composableBuilder(
    column: $table.workDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineId => $composableBuilder(
    column: $table.machineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineName => $composableBuilder(
    column: $table.machineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startReading => $composableBuilder(
    column: $table.startReading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endReading => $composableBuilder(
    column: $table.endReading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workingHours => $composableBuilder(
    column: $table.workingHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratePaise => $composableBuilder(
    column: $table.ratePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkLogsTableFilterComposer get workLogId {
    final $$WorkLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workLogId,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableFilterComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceLinesTable> {
  $$InvoiceLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workDate => $composableBuilder(
    column: $table.workDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineId => $composableBuilder(
    column: $table.machineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineName => $composableBuilder(
    column: $table.machineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startReading => $composableBuilder(
    column: $table.startReading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endReading => $composableBuilder(
    column: $table.endReading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workingHours => $composableBuilder(
    column: $table.workingHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratePaise => $composableBuilder(
    column: $table.ratePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkLogsTableOrderingComposer get workLogId {
    final $$WorkLogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workLogId,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableOrderingComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceLinesTable> {
  $$InvoiceLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get workDate =>
      $composableBuilder(column: $table.workDate, builder: (column) => column);

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get siteName =>
      $composableBuilder(column: $table.siteName, builder: (column) => column);

  GeneratedColumn<String> get machineId =>
      $composableBuilder(column: $table.machineId, builder: (column) => column);

  GeneratedColumn<String> get machineName => $composableBuilder(
    column: $table.machineName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startReading => $composableBuilder(
    column: $table.startReading,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endReading => $composableBuilder(
    column: $table.endReading,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workingHours => $composableBuilder(
    column: $table.workingHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ratePaise =>
      $composableBuilder(column: $table.ratePaise, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkLogsTableAnnotationComposer get workLogId {
    final $$WorkLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workLogId,
      referencedTable: $db.workLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.workLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoiceLinesTable,
          InvoiceLine,
          $$InvoiceLinesTableFilterComposer,
          $$InvoiceLinesTableOrderingComposer,
          $$InvoiceLinesTableAnnotationComposer,
          $$InvoiceLinesTableCreateCompanionBuilder,
          $$InvoiceLinesTableUpdateCompanionBuilder,
          (InvoiceLine, $$InvoiceLinesTableReferences),
          InvoiceLine,
          PrefetchHooks Function({bool invoiceId, bool workLogId})
        > {
  $$InvoiceLinesTableTableManager(_$AppDatabase db, $InvoiceLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<String> workLogId = const Value.absent(),
                Value<String> workDate = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> siteName = const Value.absent(),
                Value<String> machineId = const Value.absent(),
                Value<String> machineName = const Value.absent(),
                Value<int> startReading = const Value.absent(),
                Value<int> endReading = const Value.absent(),
                Value<int> workingHours = const Value.absent(),
                Value<int> ratePaise = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoiceLinesCompanion(
                id: id,
                companyId: companyId,
                invoiceId: invoiceId,
                workLogId: workLogId,
                workDate: workDate,
                siteId: siteId,
                siteName: siteName,
                machineId: machineId,
                machineName: machineName,
                startReading: startReading,
                endReading: endReading,
                workingHours: workingHours,
                ratePaise: ratePaise,
                amountPaise: amountPaise,
                description: description,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String invoiceId,
                required String workLogId,
                required String workDate,
                required String siteId,
                required String siteName,
                required String machineId,
                required String machineName,
                required int startReading,
                required int endReading,
                required int workingHours,
                required int ratePaise,
                required int amountPaise,
                Value<String?> description = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => InvoiceLinesCompanion.insert(
                id: id,
                companyId: companyId,
                invoiceId: invoiceId,
                workLogId: workLogId,
                workDate: workDate,
                siteId: siteId,
                siteName: siteName,
                machineId: machineId,
                machineName: machineName,
                startReading: startReading,
                endReading: endReading,
                workingHours: workingHours,
                ratePaise: ratePaise,
                amountPaise: amountPaise,
                description: description,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvoiceLinesTable, InvoiceLine>(table),
                  $$InvoiceLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false, workLogId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.invoiceId,
                        referencedTable: $$InvoiceLinesTableReferences
                            ._invoiceIdTable(db),
                        referencedColumn: $$InvoiceLinesTableReferences
                            ._invoiceIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (workLogId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workLogId,
                        referencedTable: $$InvoiceLinesTableReferences
                            ._workLogIdTable(db),
                        referencedColumn: $$InvoiceLinesTableReferences
                            ._workLogIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InvoiceLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoiceLinesTable,
      InvoiceLine,
      $$InvoiceLinesTableFilterComposer,
      $$InvoiceLinesTableOrderingComposer,
      $$InvoiceLinesTableAnnotationComposer,
      $$InvoiceLinesTableCreateCompanionBuilder,
      $$InvoiceLinesTableUpdateCompanionBuilder,
      (InvoiceLine, $$InvoiceLinesTableReferences),
      InvoiceLine,
      PrefetchHooks Function({bool invoiceId, bool workLogId})
    >;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  required String id,
  required String companyId,
  required String invoiceId,
  required String paymentDate,
  required int amountPaise,
  required String method,
  Value<String?> reference,
  Value<String?> notes,
  Value<int?> reversedAt,
  Value<String?> reversedBy,
  Value<String?> reverseReason,
  required int createdAt,
  required int updatedAt,
  required String createdBy,
  required String updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<int> rowid,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<String> id,
  Value<String> companyId,
  Value<String> invoiceId,
  Value<String> paymentDate,
  Value<int> amountPaise,
  Value<String> method,
  Value<String?> reference,
  Value<String?> notes,
  Value<int?> reversedAt,
  Value<String?> reversedBy,
  Value<String?> reverseReason,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> createdBy,
  Value<String> updatedBy,
  Value<String> syncStatus,
  Value<int> version,
  Value<int> rowid,
});

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, Payment> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias('payments__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reversedAt => $composableBuilder(
    column: $table.reversedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reversedBy => $composableBuilder(
    column: $table.reversedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reverseReason => $composableBuilder(
    column: $table.reverseReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reversedAt => $composableBuilder(
    column: $table.reversedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reversedBy => $composableBuilder(
    column: $table.reversedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reverseReason => $composableBuilder(
    column: $table.reverseReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get reversedAt => $composableBuilder(
    column: $table.reversedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reversedBy => $composableBuilder(
    column: $table.reversedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reverseReason => $composableBuilder(
    column: $table.reverseReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          Payment,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (Payment, $$PaymentsTableReferences),
          Payment,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<String> paymentDate = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> reversedAt = const Value.absent(),
                Value<String?> reversedBy = const Value.absent(),
                Value<String?> reverseReason = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                companyId: companyId,
                invoiceId: invoiceId,
                paymentDate: paymentDate,
                amountPaise: amountPaise,
                method: method,
                reference: reference,
                notes: notes,
                reversedAt: reversedAt,
                reversedBy: reversedBy,
                reverseReason: reverseReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String invoiceId,
                required String paymentDate,
                required int amountPaise,
                required String method,
                Value<String?> reference = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> reversedAt = const Value.absent(),
                Value<String?> reversedBy = const Value.absent(),
                Value<String?> reverseReason = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                required String createdBy,
                required String updatedBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                companyId: companyId,
                invoiceId: invoiceId,
                paymentDate: paymentDate,
                amountPaise: amountPaise,
                method: method,
                reference: reference,
                notes: notes,
                reversedAt: reversedAt,
                reversedBy: reversedBy,
                reverseReason: reverseReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                syncStatus: syncStatus,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PaymentsTable, Payment>(table),
                  $$PaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.invoiceId,
                        referencedTable: $$PaymentsTableReferences
                            ._invoiceIdTable(db),
                        referencedColumn: $$PaymentsTableReferences
                            ._invoiceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      Payment,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (Payment, $$PaymentsTableReferences),
      Payment,
      PrefetchHooks Function({bool invoiceId})
    >;
typedef $$SyncRecordsTableCreateCompanionBuilder =
    SyncRecordsCompanion Function({
      required String entity,
      required String entityId,
      required String companyId,
      Value<int?> serverRev,
      Value<int> attempts,
      Value<int?> nextAttemptAt,
      Value<String?> lastError,
      Value<String?> conflictJson,
      Value<int?> conflictRev,
      Value<int> rowid,
    });
typedef $$SyncRecordsTableUpdateCompanionBuilder =
    SyncRecordsCompanion Function({
      Value<String> entity,
      Value<String> entityId,
      Value<String> companyId,
      Value<int?> serverRev,
      Value<int> attempts,
      Value<int?> nextAttemptAt,
      Value<String?> lastError,
      Value<String?> conflictJson,
      Value<int?> conflictRev,
      Value<int> rowid,
    });

class $$SyncRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncRecordsTable> {
  $$SyncRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverRev => $composableBuilder(
    column: $table.serverRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictJson => $composableBuilder(
    column: $table.conflictJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get conflictRev => $composableBuilder(
    column: $table.conflictRev,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncRecordsTable> {
  $$SyncRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverRev => $composableBuilder(
    column: $table.serverRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictJson => $composableBuilder(
    column: $table.conflictJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get conflictRev => $composableBuilder(
    column: $table.conflictRev,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncRecordsTable> {
  $$SyncRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<int> get serverRev =>
      $composableBuilder(column: $table.serverRev, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get conflictJson => $composableBuilder(
    column: $table.conflictJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get conflictRev => $composableBuilder(
    column: $table.conflictRev,
    builder: (column) => column,
  );
}

class $$SyncRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncRecordsTable,
          SyncRecord,
          $$SyncRecordsTableFilterComposer,
          $$SyncRecordsTableOrderingComposer,
          $$SyncRecordsTableAnnotationComposer,
          $$SyncRecordsTableCreateCompanionBuilder,
          $$SyncRecordsTableUpdateCompanionBuilder,
          (
            SyncRecord,
            BaseReferences<_$AppDatabase, $SyncRecordsTable, SyncRecord>,
          ),
          SyncRecord,
          PrefetchHooks Function()
        > {
  $$SyncRecordsTableTableManager(_$AppDatabase db, $SyncRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<int?> serverRev = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> conflictJson = const Value.absent(),
                Value<int?> conflictRev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRecordsCompanion(
                entity: entity,
                entityId: entityId,
                companyId: companyId,
                serverRev: serverRev,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                conflictJson: conflictJson,
                conflictRev: conflictRev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entity,
                required String entityId,
                required String companyId,
                Value<int?> serverRev = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> conflictJson = const Value.absent(),
                Value<int?> conflictRev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRecordsCompanion.insert(
                entity: entity,
                entityId: entityId,
                companyId: companyId,
                serverRev: serverRev,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                conflictJson: conflictJson,
                conflictRev: conflictRev,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncRecordsTable, SyncRecord>(table),
                  BaseReferences<_$AppDatabase, $SyncRecordsTable, SyncRecord>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncRecordsTable,
      SyncRecord,
      $$SyncRecordsTableFilterComposer,
      $$SyncRecordsTableOrderingComposer,
      $$SyncRecordsTableAnnotationComposer,
      $$SyncRecordsTableCreateCompanionBuilder,
      $$SyncRecordsTableUpdateCompanionBuilder,
      (
        SyncRecord,
        BaseReferences<_$AppDatabase, $SyncRecordsTable, SyncRecord>,
      ),
      SyncRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db, _db.auditLogs);
  $$CachedCompaniesTableTableManager get cachedCompanies =>
      $$CachedCompaniesTableTableManager(_db, _db.cachedCompanies);
  $$ClientsTableTableManager get clients =>
      $$ClientsTableTableManager(_db, _db.clients);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db, _db.sites);
  $$MachinesTableTableManager get machines =>
      $$MachinesTableTableManager(_db, _db.machines);
  $$OperatorsTableTableManager get operators =>
      $$OperatorsTableTableManager(_db, _db.operators);
  $$PetrolPumpsTableTableManager get petrolPumps =>
      $$PetrolPumpsTableTableManager(_db, _db.petrolPumps);
  $$WorkLogsTableTableManager get workLogs =>
      $$WorkLogsTableTableManager(_db, _db.workLogs);
  $$FuelEntriesTableTableManager get fuelEntries =>
      $$FuelEntriesTableTableManager(_db, _db.fuelEntries);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$InvoiceLinesTableTableManager get invoiceLines =>
      $$InvoiceLinesTableTableManager(_db, _db.invoiceLines);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$SyncRecordsTableTableManager get syncRecords =>
      $$SyncRecordsTableTableManager(_db, _db.syncRecords);
}
