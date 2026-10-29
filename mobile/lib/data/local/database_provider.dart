import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Single app-wide database. Tests override with an in-memory executor.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// This app installation's ID, which registers the phone on the license.
final installationIdProvider = FutureProvider<String>(
  (ref) => ref.watch(appDatabaseProvider).installationId(),
);

/// The installation ID as shown to users and support (first 8 characters).
String shortDeviceId(String id) => id.substring(0, 8).toUpperCase();
