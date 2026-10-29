import 'package:cloud_functions/cloud_functions.dart';

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

/// Trusted license operations (Cloud Functions). The app never decides by
/// itself that it is licensed; it only caches what the server said.
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

class CloudLicenseService implements LicenseService {
  CloudLicenseService([FirebaseFunctions? functions])
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final r = await _functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
          )
          .call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(r.data);
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      switch (e.code) {
        case 'failed-precondition' when reason != null:
          throw LicenseDenied(reason, e.message ?? 'Activation was refused.');
        case 'failed-precondition':
          throw LicenseDenied(
            'company_inactive',
            e.message ?? 'This company is not approved yet.',
          );
        case 'permission-denied':
          throw LicenseDenied(
            'not_member',
            e.message ?? 'You are not a member of this company.',
          );
        case 'invalid-argument':
          throw LicenseDenied(
            'invalid_code',
            e.message ?? 'Check the activation code.',
          );
        default:
          throw const LicenseServerUnavailable();
      }
    } catch (e) {
      if (e is LicenseDenied) rethrow;
      throw const LicenseServerUnavailable();
    }
  }

  @override
  Future<Map<String, dynamic>> activate({
    required String companyId,
    required String activationCode,
    required String deviceId,
    required String deviceModel,
  }) => _call('activateDevice', {
    'companyId': companyId,
    'activationCode': activationCode,
    'deviceId': deviceId,
    'deviceModel': deviceModel,
    'platform': 'android',
  });

  @override
  Future<Map<String, dynamic>> validate({
    required String companyId,
    required String deviceId,
  }) =>
      _call('validateLicense', {'companyId': companyId, 'deviceId': deviceId});
}
