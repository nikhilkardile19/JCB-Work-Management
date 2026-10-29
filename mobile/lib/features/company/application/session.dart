import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/company.dart';

/// Where the signed-in user is in onboarding. Drives the router guard.
sealed class SessionState {
  const SessionState();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

/// Couldn't determine the user's company: no local cache and the server
/// couldn't be reached (or failed).
class SessionError extends SessionState {
  const SessionError(this.error);

  final Object error;
}

sealed class SignedInSession extends SessionState {
  const SignedInSession(this.user);

  final AppUser user;
}

class SessionNeedsCompany extends SignedInSession {
  const SessionNeedsCompany(super.user);
}

class SessionPickCompany extends SignedInSession {
  const SessionPickCompany(super.user, this.memberships);

  final List<CompanyMembership> memberships;
}

class SessionPendingApproval extends SignedInSession {
  const SessionPendingApproval(super.user, this.membership);

  final CompanyMembership membership;
}

class SessionSuspended extends SignedInSession {
  const SessionSuspended(super.user, this.membership);

  final CompanyMembership membership;
}

class SessionReady extends SignedInSession {
  const SessionReady(super.user, this.membership, {this.companyCount = 1});

  final CompanyMembership membership;
  final int companyCount;
}

/// Pure session resolution so every branch is unit-testable.
SessionState resolveSession({
  required AsyncValue<AppUser?> auth,
  required AsyncValue<List<CompanyMembership>> memberships,
  required AsyncValue<String?> selectedCompanyId,
  required AsyncValue<void> refresh,
}) {
  if (auth.hasError && !auth.hasValue) return SessionError(auth.error!);
  if (!auth.hasValue) return const SessionLoading();
  final user = auth.value;
  if (user == null) return const SessionSignedOut();
  if (!memberships.hasValue || !selectedCompanyId.hasValue) {
    return const SessionLoading();
  }

  final list = memberships.value!;
  if (list.isEmpty) {
    // The cache may simply be cold: wait for the server before deciding the
    // user has no company.
    if (refresh.isLoading) return const SessionLoading();
    if (refresh.hasError) return SessionError(refresh.error!);
    return SessionNeedsCompany(user);
  }

  final selectedId = selectedCompanyId.value;
  final chosen =
      list.where((m) => m.companyId == selectedId).firstOrNull ??
      (list.length == 1 ? list.single : null);
  if (chosen == null) return SessionPickCompany(user, list);

  return switch (chosen.company.status) {
    CompanyStatus.pending => SessionPendingApproval(user, chosen),
    CompanyStatus.suspended => SessionSuspended(user, chosen),
    CompanyStatus.active => SessionReady(
      user,
      chosen,
      companyCount: list.length,
    ),
  };
}
