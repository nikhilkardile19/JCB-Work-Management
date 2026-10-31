import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/core/network/session_store.dart';
import 'package:jcb_work_management/features/auth/data/auth_repository.dart';
import 'package:jcb_work_management/features/auth/data/http_auth_repository.dart';
import 'package:jcb_work_management/features/company/domain/company.dart';

import '../helpers/fake_http.dart';

const owner = AppUser(uid: 'u1', email: 'owner@jcbworks.in');

void main() {
  late ApiHarness h;
  late HttpAuthRepository auth;

  void setUpWith(FakeHandler handler) {
    h = ApiHarness(handler: handler);
    auth = HttpAuthRepository(h.api, h.session);
  }

  test('emits the stored user at once, without the network', () async {
    setUpWith((r) => throw const Offline());
    h.storeSession();
    h.http.offline = true;
    expect(await auth.authStateChanges().first, owner);
    expect(h.http.requests, isEmpty);
  });

  test('emits null when nothing is stored or storage is unreadable', () async {
    setUpWith((r) => const FakeReply(500));
    expect(await auth.authStateChanges().first, isNull);

    setUpWith((r) => const FakeReply(500));
    h.storeSession();
    h.secrets.readFails = true;
    expect(await auth.authStateChanges().first, isNull);
  });

  test('checkEmail posts the trimmed email without a token', () async {
    setUpWith((r) => const FakeReply(204));
    await auth.checkEmail(' owner@jcbworks.in ');
    final request = h.http.requests.single;
    expect(request.path, '/auth/check-email');
    expect(request.bearer, isNull);
    expect(request.json, {'email': 'owner@jcbworks.in'});
  });

  test('checkEmail failures carry the reason and a useful message', () async {
    Future<AuthException> failureFor(FakeHandler handler) async {
      setUpWith(handler);
      try {
        await auth.checkEmail('a@b.co');
      } on AuthException catch (e) {
        return e;
      }
      fail('expected AuthException');
    }

    final none = await failureFor(
      (r) => FakeReply.error(404, 'not_found', reason: 'no_account'),
    );
    expect(none.reason, 'no_account');
    expect(none.message, contains('No JCB Works account'));
    expect(
      (await failureFor(
        (r) =>
            FakeReply.error(403, 'permission_denied', reason: 'user_disabled'),
      )).message,
      'This account has been disabled. Contact your administrator.',
    );
    expect(
      (await failureFor((r) => throw const Offline())).message,
      "Couldn't reach the server. Check your internet connection and try again.",
    );
  });

  group('signInWithCode', () {
    Map<String, Object?> codeLoginJson({
      Map<String, Object?>? license = const {
        'licenseId': 'lic1',
        'licenseStatus': 'active',
        'deviceStatus': 'active',
        'validUntil': 9,
        'maxDevices': 2,
        'serverTime': 1,
      },
      Map<String, Object?>? activation,
    }) => {
      ...sessionJson(),
      'refreshTokenExpiresAt': null,
      'companyId': 'co1',
      'license': license,
      'activation': activation,
    };

    Future<AppUser> signIn({Future<void> Function(CodeSignIn)? prepare}) =>
        auth.signInWithCode(
          email: ' owner@jcbworks.in ',
          activationCode: ' JCBW-AAAA-BBBB-CCCC ',
          deviceId: testDeviceId,
          deviceModel: 'android 14',
          prepare: prepare,
        );

    test('sends email, code and device; prepares before signing in', () async {
      setUpWith((r) => FakeReply(200, codeLoginJson()));
      final events = <AppUser?>[];
      final sub = auth.authStateChanges().listen(events.add);
      await pumpEventQueue();

      CodeSignIn? prepared;
      List<AppUser?>? eventsWhenPrepared;
      expect(
        await signIn(
          prepare: (r) async {
            prepared = r;
            eventsWhenPrepared = List.of(events);
          },
        ),
        owner,
      );
      await pumpEventQueue();

      final request = h.http.requests.single;
      expect(request.path, '/auth/login-with-code');
      expect(request.bearer, isNull);
      expect(request.json, {
        'email': 'owner@jcbworks.in',
        'activationCode': 'JCBW-AAAA-BBBB-CCCC',
        'deviceId': testDeviceId,
        'deviceModel': 'android 14',
        'platform': 'android',
      });
      expect(prepared?.user, owner);
      expect(prepared?.companyId, 'co1');
      expect(prepared?.license?['licenseStatus'], 'active');
      expect(prepared?.refusalReason, isNull);
      // The user was still signed out while preparing.
      expect(eventsWhenPrepared, [null]);
      expect(events, [null, owner]);
      expect(h.secrets.values['auth_session'], contains('r1'));
      await sub.cancel();
    });

    test('passes on a device-limit refusal with the session', () async {
      setUpWith(
        (r) => FakeReply(
          200,
          codeLoginJson(
            license: null,
            activation: {'reason': 'device_limit', 'message': 'All in use.'},
          ),
        ),
      );
      CodeSignIn? prepared;
      await signIn(prepare: (r) async => prepared = r);
      expect(prepared?.license, isNull);
      expect(prepared?.refusalReason, 'device_limit');
      expect(prepared?.refusalMessage, 'All in use.');
      expect(h.session.user, isNotNull);
    });

    test('failures sign nothing in and explain what happened', () async {
      Future<String> messageFor(FakeHandler handler) async {
        setUpWith(handler);
        try {
          await signIn(prepare: (_) async => fail('must not prepare'));
        } on AuthException catch (e) {
          expect(h.secrets.values, isEmpty);
          return e.message;
        }
        fail('expected AuthException');
      }

      expect(
        await messageFor(
          (r) =>
              FakeReply.error(401, 'unauthenticated', reason: 'invalid_code'),
        ),
        'That activation code is not valid for this email address.',
      );
      // Activation refusals use the server's wording.
      expect(
        await messageFor(
          (r) => FakeReply.error(
            409,
            'failed_precondition',
            reason: 'code_used',
            message: 'This activation code has already been used.',
          ),
        ),
        'This activation code has already been used.',
      );
      expect(
        await messageFor(
          (r) => FakeReply.error(
            429,
            'resource_exhausted',
            reason: 'rate_limited',
            message:
                'Too many wrong activation codes. Wait an hour and try again.',
          ),
        ),
        'Too many wrong activation codes. Wait an hour and try again.',
      );
      expect(
        await messageFor((r) => throw const Offline()),
        "Couldn't reach the server. Check your internet connection and try again.",
      );
      expect(
        await messageFor((r) => const FakeReply(200, {'unexpected': true})),
        'Something went wrong. Please try again.',
      );
    });
  });

  test('mobile sessions without an end date are accepted', () {
    final session = AuthSession.fromJson({
      ...sessionJson(),
      'refreshTokenExpiresAt': null,
    });
    expect(session.refreshTokenExpiresAt, isNull);
    expect(session.refreshToken, 'r1');
  });

  group('signUp', () {
    const profile = CompanyProfile(
      name: 'Sai Earthmovers',
      contactPerson: 'Ravi Patil',
      phone: '9876543210',
      address: 'Plot 4, MIDC Bhosari, Pune',
      invoicePrefix: 'SAI',
    );

    Future<void> signUp() =>
        auth.signUp(email: ' new@saiearth.in ', profile: profile);

    test('creates the account and company without signing in', () async {
      setUpWith(
        (r) => const FakeReply(201, {'userId': 'u9', 'companyId': 'c9'}),
      );
      await signUp();
      final request = h.http.requests.single;
      expect(request.path, '/auth/signup');
      expect(request.bearer, isNull);
      expect(request.json, {
        'email': 'new@saiearth.in',
        'company': {
          'name': 'Sai Earthmovers',
          'contactPerson': 'Ravi Patil',
          'phone': '9876543210',
          'address': 'Plot 4, MIDC Bhosari, Pune',
          'invoicePrefix': 'SAI',
          'email': null,
          'gstin': null,
        },
      });
      expect(h.secrets.values, isEmpty);
      expect(await auth.authStateChanges().first, isNull);
    });

    test('failures are AuthExceptions with a useful message', () async {
      Future<String> messageFor(FakeHandler handler) async {
        setUpWith(handler);
        try {
          await signUp();
        } on AuthException catch (e) {
          return e.message;
        }
        fail('expected AuthException');
      }

      expect(
        await messageFor(
          (r) => FakeReply.error(409, 'already_exists', reason: 'email_taken'),
        ),
        'An account with this email already exists. Sign in with your email and activation code.',
      );
      expect(
        await messageFor((r) => FakeReply.error(400, 'invalid_argument')),
        contains('Check them'),
      );
      expect(
        await messageFor((r) => throw const Offline()),
        "Couldn't reach the server. Check your internet connection and try again.",
      );
    });
  });

  test(
    'signOut works offline: local state is cleared and null emitted',
    () async {
      setUpWith((r) => throw const Offline());
      h.storeSession();
      final events = <AppUser?>[];
      final sub = auth.authStateChanges().listen(events.add);
      await pumpEventQueue();

      await auth.signOut();
      await pumpEventQueue();

      expect(events, [owner, null]);
      expect(h.secrets.values, isEmpty);
      expect(await auth.authStateChanges().first, isNull);
      await sub.cancel();
    },
  );

  test('signOut revokes the session on the server when reachable', () async {
    setUpWith((r) => const FakeReply(204));
    await h.signIn();
    await auth.signOut();
    final logout = h.http.requests.single;
    expect(logout.path, '/auth/logout');
    expect(logout.json, {'refreshToken': 'r1'});
    expect(logout.bearer, 'a1');
    expect(h.session.user, isNull);
  });

  test('signOut after a restart gets a token to revoke the session', () async {
    setUpWith(
      (r) => switch (r.path) {
        '/auth/refresh' => FakeReply(
          200,
          sessionJson(access: 'a2', refresh: 'r2'),
        ),
        _ when r.bearer == null => FakeReply.error(401, 'unauthenticated'),
        _ => const FakeReply(204),
      },
    );
    h.storeSession();
    await auth.signOut();
    expect(h.http.requests.map((r) => '$r ${r.bearer}'), [
      'POST /auth/logout null',
      'POST /auth/refresh null',
      'POST /auth/logout a2',
    ]);
    expect(h.http.requests.last.json, {'refreshToken': 'r2'});
    expect(h.secrets.values, isEmpty, reason: 'rotated tokens not stored');
  });
}
