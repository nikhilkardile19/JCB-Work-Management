import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/core/network/api_exception.dart';
import 'package:jcb_work_management/features/auth/data/http_auth_repository.dart';
import 'package:jcb_work_management/features/company/domain/company_validators.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';

void main() {
  group('permissions', () {
    test('owner and admin can do everything', () {
      for (final p in Permission.values) {
        expect(CompanyRole.owner.can(p), isTrue, reason: p.name);
        expect(CompanyRole.admin.can(p), isTrue, reason: p.name);
      }
    });

    test('operator can only log work and fuel', () {
      final granted = Permission.values.where(CompanyRole.operator.can).toSet();
      expect(granted, {Permission.createWorkLogs, Permission.recordFuel});
    });

    test('nobody but owner/admin manages the company or licenses', () {
      for (final r in [
        CompanyRole.manager,
        CompanyRole.operator,
        CompanyRole.accounts,
      ]) {
        expect(r.can(Permission.manageCompany), isFalse, reason: r.name);
        expect(r.can(Permission.manageUsers), isFalse, reason: r.name);
        expect(
          r.can(Permission.requestDeviceReplacement),
          isFalse,
          reason: r.name,
        );
      }
    });

    test('accounts bills but cannot edit masters', () {
      expect(CompanyRole.accounts.can(Permission.manageInvoices), isTrue);
      expect(CompanyRole.accounts.can(Permission.recordPayments), isTrue);
      expect(CompanyRole.accounts.can(Permission.manageMasters), isFalse);
    });

    test('parse rejects unknown roles', () {
      expect(CompanyRole.parse('owner'), CompanyRole.owner);
      expect(CompanyRole.parse('superuser'), isNull);
      expect(CompanyRole.parse(null), isNull);
    });
  });

  group('company validators', () {
    test('name', () {
      expect(CompanyValidators.name(' '), isNotNull);
      expect(CompanyValidators.name('Sai Earthmovers'), isNull);
      expect(CompanyValidators.name('x' * 121), isNotNull);
    });

    test('phone accepts Indian formats', () {
      for (final ok in ['9876543210', '+91 98765 43210', '020-2345-6789']) {
        expect(CompanyValidators.phone(ok), isNull, reason: ok);
      }
      for (final bad in ['', '12345', 'phone', '+91 98765']) {
        expect(CompanyValidators.phone(bad), isNotNull, reason: bad);
      }
    });

    test('GSTIN is optional but validated', () {
      expect(CompanyValidators.optionalGstin(''), isNull);
      expect(CompanyValidators.optionalGstin('27ABCDE1234F1Z5'), isNull);
      expect(CompanyValidators.optionalGstin('27abcde1234f1z5'), isNull);
      expect(CompanyValidators.optionalGstin('27ABCDE1234F1X5'), isNotNull);
      expect(CompanyValidators.optionalGstin('12345'), isNotNull);
    });

    test('invoice prefix', () {
      expect(CompanyValidators.invoicePrefix(''), isNotNull);
      expect(CompanyValidators.invoicePrefix('JCB-PUNE'), isNull);
      expect(CompanyValidators.invoicePrefix('jcb'), isNull);
      expect(CompanyValidators.invoicePrefix('JCB/1'), isNotNull);
      expect(CompanyValidators.invoicePrefix('ABCDEFGHIJK'), isNotNull);
    });

    test('optional email and required address', () {
      expect(CompanyValidators.optionalEmail(''), isNull);
      expect(CompanyValidators.optionalEmail('bad'), isNotNull);
      expect(CompanyValidators.address('Pune'), isNotNull);
      expect(CompanyValidators.address('Plot 4, Pune'), isNull);
    });
  });

  test('auth error codes map to friendly messages', () {
    ApiException refused(int status, String code, [String? reason]) =>
        ApiException(status, code, reason, 'server text', const {});

    expect(
      HttpAuthRepository.messageFor(
        refused(401, 'unauthenticated', 'invalid_credentials'),
      ),
      'Incorrect email or password.',
    );
    expect(
      HttpAuthRepository.messageFor(
        refused(403, 'permission_denied', 'user_disabled'),
      ),
      'This account has been disabled. Contact your administrator.',
    );
    expect(
      HttpAuthRepository.messageFor(
        const ApiUnavailable('rate limited', statusCode: 429),
      ),
      'Too many attempts. Wait a few minutes and try again.',
    );
    expect(
      HttpAuthRepository.messageFor(const ApiUnavailable('offline')),
      'No internet connection. Connect and try again.',
    );
    expect(
      HttpAuthRepository.messageFor(refused(400, 'invalid_argument')),
      'That email address is not valid.',
    );
    expect(
      HttpAuthRepository.messageFor(
        const ApiUnavailable('boom', statusCode: 500),
      ),
      contains('try again'),
    );
    expect(
      HttpAuthRepository.messageFor(StateError('?')),
      contains('try again'),
    );
  });
}
