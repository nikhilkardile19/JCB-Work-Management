import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/core/network/api_exception.dart';
import 'package:jcb_work_management/core/network/session_store.dart';

import '../helpers/fake_http.dart';

void main() {
  test(
    'sends the device ID on every request, the token when signed in',
    () async {
      final h = ApiHarness(handler: (r) => const FakeReply(200, {'ok': true}));
      await h.api.post('/auth/login', body: {}, authenticated: false);
      await h.signIn();
      expect(await h.api.get('/me/memberships'), {'ok': true});

      final [login, me] = h.http.requests;
      expect(login.headers['x-device-id'], testDeviceId);
      expect(login.headers.containsKey('authorization'), isFalse);
      expect(me.headers['x-device-id'], testDeviceId);
      expect(me.headers['authorization'], 'Bearer a1');
    },
  );

  test('a 204 is an empty object', () async {
    final h = ApiHarness(handler: (r) => const FakeReply(204));
    expect(
      await h.api.post('/auth/forgot-password', authenticated: false),
      isEmpty,
    );
  });

  test('maps the error envelope to ApiException', () async {
    final h = ApiHarness(
      handler: (r) => FakeReply.error(
        409,
        'failed_precondition',
        message: 'License expired.',
        reason: 'expired',
      ),
    );
    await h.signIn();
    await expectLater(
      h.api.post('/x'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.code, 'code', 'failed_precondition')
            .having((e) => e.reason, 'reason', 'expired')
            .having((e) => e.message, 'message', 'License expired.')
            .having(
              (e) => e.body['error'],
              'body',
              isA<Map<String, dynamic>>(),
            ),
      ),
    );
  });

  group('unavailable', () {
    Future<ApiUnavailable> failure(ApiHarness h) async {
      try {
        await h.api.post('/x', authenticated: false);
      } on ApiUnavailable catch (e) {
        return e;
      }
      fail('expected ApiUnavailable');
    }

    test('no connection', () async {
      final h = ApiHarness()..http.offline = true;
      expect((await failure(h)).statusCode, isNull);
    });

    test('5xx and 429 (with the server hint)', () async {
      final h = ApiHarness(handler: (r) => FakeReply.error(500, 'internal'));
      expect((await failure(h)).statusCode, 500);
      h.http.handler = (r) => FakeReply.error(
        429,
        'resource_exhausted',
        message: 'Slow down.',
        reason: 'rate_limited',
        extra: {},
      );
      final e = await failure(h);
      expect(e.isRateLimited, isTrue);
      expect(e.message, 'Slow down.');
    });

    test('replies that are not from the API (proxy, captive portal)', () async {
      final h = ApiHarness(handler: (r) => const FakeReply(404, '<html>'));
      expect((await failure(h)).statusCode, 404);
      h.http.handler = (r) => const FakeReply(200, '<html>Log in to Wi-Fi');
      expect((await failure(h)).statusCode, 200);
    });

    test('timeouts', () async {
      final h = ApiHarness(handler: (r) => throw const TimedOut());
      final e = await failure(h);
      expect(e.statusCode, isNull);
      expect(e.message, contains('too long'));
    });
  });

  group('token refresh', () {
    test('concurrent 401s share one refresh, store the rotated tokens and retry once', () async {
      final refreshed = Completer<void>();
      final h = ApiHarness(
        handler: (r) async {
          if (r.path == '/auth/refresh') {
            await refreshed.future;
            expect(r.json, {'refreshToken': 'r1'});
            return FakeReply(200, sessionJson(access: 'a2', refresh: 'r2'));
          }
          return r.bearer == 'a2'
              ? FakeReply(200, {'path': r.path})
              : FakeReply.error(401, 'unauthenticated');
        },
      );
      await h.signIn();

      final results = Future.wait([
        for (final p in ['/a', '/b', '/c']) h.api.get(p),
      ]);
      await pumpEventQueue();
      refreshed.complete();

      expect(await results, [
        {'path': '/a'},
        {'path': '/b'},
        {'path': '/c'},
      ]);
      expect(h.http.to('POST', '/auth/refresh'), hasLength(1));
      for (final p in ['/a', '/b', '/c']) {
        expect(h.http.to('GET', p).map((r) => r.bearer), ['a1', 'a2']);
      }
      expect(h.session.accessToken, 'a2');
      final stored = jsonDecode(h.secrets.values['auth_session']!) as Map;
      expect(stored['refreshToken'], 'r2');
      expect(stored.containsKey('accessToken'), isFalse);
    });

    test(
      'a request still refused after the refresh is not retried again',
      () async {
        final h = ApiHarness(
          handler: (r) => r.path == '/auth/refresh'
              ? FakeReply(200, sessionJson(access: 'a2', refresh: 'r2'))
              : FakeReply.error(401, 'unauthenticated'),
        );
        await h.signIn();
        await expectLater(
          h.api.get('/a'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 401),
          ),
        );
        expect(h.http.to('GET', '/a'), hasLength(2));
        expect(h.http.to('POST', '/auth/refresh'), hasLength(1));
        expect(h.session.user, testUser, reason: 'still signed in');
      },
    );

    test(
      'after a restart the first request gets an access token first',
      () async {
        final h = ApiHarness(
          handler: (r) => r.path == '/auth/refresh'
              ? FakeReply(200, sessionJson(access: 'a2', refresh: 'r2'))
              : const FakeReply(200, {}),
        )..storeSession();
        await h.api.get('/me/memberships');
        expect(h.http.requests.map((r) => '$r ${r.bearer}'), [
          'POST /auth/refresh null',
          'GET /me/memberships a2',
        ]);
      },
    );

    test(
      'a refused refresh token signs out and the auth stream emits null',
      () async {
        final h = ApiHarness(
          handler: (r) => r.path == '/auth/refresh'
              ? FakeReply.error(
                  401,
                  'unauthenticated',
                  reason: 'invalid_refresh_token',
                )
              : FakeReply.error(401, 'unauthenticated'),
        );
        await h.signIn();
        final users = <SessionUser?>[];
        final sub = h.session.userChanges().listen(users.add);
        await pumpEventQueue();

        await expectLater(
          Future.wait([h.api.get('/a'), h.api.get('/b')]),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 401),
          ),
        );
        await pumpEventQueue();

        expect(users, [testUser, null]);
        expect(h.session.refreshToken, isNull);
        expect(h.secrets.values, isEmpty);
        expect(h.http.to('POST', '/auth/refresh'), hasLength(1));
        await sub.cancel();
      },
    );

    test('a disabled user is signed out too', () async {
      final h = ApiHarness(
        handler: (r) => r.path == '/auth/refresh'
            ? FakeReply.error(403, 'permission_denied', reason: 'user_disabled')
            : FakeReply.error(401, 'unauthenticated'),
      );
      await h.signIn();
      await expectLater(h.api.get('/a'), throwsA(isA<ApiException>()));
      expect(h.session.user, isNull);
    });

    test('a refresh that cannot reach the server keeps the session', () async {
      final h = ApiHarness(
        handler: (r) => r.path == '/auth/refresh'
            ? throw const Offline()
            : FakeReply.error(401, 'unauthenticated'),
      );
      await h.signIn();
      await expectLater(h.api.get('/a'), throwsA(isA<ApiUnavailable>()));
      // Not from the API (no envelope): not a reason to sign out either.
      h.http.handler = (r) => const FakeReply(401, '<html>');
      await expectLater(h.api.get('/a'), throwsA(isA<ApiUnavailable>()));
      // Any other refusal of the refresh: retry later, don't refuse the
      // original request (a sync push would mark its record as an error).
      h.http.handler = (r) => r.path == '/auth/refresh'
          ? FakeReply.error(400, 'invalid_argument')
          : FakeReply.error(401, 'unauthenticated');
      await expectLater(h.api.get('/a'), throwsA(isA<ApiUnavailable>()));
      expect(h.session.user, testUser);
      expect(h.secrets.values, isNotEmpty);
    });

    test('signing out during a refresh is not undone by its result', () async {
      final refreshed = Completer<void>();
      final h = ApiHarness(
        handler: (r) async {
          if (r.path == '/auth/refresh') {
            await refreshed.future;
            return FakeReply(200, sessionJson(access: 'a2', refresh: 'r2'));
          }
          return FakeReply.error(401, 'unauthenticated');
        },
      );
      await h.signIn();
      final request = h.api.get('/a');
      await pumpEventQueue();
      await h.session.clear();
      refreshed.complete();
      await expectLater(request, throwsA(isA<ApiException>()));
      expect(h.session.user, isNull);
      expect(h.secrets.values, isEmpty);
    });

    test('requests while signed out fail without a network call', () async {
      final h = ApiHarness();
      await expectLater(
        h.api.get('/a'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
      expect(h.http.requests, isEmpty);
    });
  });
}
