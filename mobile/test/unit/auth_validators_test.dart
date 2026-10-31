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

  group('AuthValidators.activationCode', () {
    test('rejects empty and incomplete codes', () {
      expect(AuthValidators.activationCode(''), 'Enter your activation code');
      expect(
        AuthValidators.activationCode('JCBW-7KQ2-M9XD'),
        contains('full code'),
      );
      expect(
        AuthValidators.activationCode('7KQ2M9XDPA4HX'),
        contains('full code'),
      );
    });

    test('accepts any case, spacing and with or without the prefix', () {
      expect(AuthValidators.activationCode('JCBW-7KQ2-M9XD-PA4H'), isNull);
      expect(AuthValidators.activationCode(' jcbw 7kq2 m9xd pa4h '), isNull);
      expect(AuthValidators.activationCode('7KQ2-M9XD-PA4H'), isNull);
    });
  });
}
