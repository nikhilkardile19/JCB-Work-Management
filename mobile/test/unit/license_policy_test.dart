import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/license/domain/license.dart';

void main() {
  final now = DateTime.utc(2026, 10, 29, 12);
  int ms(DateTime d) => d.millisecondsSinceEpoch;

  LicenseSnapshot snap({
    LicenseStatus status = LicenseStatus.active,
    DeviceStatus device = DeviceStatus.active,
    Duration checkedAgo = Duration.zero,
    DateTime? validUntil,
  }) => LicenseSnapshot(
    licenseId: 'lic1',
    status: status,
    deviceStatus: device,
    validUntil: ms(validUntil ?? DateTime.utc(2027, 3, 31)),
    maxDevices: 2,
    lastValidatedAt: ms(now.subtract(checkedAgo)),
  );

  LicenseAccess eval(LicenseSnapshot? s) => LicensePolicy.evaluate(s, now);

  test('no license or unknown device → activation needed', () {
    expect(eval(null), isA<LicenseNeedsActivation>());
    expect(
      eval(snap(status: LicenseStatus.none)),
      isA<LicenseNeedsActivation>(),
    );
    expect(
      eval(snap(device: DeviceStatus.unknown)),
      isA<LicenseNeedsActivation>(),
    );
  });

  test('freshly checked active license allows everything', () {
    final a = eval(snap(checkedAgo: const Duration(hours: 3)));
    expect(a, isA<LicenseOk>());
    expect(a.canWrite, isTrue);
    expect((a as LicenseOk).daysToExpiry, isNull);
  });

  test('renewal warning inside 14 days', () {
    final a = eval(
      snap(validUntil: now.add(const Duration(days: 10, hours: 1))),
    ) as LicenseOk;
    expect(a.daysToExpiry, 10);
  });

  test('offline: grace for 7 days, then read-only', () {
    final g = eval(snap(checkedAgo: const Duration(days: 3, hours: 1)));
    expect(g, isA<LicenseGrace>());
    expect((g as LicenseGrace).daysLeft, 4);
    expect(g.canWrite, isTrue);
    expect(
      eval(snap(checkedAgo: const Duration(days: 6, hours: 23))),
      isA<LicenseGrace>(),
    );
    final ro = eval(snap(checkedAgo: const Duration(days: 7, hours: 1)));
    expect(ro, isA<LicenseReadOnly>());
    expect((ro as LicenseReadOnly).reason, ReadOnlyReason.offlineTooLong);
    expect(ro.canWrite, isFalse);
  });

  test('server states block changes', () {
    for (final (status, reason) in [
      (LicenseStatus.suspended, ReadOnlyReason.suspended),
      (LicenseStatus.revoked, ReadOnlyReason.revoked),
      (LicenseStatus.expired, ReadOnlyReason.expired),
      (LicenseStatus.pending, ReadOnlyReason.pending),
      (LicenseStatus.notStarted, ReadOnlyReason.notStarted),
    ]) {
      expect(
        (eval(snap(status: status)) as LicenseReadOnly).reason,
        reason,
        reason: status.name,
      );
    }
    expect(
      (eval(snap(device: DeviceStatus.revoked)) as LicenseReadOnly).reason,
      ReadOnlyReason.deviceRevoked,
    );
  });

  test('end date passes while offline → expired, even if recently checked', () {
    final a = eval(snap(validUntil: now.subtract(const Duration(minutes: 1))));
    expect((a as LicenseReadOnly).reason, ReadOnlyReason.expired);
  });

  test('clock set back to stretch the grace period is caught', () {
    final s = LicenseSnapshot(
      status: LicenseStatus.active,
      deviceStatus: DeviceStatus.active,
      validUntil: ms(DateTime.utc(2027)),
      lastValidatedAt: ms(now.add(const Duration(days: 5))),
    );
    expect((eval(s) as LicenseReadOnly).reason, ReadOnlyReason.clockChanged);
  });

  test('staleness and cache round-trip', () {
    expect(LicensePolicy.isStale(null, now), isTrue);
    expect(
      LicensePolicy.isStale(snap(checkedAgo: const Duration(hours: 23)), now),
      isFalse,
    );
    expect(
      LicensePolicy.isStale(snap(checkedAgo: const Duration(hours: 25)), now),
      isTrue,
    );
    final s = snap();
    final back = LicenseSnapshot.fromJson(s.toJson())!;
    expect(back.status, s.status);
    expect(back.validUntil, s.validUntil);
    expect(back.lastValidatedAt, s.lastValidatedAt);
    final server = LicenseSnapshot.fromServer({
      'licenseStatus': 'not_started',
      'deviceStatus': 'active',
    }, checkedAt: now);
    expect(server.status, LicenseStatus.notStarted);
  });
}
