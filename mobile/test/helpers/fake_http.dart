import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:jcb_work_management/core/network/api_client.dart';
import 'package:jcb_work_management/core/network/session_store.dart';

const testBaseUrl = 'http://api.test/api/v1';
const testDeviceId = 'device-1';

/// In-memory [SecretStore]; [readFails] simulates a broken keystore.
class MemorySecretStore implements SecretStore {
  final values = <String, String>{};
  bool readFails = false;

  @override
  Future<String?> read(String key) async {
    if (readFails) throw StateError('keystore unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// One request as the server saw it.
class FakeRequest {
  FakeRequest(this.method, this.path, this.query, this.headers, this.body);

  final String method;

  /// Path below the API root, e.g. `/auth/login`.
  final String path;
  final Map<String, String> query;

  /// Lower-cased header names.
  final Map<String, String> headers;
  final Object? body;

  Map<String, dynamic> get json => body! as Map<String, dynamic>;

  String? get bearer => headers['authorization']?.replaceFirst('Bearer ', '');

  @override
  String toString() => '$method $path';
}

class FakeReply {
  const FakeReply(this.status, [this.body]);

  /// The API's error envelope.
  factory FakeReply.error(
    int status,
    String code, {
    String message = 'Refused by the server.',
    String? reason,
    Map<String, Object?> extra = const {},
  }) => FakeReply(status, {
    'error': {'code': code, 'message': message, 'reason': ?reason},
    ...extra,
  });

  final int status;

  /// Encoded as JSON unless it is a [String] (sent as text/html).
  final Object? body;
}

/// Thrown by a handler to simulate an unreachable server.
class Offline implements Exception {
  const Offline();
}

/// Thrown by a handler to simulate a server that stops answering (what the
/// real adapter reports when the receive timeout expires).
class TimedOut implements Exception {
  const TimedOut();
}

typedef FakeHandler = FutureOr<FakeReply> Function(FakeRequest request);

/// Dio adapter that answers from [handler] instead of the network.
class FakeHttp implements HttpClientAdapter {
  FakeHttp([FakeHandler? handler])
    : handler = handler ?? ((_) => const FakeReply(404));

  FakeHandler handler;
  final requests = <FakeRequest>[];

  /// Every request fails as if there were no connection.
  bool offline = false;

  Iterable<FakeRequest> to(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? const <int>[]
        : await requestStream.expand((b) => b).toList();
    final text = utf8.decode(bytes);
    final request = FakeRequest(
      options.method,
      options.uri.path.replaceFirst(Uri.parse(testBaseUrl).path, ''),
      options.uri.queryParameters,
      {
        for (final e in options.headers.entries)
          e.key.toLowerCase(): '${e.value}',
      },
      text.isEmpty ? null : jsonDecode(text),
    );
    requests.add(request);
    FakeReply reply;
    try {
      if (offline) throw const Offline();
      reply = await handler(request);
    } on Offline {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    } on TimedOut {
      throw DioException.receiveTimeout(
        timeout: options.receiveTimeout ?? Duration.zero,
        requestOptions: options,
      );
    }
    final body = reply.body;
    if (body is String) {
      return ResponseBody.fromString(
        body,
        reply.status,
        headers: {
          Headers.contentTypeHeader: ['text/html'],
        },
      );
    }
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Reads a stream's events (values and errors) one at a time, in order.
class StreamEvents<T> {
  StreamEvents(Stream<T> stream) {
    _sub = stream.listen(
      (v) => _push(Future.value(v)),
      onError: (Object e, StackTrace s) {
        errors.add(e);
        _push(Future.error(e, s));
      },
    );
  }

  late final StreamSubscription<T> _sub;
  final _ready = <Future<T>>[];
  final _waiting = <Completer<T>>[];

  /// Every error so far, read or not.
  final errors = <Object>[];

  void _push(Future<T> event) {
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete(event);
    } else {
      _ready.add(event..ignore());
    }
  }

  Future<T> get next {
    if (_ready.isNotEmpty) return _ready.removeAt(0);
    final c = Completer<T>();
    _waiting.add(c);
    return c.future;
  }

  Future<void> cancel() => _sub.cancel();
}

const testUser = SessionUser(id: 'u1', email: 'owner@jcbworks.in');

/// A `Session` body as `/auth/login` and `/auth/refresh` return it.
Map<String, Object?> sessionJson({
  String access = 'a1',
  String refresh = 'r1',
  SessionUser user = testUser,
}) => {
  'accessToken': access,
  'accessTokenExpiresAt': 1,
  'refreshToken': refresh,
  'refreshTokenExpiresAt': 2,
  'user': user.toJson(),
};

/// An [ApiClient] wired to a [FakeHttp] and in-memory secrets.
class ApiHarness {
  ApiHarness({FakeHandler? handler})
    : http = FakeHttp(handler),
      secrets = MemorySecretStore() {
    session = SessionStore(secrets);
    api = ApiClient(
      baseUrl: testBaseUrl,
      session: session,
      deviceId: () async => testDeviceId,
      adapter: http,
    );
  }

  final FakeHttp http;
  final MemorySecretStore secrets;
  late final SessionStore session;
  late final ApiClient api;

  /// Signed in, with access token [access] in memory.
  Future<void> signIn({String access = 'a1', String refresh = 'r1'}) =>
      session.save(
        AuthSession.fromJson(sessionJson(access: access, refresh: refresh)),
      );

  /// As after an app restart: only the stored refresh token and user.
  void storeSession({String refresh = 'r1', SessionUser user = testUser}) =>
      secrets.values['auth_session'] = jsonEncode({
        'refreshToken': refresh,
        'refreshTokenExpiresAt': 2,
        'user': user.toJson(),
      });
}
