import 'dart:async';

class AppUser {
  const AppUser({required this.uid, required this.email});

  final String uid;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.uid == uid && other.email == email;

  @override
  int get hashCode => Object.hash(uid, email);
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  /// Emits the current user immediately, then on every change.
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
