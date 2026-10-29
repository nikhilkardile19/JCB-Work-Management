import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/sync_indicator.dart';
import '../../evidence/photo_evidence.dart';
import '../../work/application/work_providers.dart';
import '../../work/data/work_log_repository.dart';
import '../../work/presentation/work_widgets.dart';
import '../../license/presentation/license_widgets.dart';
import '../application/fuel_providers.dart';
import '../data/fuel_repository.dart';
import '../domain/fuel_entry.dart';

class FuelDetailScreen extends ConsumerWidget {
  const FuelDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _delete(BuildContext context, WidgetRef ref, FuelView e) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete this fuel entry?',
      message:
          '${Litres.format(e.litresCl)} for ${Money.format(e.totalPaise)} will be removed from fuel reports.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref
          .read(fuelRepositoryProvider)
          .delete(ref.read(workActorProvider)!, e.id);
      if (context.mounted) {
        showAppSnackBar(context, 'Fuel entry deleted');
        context.pop();
      }
    } on FuelException catch (err) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          err.fieldErrors.values.first,
          tone: StatusTone.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(fuelEntryProvider(id));
    final actor = ref.watch(workActorProvider);
    final e = entry.value;
    final canEdit =
        e != null &&
        actor != null &&
        FuelPolicy.canEdit(actor.role, e, actor.userId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel entry'),
        actions: [
          if (canEdit)
            IconButton(
              key: const Key('fuel_edit'),
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(Routes.fuelEdit(id)),
            ),
        ],
      ),
      body: switch (entry) {
        AsyncValue(:final error?) when !entry.hasValue => ErrorView(
          message: '$error',
        ),
        AsyncValue(hasValue: true) when e == null => const EmptyView(
          icon: Icons.local_gas_station_outlined,
          title: 'Fuel entry not found',
          message: 'It may have been deleted.',
        ),
        AsyncValue(hasValue: true) => ListView(
          padding: const EdgeInsets.all(AppSpace.page),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e!.machineName, style: theme.textTheme.titleLarge),
                  Text(
                    DateFormat('EEE, d MMM yyyy, h:mm a').format(e.filledAt),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpace.md),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Money.format(e.totalPaise),
                      key: const Key('fuel_detail_total'),
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                  Text(
                    '${Litres.format(e.litresCl)} × ${Money.format(e.pricePerLitrePaise)}/L',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpace.md),
                  SyncIndicator(state: recordSyncState(e.syncStatus)),
                ],
              ),
            ),
            const SectionHeader('Details'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.local_gas_station_outlined),
                    title: const Text('Pump / supplier'),
                    subtitle: Text(e.pumpName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: const Text('Allocated to'),
                    subtitle: Text(
                      e.clientName == null
                          ? 'Not allocated'
                          : [e.clientName!, ?e.siteName].join(' · '),
                    ),
                  ),
                  if (e.notes != null)
                    ListTile(
                      leading: const Icon(Icons.notes_outlined),
                      title: const Text('Notes'),
                      subtitle: Text(e.notes!),
                    ),
                ],
              ),
            ),
            const SectionHeader('Receipt'),
            AppCard(
              child: e.receipt == null
                  ? const Text('No receipt photo was taken for this fill.')
                  : Row(
                      children: [
                        EvidencePhoto(path: e.receipt!.photoPath),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            evidenceMeta(
                              capturedAt: e.receipt!.capturedAt,
                              status: e.receipt!.locationStatus,
                              lat: e.receipt!.lat,
                              lng: e.receipt!.lng,
                              accuracy: e.receipt!.accuracy,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
            ),
            if (canEdit) ...[
              const SizedBox(height: AppSpace.xl),
              AppButton(
                key: const Key('fuel_delete'),
                label: 'Delete fuel entry',
                icon: Icons.delete_outline,
                variant: AppButtonVariant.secondary,
                onPressed: () => _delete(context, ref, e),
              ),
            ],
            const SectionHeader('History'),
            for (final h
                in ref.watch(fuelHistoryProvider(id)).value ??
                    const <WorkHistoryEntry>[])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.circle, size: 12),
                title: Text(switch (h.action) {
                  'create' => 'Recorded',
                  'update' => 'Edited',
                  'delete' => 'Deleted',
                  _ => h.action,
                }),
                subtitle: Text(
                  '${h.actorId == actor?.userId ? 'You' : 'Team member'} · ${formatCaptureTime(h.at)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpace.xl),
          ],
        ),
        _ => const LoadingView(),
      },
    );
  }
}
