import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';

/// One unexpected error, kept on this phone for support.
class ErrorLogEntry {
  const ErrorLogEntry({
    required this.at,
    required this.message,
    this.context,
    this.stack,
  });

  factory ErrorLogEntry.fromJson(Map<String, dynamic> j) => ErrorLogEntry(
    at: j['at'] as int,
    message: j['message'] as String,
    context: j['context'] as String?,
    stack: j['stack'] as String?,
  );

  /// UTC epoch ms.
  final int at;
  final String message;
  final String? context;

  /// The first few frames only.
  final String? stack;

  Map<String, dynamic> toJson() => {
    'at': at,
    'message': message,
    'context': ?context,
    'stack': ?stack,
  };
}

/// The most recent unexpected errors (uncaught Flutter, platform and sync
/// errors), stored in local settings. Nothing is uploaded: the user can copy
/// the list for support from Sync & data.
class ErrorLog {
  ErrorLog(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;
  Future<void> _last = Future.value();

  static const _key = 'error_log';
  static const maxEntries = 30;

  static String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  /// Records [error]. Never throws: logging must not cause new errors.
  Future<void> record(Object error, StackTrace? stack, {String? context}) =>
      _last = _last.then((_) async {
        try {
          final entry = ErrorLogEntry(
            at: _clock().toUtc().millisecondsSinceEpoch,
            message: _clip('$error', 500),
            context: context == null ? null : _clip(context, 200),
            stack: stack == null
                ? null
                : _clip(stack.toString().split('\n').take(8).join('\n'), 1500),
          );
          final list = [entry, ...await entries()].take(maxEntries);
          await _db.writeSetting(
            _key,
            jsonEncode([for (final e in list) e.toJson()]),
          );
        } catch (_) {
          // Ignore: the database may be closing.
        }
      });

  static List<ErrorLogEntry> _decode(String? json) {
    if (json == null) return const [];
    try {
      return [
        for (final e in jsonDecode(json) as List)
          ErrorLogEntry.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Newest first.
  Future<List<ErrorLogEntry>> entries() async =>
      _decode(await _db.readSetting(_key));

  Stream<List<ErrorLogEntry>> watch() => _db.watchSetting(_key).map(_decode);

  Future<void> clear() => _db.deleteSetting(_key);
}

final errorLogProvider = Provider<ErrorLog>(
  (ref) => ErrorLog(ref.watch(appDatabaseProvider)),
);

final recentErrorsProvider = StreamProvider.autoDispose<List<ErrorLogEntry>>(
  (ref) => ref.watch(errorLogProvider).watch(),
);
