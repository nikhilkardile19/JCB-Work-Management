import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database_provider.dart';

const _themeModeKey = 'theme_mode';

/// User's theme choice, persisted in the local database.
final themeModeProvider = StreamProvider<ThemeMode>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .watchSetting(_themeModeKey)
      .map(
        (v) => ThemeMode.values.firstWhere(
          (m) => m.name == v,
          orElse: () => ThemeMode.system,
        ),
      );
});

Future<void> setThemeMode(WidgetRef ref, ThemeMode mode) =>
    ref.read(appDatabaseProvider).writeSetting(_themeModeKey, mode.name);
