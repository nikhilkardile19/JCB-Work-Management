import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/state_views.dart';

/// Shown when the app cannot initialize (e.g. Firebase is not configured for
/// this platform). Local data is untouched.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: ErrorView(
            title: "The app couldn't start",
            message: error is UnsupportedError
                ? (error as UnsupportedError).message
                : 'Please restart the app. If this keeps happening, contact support.',
          ),
        ),
      ),
    );
  }
}
