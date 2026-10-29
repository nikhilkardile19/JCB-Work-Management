import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options for project `jcb-work-management`, taken from
/// `android/app/google-services.json`. Equivalent to the file
/// `flutterfire configure` generates; regenerate with it when platforms are
/// added.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('The mobile app does not target the web.');
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
        'Firebase is not configured for ${defaultTargetPlatform.name}. '
        'Register the app in the Firebase console and run `flutterfire configure`.',
      ),
    };
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyC7YU9rDWNwOHJo1qq7IlbG41ShJlT0dbw',
    appId: '1:192106131234:android:1984b6944337ff9e21bf7b',
    messagingSenderId: '192106131234',
    projectId: 'jcb-work-management',
    storageBucket: 'jcb-work-management.firebasestorage.app',
  );
}
