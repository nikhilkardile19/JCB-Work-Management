import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../work/application/work_providers.dart';
import '../../work/presentation/work_widgets.dart';
import '../application/fuel_providers.dart';
import '../domain/fuel_entry.dart';

/// Fuel tab: period summary with per-machine breakdown, then entries.
class FuelScreen extends ConsumerStatefulWidget {
  const FuelScreen({super.key});

  @override
  ConsumerState<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends ConsumerState<FuelScreen> {
  FuelPeriod _period = FuelPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(workActorProvider);
    final canRecord = actor != null && FuelPolicy.canRecord(actor.role);
    final entries = ref.watch(fuelListProvider(_period));
    final summary = ref.watch(fuelSummaryProvider(_period)).value;
    void add() => context.push(Routes.fuelNew);

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel')),
      floatingActionButton: canRecord
          ? FloatingActionButton.extended(
              // Unique per tab: tab branches stay alive side by side.
              heroTag: 'fab_fuel',
              key: const Key('fuel_add'),
              onPressed: add,
              icon: const Icon(Icons.add),
              label: const Text('Add fuel'),
            )
          : null,
      body: switch (entries) {
        AsyncValue(:final error?) when !entries.hasValue => ErrorView(
          message: '$error',
        ),
        AsyncValue(:final value?) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              sliver: SliverList.list(
                children: [
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      for (final p in FuelPeriod.values)
                        ChoiceChip(
                          key: Key('fuel_period_${p.name}'),
                          label: Text(p.label),
                          selected: _period == p,
                          onSelected: (_) => setState(() => _period = p),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  _SummaryCard(summary: summary ?? FuelSummary.empty),
                ],
              ),
            ),
            if (value.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  icon: Icons.local_gas_station_outlined,
                  title: 'No fuel ${_period.label.toLowerCase()}',
                  message: 'Record each fill with litres, price and the receipt photo.',
                  actionLabel: canRecord ? 'Add fuel' : null,
                  onAction: canRecord ? add : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  0,
                  AppSpace.page,
                  96,
                ),
                sliver: SliverList.list(
                  children: [
                    for (final (i, e) in value.indexed) ...[
                      if (i == 0 || value[i - 1].fuelDate != e.fuelDate)
                        SectionHeader(formatWorkDate(e.fuelDate)),
                      FuelCard(entry: e),
                      const SizedBox(height: AppSpace.sm),
                    ],
                  ],
                ),
              ),
          ],
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final FuelSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avg = summary.averagePricePaise;
    final maxSpend = summary.byMachine.isEmpty
        ? 0
        : summary.byMachine.first.totalPaise;
    return AppCard(
      key: const Key('fuel_summary'),
      color: theme.colorScheme.primary.withValues(alpha: .12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fuel cost', style: theme.textTheme.labelLarge),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(summary.totalPaise),
              style: theme.textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            [
              Litres.format(summary.litresCl),
              '${summary.count} ${summary.count == 1 ? 'fill' : 'fills'}',
              if (avg != null) 'avg ${Money.format(avg)}/L',
            ].join(' · '),
            style: theme.textTheme.bodyMedium,
          ),
          if (summary.byMachine.length > 1) ...[
            const SizedBox(height: AppSpace.lg),
            for (final m in summary.byMachine) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      m.machineName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    Money.format(m.totalPaise),
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: maxSpend == 0 ? 0 : m.totalPaise / maxSpend,
                  minHeight: 6,
                  semanticsLabel: '${m.machineName} fuel cost',
                  semanticsValue: Money.format(m.totalPaise),
                ),
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ],
        ],
      ),
    );
  }
}

class FuelCard extends StatelessWidget {
  const FuelCard({super.key, required this.entry});

  final FuelView entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      key: Key('fuel_tile_${entry.id}'),
      onTap: () => context.push(Routes.fuelDetail(entry.id)),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.machineName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.pumpName} · ${DateFormat('h:mm a').format(entry.filledAt)}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    if (entry.receipt == null)
                      const StatusChip(
                        label: 'No receipt',
                        tone: StatusTone.warning,
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      const StatusChip(
                        label: 'Receipt',
                        tone: StatusTone.success,
                        icon: Icons.receipt_long_outlined,
                      ),
                    if (entry.siteName != null)
                      StatusChip(
                        label: entry.siteName!,
                        icon: Icons.location_on_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    Money.format(entry.totalPaise),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    Litres.format(entry.litresCl),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
