import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../company/domain/permissions.dart';
import '../../work/application/work_providers.dart';
import '../data/company_users_service.dart';

final companyUsersServiceProvider = Provider<CompanyUsersService>(
  (ref) => CloudCompanyUsersService(),
);

final companyMembersProvider = StreamProvider.autoDispose<List<CompanyMember>>((
  ref,
) {
  final actor = ref.watch(workActorProvider);
  if (actor == null) return Stream.value(const []);
  return ref.watch(companyUsersServiceProvider).watch(actor.companyId);
});

/// Mirrors the server rules so the screen only offers allowed changes:
/// never the owner or yourself; only the owner manages admins.
abstract final class UserAdminPolicy {
  static bool canManage(CompanyRole r) => r.can(Permission.manageUsers);

  static bool canChange(CompanyRole me, String myUid, CompanyMember m) =>
      canManage(me) &&
      m.uid != myUid &&
      m.role != 'owner' &&
      (m.role != 'admin' || me == CompanyRole.owner);

  static List<CompanyRole> assignableRoles(CompanyRole me) => [
    if (me == CompanyRole.owner) CompanyRole.admin,
    CompanyRole.manager,
    CompanyRole.operator,
    CompanyRole.accounts,
  ];
}
