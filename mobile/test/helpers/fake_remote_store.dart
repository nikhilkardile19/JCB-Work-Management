import 'dart:convert';

import 'package:jcb_work_management/features/sync/data/remote_store.dart';

/// In-memory server shared by several "devices" in tests. Mirrors the
/// Firestore store's revision semantics, and can simulate being offline,
/// rejecting writes, or losing the reply to an accepted write.
class FakeRemoteStore implements RemoteStore {
  final docs = <String, _Doc>{}; // key: company/collection/id
  int _clock = 0;
  bool offline = false;
  int pushCalls = 0;

  /// Collections whose writes are refused (simulates security rules).
  final rejectCollections = <String>{};

  /// Accept the next write but throw as if the reply never arrived.
  bool loseNextReply = false;

  /// Thrown by every call: an unexpected error rather than a network one.
  Object? failWith;

  String _key(String c, String col, String id) => '$c/$col/$id';

  Map<String, dynamic>? read(String companyId, String collection, String id) =>
      docs[_key(companyId, collection, id)]?.data;

  int count(String companyId, String collection) =>
      docs.keys.where((k) => k.startsWith('$companyId/$collection/')).length;

  /// Another device changes a record on the server.
  void simulateRemoteEdit(
    String companyId,
    String collection,
    String id,
    Map<String, dynamic> changes,
  ) {
    final key = _key(companyId, collection, id);
    final d = docs[key]!;
    docs[key] = _Doc(id, d.rev + 1, ++_clock, {...d.data, ...changes});
  }

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
    pushCalls++;
    if (failWith case final e?) throw e;
    if (offline) throw const SyncUnavailable();
    if (rejectCollections.contains(collection)) {
      return const PushRejected('Refused by server rules');
    }
    final key = _key(companyId, collection, id);
    final current = docs[key];
    if (!force && current?.rev != baseRev) {
      return PushConflict(
        current?.rev ?? 0,
        jsonDecode(jsonEncode(current?.data ?? {})) as Map<String, dynamic>,
      );
    }
    final rev = (current?.rev ?? 0) + 1;
    docs[key] = _Doc(
      id,
      rev,
      ++_clock,
      jsonDecode(jsonEncode(data)) as Map<String, dynamic>,
    );
    if (loseNextReply) {
      loseNextReply = false;
      throw const SyncUnavailable('reply lost');
    }
    return PushAccepted(rev);
  }

  @override
  Future<List<RemoteDoc>> pull({
    required String companyId,
    required String collection,
    required SyncCursor? after,
    required int limit,
  }) async {
    if (failWith case final e?) throw e;
    if (offline) throw const SyncUnavailable();
    final prefix = '$companyId/$collection/';
    final list =
        docs.entries
            .where((e) => e.key.startsWith(prefix))
            .map((e) => e.value)
            .toList()
          ..sort(
            (a, b) => a.time != b.time
                ? a.time.compareTo(b.time)
                : a.id.compareTo(b.id),
          );
    return list
        .where(
          (d) =>
              after == null ||
              d.time > after.micros ||
              (d.time == after.micros && d.id.compareTo(after.id) > 0),
        )
        .take(limit)
        .map(
          (d) => RemoteDoc(
            id: d.id,
            rev: d.rev,
            data: jsonDecode(jsonEncode(d.data)) as Map<String, dynamic>,
            cursor: SyncCursor(d.time, d.id),
          ),
        )
        .toList();
  }
}

class _Doc {
  _Doc(this.id, this.rev, this.time, this.data);

  final String id;
  final int rev;
  final int time;
  final Map<String, dynamic> data;
}
