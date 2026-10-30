import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../data/local/database_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../data/company_remote_source.dart';
import '../data/company_repository.dart';
import '../domain/company.dart';
import 'session.dart';

final companyRemoteSourceProvider = Provider<CompanyRemoteSource>(
  (ref) => HttpCompanyRemoteSource(ref.watch(apiClientProvider)),
);

final companyRepositoryProvider = Provider<CompanyRepository>(
  (ref) => CompanyRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(companyRemoteSourceProvider),
  ),
);

String? _uid(Ref ref) => ref.watch(authStateProvider).value?.uid;

/// Cached memberships for the signed-in user (offline-safe).
final membershipsProvider = StreamProvider<List<CompanyMembership>>((ref) {
  final uid = _uid(ref);
  if (uid == null) return Stream.value(const []);
  return ref.watch(companyRepositoryProvider).watchMemberships(uid);
});

final selectedCompanyIdProvider = StreamProvider<String?>((ref) {
  final uid = _uid(ref);
  if (uid == null) return Stream.value(null);
  return ref.watch(companyRepositoryProvider).watchSelectedCompanyId(uid);
});

/// Server refresh of memberships, run once per sign-in. Invalidate to retry.
final membershipRefreshProvider = FutureProvider<void>((ref) async {
  final uid = _uid(ref);
  if (uid == null) return;
  await ref.watch(companyRepositoryProvider).refresh(uid);
}, retry: (_, _) => null);

final sessionProvider = Provider<SessionState>(
  (ref) => resolveSession(
    auth: ref.watch(authStateProvider),
    memberships: ref.watch(membershipsProvider),
    selectedCompanyId: ref.watch(selectedCompanyIdProvider),
    refresh: ref.watch(membershipRefreshProvider),
  ),
);

/// The active company. Only read inside screens reachable when ready.
final currentMembershipProvider = Provider<CompanyMembership?>((ref) {
  final s = ref.watch(sessionProvider);
  return s is SessionReady ? s.membership : null;
});
