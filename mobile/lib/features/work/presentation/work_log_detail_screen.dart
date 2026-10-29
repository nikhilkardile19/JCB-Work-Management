import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/sync_indicator.dart';
import '../../license/presentation/license_widgets.dart';
import '../application/work_providers.dart';
import '../data/work_log_repository.dart';
import '../domain/work_log.dart';
import 'work_widgets.dart';

class WorkLogDetailScreen extends ConsumerWidget {
  const WorkLogDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(workLogProvider(id));
    final actor = ref.watch(workActorProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Work log')),
      body: switch (log) {
        AsyncValue(:final error?) when !log.hasValue => ErrorView(
          message: '$error',
        ),
        AsyncValue(value: final v?) when actor != null => _Body(
          log: v,
          actor: actor,
        ),
        AsyncValue(hasValue: true) => const EmptyView(
          icon: Icons.engineering_outlined,
          title: 'Work log not found',
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.log, required this.actor});

  final WorkLogView log;
  final WorkActor actor;

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(WorkLogRepository repo) action,
    String done,
  ) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    try {
      await action(ref.read(workLogRepositoryProvider));
      if (context.mounted) {
        showAppSnackBar(context, done, tone: StatusTone.success);
      }
    } on WorkLogException catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          e.fieldErrors.values.first,
          tone: StatusTone.danger,
        );
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    final reason = await showReasonDialog(
      context,
      title: 'Reject work log',
      label: 'Reason',
      message:
          'The person who logged it will see this and can fix and resubmit.',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    await _act(
      context,
      ref,
      (r) => r.reject(actor, log.id, reason: reason),
      'Work log rejected',
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    final approved = log.status == WorkLogStatus.approved;
    final reason = await showReasonDialog(
      context,
      title: 'Cancel work log?',
      label: approved ? 'Reason' : 'Reason (optional)',
      message: 'Cancelled logs are kept for the record but not billed.',
      confirmLabel: 'Cancel log',
      required: approved,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    await _act(
      context,
      ref,
      (r) => r.cancel(actor, log.id, reason: reason),
      'Work log cancelled',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final role = actor.role;
    final canEdit =
        WorkLogPolicy.canEdit(role, log, actor.userId) &&
        log.status != WorkLogStatus.submitted;
    final canReview = WorkLogPolicy.canReview(role, log);
    final canCorrect = WorkLogPolicy.canCorrect(role, log);
    final canCancel = WorkLogPolicy.canCancel(role, log, actor.userId);
    final details = <(IconData, String, String)>[
      (Icons.groups_outlined, 'Client', log.clientName),
      (Icons.location_on_outlined, 'Site', log.siteName),
      (Icons.badge_outlined, 'Operator', log.operatorName ?? 'Not recorded'),
      if (log.notes != null) (Icons.notes_outlined, 'Notes', log.notes!),
      if (log.entryMode == EntryMode.manual && log.manualReason != null)
        (Icons.edit_note, 'Manual entry reason', log.manualReason!),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpace.page),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.machineName, style: theme.textTheme.titleLarge),
              Text(
                formatWorkDate(log.workDate),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                log.inProgress ? 'In progress' : formatHours(log.workingHours),
                key: const Key('detail_hours'),
                style: theme.textTheme.displaySmall,
              ),
              if (!log.inProgress)
                Text(
                  '${MeterReading.format(log.start.reading!)} → ${MeterReading.format(log.end.reading!)}',
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  WorkStatusChip(log.status),
                  StatusChip(
                    label: log.entryMode == EntryMode.photo
                        ? 'Photo evidence'
                        : 'Manual entry',
                    tone: log.entryMode == EntryMode.photo
                        ? StatusTone.success
                        : StatusTone.warning,
                    icon: log.entryMode == EntryMode.photo
                        ? Icons.photo_camera_outlined
                        : Icons.edit_note,
                  ),
                  SyncIndicator(state: recordSyncState(log.syncStatus)),
                ],
              ),
            ],
          ),
        ),
        if (log.statusReason != null &&
            (log.status == WorkLogStatus.rejected ||
                log.status == WorkLogStatus.cancelled)) ...[
          const SizedBox(height: AppSpace.md),
          AppCard(
            color: AppStatusColors.of(context).danger.withValues(alpha: .1),
            child: Text('${log.status.label}: ${log.statusReason}'),
          ),
        ],
        for (final f in log.anomalyFlags) ...[
          const SizedBox(height: AppSpace.sm),
          AppCard(
            color: AppStatusColors.of(context).warning.withValues(alpha: .12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text(_flagText(f))),
              ],
            ),
          ),
        ],
        const SectionHeader('Readings'),
        AppCard(
          child: Column(
            children: [
              MeterReadingTile(title: 'Start', capture: log.start),
              const Divider(height: AppSpace.xl),
              MeterReadingTile(title: 'End', capture: log.end),
            ],
          ),
        ),
        const SectionHeader('Details'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (icon, label, value) in details)
                ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  subtitle: Text(value),
                ),
            ],
          ),
        ),
        if (canReview) ...[
          const SizedBox(height: AppSpace.xl),
          AppButton(
            key: const Key('work_approve'),
            label: 'Approve',
            icon: Icons.check_circle_outline,
            onPressed: () => _act(
              context,
              ref,
              (r) => r.approve(actor, log.id),
              'Work log approved',
            ),
          ),
          const SizedBox(height: AppSpace.md),
          AppButton(
            key: const Key('work_reject'),
            label: 'Reject',
            icon: Icons.cancel_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () => _reject(context, ref),
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: AppSpace.md),
          AppButton(
            key: const Key('work_edit'),
            label: log.inProgress ? 'Add end reading' : 'Edit',
            icon: Icons.edit_outlined,
            variant: canReview
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            onPressed: () => context.push(Routes.workEdit(log.id)),
          ),
        ],
        if (canCorrect) ...[
          const SizedBox(height: AppSpace.md),
          AppButton(
            key: const Key('work_correct'),
            label: 'Correct',
            icon: Icons.history_edu,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push(Routes.workCorrect(log.id)),
          ),
        ],
        if (canCancel) ...[
          const SizedBox(height: AppSpace.sm),
          TextButton.icon(
            key: const Key('work_cancel'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            icon: const Icon(Icons.block),
            label: const Text('Cancel work log'),
            onPressed: () => _cancel(context, ref),
          ),
        ],
        const SectionHeader('History'),
        _History(id: log.id, me: actor.userId),
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }

  static String _flagText(AnomalyFlag f) => switch (f) {
    AnomalyFlag.meterBackwards =>
      'Start reading was below the previous reading (confirmed by the user).',
    AnomalyFlag.highHours =>
      'Unusually long working hours (confirmed by the user).',
    AnomalyFlag.duplicateDay =>
      'Another log exists for this machine on the same day.',
  };
}

