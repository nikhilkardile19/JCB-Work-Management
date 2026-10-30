import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/startup_error_app.dart';
import 'core/config/app_config.dart';
import 'core/errors/error_log.dart';
import 'core/network/network_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String apiBaseUrl;
  try {
    apiBaseUrl = AppConfig.apiBaseUrl;
  } on ConfigError catch (e) {
    runApp(StartupErrorApp(error: e));
    return;
  }
  final container = ProviderContainer(
    overrides: [apiBaseUrlProvider.overrideWithValue(apiBaseUrl)],
  );
  recordUncaughtErrors(container.read(errorLogProvider));
  runApp(
    UncontrolledProviderScope(container: container, child: const JcbApp()),
  );
}
