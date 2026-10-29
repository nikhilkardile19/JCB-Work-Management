import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/errors/error_log.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/sync_indicator.dart';
import '../../../data/local/database_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../company/application/company_providers.dart';
import '../../company/domain/company.dart';
import '../../license/application/license_controller.dart';
import '../../license/domain/license.dart';
import '../../license/presentation/license_widgets.dart';
import '../application/sync_controller.dart';
import '../data/sync_engine.dart';

/// App-wide sync state, combining connectivity, the controller and the
/// local queue.
final appSyncStateProvider = Provider.autoDispose<SyncState>((ref) {
  if (ref.watch(isOnlineProvider).value == false) return SyncState.offline;
  final status = ref.watch(syncControllerProvider);
  if (status.phase == SyncPhase.syncing) return SyncState.syncing;
  if ((ref.watch(syncIssuesProvider).value ?? const []).isNotEmpty) {
    return SyncState.error;
  }
  if ((ref.watch(pendingSyncCountProvider).value ?? 0) > 0) {
    return status.phase == SyncPhase.offline
        ? SyncState.offline
        : SyncState.pending;
  }
  return status.lastSyncAt == null ? SyncState.localOnly : SyncState.synced;
});

/// Tappable chip showing [appSyncStateProvider]; opens the Sync screen.
class AppSyncIndicator extends ConsumerWidget {
  const AppSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
    key: const Key('app_sync_indicator'),
    borderRadius: BorderRadius.circular(AppRadius.pill),
    onTap: () => context.push(Routes.sync),
    child: SyncIndicator(state: ref.watch(appSyncStateProvider)),
  );
}

const _collectionLabels = {
  'clients': 'Clients',
  'sites': 'Sites',
  'machines': 'Machines',
  'operators': 'Operators',
  'petrolPumps': 'Petrol pumps',
  'workLogs': 'Work logs',
  'fuelEntries': 'Fuel entries',
  'invoices': 'Invoices',
  'payments': 'Payments',
  'auditLogs': 'History entries',
};

