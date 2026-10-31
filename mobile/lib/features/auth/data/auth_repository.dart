import 'dart:async';

import '../../company/domain/company.dart';

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
  const AuthException(this.message, {this.reason});

  final String message;

  /// Stable server reason when known (e.g. `no_account`, `code_used`).
  final String? reason;

  @override
  String toString() => message;
}

/// What the server answered to a sign-in with an activation code, before
/// the session is stored on the phone.
class CodeSignIn {
  const CodeSignIn({
    required this.user,
    required this.companyId,
    this.license,
    this.refusalReason,
    this.refusalMessage,
  });

  final AppUser user;

  /// The company whose license the code belongs to.
  final String companyId;

  /// This phone's license state (`LicenseState`); null when the phone was
  /// not activated (see [refusalReason]).
  final Map<String, dynamic>? license;

  /// Signed in, but the phone was not activated: `device_limit` (all
  /// devices in use, so a replacement can be requested).
  final String? refusalReason;
  final String? refusalMessage;
}

abstract interface class AuthRepository {
  /// Emits the current user immediately, then on every change.
  Stream<AppUser?> authStateChanges();

  /// Sign-in step 1: checks that [email] has an account that may sign in.
  /// Throws [AuthException] otherwise.
  Future<void> checkEmail(String email);

  /// Sign-in step 2: email and activation code, no password. The server
  /// activates this phone and starts the session.
  ///
  /// [prepare] runs after the server accepted the code and before the user
  /// is signed in on the phone, so local state (selected company, license
  /// cache) is in place when the router reacts. Throws [AuthException].
  Future<AppUser> signInWithCode({
    required String email,
    required String activationCode,
    required String deviceId,
    required String deviceModel,
    Future<void> Function(CodeSignIn result)? prepare,
  });

  /// Creates the account and its company, which waits for developer-admin
  /// approval; the activation code is then emailed to [email]. Does not
  /// sign in.
  Future<void> signUp({required String email, required CompanyProfile profile});

  Future<void> signOut();
}
