import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/sync_indicator.dart';
import '../../license/presentation/license_widgets.dart';
import '../application/masters_providers.dart';
import '../data/masters_repository.dart';
import '../domain/master_kind.dart';
import '../domain/master_validators.dart';
import 'master_list_screen.dart';

class MasterDetailScreen extends ConsumerWidget {
  const MasterDetailScreen({super.key, required this.kind, required this.id});

  final MasterKind kind;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(masterRecordProvider((kind, id)));
    final canManage = ref.watch(canManageMastersProvider);
    final r = record.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(kind.singular),
        actions: [
          if (canManage && r != null)
            IconButton(
              key: const Key('master_edit'),
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(Routes.masterEdit(kind, id)),
            ),
        ],
      ),
      body: switch (record) {
        AsyncValue(:final error?) when !record.hasValue => ErrorView(
          message: '$error',
        ),
        AsyncValue(hasValue: true) when r == null => EmptyView(
          icon: kind.icon,
          title: '${kind.singular} not found',
          message: 'It may have been deleted.',
        ),
        AsyncValue(hasValue: true) => _Body(record: r!, canManage: canManage),
        _ => const LoadingView(),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.record, required this.canManage});

  final MasterRecord record;
  final bool canManage;

  MasterKind get kind => record.kind;

  MasterScope? _scope(WidgetRef ref) => ref.read(masterScopeProvider);

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    final deactivate = record.isActive;
    if (deactivate) {
      final ok = await showConfirmDialog(
        context,
        title: 'Deactivate ${record.name}?',
        message: "It won't be offered for new entries. Existing records keep it, and you can reactivate it any time.",
        confirmLabel: 'Deactivate',
      );
      if (!ok) return;
    }
    await ref
        .read(mastersRepositoryProvider)
        .setActive(kind, _scope(ref)!, record.id, active: !deactivate);
    if (context.mounted) {
      showAppSnackBar(
        context,
        '${record.name} ${deactivate ? 'deactivated' : 'reactivated'}',
        tone: StatusTone.success,
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    final repo = ref.read(mastersRepositoryProvider);
    final scope = _scope(ref)!;
    final refs = await repo.referenceCount(kind, scope.companyId, record.id);
    if (!context.mounted) return;
    if (refs > 0) {
      final deactivate = await showConfirmDialog(
        context,
        title: "Can't delete ${record.name}",
        message:
            'It is used by $refs ${refs == 1 ? 'record' : 'records'}. Deactivate it instead to hide it from new entries.',
        confirmLabel: 'Deactivate',
        cancelLabel: 'Keep',
      );
      if (deactivate && record.isActive && context.mounted) {
        await repo.setActive(kind, scope, record.id, active: false);
      }
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${record.name}?',
      message: 'This removes it from your ${kind.plural.toLowerCase()}.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await repo.delete(kind, scope, record.id);
      if (context.mounted) {
        showAppSnackBar(context, '${record.name} deleted');
        context.pop();
      }
    } on MasterInUseException catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message, tone: StatusTone.warning);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rows = [
      for (final f in kind.fields.where((f) => f.key != 'name'))
        if ((f.type == FieldType.clientRef
                ? record.clientName
                : formatMasterField(f, record[f.key]))
            case final value?)
          (f, value),
    ];
    final updated = DateFormat('d MMM yyyy, h:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(record.updatedAt));

    return ListView(
      padding: const EdgeInsets.all(AppSpace.page),
      children: [
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: AppPalette.graphite,
                child: Icon(kind.icon),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      children: [
                        StatusChip(
                          label: record.isActive ? 'Active' : 'Inactive',
                          tone: record.isActive
                              ? StatusTone.success
                              : StatusTone.neutral,
                        ),
                        SyncIndicator(
                          state: recordSyncState(record.syncStatus),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (rows.isNotEmpty)
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (f, value) in rows)
                  ListTile(
                    leading: Icon(f.icon),
                    title: Text(f.label),
                    subtitle: Text(value, style: theme.textTheme.bodyLarge),
                    trailing: f.type == FieldType.clientRef
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: f.type == FieldType.clientRef
                        ? () => context.push(
                            Routes.masterDetail(
                              MasterKind.clients,
                              record.clientId!,
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        if (kind == MasterKind.clients)
          _ClientSites(clientId: record.id, canManage: canManage),
        const SizedBox(height: AppSpace.lg),
        Text(
          'Last updated $updated',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpace.xl),
          AppButton(
            key: const Key('master_toggle_active'),
            label: record.isActive ? 'Deactivate' : 'Reactivate',
            icon: record.isActive
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            variant: AppButtonVariant.secondary,
            onPressed: () => _toggleActive(context, ref),
          ),
          const SizedBox(height: AppSpace.md),
          TextButton.icon(
            key: const Key('master_delete'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline),
            label: Text('Delete ${kind.singular.toLowerCase()}'),
            onPressed: () => _delete(context, ref),
          ),
        ],
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }
}

class _ClientSites extends ConsumerWidget {
  const _ClientSites({required this.clientId, required this.canManage});

  final String clientId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sites =
        ref
            .watch(
              masterListProvider((
                kind: MasterKind.sites,
                search: '',
                status: StatusFilter.all,
                clientId: clientId,
              )),
            )
            .value ??
        const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Sites (${sites.length})',
          trailing: canManage
              ? TextButton.icon(
                  key: const Key('client_add_site'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add site'),
                  onPressed: () => context.push(
                    Routes.masterNew(MasterKind.sites, clientId: clientId),
                  ),
                )
              : null,
        ),
        if (sites.isEmpty)
          Text(
            'No sites for this client yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final s in sites) ...[
            MasterTile(record: s),
            const SizedBox(height: AppSpace.sm),
          ],
      ],
    );
  }
}
