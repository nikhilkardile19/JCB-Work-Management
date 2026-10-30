import 'dart:async';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class CompanyMember {
  const CompanyMember({
    required this.uid,
    required this.email,
    required this.role,
    required this.active,
  });

  final String uid;
  final String email;

  /// owner, admin, manager, operator or accounts.
  final String role;
  final bool active;
}

class CompanyUsersException implements Exception {
  const CompanyUsersException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Company user administration (owner/admin). Every change goes through the
/// server, which re-checks the caller.
abstract interface class CompanyUsersService {
  /// The company's members, sorted by email, kept up to date while listened
  /// to.
  Stream<List<CompanyMember>> watch(String companyId);

  Future<void> invite({
    required String companyId,
    required String email,
    required String role,
  });

  Future<void> setRole({
    required String companyId,
    required String userId,
    required String role,
  });

  Future<void> setActive({
    required String companyId,
    required String userId,
    required bool active,
  });
}

/// `/companies/:companyId/members`. The server has no push channel, so
/// [watch] polls: at once, after every change made through this service,
/// and every [refreshInterval] while listened to.
class HttpCompanyUsersService implements CompanyUsersService {
  HttpCompanyUsersService(
    this._api, {
    this.refreshInterval = const Duration(seconds: 30),
  });

  final ApiClient _api;
  final Duration refreshInterval;

  /// Company IDs changed through this instance.
  final _changed = StreamController<String>.broadcast();

  static const _unreachable =
      'Could not reach the server. Connect to the internet and try again.';

  static CompanyUsersException _failure(Object e) =>
      CompanyUsersException(switch (e) {
        ApiUnavailable(isRateLimited: true) => e.message,
        ApiException(:final message) => message,
        _ => _unreachable,
      });

  Future<List<CompanyMember>> _fetch(String companyId) async {
    try {
      final json = await _api.get(apiPath(['companies', companyId, 'members']));
      return [
        for (final m in (json['items'] as List).cast<Json>())
          CompanyMember(
            uid: m['uid'] as String,
            email: m['email'] as String? ?? '',
            role: m['role'] as String? ?? 'operator',
            active: m['status'] == 'active',
          ),
      ]..sort((a, b) => a.email.compareTo(b.email));
    } catch (e) {
      throw _failure(e);
    }
  }

  @override
  Stream<List<CompanyMember>> watch(String companyId) {
    late final StreamController<List<CompanyMember>> out;
    Timer? timer;
    StreamSubscription<String>? changes;
    var listening = true, busy = false, again = false, loaded = false;

    Future<void> load() async {
      if (busy) {
        // A change landed during this fetch; read again after it.
        again = true;
        return;
      }
      busy = true;
      try {
        do {
          again = false;
          try {
            final members = await _fetch(companyId);
            if (!listening) return;
            loaded = true;
            out.add(members);
          } catch (e, st) {
            // Once a list is shown, keep it and try again on the next tick.
            if (listening && !loaded) out.addError(e, st);
          }
        } while (again && listening);
      } finally {
        busy = false;
      }
    }

    out = StreamController<List<CompanyMember>>(
      onListen: () {
        changes = _changed.stream
            .where((id) => id == companyId)
            .listen((_) => unawaited(load()));
        timer = Timer.periodic(refreshInterval, (_) => unawaited(load()));
        unawaited(load());
      },
      onCancel: () {
        listening = false;
        timer?.cancel();
        return changes?.cancel();
      },
    );
    return out.stream;
  }

  Future<void> _change(
    String companyId,
    Future<Object?> Function() request,
  ) async {
    try {
      await request();
    } catch (e) {
      throw _failure(e);
    }
    _changed.add(companyId);
  }

  @override
  Future<void> invite({
    required String companyId,
    required String email,
    required String role,
  }) => _change(
    companyId,
    () => _api.post(
      apiPath(['companies', companyId, 'members']),
      body: {'email': email, 'role': role},
    ),
  );

  @override
  Future<void> setRole({
    required String companyId,
    required String userId,
    required String role,
  }) => _change(
    companyId,
    () => _api.patch(
      apiPath(['companies', companyId, 'members', userId]),
      body: {'role': role},
    ),
  );

  @override
  Future<void> setActive({
    required String companyId,
    required String userId,
    required bool active,
  }) => _change(
    companyId,
    () => _api.patch(
      apiPath(['companies', companyId, 'members', userId]),
      body: {'status': active ? 'active' : 'disabled'},
    ),
  );
}
