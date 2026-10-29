import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../../company/application/company_providers.dart';
import '../../company/application/session.dart';
import '../../company/domain/permissions.dart';
import '../data/masters_repository.dart';
import '../domain/master_kind.dart';

final mastersRepositoryProvider = Provider<MastersRepository>(
  (ref) => MastersRepository(ref.watch(appDatabaseProvider)),
);

/// Active company + user, or null before onboarding completes.
final masterScopeProvider = Provider<MasterScope?>((ref) {
  final s = ref.watch(sessionProvider);
  return s is SessionReady
      ? MasterScope(companyId: s.membership.companyId, userId: s.user.uid)
      : null;
});

final canManageMastersProvider = Provider<bool>(
  (ref) =>
      ref.watch(currentMembershipProvider)?.can(Permission.manageMasters) ??
      false,
);

typedef MasterQuery = ({
  MasterKind kind,
  String search,
  StatusFilter status,
  String? clientId,
});

final _rawMasterListProvider = StreamProvider.autoDispose
    .family<List<MasterRecord>, MasterQuery>((ref, q) {
      final scope = ref.watch(masterScopeProvider);
      if (scope == null) return Stream.value(const []);
      return ref
          .watch(mastersRepositoryProvider)
          .watchList(
            q.kind,
            scope.companyId,
            search: q.search,
            status: q.status,
            clientId: q.clientId,
          );
    });

/// Client ID → name, including inactive clients (for labels on sites).
final clientNamesProvider = StreamProvider.autoDispose<Map<String, String>>((
  ref,
) {
  final scope = ref.watch(masterScopeProvider);
  if (scope == null) return Stream.value(const {});
  return ref
      .watch(mastersRepositoryProvider)
      .watchList(MasterKind.clients, scope.companyId, status: StatusFilter.all)
      .map((list) => {for (final c in list) c.id: c.name});
});

MasterRecord _withClientName(MasterRecord r, Map<String, String>? names) =>
    r.kind == MasterKind.sites
    ? MasterRecord(r.kind, r.values, clientName: names?[r.clientId])
    : r;

final masterListProvider = Provider.autoDispose
    .family<AsyncValue<List<MasterRecord>>, MasterQuery>((ref, q) {
      final raw = ref.watch(_rawMasterListProvider(q));
      if (q.kind != MasterKind.sites) return raw;
      final names = ref.watch(clientNamesProvider).value;
      return raw.whenData(
        (list) => [for (final r in list) _withClientName(r, names)],
      );
    });

final _rawMasterRecordProvider = StreamProvider.autoDispose
    .family<MasterRecord?, (MasterKind, String)>((ref, key) {
      final scope = ref.watch(masterScopeProvider);
      if (scope == null) return Stream.value(null);
      return ref
          .watch(mastersRepositoryProvider)
          .watchOne(key.$1, scope.companyId, key.$2);
    });

final masterRecordProvider = Provider.autoDispose
    .family<AsyncValue<MasterRecord?>, (MasterKind, String)>((ref, key) {
      final raw = ref.watch(_rawMasterRecordProvider(key));
      if (key.$1 != MasterKind.sites) return raw;
      final names = ref.watch(clientNamesProvider).value;
      return raw.whenData((r) => r == null ? null : _withClientName(r, names));
    });

final masterActiveCountProvider = StreamProvider.autoDispose
    .family<int, MasterKind>((ref, kind) {
      final scope = ref.watch(masterScopeProvider);
      if (scope == null) return Stream.value(0);
      return ref
          .watch(mastersRepositoryProvider)
          .watchActiveCount(kind, scope.companyId);
    });
