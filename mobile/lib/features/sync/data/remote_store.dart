import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// Position in a collection's change feed: the server's per-company change
/// sequence number of the last record seen, plus that record's ID.
class SyncCursor {
  const SyncCursor(this.position, this.id);

  final int position;
  final String id;

  String encode() => '$position|$id';

  static SyncCursor? decode(String? s) {
    if (s == null) return null;
    final i = s.indexOf('|');
    return SyncCursor(int.parse(s.substring(0, i)), s.substring(i + 1));
  }
}

class RemoteDoc {
  const RemoteDoc({
    required this.id,
    required this.rev,
    required this.data,
    required this.cursor,
  });

  final String id;

  /// Server revision, incremented by every accepted write.
  final int rev;

  /// Business fields only (sync metadata removed).
  final Map<String, dynamic> data;
  final SyncCursor cursor;
}

sealed class PushResult {
  const PushResult();
}

class PushAccepted extends PushResult {
  const PushAccepted(this.rev);

  final int rev;
}

/// The server copy changed since this device last saw it.
class PushConflict extends PushResult {
  const PushConflict(this.serverRev, this.serverData);

  final int serverRev;
  final Map<String, dynamic> serverData;
}

/// The server refused the write (rules/permissions). Retrying won't help
/// until something changes.
class PushRejected extends PushResult {
  const PushRejected(this.message);

  final String message;
}

/// The server can't be reached right now; try again later.
class SyncUnavailable implements Exception {
  const SyncUnavailable([this.message = 'Server unreachable']);

  final String message;

  @override
  String toString() => message;
}

/// Server side of sync. The REST API in the app; in-memory in tests.
abstract interface class RemoteStore {
  /// Writes [data] if the server is still at [baseRev] (null = should not
  /// exist yet), or unconditionally when [force] is true (where the server
  /// allows it).
  Future<PushResult> push({
    required String companyId,
    required String collection,
    required String id,
    required Map<String, dynamic> data,
    required int? baseRev,
    required String userId,
    required String deviceId,
    bool force = false,
  });

  /// Next page of documents changed after [after], oldest first.
  Future<List<RemoteDoc>> pull({
    required String companyId,
    required String collection,
    required SyncCursor? after,
    required int limit,
  });
}

/// Metadata the sync layer adds to every document.
const syncMetaKeys = {'rev', 'serverUpdatedAt', 'pushedBy', 'deviceId'};

/// `PUT|GET /companies/:companyId/sync/:collection[/:id]` (contract, "offline
/// sync").
class HttpRemoteStore implements RemoteStore {
  HttpRemoteStore(this._api);

  final ApiClient _api;

  /// 403 reasons that refuse the whole pass, not just one record: records
  /// stay `pending` until access is restored.
  static const passRefusals = {
    'not_member',
    'company_inactive',
    'device_not_licensed',
  };

  static Map<String, dynamic> _business(Map<String, dynamic> d) =>
      Map.of(d)..removeWhere((k, _) => syncMetaKeys.contains(k));

  @override
  Future<PushResult> push({
    required String companyId,
    required String collection,
    required String id,
    required Map<String, dynamic> data,
    required int? baseRev,
    required String userId,
    required String deviceId,
    bool force = false,
  }) async {
    if (force) {
      throw ArgumentError.value(
        force,
        'force',
        'The server refuses unconditional writes',
      );
    }
    try {
      final json = await _api.put(
        apiPath(['companies', companyId, 'sync', collection, id]),
        // Revisions start at 1, so 0 (a conflict on a missing record) means
        // "should not exist yet".
        body: {'baseRev': baseRev == 0 ? null : baseRev, 'data': data},
        headers: {'X-Device-Id': deviceId},
      );
      return PushAccepted((json['rev'] as num).toInt());
    } on ApiException catch (e) {
      return switch (e) {
        ApiException(statusCode: 409, code: 'conflict') => PushConflict(
          (e.body['serverRev'] as num).toInt(),
          _business(e.body['serverData'] as Map<String, dynamic>),
        ),
        // Signed out, or no access for this phone right now: stop the pass.
        ApiException(statusCode: 401) => throw SyncUnavailable(e.message),
        ApiException(statusCode: 403, :final reason?)
            when passRefusals.contains(reason) =>
          throw SyncUnavailable(e.message),
        ApiException(statusCode: 400 || 403 || 404 || 409) => PushRejected(
          e.message,
        ),
        _ => throw SyncUnavailable(e.message),
      };
    } on ApiUnavailable catch (e) {
      throw SyncUnavailable(e.message);
    }
  }

  @override
  Future<List<RemoteDoc>> pull({
    required String companyId,
    required String collection,
    required SyncCursor? after,
    required int limit,
  }) async {
    try {
      final json = await _api.get(
        apiPath(['companies', companyId, 'sync', collection]),
        query: {'after': ?after?.encode(), 'limit': limit},
      );
      return [
        for (final item in (json['items'] as List).cast<Json>())
          RemoteDoc(
            id: item['id'] as String,
            rev: (item['rev'] as num).toInt(),
            data: _business(item['data'] as Map<String, dynamic>),
            cursor: SyncCursor.decode(item['cursor'] as String)!,
          ),
      ];
    } on ApiException catch (e) {
      // Not allowed to read this collection (e.g. billing for an operator):
      // nothing to download.
      if (e.statusCode == 403) return const [];
      throw SyncUnavailable(e.message);
    } on ApiUnavailable catch (e) {
      throw SyncUnavailable(e.message);
    }
  }
}
