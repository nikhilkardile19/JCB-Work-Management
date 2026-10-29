import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../auth/application/auth_providers.dart';
import '../application/company_providers.dart';
import '../application/session.dart';
import '../domain/company.dart';

/// Blocking screen for a company that is awaiting approval or suspended.
/// Local data is never deleted here.
class CompanyStatusScreen extends ConsumerStatefulWidget {
  const CompanyStatusScreen({super.key});

  @override
  ConsumerState<CompanyStatusScreen> createState() =>
      _CompanyStatusScreenState();
}

class _CompanyStatusScreenState extends ConsumerState<CompanyStatusScreen> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    ref.invalidate(membershipRefreshProvider);
    try {
      await ref.read(membershipRefreshProvider.future);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          "Couldn't reach the server. Check your connection.",
          tone: StatusTone.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'Records saved on this device are kept.',
      confirmLabel: 'Sign out',
    );
    if (ok) await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final (CompanyMembership? membership, bool suspended) = switch (session) {
      SessionPendingApproval(:final membership) => (membership, false),
      SessionSuspended(:final membership) => (membership, true),
      _ => (null, false),
    };
    final theme = Theme.of(context);
    final tone = suspended ? StatusTone.danger : StatusTone.info;
    final color = AppStatusColors.of(context).forTone(tone);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpace.xl),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        suspended
                            ? Icons.block_outlined
                            : Icons.hourglass_top_rounded,
                        size: AppSize.iconLg,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Text(
                    suspended ? 'Account suspended' : 'Awaiting approval',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    suspended
                        ? 'Access for this company has been paused. Records saved on this phone are kept. Contact support to restore access.'
                        : "Thanks for registering. We'll activate your company once it's reviewed. Tap Check again to refresh.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (membership != null) ...[
                    const SizedBox(height: AppSpace.xl),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.business_outlined),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Text(
                              membership.company.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          StatusChip(
                            label: suspended ? 'Suspended' : 'Pending',
                            tone: suspended
                                ? StatusTone.danger
                                : StatusTone.warning,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  AppButton(
                    key: const Key('status_check_again'),
                    label: 'Check again',
                    icon: Icons.refresh,
                    loading: _checking,
                    onPressed: _checkAgain,
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppButton(
                    label: 'Sign out',
                    icon: Icons.logout,
                    variant: AppButtonVariant.secondary,
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
