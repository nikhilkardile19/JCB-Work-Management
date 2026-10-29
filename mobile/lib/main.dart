import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/startup_error_app.dart';
import 'core/errors/error_log.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(StartupErrorApp(error: e));
    return;
  }
  final container = ProviderContainer();
  recordUncaughtErrors(container.read(errorLogProvider));
  runApp(
    UncontrolledProviderScope(container: container, child: const JcbApp()),
  );
}