class _History extends ConsumerWidget {
  const _History({required this.id, required this.me});

  final String id;
  final String me;

  static String _label(String action) => switch (action) {
    'create' => 'Created',
    'update' => 'Edited',
    'submit' => 'Submitted for approval',
    'submit_approve' => 'Submitted and approved',
    'approve' => 'Approved',
    'reject' => 'Rejected',
    'correct' => 'Corrected',
    'cancel' => 'Cancelled',
    _ => action,
  };

  static String _describe(Map<String, dynamic>? d) {
    if (d == null) return '';
    final parts = <String>[];
    final reason = d['reason'];
    if (reason is String) parts.add('Reason: $reason');
    for (final key in ['startReading', 'endReading']) {
      final change = d[key];
      if (change is Map && change['from'] is int && change['to'] is int) {
        parts.add(
          '${key == 'startReading' ? 'Start' : 'End'}: '
          '${MeterReading.format(change['from'] as int)} → ${MeterReading.format(change['to'] as int)}',
        );
      }
    }
    final mr = d['manualReason'];
    if (mr is String) parts.add('Manual entry: $mr');
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(workHistoryProvider(id)).value ?? const [];
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final e in entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.circle, size: 12),
            title: Text(_label(e.action)),
            subtitle: Text(
              [
                '${e.actorId == me ? 'You' : 'Team member'} · ${formatCaptureTime(e.at)}',
                if (_describe(e.details) case final d when d.isNotEmpty) d,
              ].join('\n'),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
