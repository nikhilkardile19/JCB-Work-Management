import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/core/errors/error_log.dart';

import '../helpers/pump_app.dart';

void main() {
  test('keeps the newest errors, clipped, and never throws', () async {
    final db = memoryDatabase();
    var t = DateTime.utc(2026, 10, 29, 10);
    final log = ErrorLog(db, clock: () => t);

    await log.record(StateError('first'), StackTrace.current, context: 'sync');
    t = t.add(const Duration(minutes: 1));
    await log.record('x' * 2000, null);
    final list = await log.entries();
    expect(list, hasLength(2));
    expect(list.first.message.length, lessThanOrEqualTo(501));
    expect(list.last.message, 'Bad state: first');
    expect(list.last.context, 'sync');
    expect(list.last.stack!.split('\n').length, lessThanOrEqualTo(8));
    expect(list.first.at, t.millisecondsSinceEpoch);

    await Future.wait([
      for (var i = 0; i < ErrorLog.maxEntries + 5; i++) log.record('e$i', null),
    ]);
    final capped = await log.entries();
    expect(capped, hasLength(ErrorLog.maxEntries));
    expect(capped.first.message, 'e${ErrorLog.maxEntries + 4}');

    await log.clear();
    expect(await log.entries(), isEmpty);

    await db.close();
    await log.record('after close', null); // swallowed
  });

  test('records uncaught Flutter and platform errors', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final log = ErrorLog(db);
    final flutterHandler = FlutterError.onError;
    final platformHandler = PlatformDispatcher.instance.onError;
    final presented = <FlutterErrorDetails>[];
    FlutterError.onError = presented.add;
    try {
      recordUncaughtErrors(log);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: StateError('build failed'),
          library: 'widgets library',
        ),
      );
      FlutterError.reportError(
        const FlutterErrorDetails(exception: 'image not found', silent: true),
      );
      PlatformDispatcher.instance.onError!(
        ArgumentError('lost future'),
        StackTrace.current,
      );
    } finally {
      FlutterError.onError = flutterHandler;
      PlatformDispatcher.instance.onError = platformHandler;
    }

    expect(presented, hasLength(2), reason: 'default handling still runs');
    final list = await log.entries();
    expect(list.map((e) => e.message), [
      'Invalid argument(s): lost future',
      'Bad state: build failed',
    ], reason: 'silent errors are not recorded');
    expect(list.first.context, 'Uncaught error');
    expect(list.first.stack, isNotNull);
    expect(list.last.context, 'widgets library');
  });
}
