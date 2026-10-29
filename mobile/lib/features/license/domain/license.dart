import 'dart:convert';

import '../../../core/config/app_config.dart';

enum LicenseStatus {
  active,
  pending,
  suspended,
  expired,
  revoked,
  notStarted,
  none;

  static LicenseStatus parse(String? v) => switch (v) {
    'not_started' => LicenseStatus.notStarted,
    final s? =>
      LicenseStatus.values.where((e) => e.name == s).firstOrNull ??
          LicenseStatus.none,
    null => LicenseStatus.none,
  };
}

enum DeviceStatus {
  active,
  revoked,
  unknown;

  static DeviceStatus parse(String? v) =>
      DeviceStatus.values.where((e) => e.name == v).firstOrNull ??
      DeviceStatus.unknown;
}

/// What the server last said about this device's license. Cached locally so
/// the app works offline; the server remains the authority.
class LicenseSnapshot {
  const LicenseSnapshot({
    required this.status,
    required this.deviceStatus,
    required this.lastValidatedAt,
    this.licenseId,
    this.validUntil,
    this.maxDevices,
  });

  final String? licenseId;
  final LicenseStatus status;
  final DeviceStatus deviceStatus;

  /// UTC epoch ms; null when the license has no end.
  final int? validUntil;
  final int? maxDevices;

  /// Device clock (UTC ms) at the last successful server check.
  final int lastValidatedAt;

  static LicenseSnapshot fromServer(
    Map<String, dynamic> m, {
    required DateTime checkedAt,
  }) => LicenseSnapshot(
    licenseId: m['licenseId'] as String?,
    status: LicenseStatus.parse(m['licenseStatus'] as String?),
    deviceStatus: DeviceStatus.parse(m['deviceStatus'] as String?),
    validUntil: (m['validUntil'] as num?)?.toInt(),
    maxDevices: (m['maxDevices'] as num?)?.toInt(),
    lastValidatedAt: checkedAt.toUtc().millisecondsSinceEpoch,
  );

  String toJson() => jsonEncode({
    'licenseId': licenseId,
    'status': status.name,
    'deviceStatus': deviceStatus.name,
    'validUntil': validUntil,
    'maxDevices': maxDevices,
    'lastValidatedAt': lastValidatedAt,
  });

  static LicenseSnapshot? fromJson(String? json) {
    if (json == null) return null;
    final m = jsonDecode(json) as Map<String, dynamic>;
    return LicenseSnapshot(
      licenseId: m['licenseId'] as String?,
      status: LicenseStatus.values.byName(m['status'] as String),
      deviceStatus: DeviceStatus.values.byName(m['deviceStatus'] as String),
      validUntil: m['validUntil'] as int?,
      maxDevices: m['maxDevices'] as int?,
      lastValidatedAt: m['lastValidatedAt'] as int,
    );
  }
}

enum ReadOnlyReason {
  expired('This license has expired.'),
  suspended('This license is suspended.'),
  revoked('This license has been revoked.'),
  pending('This license is not active yet.'),
  notStarted('This license has not started yet.'),
  deviceRevoked('This phone has been deactivated for the license.'),
  offlineTooLong(
    "The license hasn't been checked for too long. Connect to the internet.",
  ),
  clockChanged(
    "The phone's date or time looks wrong. Fix it and connect to the internet.",
  );

  const ReadOnlyReason(this.message);

  final String message;
}

/// What the user may do right now.
sealed class LicenseAccess {
  const LicenseAccess();

  bool get canWrite => this is LicenseOk || this is LicenseGrace;
}

/// No license on this phone yet: activation (online) is required.
class LicenseNeedsActivation extends LicenseAccess {
  const LicenseNeedsActivation();
}

class LicenseOk extends LicenseAccess {
  const LicenseOk({this.daysToExpiry});

  /// Set when the license ends within the warning window.
  final int? daysToExpiry;
}

/// Not checked recently (offline) but still within the grace period.
class LicenseGrace extends LicenseAccess {
  const LicenseGrace(this.daysLeft);

  final int daysLeft;
}

/// Existing data stays viewable and exportable; changes are blocked.
class LicenseReadOnly extends LicenseAccess {
  const LicenseReadOnly(this.reason);

  final ReadOnlyReason reason;
}

/// Offline license policy (sprint doc §5.6, product decision #5).
abstract final class LicensePolicy {
  static const _day = Duration(days: 1);

  static LicenseAccess evaluate(
    LicenseSnapshot? s,
    DateTime now, {
    int graceDays = AppConfig.offlineGraceDays,
    Duration revalidateAfter = AppConfig.licenseRevalidateAfter,
  }) {
    if (s == null ||
        s.status == LicenseStatus.none ||
        s.deviceStatus == DeviceStatus.unknown) {
      return const LicenseNeedsActivation();
    }
    if (s.deviceStatus == DeviceStatus.revoked) {
      return const LicenseReadOnly(ReadOnlyReason.deviceRevoked);
    }
    final blocked = switch (s.status) {
      LicenseStatus.suspended => ReadOnlyReason.suspended,
      LicenseStatus.revoked => ReadOnlyReason.revoked,
      LicenseStatus.expired => ReadOnlyReason.expired,
      LicenseStatus.pending => ReadOnlyReason.pending,
      LicenseStatus.notStarted => ReadOnlyReason.notStarted,
      _ => null,
    };
    if (blocked != null) return LicenseReadOnly(blocked);

    final nowMs = now.toUtc().millisecondsSinceEpoch;
    if (s.validUntil != null && nowMs > s.validUntil!) {
      return const LicenseReadOnly(ReadOnlyReason.expired);
    }
    // A clock set back to stretch the grace period is treated as unverified.
    if (nowMs < s.lastValidatedAt - _day.inMilliseconds) {
      return const LicenseReadOnly(ReadOnlyReason.clockChanged);
    }

    final age = Duration(milliseconds: nowMs - s.lastValidatedAt);
    if (age > Duration(days: graceDays)) {
      return const LicenseReadOnly(ReadOnlyReason.offlineTooLong);
    }
    if (age > revalidateAfter) return LicenseGrace(graceDays - age.inDays);

    final daysToExpiry = s.validUntil == null
        ? null
        : Duration(milliseconds: s.validUntil! - nowMs).inDays;
    return LicenseOk(
      daysToExpiry:
          daysToExpiry != null &&
              daysToExpiry <= AppConfig.licenseExpiryWarningDays
          ? daysToExpiry
          : null,
    );
  }

  /// Whether a server check is due.
  static bool isStale(
    LicenseSnapshot? s,
    DateTime now, {
    Duration revalidateAfter = AppConfig.licenseRevalidateAfter,
  }) =>
      s == null ||
      now.toUtc().millisecondsSinceEpoch - s.lastValidatedAt >
          revalidateAfter.inMilliseconds;
}
