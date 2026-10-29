import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/auth/application/auth_providers.dart';

void main() {
  group('AuthValidators.email', () {
    test('rejects empty and malformed', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('   '), isNotNull);
      expect(AuthValidators.email('owner'), isNotNull);
      expect(AuthValidators.email('owner@site'), isNotNull);
      expect(AuthValidators.email('a b@site.com'), isNotNull);
    });

    test('accepts valid, ignoring surrounding spaces', () {
      expect(AuthValidators.email('owner@jcbworks.in'), isNull);
      expect(AuthValidators.email('  owner@jcbworks.in '), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('enforces minimum length', () {
      expect(AuthValidators.password(''), 'Enter your password');
      expect(AuthValidators.password('12345'), contains('at least 6'));
      expect(AuthValidators.password('123456'), isNull);
      expect(AuthValidators.password('1234567', minLength: 8), isNotNull);
    });
  });
}
