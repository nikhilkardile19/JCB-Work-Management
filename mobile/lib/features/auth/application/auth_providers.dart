import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/auth_repository.dart';
import '../data/http_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  ),
);

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Pure validators, kept out of widgets so they can be unit-tested.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email address';
    if (!_email.hasMatch(v)) {
      return 'Enter a valid email, e.g. name@company.com';
    }
    return null;
  }

  /// Codes look like `JCBW-7KQ2-M9XD-PA4H`; case, spaces, dashes and the
  /// `JCBW` prefix don't matter (the server normalizes them the same way).
  static String? activationCode(String? value) {
    final v = (value ?? '').toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return 'Enter your activation code';
    final body = v.startsWith('JCBW') ? v.substring(4) : v;
    if (body.length != 12) {
      return 'Enter the full code, e.g. JCBW-7KQ2-M9XD-PA4H';
    }
    return null;
  }
}
