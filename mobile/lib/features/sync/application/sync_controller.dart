import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../data/local/database_provider.dart';
import '../../billing/domain/invoice.dart';
import '../../license/application/license_controller.dart';
import '../../work/application/work_providers.dart';
import '../data/remote_store.dart';
import '../data/sync_engine.dart';

final remoteStoreProvider = Provider<RemoteStore>(
  (ref) => FirestoreRemoteStore(FirebaseFirestore.instance),
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    ref.watch(appDatabaseProvider),
    ref.watch(remoteStoreProvider),
  ),
);

/// Automatic triggers (startup, reconnect, local changes, timer). Tests
/// turn this off and call [SyncController.syncNow] explicitly.
final autoSyncProvider = Provider<bool>((ref) => true);

enum SyncPhase { idle, syncing, offline, failed }

class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.lastSyncAt,
    this.lastReport,
    this.message,
  });

  final SyncPhase phase;

  /// UTC epoch ms of the last completed sync.
  final int? lastSyncAt;
  final SyncReport? lastReport;
  final String? message;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? lastSyncAt,
    SyncReport? lastReport,
    String? message,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastReport: lastReport ?? this.lastReport,
    message: message,
  );
}

/// Runs sync passes and decides when. Retries with exponential backoff
/// (30 s doubling to 15 min) while the server is unreachable.
class SyncController extends Notifier<SyncStatus> {
  static const _debounce = Duration(seconds: 5);
  static const _periodic = Duration(minutes: 5);
  static const _maxBackoff = Duration(minutes: 15);

  Timer? _changeTimer;
  Timer? _periodicTimer;
  Timer? _retryTimer;
  int _failures = 0;
  bool _running = false;

  @override
  SyncStatus build() {
    final actor = ref.watch(workActorProvider);
    ref.onDispose(_cancelTimers);
    if (actor == null) return const SyncStatus();

    if (ref.watch(autoSyncProvider)) {
      ref.listen(isOnlineProvider, (prev, next) {
        if (next.value == true && prev?.value != true) unawaited(syncNow());
      });
      final db = ref.watch(appDatabaseProvider);
      final sub = db.tableUpdates().listen((_) {
        if (_running) return;
        _changeTimer?.cancel();
        _changeTimer = Timer(_debounce, () => unawaited(syncNow()));
      });
      ref.onDispose(sub.cancel);
      _periodicTimer = Timer.periodic(_periodic, (_) => unawaited(syncNow()));
      Future.microtask(syncNow);
    }
    unawaited(_loadLastSync(actor.companyId));
    return const SyncStatus();
  }

  Future<void> _loadLastSync(String companyId) async {
    final at = await ref.read(syncEngineProvider).lastSyncAt(companyId);
    if (at != null && state.lastSyncAt == null) {
      state = state.copyWith(lastSyncAt: at);
    }
  }

  void _cancelTimers() {
    _changeTimer?.cancel();
    _periodicTimer?.cancel();
    _retryTimer?.cancel();
  }

  /// One sync pass now (no-op if one is already running).
  Future<void> syncNow() async {
    final actor = ref.read(workActorProvider);
    if (actor == null || _running) return;
    _running = true;
    _retryTimer?.cancel();
    state = state.copyWith(phase: SyncPhase.syncing);
    try {
      final report = await ref
          .read(syncEngineProvider)
          .run(
            companyId: actor.companyId,
            userId: actor.userId,
            canViewBilling: InvoicePolicy.canView(actor.role),
            push: ref.read(canWriteProvider),
          );
      _failures = 0;
      state = SyncStatus(
        phase: SyncPhase.idle,
        lastSyncAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        lastReport: report,
      );
    } on SyncUnavailable catch (e) {
      _failures++;
      state = state.copyWith(phase: SyncPhase.offline, message: e.message);
      _scheduleRetry();
    } catch (e) {
      _failures++;
      state = state.copyWith(phase: SyncPhase.failed, message: '$e');
      _scheduleRetry();
    } finally {
      _running = false;
    }
  }

  void _scheduleRetry() {
    if (!ref.read(autoSyncProvider)) return;
    final seconds = min(
      30 * pow(2, _failures - 1).toInt(),
      _maxBackoff.inSeconds,
    );
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), () => unawaited(syncNow()));
  }

  Future<void> keepLocal(String collection, String id) async {
    await ref.read(syncEngineProvider).keepLocal(collection, id);
    await syncNow();
  }

  Future<void> useServer(String collection, String id) =>
      ref.read(syncEngineProvider).useServer(collection, id);

  Future<void> retry(String collection, String id) async {
    await ref.read(syncEngineProvider).retry(collection, id);
    await syncNow();
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

final pendingSyncCountProvider = StreamProvider.autoDispose<int>((ref) {
  final actor = ref.watch(workActorProvider);
  if (actor == null) return Stream.value(0);
  return ref.watch(syncEngineProvider).watchPendingCount(actor.companyId);
});

final syncIssuesProvider = StreamProvider.autoDispose<List<SyncIssue>>((ref) {
  final actor = ref.watch(workActorProvider);
  if (actor == null) return Stream.value(const []);
  return ref.watch(syncEngineProvider).watchIssues(actor.companyId);
});

final syncCountsProvider = FutureProvider.autoDispose<List<SyncCount>>((ref) {
  final actor = ref.watch(workActorProvider);
  if (actor == null) return Future.value(const []);
  ref.watch(syncControllerProvider.select((s) => s.lastSyncAt));
  return ref.watch(syncEngineProvider).counts(actor.companyId);
});
