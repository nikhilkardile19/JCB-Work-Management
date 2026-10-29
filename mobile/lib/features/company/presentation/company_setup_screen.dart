import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/dialogs.dart';
import '../../auth/application/auth_providers.dart';
import '../application/company_providers.dart';
import 'company_profile_form.dart';

/// First-time company registration. The router moves on once the new
/// (pending) company lands in the local cache.
class CompanySetupScreen extends ConsumerWidget {
  const CompanySetupScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message:
          'You can finish setting up your company the next time you sign in.',
      confirmLabel: 'Sign out',
    );
    if (ok) await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your company'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSize.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.sm,
                AppSpace.page,
                AppSpace.xxl,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text(
                  'Tell us about your business. After you submit, we review and activate your account — usually within one working day.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                CompanyProfileForm(
                  submitLabel: 'Submit for approval',
                  onSubmit: (profile) => ref
                      .read(companyRepositoryProvider)
                      .register(
                        uid: user!.uid,
                        email: user.email,
                        profile: profile,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
