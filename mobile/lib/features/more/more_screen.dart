import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/dialogs.dart';
import '../auth/application/auth_providers.dart';
import '../company/application/company_providers.dart';
import '../company/application/session.dart';
import '../company/domain/permissions.dart';
import '../license/application/license_controller.dart';
import '../license/presentation/license_widgets.dart';
import '../masters/application/masters_providers.dart';
import '../masters/domain/master_kind.dart';
import '../reports/domain/reports.dart';
import '../settings/theme_mode_provider.dart';
import '../sync/presentation/sync_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const _themeLabels = {
    ThemeMode.system: 'System',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'Records saved on this device are kept and will be available when you sign in again.',
      confirmLabel: 'Sign out',
    );
    if (ok) await ref.read(authRepositoryProvider).signOut();
  }

  void _pickTheme(BuildContext context, WidgetRef ref, ThemeMode current) {
    showAppBottomSheet<void>(
      context,
      title: 'Appearance',
      builder: (sheetContext) => SegmentedButton<ThemeMode>(
        segments: [
          for (final e in _themeLabels.entries)
            ButtonSegment(value: e.key, label: Text(e.value)),
        ],
        selected: {current},
        onSelectionChanged: (s) async {
          await setThemeMode(ref, s.first);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final session = ref.watch(sessionProvider);
    final membership = session is SessionReady ? session.membership : null;
    final canSwitch = session is SessionReady && session.companyCount > 1;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
        children: [
          if (membership != null) ...[
            const SectionHeader('Company'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    key: const Key('more_company'),
                    leading: const Icon(Icons.business_outlined),
                    title: Text(membership.company.name),
                    subtitle: Text(membership.role.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(Routes.companyProfile),
                  ),
                  if (membership.can(Permission.manageUsers)) ...[
                    const Divider(),
                    ListTile(
                      key: const Key('more_users'),
                      leading: const Icon(Icons.people_outline),
                      title: const Text('Users'),
                      subtitle: const Text(
                        'Add people, set roles, disable access',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.users),
                    ),
                  ],
                  if (canSwitch) ...[
                    const Divider(),
                    ListTile(
                      key: const Key('more_switch_company'),
                      leading: const Icon(Icons.swap_horiz),
                      title: const Text('Switch company'),
                      onTap: () => ref
                          .read(companyRepositoryProvider)
                          .clearSelection(user!.uid),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (membership != null) ...[
            const SectionHeader('Masters'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, kind) in MasterKind.values.indexed) ...[
                    if (i > 0) const Divider(),
                    _MasterEntry(kind: kind),
                  ],
                ],
              ),
            ),
          ],
          if (membership != null) ...[
            const SectionHeader('Data'),
            if (ReportPolicy.canView(membership.role)) ...[
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('more_reports'),
                  leading: const Icon(Icons.insert_chart_outlined),
                  title: const Text('Reports'),
                  subtitle: const Text('Work, fuel, invoices, payments, dues'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.reports),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                key: const Key('more_sync'),
                leading: const Icon(Icons.sync),
                title: const Text('Sync & data'),
                subtitle: const Align(
                  alignment: Alignment.centerLeft,
                  child: AppSyncIndicator(),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.sync),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                key: const Key('more_license'),
                leading: const Icon(Icons.key_outlined),
                title: const Text('License'),
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: switch (ref.watch(licenseAccessProvider).value) {
                    final a? => LicenseChip(a),
                    null => const SizedBox.shrink(),
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.license),
              ),
            ),
          ],
          const SectionHeader('Account'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user?.email ?? 'Not signed in'),
                  subtitle: const Text('Signed in'),
                ),
                const Divider(),
                ListTile(
                  key: const Key('more_sign_out'),
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
          ),
          const SectionHeader('Preferences'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              key: const Key('more_appearance'),
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Appearance'),
              subtitle: Text(_themeLabels[mode]!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickTheme(context, ref, mode),
            ),
          ),
          const SectionHeader('App'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: const Key('more_privacy'),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy and permissions'),
                  subtitle: const Text('What is stored where, and why'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.privacy),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: AppConfig.appName,
                    applicationVersion: '0.1.0 (${AppConfig.env.name})',
                    applicationLegalese: 'Meter photos, receipts and invoice PDFs are stored only on this device.',
                  ),
                ),
                if (AppConfig.isDev) ...[
                  const Divider(),
                  ListTile(
                    key: const Key('more_components'),
                    leading: const Icon(Icons.widgets_outlined),
                    title: const Text('Design system'),
                    subtitle: const Text('Component gallery (dev builds)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(Routes.components),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
        ],
      ),
    );
  }
}

class _MasterEntry extends ConsumerWidget {
  const _MasterEntry({required this.kind});

  final MasterKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(masterActiveCountProvider(kind)).value;
    return ListTile(
      key: Key('more_master_${kind.slug}'),
      leading: Icon(kind.icon),
      title: Text(kind.plural),
      subtitle: Text(count == null ? ' ' : '$count active'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(Routes.masterList(kind)),
    );
  }
}
