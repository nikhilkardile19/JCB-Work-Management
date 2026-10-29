import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

class CloudReplacementService implements ReplacementService {
  CloudReplacementService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _db;

  @override
  Future<ReplacementState> request({
    required String companyId,
    required String activationCode,
    required String newDeviceId,
    required String newDeviceModel,
    required String reason,
  }) async {
    try {
      final r = await _functions
          .httpsCallable(
            'requestDeviceReplacement',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
          )
          .call<Map<String, dynamic>>({
            'companyId': companyId,
            'activationCode': activationCode,
            'newDeviceId': newDeviceId,
            'newDeviceModel': newDeviceModel,
            'reason': reason,
          });
      return ReplacementState(
        ReplacementStatus.parse(r.data['status'] as String?),
        requestId: r.data['requestId'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' ||
          e.code == 'invalid-argument' ||
          e.code == 'permission-denied') {
        final reason = e.details is Map
            ? (e.details as Map)['reason'] as String?
            : null;
        throw LicenseDenied(
          reason ?? e.code,
          e.message ?? 'The request was refused.',
        );
      }
      throw const LicenseServerUnavailable();
    } catch (e) {
      if (e is LicenseDenied) rethrow;
      throw const LicenseServerUnavailable();
    }
  }

  @override
  Future<ReplacementState> status({
    required String companyId,
    required String requestId,
  }) async {
    try {
      final d = await _db
          .doc('companies/$companyId/deviceReplacementRequests/$requestId')
          .get(const GetOptions(source: Source.server));
      return ReplacementState(
        ReplacementStatus.parse(d.data()?['status'] as String?),
        requestId: requestId,
        reviewReason: d.data()?['reviewReason'] as String?,
      );
    } on FirebaseException {
      throw const LicenseServerUnavailable();
    }
  }
}
