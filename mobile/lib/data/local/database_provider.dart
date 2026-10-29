import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Single app-wide database. Tests override with an in-memory executor.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
