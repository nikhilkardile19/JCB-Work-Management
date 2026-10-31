import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/session_store.dart';
import '../../company/data/company_remote_source.dart';
import '../../company/domain/company.dart';
import 'auth_repository.dart';

/// Email + activation code sign-in against the REST API (`/auth/*`); the
/// app has no passwords.
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
  Future<void> checkEmail(String email) async {
    try {
      await _api.post(
        '/auth/check-email',
        body: {'email': email.trim()},
        authenticated: false,
      );
    } catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<AppUser> signInWithCode({
    required String email,
    required String activationCode,
    required String deviceId,
    required String deviceModel,
    Future<void> Function(CodeSignIn result)? prepare,
  }) async {
    final AuthSession session;
    final CodeSignIn result;
    try {
      final json = await _api.post(
        '/auth/login-with-code',
        body: {
          'email': email.trim(),
          'activationCode': activationCode.trim(),
          'deviceId': deviceId,
          'deviceModel': deviceModel,
          'platform': 'android',
        },
        authenticated: false,
      );
      session = AuthSession.fromJson(json);
      final refusal = json['activation'] as Map<String, dynamic>?;
      result = CodeSignIn(
        user: _toUser(session.user)!,
        companyId: json['companyId'] as String,
        license: json['license'] as Map<String, dynamic>?,
        refusalReason: refusal?['reason'] as String?,
        refusalMessage: refusal?['message'] as String?,
      );
    } catch (e) {
      throw _failure(e);
    }
    await prepare?.call(result);
    await _session.save(session);
    return result.user;
  }

  @override
  Future<void> signUp({
    required String email,
    required CompanyProfile profile,
  }) async {
    try {
      await _api.post(
        '/auth/signup',
        body: {'email': email.trim(), 'company': companyProfileBody(profile)},
        authenticated: false,
      );
    } catch (e) {
      throw switch (e) {
        ApiException(reason: 'email_taken') => const AuthException(
          'An account with this email already exists. Sign in with your email and activation code.',
          reason: 'email_taken',
        ),
        ApiException(code: 'invalid_argument') => const AuthException(
          'Some details were not accepted. Check them and try again.',
        ),
        _ => _failure(e),
      };
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

  static AuthException _failure(Object e) =>
      AuthException(messageFor(e), reason: e is ApiException ? e.reason : null);

  /// User-facing message for a failed sign-in request.
  static String messageFor(Object error) => switch (error) {
    // The server says how long to wait (minutes for sign-in, an hour for
    // wrong activation codes).
    ApiUnavailable(isRateLimited: true, :final message) => message,
    ApiUnavailable(statusCode: null) => "Couldn't reach the server. Check your internet connection and try again.",
    ApiException(reason: 'user_disabled') =>
      'This account has been disabled. Contact your administrator.',
    ApiException(reason: 'no_account') =>
      'No JCB Works account uses this email. Check it, or create an account.',
    ApiException(reason: 'invalid_code') || ApiException(statusCode: 401) =>
      'That activation code is not valid for this email address.',
    // Activation refusals (code already used, license expired, company not
    // approved, …): the server's text is written for users.
    ApiException(code: 'failed_precondition', :final message) => message,
    ApiException(code: 'invalid_argument') =>
      'That email address is not valid.',
    _ => 'Something went wrong. Please try again.',
  };
}
