import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// The server refused activation; [reason] is a stable code
/// (invalid_code, expired, suspended, revoked, device_limit, …).
class LicenseDenied implements Exception {
  const LicenseDenied(this.reason, this.message);

  final String reason;
  final String message;

  @override
  String toString() => message;
}

/// The license server can't be reached; the cached state still applies.
class LicenseServerUnavailable implements Exception {
  const LicenseServerUnavailable([
    this.message = 'Could not reach the license server.',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Trusted license operations (REST API). The app never decides by itself
/// that it is licensed; it only caches what the server said.
abstract interface class LicenseService {
  Future<Map<String, dynamic>> activate({
    required String companyId,
    required String activationCode,
    required String deviceId,
    required String deviceModel,
  });

  Future<Map<String, dynamic>> validate({
    required String companyId,
    required String deviceId,
  });
}

/// Maps a failed license or replacement request to [LicenseDenied] or
/// [LicenseServerUnavailable].
Exception licenseFailure(Object error) => switch (error) {
  LicenseDenied() || LicenseServerUnavailable() => error as Exception,
  ApiException(statusCode: 409, code: 'failed_precondition', :final reason?) =>
    LicenseDenied(reason, error.message),
  ApiException(statusCode: 409, code: 'failed_precondition') => LicenseDenied(
    'company_inactive',
    error.message,
  ),
  ApiException(statusCode: 403) => LicenseDenied('not_member', error.message),
  ApiException(statusCode: 400) => LicenseDenied('invalid_code', error.message),
  // Too many wrong codes: say so rather than "can't reach the server".
  ApiUnavailable(isRateLimited: true) => LicenseServerUnavailable(
    error.message,
  ),
  _ => const LicenseServerUnavailable(),
};

/// `POST /companies/:companyId/license/activate|validate`.
class HttpLicenseService implements LicenseService {
  HttpLicenseService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> _call(
    String companyId,
    String action,
    Map<String, dynamic> body,
  ) async {
    try {
      return await _api.post(
        apiPath(['companies', companyId, 'license', action]),
        body: body,
      );
    } catch (e) {
      throw licenseFailure(e);
    }
  }

  @override
  Future<Map<String, dynamic>> activate({
    required String companyId,
    required String activationCode,
    required String deviceId,
    required String deviceModel,
  }) => _call(companyId, 'activate', {
    'activationCode': activationCode,
    'deviceId': deviceId,
    'deviceModel': deviceModel,
    'platform': 'android',
  });

  @override
  Future<Map<String, dynamic>> validate({
    required String companyId,
    required String deviceId,
  }) => _call(companyId, 'validate', {'deviceId': deviceId});
}
