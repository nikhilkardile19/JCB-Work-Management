import 'package:cloud_firestore/cloud_firestore.dart';

/// Position in a collection's change feed: server update time + doc ID.
class SyncCursor {
  const SyncCursor(this.micros, this.id);

  final int micros;
  final String id;

  String encode() => '$micros|$id';

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

/// Server side of sync. Firestore in the app; in-memory in tests.
abstract interface class RemoteStore {
  /// Writes [data] if the server is still at [baseRev] (null = should not
  /// exist yet), or unconditionally when [force] is true.
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

/// Firestore layout: `companies/{companyId}/{collection}/{id}`.
class FirestoreRemoteStore implements RemoteStore {
  FirestoreRemoteStore(this._fs);

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> _col(
    String companyId,
    String collection,
  ) => _fs.collection('companies').doc(companyId).collection(collection);

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
    final ref = _col(companyId, collection).doc(id);
    try {
      return await _fs.runTransaction<PushResult>((tx) async {
        final snap = await tx.get(ref);
        final serverRev = snap.exists
            ? (snap.data()!['rev'] as num).toInt()
            : null;
        if (!force && serverRev != baseRev) {
          return PushConflict(
            serverRev ?? 0,
            _business(snap.data() ?? const {}),
          );
        }
        final rev = (serverRev ?? 0) + 1;
        tx.set(ref, {
          ...data,
          'rev': rev,
          'serverUpdatedAt': FieldValue.serverTimestamp(),
          'pushedBy': userId,
          'deviceId': deviceId,
        });
        return PushAccepted(rev);
      }, timeout: const Duration(seconds: 20));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const PushRejected(
          'The server refused this change (permission or validation).',
        );
      }
      throw SyncUnavailable(e.message ?? e.code);
    }
  }

  @override
  Future<List<RemoteDoc>> pull({
    required String companyId,
    required String collection,
    required SyncCursor? after,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> q = _col(
      companyId,
      collection,
    ).orderBy('serverUpdatedAt').orderBy(FieldPath.documentId).limit(limit);
    if (after != null) {
      q = q.startAfter([
        Timestamp.fromMicrosecondsSinceEpoch(after.micros),
        after.id,
      ]);
    }
    try {
      final snap = await q.get(const GetOptions(source: Source.server));
      return [
        for (final d in snap.docs)
          if (d.data()['serverUpdatedAt'] is Timestamp)
            RemoteDoc(
              id: d.id,
              rev: (d.data()['rev'] as num).toInt(),
              data: _business(d.data()),
              cursor: SyncCursor(
                (d.data()['serverUpdatedAt'] as Timestamp)
                    .microsecondsSinceEpoch,
                d.id,
              ),
            ),
      ];
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return const [];
      throw SyncUnavailable(e.message ?? e.code);
    }
  }
}
