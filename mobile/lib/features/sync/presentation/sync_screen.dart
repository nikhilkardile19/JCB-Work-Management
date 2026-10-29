import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/sync_indicator.dart';
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
