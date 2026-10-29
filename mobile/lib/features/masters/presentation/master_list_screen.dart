import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/state_views.dart';
import '../application/masters_providers.dart';
import '../data/masters_repository.dart';
import '../domain/master_kind.dart';
import '../domain/master_validators.dart';

class MasterListScreen extends ConsumerStatefulWidget {
  const MasterListScreen({super.key, required this.kind});

  final MasterKind kind;

  @override
  ConsumerState<MasterListScreen> createState() => _MasterListScreenState();
}

class _MasterListScreenState extends ConsumerState<MasterListScreen> {
  String _search = '';
  StatusFilter _status = StatusFilter.active;

  MasterKind get kind => widget.kind;

  @override
  Widget build(BuildContext context) {
    final canManage = ref.watch(canManageMastersProvider);
    final records = ref.watch(
      masterListProvider((
        kind: kind,
        search: _search,
        status: _status,
        clientId: null,
      )),
    );
    void add() => context.push(Routes.masterNew(kind));

    return Scaffold(
      appBar: AppBar(title: Text(kind.plural)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              // Unique per tab: tab branches stay alive side by side.
              heroTag: 'fab_master_${kind.slug}',
              key: const Key('master_add'),
              onPressed: add,
              icon: const Icon(Icons.add),
              label: Text('Add ${kind.singular.toLowerCase()}'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.page,
              0,
              AppSpace.page,
              AppSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchField(
                  key: const Key('master_search'),
                  hint: 'Search ${kind.plural.toLowerCase()}',
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: AppSpace.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<StatusFilter>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: StatusFilter.active,
                        label: Text('Active'),
                      ),
                      ButtonSegment(
                        value: StatusFilter.inactive,
                        label: Text('Inactive'),
                      ),
                      ButtonSegment(
                        value: StatusFilter.all,
                        label: Text('All'),
                      ),
                    ],
                    selected: {_status},
                    onSelectionChanged: (s) =>
                        setState(() => _status = s.first),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (records) {
              AsyncValue(:final error?) when !records.hasValue => ErrorView(
                message: 'Could not load ${kind.plural.toLowerCase()}. $error',
              ),
              AsyncValue(:final value?) when value.isEmpty =>
                _search.trim().isNotEmpty
                    ? EmptyView(
                        icon: Icons.search_off,
                        title: 'No matches',
                        message:
                            'No ${kind.plural.toLowerCase()} match "${_search.trim()}".',
                      )
                    : _status == StatusFilter.inactive
                    ? EmptyView(
                        icon: kind.icon,
                        title: 'No inactive ${kind.plural.toLowerCase()}',
                      )
                    : EmptyView(
                        icon: kind.icon,
                        title: 'No ${kind.plural.toLowerCase()} yet',
                        message: kind.emptyMessage,
                        actionLabel: canManage
                            ? 'Add ${kind.singular.toLowerCase()}'
                            : null,
                        onAction: canManage ? add : null,
                      ),
              AsyncValue(:final value?) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  0,
                  AppSpace.page,
                  96, // clear the FAB
                ),
                itemCount: value.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
                itemBuilder: (context, i) => MasterTile(record: value[i]),
              ),
              _ => const LoadingView(),
            },
          ),
        ],
      ),
    );
  }
}

/// Subtitle for a record in lists: client (for sites) and key fields.
String? masterSubtitle(MasterRecord r) {
  final parts = [
    ?r.clientName,
    for (final k in r.kind.subtitleKeys)
      ?formatMasterField(r.kind.field(k), r[k]),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

class MasterTile extends StatelessWidget {
  const MasterTile({super.key, required this.record});

  final MasterRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = masterSubtitle(record);
    return AppCard(
      key: Key('master_tile_${record.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      onTap: () => context.push(Routes.masterDetail(record.kind, record.id)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: .18),
            foregroundColor: theme.colorScheme.onSurface,
            child: Icon(record.kind.icon, size: AppSize.iconSm + 2),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!record.isActive) ...[
            const SizedBox(width: AppSpace.sm),
            const StatusChip(label: 'Inactive'),
          ],
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
