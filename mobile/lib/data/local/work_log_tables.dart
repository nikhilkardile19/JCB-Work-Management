import 'package:drift/drift.dart';

import 'master_tables.dart';

/// Meter-reading work log (sprint doc §4.8). Readings and hours are integer
/// hundredths of an hour. Photo paths are relative to the app documents
/// directory (absolute paths change across iOS app updates) and never leave
/// the device in v1.
@TableIndex(name: 'work_logs_company_date', columns: {#companyId, #workDate})
@TableIndex(
  name: 'work_logs_company_machine',
  columns: {#companyId, #machineId},
)
class WorkLogs extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();

  /// Local calendar date, `yyyy-MM-dd`.
  TextColumn get workDate => text()();
  TextColumn get clientId => text().references(Clients, #id)();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get machineId => text().references(Machines, #id)();
  TextColumn get operatorId => text().nullable().references(Operators, #id)();

  /// Operator name as recorded, kept even if the operator master changes.
  TextColumn get operatorName => text().nullable()();

  IntColumn get startReading => integer()();
  TextColumn get startPhotoPath => text().nullable()();
  IntColumn get startCapturedAt => integer().nullable()();
  RealColumn get startLat => real().nullable()();
  RealColumn get startLng => real().nullable()();
  RealColumn get startAccuracy => real().nullable()();
  TextColumn get startLocationStatus => text().nullable()();

  IntColumn get endReading => integer().nullable()();
  TextColumn get endPhotoPath => text().nullable()();
  IntColumn get endCapturedAt => integer().nullable()();
  RealColumn get endLat => real().nullable()();
  RealColumn get endLng => real().nullable()();
  RealColumn get endAccuracy => real().nullable()();
  TextColumn get endLocationStatus => text().nullable()();

  /// endReading − startReading, once both are known.
  IntColumn get workingHours => integer().nullable()();

  /// `photo` when both readings have photos, otherwise `manual`.
  TextColumn get entryMode => text()();
  TextColumn get manualReason => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Comma-separated anomaly flags confirmed by the user (see WorkLogRules).
  TextColumn get anomalyFlags => text().nullable()();

  /// draft, submitted, approved, rejected, invoiced, cancelled.
  TextColumn get status => text()();
  TextColumn get statusReason => text().nullable()();
  TextColumn get approvedBy => text().nullable()();
  IntColumn get approvedAt => integer().nullable()();
  TextColumn get invoiceId => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
