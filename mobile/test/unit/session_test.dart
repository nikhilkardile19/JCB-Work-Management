import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/app/router.dart';
import 'package:jcb_work_management/app/routes.dart';
import 'package:jcb_work_management/features/auth/data/auth_repository.dart';
import 'package:jcb_work_management/features/company/application/session.dart';
import 'package:jcb_work_management/features/company/domain/company.dart';
import 'package:jcb_work_management/features/license/domain/license.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';

import '../helpers/fakes.dart';

const user = AppUser(uid: 'u1', email: 'a@b.co');

SessionState resolve({
  AsyncValue<AppUser?> auth = const AsyncData(user),
  List<CompanyMembership>? companies = const [],
  String? selected,
  AsyncValue<void> refresh = const AsyncData(null),
}) => resolveSession(
  auth: auth,
  memberships: companies == null ? const AsyncLoading() : AsyncData(companies),
  selectedCompanyId: AsyncData(selected),
  refresh: refresh,
);

void main() {
  final active = membership('a', 'Alpha');
  final beta = membership('b', 'Beta');

  group('resolveSession', () {
    test('auth loading → loading; auth error → error', () {
      expect(resolve(auth: const AsyncLoading()), isA<SessionLoading>());
      expect(
        resolve(auth: AsyncError(Exception(), StackTrace.empty)),
        isA<SessionError>(),
      );
    });

    test('signed out', () {
      expect(resolve(auth: const AsyncData(null)), isA<SessionSignedOut>());
    });

    test('cache still loading → loading', () {
      expect(resolve(companies: null), isA<SessionLoading>());
    });

    test('empty cache waits for server before asking for setup', () {
      expect(resolve(refresh: const AsyncLoading()), isA<SessionLoading>());
      expect(
        resolve(refresh: AsyncError(Exception('offline'), StackTrace.empty)),
        isA<SessionError>(),
      );
      expect(resolve(), isA<SessionNeedsCompany>());
    });

    test('cached company is used even when the server is unreachable', () {
      final s = resolve(
        companies: [active],
        refresh: AsyncError(Exception('offline'), StackTrace.empty),
      );
      expect(s, isA<SessionReady>());
    });

    test('single company is auto-selected; several need a choice', () {
      expect(resolve(companies: [active]), isA<SessionReady>());
      expect(resolve(companies: [active, beta]), isA<SessionPickCompany>());
      final s = resolve(companies: [active, beta], selected: 'b');
      expect((s as SessionReady).membership.companyId, 'b');
      expect(s.companyCount, 2);
    });

    test('stale selection falls back to choosing', () {
      expect(
        resolve(companies: [active, beta], selected: 'gone'),
        isA<SessionPickCompany>(),
      );
    });

    test('pending and suspended companies are gated', () {
      expect(
        resolve(
          companies: [membership('p', 'P', status: CompanyStatus.pending)],
        ),
        isA<SessionPendingApproval>(),
      );
      expect(
        resolve(
          companies: [membership('s', 'S', status: CompanyStatus.suspended)],
        ),
        isA<SessionSuspended>(),
      );
    });
  });

  group('sessionRedirect', () {
    test('loading and errors park on splash', () {
      expect(
        sessionRedirect(const SessionLoading(), Routes.work),
        Routes.splash,
      );
      expect(sessionRedirect(SessionError(Exception()), Routes.splash), isNull);
    });

    test('signed out may only see login, sign-up and password reset', () {
      const s = SessionSignedOut();
      for (final r in [
        Routes.dashboard,
        Routes.companySetup,
        Routes.companyProfile,
        Routes.components,
      ]) {
        expect(sessionRedirect(s, r), Routes.login, reason: r);
      }
      expect(sessionRedirect(s, Routes.login), isNull);
      expect(sessionRedirect(s, Routes.forgotPassword), isNull);
      expect(sessionRedirect(s, Routes.signUp), isNull);
    });

    test('onboarding states pin their screen', () {
      expect(
        sessionRedirect(const SessionNeedsCompany(user), Routes.dashboard),
        Routes.companySetup,
      );
      expect(
        sessionRedirect(SessionPickCompany(user, [active]), Routes.more),
        Routes.selectCompany,
      );
      expect(
        sessionRedirect(SessionPendingApproval(user, active), Routes.billing),
        Routes.companyStatus,
      );
      expect(
        sessionRedirect(SessionSuspended(user, active), Routes.dashboard),
        Routes.companyStatus,
      );
    });

    test('ready users skip gate screens but reach app screens', () {
      final s = SessionReady(user, active);
      const ok = LicenseOk();
      for (final r in Routes.gate) {
        expect(sessionRedirect(s, r, license: ok), Routes.dashboard, reason: r);
      }
      expect(sessionRedirect(s, Routes.companyProfile, license: ok), isNull);
      expect(sessionRedirect(s, Routes.billing, license: ok), isNull);
      expect(sessionRedirect(s, Routes.workNew, license: ok), isNull);
    });

    test('license gate: loading, activation, read-only forms', () {
      final s = SessionReady(user, active);
      expect(sessionRedirect(s, Routes.dashboard), Routes.splash);
      const needs = LicenseNeedsActivation();
      expect(
        sessionRedirect(s, Routes.dashboard, license: needs),
        Routes.activate,
      );
      expect(sessionRedirect(s, Routes.activate, license: needs), isNull);
      const ro = LicenseReadOnly(ReadOnlyReason.expired);
      for (final r in [
        Routes.workNew,
        Routes.workEdit('x'),
        Routes.workCorrect('x'),
        Routes.fuelNew,
        Routes.invoiceEdit('x'),
        Routes.masterNew(MasterKind.clients),
      ]) {
        expect(sessionRedirect(s, r, license: ro), Routes.license, reason: r);
      }
      expect(
        sessionRedirect(s, Routes.workDetail('x'), license: ro),
        isNull,
        reason: 'viewing still works',
      );
      expect(sessionRedirect(s, Routes.billing, license: ro), isNull);
      expect(
        sessionRedirect(s, Routes.workNew, license: const LicenseGrace(3)),
        isNull,
      );
    });
  });
}