String _ago(int epochMs) =>
    DateFormat('d MMM, h:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(epochMs));

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(syncControllerProvider);
    final state = ref.watch(appSyncStateProvider);
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;
    final issues = ref.watch(syncIssuesProvider).value ?? const <SyncIssue>[];
    final counts = ref.watch(syncCountsProvider).value;
    final offline = ref.watch(isOnlineProvider).value == false;
    final controller = ref.read(syncControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync & data')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.page),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SyncIndicator(state: state),
                const SizedBox(height: AppSpace.md),
                Text(
                  status.lastSyncAt == null
                      ? 'Not synced yet'
                      : 'Last synced ${_ago(status.lastSyncAt!)}',
                  key: const Key('sync_last'),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  pending == 0
                      ? 'Everything on this phone is on the server.'
                      : '$pending ${pending == 1 ? 'change' : 'changes'} waiting to upload.',
                  key: const Key('sync_pending'),
                ),
                if (status.phase == SyncPhase.offline ||
                    status.phase == SyncPhase.failed)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: Text(
                      'Could not reach the server. Your work is safe on this phone; sync will retry automatically.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  key: const Key('sync_now'),
                  label: offline ? 'Waiting for internet' : 'Sync now',
                  icon: Icons.sync,
                  loading: status.phase == SyncPhase.syncing,
                  onPressed: offline ? null : controller.syncNow,
                ),
              ],
            ),
          ),
          if (issues.isNotEmpty) ...[
            const SectionHeader('Needs your attention'),
            for (final i in issues) ...[
              _IssueCard(issue: i),
              const SizedBox(height: AppSpace.sm),
            ],
          ],
          const SectionHeader('Data check'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (counts == null)
                  const Padding(
                    padding: EdgeInsets.all(AppSpace.lg),
                    child: LinearProgressIndicator(),
                  )
                else
                  for (final c in counts.where((c) => c.total > 0))
                    ListTile(
                      dense: true,
                      title: Text(
                        _collectionLabels[c.collection] ?? c.collection,
                      ),
                      trailing: Text(
                        c.synced == c.total
                            ? '${c.total} synced'
                            : '${c.synced} of ${c.total} synced',
                        style: TextStyle(
                          color: c.synced == c.total
                              ? AppStatusColors.of(context).success
                              : AppStatusColors.of(context).warning,
                        ),
                      ),
                    ),
                if (counts != null && counts.every((c) => c.total == 0))
                  const ListTile(title: Text('No records yet')),
              ],
            ),
          ),
          const SectionHeader('This phone'),
          const _PhoneCard(),
          const SectionHeader('Recent errors'),
          const _RecentErrors(),
          const SizedBox(height: AppSpace.lg),
          Text(
            'Meter photos, fuel receipts and invoice PDFs stay on this phone and are not uploaded. '
            'Keep the phone safe, or share important PDFs, until cloud backup is added.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

final _fullDate = DateFormat('d MMM yyyy, h:mm a');

String _at(int epochMs) =>
    _fullDate.format(DateTime.fromMillisecondsSinceEpoch(epochMs));

/// Plain-text state of this phone for a support request (sprint doc §4.13
/// "device and sync status for troubleshooting"). It only leaves the phone
/// if the user pastes it somewhere.
String supportDetails({
  required AppUser? user,
  required CompanyMembership? membership,
  required String? deviceId,
  required LicenseAccess? license,
  required LicenseSnapshot? licenseCheck,
  required SyncState sync,
  required int? lastSyncAt,
  required int pending,
  required int issues,
  required List<ErrorLogEntry> errors,
}) => [
  '${AppConfig.appName} ${AppConfig.version} (${AppConfig.env.name}), Android',
  if (membership != null)
    'Company: ${membership.company.name} (${membership.company.id})',
  if (user != null)
    'User: ${user.email} (${user.uid})'
        '${membership == null ? '' : ', ${membership.role.label}'}',
  'Device ID: ${deviceId ?? 'unknown'}',
  'License: ${license == null ? 'unknown' : licenseLook(license).$1}'
      '${licenseCheck == null ? '' : ', last checked ${_at(licenseCheck.lastValidatedAt)}'}',
  'Sync: ${sync.look.$1}'
      '${lastSyncAt == null ? ', never synced' : ', last synced ${_at(lastSyncAt)}'}',
  'Waiting to upload: $pending, needing attention: $issues',
  '',
  if (errors.isEmpty)
    'No recent errors.'
  else ...[
    'Recent errors (${errors.length}):',
    for (final e in errors) ...[
      '- ${_at(e.at)}${e.context == null ? '' : ' · ${e.context}'}',
      '  ${e.message}',
      if (e.stack != null)
        for (final line in e.stack!.split('\n')) '  $line',
    ],
  ],
].join('\n');

/// Who and what this phone is, with a summary to send to support.
class _PhoneCard extends ConsumerWidget {
  const _PhoneCard();

  Future<void> _copy(BuildContext context, WidgetRef ref) async {
    final text = supportDetails(
      user: ref.read(authStateProvider).value,
      membership: ref.read(currentMembershipProvider),
      deviceId: await ref.read(installationIdProvider.future),
      license: ref.read(licenseAccessProvider).value,
      licenseCheck: ref.read(licenseControllerProvider).value,
      sync: ref.read(appSyncStateProvider),
      lastSyncAt: ref.read(syncControllerProvider).lastSyncAt,
      pending: ref.read(pendingSyncCountProvider).value ?? 0,
      issues: (ref.read(syncIssuesProvider).value ?? const []).length,
      errors: await ref.read(errorLogProvider).entries(),
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showAppSnackBar(
        context,
        'Copied. Paste it into a message to support.',
        tone: StatusTone.success,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final membership = ref.watch(currentMembershipProvider);
    final deviceId = ref.watch(installationIdProvider).value;
    final license = ref.watch(licenseAccessProvider).value;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.email ?? 'Not signed in'),
            subtitle: Text(
              [?membership?.role.label, ?membership?.company.name].join(' · '),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: const Text('Device ID'),
            subtitle: Text(
              deviceId == null ? '…' : shortDeviceId(deviceId),
              key: const Key('sync_device_id'),
            ),
          ),
          const Divider(),
          ListTile(
            key: const Key('sync_license'),
            leading: const Icon(Icons.key_outlined),
            title: const Text('License'),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: license == null
                  ? const Text('Checking…')
                  : LicenseChip(license),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.license),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App version'),
            subtitle: Text('${AppConfig.version} (${AppConfig.env.name})'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.xs,
              AppSpace.lg,
              AppSpace.lg,
            ),
            child: AppButton(
              key: const Key('sync_copy_support'),
              label: 'Copy details for support',
              icon: Icons.copy_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => _copy(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unexpected errors recorded on this phone (newest first).
class _RecentErrors extends ConsumerWidget {
  const _RecentErrors();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final errors =
        ref.watch(recentErrorsProvider).value ?? const <ErrorLogEntry>[];
    if (errors.isEmpty) {
      return AppCard(
        key: const Key('sync_no_errors'),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppStatusColors.of(context).success,
            ),
            const SizedBox(width: AppSpace.md),
            const Expanded(child: Text('No errors recorded on this phone.')),
          ],
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, e) in errors.indexed) ...[
            if (i > 0) const Divider(),
            ExpansionTile(
              key: Key('sync_error_$i'),
              shape: const Border(),
              collapsedShape: const Border(),
              leading: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                e.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text([_ago(e.at), ?e.context].join(' · ')),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                0,
                AppSpace.lg,
                AppSpace.lg,
              ),
              children: [
                SelectableText(e.message),
                if (e.stack != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  SelectableText(
                    e.stack!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('sync_clear_errors'),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear list'),
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Clear the error list?',
                    message:
                        'If support is looking into a problem, copy the '
                        'details for them first.',
                    confirmLabel: 'Clear',
                  );
                  if (ok) await ref.read(errorLogProvider).clear();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends ConsumerWidget {
  const _IssueCard({required this.issue});

  final SyncIssue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(syncControllerProvider.notifier);
    return AppCard(
      key: Key('sync_issue_${issue.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                issue.isConflict ? Icons.call_split : Icons.sync_problem,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(issue.label, style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            issue.isConflict
                ? 'Changed on this phone and on another device. Server now has: ${issue.serverLabel ?? '—'}.'
                : issue.message ?? 'The server refused this change.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.sm),
          if (issue.isConflict)
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                AppButton(
                  key: const Key('sync_keep_local'),
                  label: 'Keep this phone\'s',
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  onPressed: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Keep this phone\'s version?',
                      message: 'The other device\'s change on the server will be replaced. This is recorded in the history.',
                      confirmLabel: 'Keep mine',
                    );
                    if (ok) {
                      await controller.keepLocal(issue.collection, issue.id);
                    }
                  },
                ),
                AppButton(
                  key: const Key('sync_use_server'),
                  label: 'Use server version',
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  onPressed: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Use the server version?',
                      message: 'Your unsynced change to this record on this phone will be discarded.',
                      confirmLabel: 'Use server version',
                      destructive: true,
                    );
                    if (ok) {
                      await controller.useServer(issue.collection, issue.id);
                    }
                  },
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                key: const Key('sync_retry'),
                label: 'Try again',
                icon: Icons.refresh,
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: () => controller.retry(issue.collection, issue.id),
              ),
            ),
        ],
      ),
    );
  }
}
