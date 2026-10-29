import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';

import '../helpers/pump_app.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  test('schema is version 7', () {
    expect(db.schemaVersion, 7);
  });

  test('settings upsert, read, watch and delete', () async {
    expect(await db.readSetting('k'), isNull);
    final seen = <String?>[];
    final sub = db.watchSetting('k').listen(seen.add);

    await db.writeSetting('k', 'one');
    await db.writeSetting('k', 'two');
    expect(await db.readSetting('k'), 'two');
    await db.deleteSetting('k');
    expect(await db.readSetting('k'), isNull);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(seen.first, isNull);
    expect(seen, contains('two'));
  });

  test('audit log rows default to pending sync', () async {
    await db
        .into(db.auditLogs)
        .insert(
          AuditLogsCompanion.insert(
            id: 'a1',
            actorId: 'u1',
            action: 'create',
            entityType: 'client',
            entityId: 'c1',
            createdAt: DateTime.utc(2026).millisecondsSinceEpoch,
            companyId: const Value('co1'),
          ),
        );
    final row = await db.select(db.auditLogs).getSingle();
    expect(row.syncStatus, 'pending');
    expect(row.companyId, 'co1');
  });

  test('foreign keys are enforced', () async {
    final r = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(r.data.values.first, 1);
  });

  test(
    'upgrades a v1 database to the latest schema without losing data',
    () async {
      final old = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(
              'CREATE TABLE app_settings (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
            );
            raw.execute(
              "CREATE TABLE audit_logs (id TEXT NOT NULL PRIMARY KEY, company_id TEXT, actor_id TEXT NOT NULL, action TEXT NOT NULL, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, details TEXT, created_at INTEGER NOT NULL, sync_status TEXT NOT NULL DEFAULT 'pending')",
            );
            raw.execute(
              "INSERT INTO app_settings VALUES ('theme_mode', 'dark')",
            );
            raw.userVersion = 1;
          },
        ),
      );
      addTearDown(old.close);
      expect(await old.readSetting('theme_mode'), 'dark');
      expect(await old.select(old.cachedCompanies).get(), isEmpty);
      final v = await old.customSelect('PRAGMA user_version').getSingle();
      expect(v.data.values.first, 7);
      expect(await old.select(old.syncRecords).get(), isEmpty);
      expect(await old.select(old.invoices).get(), isEmpty);
      expect(await old.select(old.fuelEntries).get(), isEmpty);
      expect(await old.select(old.workLogs).get(), isEmpty);
      expect(await old.select(old.clients).get(), isEmpty);
    },
  );
}
