import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The signed-in user as the server identifies them.
class SessionUser {
  const SessionUser({required this.id, required this.email});

  factory SessionUser.fromJson(Map<String, dynamic> j) =>
      SessionUser(id: j['id'] as String, email: j['email'] as String? ?? '');

  final String id;
  final String email;

  Map<String, Object?> toJson() => {'id': id, 'email': email};

  @override
  bool operator ==(Object other) =>
      other is SessionUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

/// Tokens from `/auth/login` and `/auth/refresh`. Times are UTC epoch ms.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
    accessToken: j['accessToken'] as String,
    accessTokenExpiresAt: (j['accessTokenExpiresAt'] as num).toInt(),
    refreshToken: j['refreshToken'] as String,
    refreshTokenExpiresAt: (j['refreshTokenExpiresAt'] as num).toInt(),
    user: SessionUser.fromJson(j['user'] as Map<String, dynamic>),
  );

  final String accessToken;
  final int accessTokenExpiresAt;
  final String refreshToken;
  final int refreshTokenExpiresAt;
  final SessionUser user;
}

/// Small key-value store for secrets, so tests can swap in memory.
abstract interface class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Android Keystore-backed storage. Backups exclude it
/// (`data_extraction_rules.xml`), so it never moves to another phone.
class SecureSecretStore implements SecretStore {
  const SecureSecretStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// The signed-in session. The refresh token and user survive restarts in
/// a [SecretStore]; the short-lived access token is kept in memory only, so
/// the first request after a restart refreshes it.
class SessionStore {
  SessionStore(this._secrets);

  static const _key = 'auth_session';

  final SecretStore _secrets;
  final _changes = StreamController<SessionUser?>.broadcast();
  Future<void>? _loaded;
  Future<void> _queue = Future.value();

  SessionUser? _user;
  String? _accessToken;
  String? _refreshToken;

  SessionUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// Reads the stored session once; later calls complete immediately.
  Future<void> load() => _loaded ??= _read();

  Future<void> _read() async {
    try {
      final raw = await _secrets.read(_key);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _refreshToken = j['refreshToken'] as String;
      _user = SessionUser.fromJson(j['user'] as Map<String, dynamic>);
    } catch (_) {
      // Unreadable: signed out for now. A new sign-in overwrites it.
      _refreshToken = null;
      _user = null;
    }
  }

  /// The stored user right away (no network needed), then every change.
  Stream<SessionUser?> userChanges() async* {
    await load();
    yield _user;
    yield* _changes.stream;
  }

  /// Runs storage changes one at a time, so a token rotation that finishes
  /// late can't bring back a session that was signed out meanwhile.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Stores a new session after sign-in.
  Future<void> save(AuthSession session) => _serial(() async {
    await load();
    await _persist(session);
    _apply(session);
  });

  /// Stores tokens rotated from [previousRefreshToken]. Returns false, and
  /// stores nothing, when the session changed meanwhile (signed out, or
  /// another sign-in).
  Future<bool> rotate(String previousRefreshToken, AuthSession session) =>
      _serial(() async {
        await load();
        if (_refreshToken != previousRefreshToken) return false;
        await _persist(session);
        _apply(session);
        return true;
      });

  /// Signs out on this phone. With [onlyIf], only when that refresh token is
  /// still the current one.
  Future<void> clear({String? onlyIf}) => _serial(() async {
    await load();
    if (onlyIf != null && _refreshToken != onlyIf) return;
    final hadUser = _user != null;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    if (hadUser) _changes.add(null);
    await _secrets.delete(_key);
  });

  Future<void> _persist(AuthSession s) => _secrets.write(
    _key,
    jsonEncode({
      'refreshToken': s.refreshToken,
      'refreshTokenExpiresAt': s.refreshTokenExpiresAt,
      'user': s.user.toJson(),
    }),
  );

  void _apply(AuthSession s) {
    final changed = _user != s.user;
    _user = s.user;
    _accessToken = s.accessToken;
    _refreshToken = s.refreshToken;
    if (changed) _changes.add(_user);
  }

  Future<void> dispose() => _changes.close();
}
