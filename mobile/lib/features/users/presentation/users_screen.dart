import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/auth_providers.dart';
import '../../company/domain/permissions.dart';
import '../../work/application/work_providers.dart';
import '../../work/data/work_log_repository.dart';
import '../application/users_providers.dart';
import '../data/company_users_service.dart';

String _roleLabel(String role) => CompanyRole.parse(role)?.label ?? 'Owner';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(workActorProvider);
    final members = ref.watch(companyMembersProvider);
    final offline = ref.watch(isOnlineProvider).value == false;
    if (actor == null || !UserAdminPolicy.canManage(actor.role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Users')),
        body: const PermissionDeniedView(
          permission: 'User management',
          reason: 'Only the company owner and admins can manage users.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: offline
          ? null
          : FloatingActionButton.extended(
              key: const Key('users_invite'),
              heroTag: 'fab_users',
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add user'),
              onPressed: () => showAppBottomSheet<void>(
                context,
                title: 'Add a user',
                builder: (_) => _InviteForm(actor: actor),
              ),
            ),
      body: switch (members) {
        AsyncValue(:final error?) when !members.hasValue =>
          offline
              ? const OfflineView(
                  message: 'Connect to the internet to see and manage users.',
                )
              : ErrorView(message: '$error'),
        AsyncValue(:final value?) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.sm,
            AppSpace.page,
            96,
          ),
          children: [
            if (offline) ...[
              const StatusChip(
                label: 'Connect to the internet to make changes',
                tone: StatusTone.warning,
                icon: Icons.cloud_off_outlined,
              ),
              const SizedBox(height: AppSpace.md),
            ],
            for (final m in value) ...[
              _MemberCard(member: m, actor: actor, offline: offline),
              const SizedBox(height: AppSpace.sm),
            ],
          ],
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({
    required this.member,
    required this.actor,
    required this.offline,
  });

  final CompanyMember member;
  final WorkActor actor;
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = member.uid == actor.userId;
    final editable =
        !offline && UserAdminPolicy.canChange(actor.role, actor.userId, member);
    return AppCard(
      key: Key('user_${member.email}'),
      onTap: editable
          ? () => showAppBottomSheet<void>(
              context,
              title: member.email,
              builder: (_) => _MemberActions(member: member, actor: actor),
            )
          : null,
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              member.email.isEmpty ? '?' : member.email[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.email,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    StatusChip(
                      label: _roleLabel(member.role),
                      tone: StatusTone.info,
                    ),
                    if (!member.active)
                      const StatusChip(
                        label: 'Disabled',
                        tone: StatusTone.danger,
                      ),
                    if (me) const StatusChip(label: 'You'),
                  ],
                ),
              ],
            ),
          ),
          if (editable) const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _MemberActions extends ConsumerStatefulWidget {
  const _MemberActions({required this.member, required this.actor});

  final CompanyMember member;
  final WorkActor actor;

  @override
  ConsumerState<_MemberActions> createState() => _MemberActionsState();
}

class _MemberActionsState extends ConsumerState<_MemberActions> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function(CompanyUsersService s) action,
    String done,
  ) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(companyUsersServiceProvider));
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(context, done, tone: StatusTone.success);
    } on CompanyUsersException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: StatusTone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final cid = widget.actor.companyId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Role', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final r in UserAdminPolicy.assignableRoles(widget.actor.role))
              ChoiceChip(
                key: Key('role_${r.name}'),
                label: Text(r.label),
                selected: m.role == r.name,
                onSelected: _busy || m.role == r.name
                    ? null
                    : (_) => _run(
                        (s) => s.setRole(
                          companyId: cid,
                          userId: m.uid,
                          role: r.name,
                        ),
                        '${m.email} is now ${r.label.toLowerCase()}',
                      ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        AppButton(
          key: const Key('user_toggle'),
          label: m.active ? 'Disable access' : 'Enable access',
          icon: m.active ? Icons.block : Icons.check_circle_outline,
          variant: m.active
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          loading: _busy,
          onPressed: () async {
            if (m.active) {
              final ok = await showConfirmDialog(
                context,
                title: 'Disable ${m.email}?',
                message: 'They can no longer sync or use company data online. Records already on their phone are not deleted.',
                confirmLabel: 'Disable',
                destructive: true,
              );
              if (!ok) return;
            }
            await _run(
              (s) =>
                  s.setActive(companyId: cid, userId: m.uid, active: !m.active),
              m.active ? 'Access disabled' : 'Access enabled',
            );
          },
        ),
      ],
    );
  }
}

class _InviteForm extends ConsumerStatefulWidget {
  const _InviteForm({required this.actor});

  final WorkActor actor;

  @override
  ConsumerState<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends ConsumerState<_InviteForm> {
  final _email = TextEditingController();
  CompanyRole _role = CompanyRole.operator;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final err = AuthValidators.email(_email.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(companyUsersServiceProvider)
          .invite(
            companyId: widget.actor.companyId,
            email: _email.text.trim(),
            role: _role.name,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(
        context,
        'Added. They can sign in after setting a password with “Forgot password”.',
        tone: StatusTone.success,
      );
    } on CompanyUsersException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('invite_email'),
          label: 'Email',
          controller: _email,
          prefixIcon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
          errorText: _error,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: AppSpace.lg),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final r in UserAdminPolicy.assignableRoles(widget.actor.role))
              ChoiceChip(
                key: Key('invite_role_${r.name}'),
                label: Text(r.label),
                selected: _role == r,
                onSelected: (_) => setState(() => _role = r),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        AppButton(
          key: const Key('invite_submit'),
          label: 'Add user',
          icon: Icons.person_add_alt_1,
          loading: _busy,
          onPressed: _invite,
        ),
      ],
    );
  }
}
