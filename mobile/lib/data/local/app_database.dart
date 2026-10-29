import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import 'fuel_tables.dart';
import 'invoice_tables.dart';
import 'master_tables.dart';
import 'sync_tables.dart';
import 'work_log_tables.dart';

export 'fuel_tables.dart';
export 'invoice_tables.dart';
export 'master_tables.dart';
export 'sync_tables.dart';
export 'work_log_tables.dart';

part 'app_database.g.dart';

/// Device-local key/value settings (theme, cached session, last sync time…).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Local audit trail. Synced to `companies/{id}/auditLogs` from Sprint 7.
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().nullable()();
  TextColumn get actorId => text()();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// JSON-encoded details (before/after values, reason).
  TextColumn get details => text().nullable()();

  /// UTC epoch milliseconds.
  IntColumn get createdAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline cache of the signed-in user's company memberships. Keyed by user so
/// another account on the same phone never sees this user's companies.
class CachedCompanies extends Table {
  TextColumn get userId => text()();
  TextColumn get companyId => text()();
  TextColumn get role => text()();
  TextColumn get status => text()();
  TextColumn get ownerUid => text()();
  TextColumn get name => text()();
  TextColumn get contactPerson => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text()();
  TextColumn get gstin => text().nullable()();
  TextColumn get invoicePrefix => text()();
  TextColumn get currency => text()();

  /// UTC epoch milliseconds of the last successful server refresh.
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {userId, companyId};
}

@DriftDatabase(
  tables: [
    AppSettings,
    AuditLogs,
    CachedCompanies,
    Clients,
    Sites,
    Machines,
    Operators,
    PetrolPumps,
    WorkLogs,
    FuelEntries,
    Invoices,
    InvoiceLines,
    Payments,
    SyncRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'jcb_work_management'));

  /// Bump on every schema change and add a step in [migration].
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(cachedCompanies);
      if (from < 3) {
        for (final table in <TableInfo<Table, Object?>>[
          clients,
          sites,
          machines,
          operators,
          petrolPumps,
        ]) {
          await m.createTable(table);
        }
        for (final index in [
          clientsCompanyName,
          sitesCompanyClient,
          machinesCompanyName,
          operatorsCompanyName,
          petrolPumpsCompanyName,
        ]) {
          await m.createIndex(index);
        }
      }
      if (from < 4) {
        await m.createTable(workLogs);
        await m.createIndex(workLogsCompanyDate);
        await m.createIndex(workLogsCompanyMachine);
      }
      if (from < 5) {
        await m.createTable(fuelEntries);
        await m.createIndex(fuelCompanyDate);
      }
      if (from < 6) {
        for (final table in <TableInfo<Table, Object?>>[
          invoices,
          invoiceLines,
          payments,
        ]) {
          await m.createTable(table);
        }
        for (final index in [
          invoicesCompanyClient,
          invoiceLinesInvoice,
          paymentsInvoice,
        ]) {
          await m.createIndex(index);
        }
      }
      if (from < 7) await m.createTable(syncRecords);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Random per-installation ID, used as the device ID for licensing and
  /// sync. A reinstall or data wipe creates a new one (the old device can be
  /// replaced through a device replacement request).
  Future<String> installationId() async {
    final existing = await readSetting('device_id');
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await writeSetting('device_id', id);
    return id;
  }

  Future<String?> readSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchSetting(String key) =>
      (select(appSettings)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<void> writeSetting(String key, String value) => into(
    appSettings,
  ).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<void> deleteSetting(String key) =>
      (delete(appSettings)..where((t) => t.key.equals(key))).go();
}
