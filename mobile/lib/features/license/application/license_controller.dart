import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/network/network_providers.dart';
import '../../../data/local/database_provider.dart';
import '../../work/application/work_providers.dart';
import '../data/license_service.dart';
import '../data/replacement_service.dart';
import '../domain/license.dart';

final licenseServiceProvider = Provider<LicenseService>(
  (ref) => HttpLicenseService(ref.watch(apiClientProvider)),
);

final replacementServiceProvider = Provider<ReplacementService>(
  (ref) => HttpReplacementService(ref.watch(apiClientProvider)),
);

/// Background license checks (startup, reconnect, hourly). Off in tests.
final autoLicenseCheckProvider = Provider<bool>((ref) => true);

/// Injectable clock so time-based rules can be tested.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Cached license state for the signed-in user on this phone in the active
/// company, refreshed from the server when stale.
class LicenseController extends AsyncNotifier<LicenseSnapshot?> {
  Timer? _timer;

  String _key(String companyId, String userId) => 'license:$companyId:$userId';

  @override
  Future<LicenseSnapshot?> build() async {
    final actor = ref.watch(workActorProvider);
    ref.onDispose(() => _timer?.cancel());
    if (actor == null) return null;
    final db = ref.watch(appDatabaseProvider);
    final cached = LicenseSnapshot.fromJson(
      await db.readSetting(_key(actor.companyId, actor.userId)),
    );
    if (ref.watch(autoLicenseCheckProvider)) {
      ref.listen(isOnlineProvider, (prev, next) {
        if (next.value == true && prev?.value != true) {
          unawaited(refreshIfStale());
        }
      });
      _timer = Timer.periodic(
        const Duration(hours: 1),
        (_) => unawaited(refreshIfStale()),
      );
      unawaited(Future.microtask(refreshIfStale));
    }
    return cached;
  }

  Future<void> _save(LicenseSnapshot s) async {
    final actor = ref.read(workActorProvider)!;
    await ref
        .read(appDatabaseProvider)
        .writeSetting(_key(actor.companyId, actor.userId), s.toJson());
    state = AsyncData(s);
  }

  /// Registers this phone with an activation code. Throws [LicenseDenied]
  /// or [LicenseServerUnavailable].
  Future<void> activate(String code) async {
    final actor = ref.read(workActorProvider)!;
    final result = await ref
        .read(licenseServiceProvider)
        .activate(
          companyId: actor.companyId,
          activationCode: code.trim(),
          deviceId: await ref.read(appDatabaseProvider).installationId(),
          deviceModel: _deviceModel(),
        );
    await _save(
      LicenseSnapshot.fromServer(result, checkedAt: ref.read(clockProvider)()),
    );
  }

  /// Asks the server for the current state. Throws
  /// [LicenseServerUnavailable] when offline (the cache stays as it is).
  Future<void> refresh() async {
    final actor = ref.read(workActorProvider);
    if (actor == null) return;
    final result = await ref
        .read(licenseServiceProvider)
        .validate(
          companyId: actor.companyId,
          deviceId: await ref.read(appDatabaseProvider).installationId(),
        );
    await _save(
      LicenseSnapshot.fromServer(result, checkedAt: ref.read(clockProvider)()),
    );
  }

  String _requestKey(String companyId, String userId) =>
      'replacement:$companyId:$userId';

  /// Pending replacement request for this phone, if any.
  Future<String?> pendingRequestId() async {
    final actor = ref.read(workActorProvider);
    if (actor == null) return null;
    return ref
        .read(appDatabaseProvider)
        .readSetting(_requestKey(actor.companyId, actor.userId));
  }

  /// Asks for this phone to replace one on the full license. Throws
  /// [LicenseDenied] or [LicenseServerUnavailable].
  Future<ReplacementState> requestReplacement({
    required String activationCode,
    required String reason,
  }) async {
    final actor = ref.read(workActorProvider)!;
    final db = ref.read(appDatabaseProvider);
    final r = await ref
        .read(replacementServiceProvider)
        .request(
          companyId: actor.companyId,
          activationCode: activationCode.trim(),
          newDeviceId: await db.installationId(),
          newDeviceModel: _deviceModel(),
          reason: reason.trim(),
        );
    if (r.status == ReplacementStatus.alreadyActive) {
      await refresh();
    } else if (r.requestId != null) {
      await db.writeSetting(
        _requestKey(actor.companyId, actor.userId),
        r.requestId!,
      );
    }
    return r;
  }

  /// Checks the pending request; on approval the license is refreshed so the
  /// app unlocks. A rejected request is cleared so a new one can be made.
  Future<ReplacementState?> checkReplacement() async {
    final actor = ref.read(workActorProvider);
    final id = await pendingRequestId();
    if (actor == null || id == null) return null;
    final r = await ref
        .read(replacementServiceProvider)
        .status(companyId: actor.companyId, requestId: id);
    final db = ref.read(appDatabaseProvider);
    if (r.status == ReplacementStatus.approved) {
      await db.deleteSetting(_requestKey(actor.companyId, actor.userId));
      await refresh();
    } else if (r.status == ReplacementStatus.rejected) {
      await db.deleteSetting(_requestKey(actor.companyId, actor.userId));
    }
    return r;
  }

  Future<void> refreshIfStale() async {
    if (!LicensePolicy.isStale(state.value, ref.read(clockProvider)())) return;
    try {
      await refresh();
    } on LicenseServerUnavailable {
      // Offline: the grace period applies.
    } on LicenseDenied {
      // e.g. company no longer active; the cached state stands.
    }
  }

  static String _deviceModel() {
    final s = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    return s.length > 100 ? s.substring(0, 100) : s;
  }
}

final licenseControllerProvider =
    AsyncNotifierProvider<LicenseController, LicenseSnapshot?>(
      LicenseController.new,
      retry: (_, _) => null,
    );

/// What the user may do now; loading until the cache is read.
final licenseAccessProvider = Provider<AsyncValue<LicenseAccess>>((ref) {
  final now = ref.watch(clockProvider)();
  return ref
      .watch(licenseControllerProvider)
      .whenData((s) => LicensePolicy.evaluate(s, now));
});

/// True when changes may be made (license OK or within the grace period).
final canWriteProvider = Provider<bool>(
  (ref) => ref.watch(licenseAccessProvider).value?.canWrite ?? false,
);
