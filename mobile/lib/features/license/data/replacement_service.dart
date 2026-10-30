import '../../../core/network/api_client.dart';
import 'license_service.dart';

enum ReplacementStatus {
  pending,
  approved,
  rejected,
  alreadyActive;

  static ReplacementStatus parse(String? v) => switch (v) {
    'already_active' => ReplacementStatus.alreadyActive,
    'approved' => ReplacementStatus.approved,
    'rejected' => ReplacementStatus.rejected,
    _ => ReplacementStatus.pending,
  };
}

class ReplacementState {
  const ReplacementState(this.status, {this.requestId, this.reviewReason});

  final ReplacementStatus status;
  final String? requestId;
  final String? reviewReason;
}

/// Asks the developer admin to move a license place to this phone.
abstract interface class ReplacementService {
  Future<ReplacementState> request({
    required String companyId,
    required String activationCode,
    required String newDeviceId,
    required String newDeviceModel,
    required String reason,
  });

  Future<ReplacementState> status({
    required String companyId,
    required String requestId,
  });
}

/// `/companies/:companyId/device-replacements[/:requestId]`.
class HttpReplacementService implements ReplacementService {
  HttpReplacementService(this._api);

  final ApiClient _api;

  @override
  Future<ReplacementState> request({
    required String companyId,
    required String activationCode,
    required String newDeviceId,
    required String newDeviceModel,
    required String reason,
  }) async {
    try {
      final r = await _api.post(
        apiPath(['companies', companyId, 'device-replacements']),
        body: {
          'activationCode': activationCode,
          'newDeviceId': newDeviceId,
          'newDeviceModel': newDeviceModel,
          'reason': reason,
        },
      );
      return ReplacementState(
        ReplacementStatus.parse(r['status'] as String?),
        requestId: r['requestId'] as String?,
      );
    } catch (e) {
      throw licenseFailure(e);
    }
  }

  @override
  Future<ReplacementState> status({
    required String companyId,
    required String requestId,
  }) async {
    try {
      final r = await _api.get(
        apiPath(['companies', companyId, 'device-replacements', requestId]),
      );
      return ReplacementState(
        ReplacementStatus.parse(r['status'] as String?),
        requestId: requestId,
        reviewReason: r['reviewReason'] as String?,
      );
    } catch (_) {
      // Callers only expect "unavailable" here, as before.
      throw const LicenseServerUnavailable();
    }
  }
}
