import 'package:drift/drift.dart';

/// Per-record sync bookkeeping, separate from the business tables.
/// [serverRev] is the server revision this device last saw for the record;
/// a push only succeeds if the server is still at that revision.
class SyncRecords extends Table {
  /// Firestore collection, e.g. `workLogs`.
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get companyId => text()();
  IntColumn get serverRev => integer().nullable()();

  /// Consecutive failed attempts and when to try again (UTC ms).
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().nullable()();

  /// Why the server refused the record (shown on the Sync screen).
  TextColumn get lastError => text().nullable()();

  /// Server copy (JSON) when the record is in conflict.
  TextColumn get conflictJson => text().nullable()();
  IntColumn get conflictRev => integer().nullable()();

  @override
  Set<Column> get primaryKey => {entity, entityId};
}
