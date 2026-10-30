import 'dart:async';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'session_store.dart';

typedef Json = Map<String, dynamic>;

/// `/a/b/c` from raw segments, each percent-encoded (IDs are opaque).
String apiPath(List<String> segments) =>
    '/${segments.map(Uri.encodeComponent).join('/')}';

/// HTTP access to the REST API (`docs/migration/api-contract.md`).
///
/// Every request carries `X-Device-Id`; authenticated ones also carry the
/// access token. A 401 triggers one token refresh, shared by all requests
/// that hit it at the same time, and the request is retried once. When the
/// server rejects the refresh token itself the session is cleared, which
/// signs the user out.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this._session,
    required this._deviceId,
    HttpClientAdapter? adapter,
    Duration timeout = const Duration(seconds: 20),
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: timeout,
           sendTimeout: timeout,
           receiveTimeout: timeout,
           contentType: Headers.jsonContentType,
           responseType: ResponseType.json,
           // Status codes are mapped below, not thrown by Dio.
           validateStatus: (_) => true,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  final Dio _dio;
  final SessionStore _session;
  final Future<String> Function() _deviceId;
  String? _device;
  Future<bool>? _refreshing;

  static const _unexpected = 'The server sent an unexpected response.';
  static const _signedOut = ApiException(
    401,
    'unauthenticated',
    null,
    'Your session has ended. Sign in again.',
    {},
  );

  /// The signed-in user's ID, or null when signed out.
  String? get currentUserId => _session.user?.id;

  Future<Json> get(String path, {Map<String, Object?>? query}) =>
      send('GET', path, query: query);

  Future<Json> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) => send(
    'POST',
    path,
    body: body,
    headers: headers,
    authenticated: authenticated,
  );

  Future<Json> put(String path, {Object? body, Map<String, String>? headers}) =>
      send('PUT', path, body: body, headers: headers);

  Future<Json> patch(String path, {Object? body}) =>
      send('PATCH', path, body: body);

  /// Sends one request and returns the decoded JSON object (empty for a
  /// 204). Throws [ApiException] when the API refuses it and
  /// [ApiUnavailable] when it can't be served now.
  Future<Json> send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    if (!authenticated) {
      return _decode(
        await _fetch(method, path, body: body, query: query, headers: headers),
      );
    }
    await _session.load();
    final userId = currentUserId;
    if (userId == null) throw _signedOut;
    var token = _session.accessToken;
    if (token == null) {
      // After a restart only the refresh token is known.
      await _refresh(null, userId);
      token = _session.accessToken;
    }
    var response = await _fetch(
      method,
      path,
      body: body,
      query: query,
      headers: headers,
      token: token,
    );
    if (response.statusCode == 401) {
      await _refresh(token, userId);
      response = await _fetch(
        method,
        path,
        body: body,
        query: query,
        headers: headers,
        token: _session.accessToken,
      );
    }
    return _decode(response);
  }

  /// Makes sure the access token is newer than [rejected], refreshing it
  /// once for everyone waiting. Throws [ApiException] (401) when the session
  /// is gone or now belongs to someone else.
  Future<void> _refresh(String? rejected, String userId) async {
    final current = _session.accessToken;
    if (current == null || current == rejected) {
      final ok = await (_refreshing ??= _rotate().whenComplete(
        () => _refreshing = null,
      ));
      if (!ok) throw _signedOut;
    }
    if (currentUserId != userId || _session.accessToken == null) {
      throw _signedOut;
    }
  }

  Future<bool> _rotate() async {
    final refreshToken = _session.refreshToken;
    if (refreshToken == null) return false;
    final session = await _exchange(refreshToken);
    if (session == null) {
      await _session.clear(onlyIf: refreshToken);
      return false;
    }
    return _session.rotate(refreshToken, session);
  }

  /// `POST /auth/refresh`. Null when the server refuses the token (expired,
  /// revoked, user disabled); otherwise throws [ApiUnavailable], so a failed
  /// refresh never reads as a refusal of the original request.
  Future<AuthSession?> _exchange(String refreshToken) async {
    final response = await _fetch(
      'POST',
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    try {
      return AuthSession.fromJson(_decode(response));
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.reason == 'user_disabled') return null;
      throw ApiUnavailable(e.message, statusCode: e.statusCode);
    } on TypeError {
      throw ApiUnavailable(_unexpected, statusCode: response.statusCode);
    }
  }

  /// Best-effort `POST /auth/logout` for a session already removed from
  /// this phone. Never throws.
  Future<void> logout({
    required String? accessToken,
    required String refreshToken,
  }) async {
    try {
      final r = await _fetch(
        'POST',
        '/auth/logout',
        body: {'refreshToken': refreshToken},
        token: accessToken,
      );
      if (r.statusCode != 401) return;
      // No valid access token (e.g. right after a restart): get one with
      // the refresh token, then revoke the rotated session.
      final fresh = await _exchange(refreshToken);
      if (fresh == null) return;
      await _fetch(
        'POST',
        '/auth/logout',
        body: {'refreshToken': fresh.refreshToken},
        token: fresh.accessToken,
      );
    } on Exception {
      // Offline or refused: the tokens are gone from this phone anyway.
    }
  }

  Future<Response<Object?>> _fetch(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    String? token,
  }) async {
    try {
      final device = _device ??= await _deviceId();
      return await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            'Accept': 'application/json',
            'X-Device-Id': device,
            if (token != null) 'Authorization': 'Bearer $token',
            ...?headers,
          },
        ),
      );
    } on DioException catch (e) {
      throw switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => const ApiUnavailable(
          'The server took too long to respond.',
        ),
        // A body that claims to be JSON but isn't.
        _ when e.error is FormatException => const ApiUnavailable(_unexpected),
        _ => const ApiUnavailable('Could not reach the server.'),
      };
    }
  }

  static Json _decode(Response<Object?> response) {
    final status = response.statusCode ?? 0;
    final data = response.data;
    if (status >= 200 && status < 300) {
      if (data is Json) return data;
      if (data == null || data == '') return {};
      throw ApiUnavailable(_unexpected, statusCode: status);
    }
    final error = data is Json ? data['error'] : null;
    final envelope = error is Json && error['code'] is String ? error : null;
    final message = switch (envelope?['message']) {
      final String m when m.trim().isNotEmpty => m,
      _ => null,
    };
    if (status == 429 || status >= 500) {
      final retryMs = envelope?['retryAfterMs'];
      throw ApiUnavailable(
        message ??
            (status == 429
                ? 'Too many requests. Wait a little and try again.'
                : 'The server had a problem. Try again later.'),
        statusCode: status,
        retryAfter: retryMs is num
            ? Duration(milliseconds: retryMs.toInt())
            : null,
      );
    }
    // Only replies that carry the API's error envelope are refusals; other
    // 3xx/4xx come from something in between (proxy, captive portal).
    if (status >= 400 && envelope != null) {
      final reason = envelope['reason'];
      throw ApiException(
        status,
        envelope['code'] as String,
        reason is String ? reason : null,
        message ?? 'The server refused the request.',
        data as Json,
      );
    }
    throw ApiUnavailable(_unexpected, statusCode: status);
  }

  void close() => _dio.close(force: true);
}
