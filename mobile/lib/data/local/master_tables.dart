import 'package:drift/drift.dart';

/// Columns shared by every company-owned master record: tenant scope, status,
/// audit and sync metadata. Records are never hard-deleted locally; delete
/// writes a tombstone ([deletedAt]) so the deletion can sync (Sprint 7).
mixin MasterColumns on Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// UTC epoch milliseconds.
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text()();

  /// `pending` until the sync engine uploads it, then `synced`.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  /// Incremented on every local change; used for conflict detection.
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'clients_company_name', columns: {#companyId, #name})
class Clients extends Table with MasterColumns {
  TextColumn get contactPerson => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get billingAddress => text().nullable()();
  TextColumn get gstin => text().nullable()();
}

@TableIndex(name: 'sites_company_client', columns: {#companyId, #clientId})
class Sites extends Table with MasterColumns {
  TextColumn get clientId => text().references(Clients, #id)();
  TextColumn get address => text().nullable()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get phone => text().nullable()();

  /// Suggested rate in paise per hour. Invoices may override it.
  IntColumn get defaultHourlyRatePaise => integer().nullable()();
}

@TableIndex(name: 'machines_company_name', columns: {#companyId, #name})
class Machines extends Table with MasterColumns {
  TextColumn get registrationNumber => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get model => text().nullable()();

  /// Hour-meter reading when the machine was added, in hundredths of an hour.
  IntColumn get initialMeterReading => integer()();
  TextColumn get meterUnit => text().withDefault(const Constant('hours'))();
}

@TableIndex(name: 'operators_company_name', columns: {#companyId, #name})
class Operators extends Table with MasterColumns {
  TextColumn get phone => text().nullable()();
  TextColumn get code => text().nullable()();
}

@TableIndex(name: 'petrol_pumps_company_name', columns: {#companyId, #name})
class PetrolPumps extends Table with MasterColumns {
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
}
