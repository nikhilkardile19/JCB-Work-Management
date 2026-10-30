import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/auth/data/auth_repository.dart';
import 'package:jcb_work_management/features/auth/data/http_auth_repository.dart';

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

  test(
    'signIn sends client "mobile", stores the session, emits the user',
    () async {
      setUpWith((r) => FakeReply(200, sessionJson()));
      final events = <AppUser?>[];
      final sub = auth.authStateChanges().listen(events.add);
      await pumpEventQueue();

      expect(
        await auth.signIn(email: ' owner@jcbworks.in ', password: 'secret1'),
        owner,
      );
      await pumpEventQueue();

      expect(h.http.requests.single.path, '/auth/login');
      expect(h.http.requests.single.json, {
        'email': 'owner@jcbworks.in',
        'password': 'secret1',
        'client': 'mobile',
      });
      expect(events, [null, owner]);
      expect(h.secrets.values['auth_session'], contains('r1'));
      expect(h.secrets.values['auth_session'], isNot(contains('a1')));
      await sub.cancel();
    },
  );

  test('signIn failures keep the existing messages', () async {
    Future<String> messageFor(FakeHandler handler) async {
      setUpWith(handler);
      try {
        await auth.signIn(email: 'a@b.co', password: 'x');
      } on AuthException catch (e) {
        return e.message;
      }
      fail('expected AuthException');
    }

    expect(
      await messageFor(
        (r) => FakeReply.error(
          401,
          'unauthenticated',
          reason: 'invalid_credentials',
        ),
      ),
      'Incorrect email or password.',
    );
    expect(
      await messageFor(
        (r) =>
            FakeReply.error(403, 'permission_denied', reason: 'user_disabled'),
      ),
      'This account has been disabled. Contact your administrator.',
    );
    expect(
      await messageFor(
        (r) =>
            FakeReply.error(429, 'resource_exhausted', reason: 'rate_limited'),
      ),
      'Too many attempts. Wait a few minutes and try again.',
    );
    expect(
      await messageFor((r) => throw const Offline()),
      'No internet connection. Connect and try again.',
    );
    expect(
      await messageFor((r) => const FakeReply(200, {'unexpected': true})),
      'Something went wrong. Please try again.',
    );
  });

  test(
    'sendPasswordReset posts the email; failures are AuthExceptions',
    () async {
      setUpWith((r) => const FakeReply(204));
      await auth.sendPasswordReset(' owner@jcbworks.in ');
      expect(h.http.requests.single.path, '/auth/forgot-password');
      expect(h.http.requests.single.json, {'email': 'owner@jcbworks.in'});

      h.http.offline = true;
      await expectLater(
        auth.sendPasswordReset('owner@jcbworks.in'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('internet'),
          ),
        ),
      );
    },
  );

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
