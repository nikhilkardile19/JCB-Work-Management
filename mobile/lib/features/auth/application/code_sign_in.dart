import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../../company/application/company_providers.dart';
import '../../license/application/license_controller.dart';
import '../../license/domain/license.dart';
import 'auth_providers.dart';

/// Sign-in with email and activation code (no password).
///
/// Before the session starts, the company the code belongs to is selected
/// and the server's license state for this phone is cached, so the router
/// goes straight to the dashboard instead of asking to pick a company or
/// activate the phone.
class CodeSignInService {
  CodeSignInService(this._ref);

  final Ref _ref;

  /// Throws [AuthException].
  Future<void> signIn({
    required String email,
    required String activationCode,
  }) async {
    final db = _ref.read(appDatabaseProvider);
    final code = activationCode.trim();
    await _ref
        .read(authRepositoryProvider)
        .signInWithCode(
          email: email,
          activationCode: code,
          deviceId: await db.installationId(),
          deviceModel: LicenseController.deviceModel(),
          prepare: (r) async {
            await _ref
                .read(companyRepositoryProvider)
                .selectCompany(r.user.uid, r.companyId);
            if (r.license case final license?) {
              final snapshot = LicenseSnapshot.fromServer(
                license,
                checkedAt: _ref.read(clockProvider)(),
              );
              await db.writeSetting(
                LicenseController.cacheKey(r.companyId, r.user.uid),
                snapshot.toJson(),
              );
            }
            _ref
                .read(pendingActivationProvider.notifier)
                .set(
                  r.refusalReason == null
                      ? null
                      : PendingActivation(
                          code: code,
                          reason: r.refusalReason!,
                          message: r.refusalMessage ?? '',
                        ),
                );
          },
        );
  }
}

final codeSignInProvider = Provider<CodeSignInService>(CodeSignInService.new);
