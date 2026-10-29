import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../application/work_providers.dart';
import '../domain/work_log.dart';
import 'work_widgets.dart';

class WorkLogsScreen extends ConsumerStatefulWidget {
  const WorkLogsScreen({super.key});

  @override
  ConsumerState<WorkLogsScreen> createState() => _WorkLogsScreenState();
}

class _WorkLogsScreenState extends ConsumerState<WorkLogsScreen> {
  WorkFilter _filter = WorkFilter.all;

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(workActorProvider);
    final canCreate = actor != null && WorkLogPolicy.canCreate(actor.role);
    final logs = ref.watch(workLogListProvider(_filter));
    void create() => context.push(Routes.workNew);

    return Scaffold(
      appBar: AppBar(title: const Text('Work logs')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              // Unique per tab: tab branches stay alive side by side.
              heroTag: 'fab_work',
              key: const Key('work_add'),
              onPressed: create,
              icon: const Icon(Icons.add),
              label: const Text('Log work'),
            )
          : null,
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              children: [
                for (final f in WorkFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.sm),
                    child: ChoiceChip(
                      key: Key('work_filter_${f.name}'),
                      label: Text(f.label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (logs) {
              AsyncValue(:final error?) when !logs.hasValue => ErrorView(
                message: '$error',
              ),
              AsyncValue(:final value?) when value.isEmpty =>
                _filter == WorkFilter.all
                    ? EmptyView(
                        icon: Icons.engineering_outlined,
                        title: 'No work logs yet',
                        message: 'Record start and end hour-meter readings; hours are calculated for you.',
                        actionLabel: canCreate ? 'Log work' : null,
                        onAction: canCreate ? create : null,
                      )
                    : EmptyView(
                        icon: Icons.filter_list_off,
                        title: 'Nothing ${_filter.label.toLowerCase()}',
                      ),
              AsyncValue(:final value?) => _GroupedList(logs: value),
              _ => const LoadingView(),
            },
          ),
        ],
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.logs});

  final List<WorkLogView> logs;

  @override
  Widget build(BuildContext context) {
    final items = <Object>[];
    String? lastDate;
    for (final l in logs) {
      if (l.workDate != lastDate) items.add(lastDate = l.workDate);
      items.add(l);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, 96),
      itemCount: items.length,
      itemBuilder: (context, i) => switch (items[i]) {
        final String date => SectionHeader(formatWorkDate(date)),
        final WorkLogView log => Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          child: WorkLogCard(log: log),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class WorkLogCard extends StatelessWidget {
  const WorkLogCard({super.key, required this.log});

  final WorkLogView log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = AppStatusColors.of(context);
    return AppCard(
      key: Key('work_tile_${log.id}'),
      onTap: () => context.push(Routes.workDetail(log.id)),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.machineName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${log.siteName} · ${log.clientName}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    WorkStatusChip(log.status),
                    if (log.entryMode == EntryMode.manual)
                      const StatusChip(
                        label: 'Manual',
                        tone: StatusTone.warning,
                        icon: Icons.edit_note,
                      ),
                    if (log.anomalyFlags.isNotEmpty)
                      const StatusChip(
                        label: 'Check',
                        tone: StatusTone.danger,
                        icon: Icons.warning_amber_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          // Shrinks (and scales its text) with large accessibility fonts.
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    log.inProgress ? 'Running' : formatHours(log.workingHours),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: log.inProgress ? status.info : null,
                    ),
                  ),
                ),
                if (log.operatorName != null)
                  Text(
                    log.operatorName!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
