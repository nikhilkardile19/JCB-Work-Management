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

  static String? password(String? value, {int minLength = 6}) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    if (v.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }
}
