import 'package:drift/drift.dart';

import 'master_tables.dart';

/// Fuel purchase (sprint doc §4.10). Litres are hundredths of a litre, money
/// is paise; the total is always derived from litres × price.
@TableIndex(name: 'fuel_company_date', columns: {#companyId, #fuelDate})
class FuelEntries extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();

  /// When fuel was filled, UTC epoch ms.
  IntColumn get filledAt => integer()();

  /// Local calendar date of [filledAt], `yyyy-MM-dd` (for grouping/reports).
  TextColumn get fuelDate => text()();
  TextColumn get machineId => text().references(Machines, #id)();
  TextColumn get pumpId => text().references(PetrolPumps, #id)();
  TextColumn get clientId => text().nullable().references(Clients, #id)();
  TextColumn get siteId => text().nullable().references(Sites, #id)();

  IntColumn get litresCl => integer()();
  IntColumn get pricePerLitrePaise => integer()();
  IntColumn get totalPaise => integer()();

  /// Receipt photo, relative to the app documents directory; device-only.
  TextColumn get receiptPhotoPath => text().nullable()();
  IntColumn get receiptCapturedAt => integer().nullable()();
  RealColumn get receiptLat => real().nullable()();
  RealColumn get receiptLng => real().nullable()();
  RealColumn get receiptAccuracy => real().nullable()();
  TextColumn get receiptLocationStatus => text().nullable()();
  TextColumn get notes => text().nullable()();

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
