import 'package:firebase_auth/firebase_auth.dart';

import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toUser);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _toUser(cred.user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(messageFor(e.code));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether an account exists for this address.
      if (e.code == 'user-not-found') return;
      throw AuthException(messageFor(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static AppUser? _toUser(User? u) =>
      u == null ? null : AppUser(uid: u.uid, email: u.email ?? '');

  /// User-facing message for a Firebase Auth error code.
  static String messageFor(String code) => switch (code) {
    'invalid-email' => 'That email address is not valid.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Incorrect email or password.',
    'user-disabled' =>
      'This account has been disabled. Contact your administrator.',
    'too-many-requests' =>
      'Too many attempts. Wait a few minutes and try again.',
    'network-request-failed' =>
      'No internet connection. Connect and try again.',
    'operation-not-allowed' =>
      'Email sign-in is not enabled for this app. Contact support.',
    _ => 'Something went wrong. Please try again.',
  };
}
