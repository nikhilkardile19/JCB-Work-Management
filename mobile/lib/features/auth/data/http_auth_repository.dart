import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/session_store.dart';
import 'auth_repository.dart';

/// Email + password sign-in against the REST API (`/auth/*`).
///
/// The stored session is the sign-in state: a user who signed in once stays
/// signed in offline until they sign out or the server rejects the refresh
/// token.
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api, this._session);

  final ApiClient _api;
  final SessionStore _session;

  @override
  Stream<AppUser?> authStateChanges() => _session.userChanges().map(_toUser);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final json = await _api.post(
        '/auth/login',
        body: {'email': email.trim(), 'password': password, 'client': 'mobile'},
        authenticated: false,
      );
      final session = AuthSession.fromJson(json);
      await _session.save(session);
      return _toUser(session.user)!;
    } catch (e) {
      throw AuthException(messageFor(e));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      // The server answers 204 whether or not the account exists.
      await _api.post(
        '/auth/forgot-password',
        body: {'email': email.trim()},
        authenticated: false,
      );
    } catch (e) {
      throw AuthException(messageFor(e));
    }
  }

  /// Signs out on this phone at once (works offline), then asks the server
  /// to revoke the session if it can be reached.
  @override
  Future<void> signOut() async {
    await _session.load();
    final access = _session.accessToken;
    final refresh = _session.refreshToken;
    await _session.clear();
    if (refresh != null) {
      await _api.logout(accessToken: access, refreshToken: refresh);
    }
  }

  static AppUser? _toUser(SessionUser? u) =>
      u == null ? null : AppUser(uid: u.id, email: u.email);

  /// User-facing message for a failed sign-in or password-reset request.
  static String messageFor(Object error) => switch (error) {
    ApiUnavailable(isRateLimited: true) || ApiException(statusCode: 429) =>
      'Too many attempts. Wait a few minutes and try again.',
    ApiUnavailable(statusCode: null) =>
      'No internet connection. Connect and try again.',
    ApiException(reason: 'user_disabled') =>
      'This account has been disabled. Contact your administrator.',
    ApiException(reason: 'invalid_credentials') ||
    ApiException(statusCode: 401) => 'Incorrect email or password.',
    ApiException(code: 'invalid_argument') =>
      'That email address is not valid.',
    _ => 'Something went wrong. Please try again.',
  };
}
