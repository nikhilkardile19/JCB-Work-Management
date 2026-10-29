import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../license/application/license_controller.dart';
import '../application/reports_providers.dart';
import '../domain/reports.dart';
import 'report_document.dart';

IconData reportIcon(ReportKind k) => switch (k) {
  ReportKind.work => Icons.timer_outlined,
  ReportKind.meter => Icons.speed_outlined,
  ReportKind.fuel => Icons.local_gas_station_outlined,
  ReportKind.invoices => Icons.receipt_long_outlined,
  ReportKind.payments => Icons.payments_outlined,
  ReportKind.outstanding => Icons.account_balance_wallet_outlined,
  ReportKind.manual => Icons.edit_note_outlined,
};

/// Period presets plus a custom date range, shared by all reports.
class ReportPeriodBar extends ConsumerWidget {
  const ReportPeriodBar({super.key});

  Future<void> _pickCustom(BuildContext context, WidgetRef ref) async {
    final now = ref.read(clockProvider)();
    final current = ref.read(reportRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(
        start: DateTime.parse(current.from),
        end: DateTime.parse(current.to),
      ),
      helpText: 'Report period',
    );
    if (picked != null) ref.read(reportRangeProvider.notifier).custom(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportRangeProvider);
    final notifier = ref.read(reportRangeProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final p in ReportPreset.values)
              ChoiceChip(
                key: Key('report_period_${p.name}'),
                label: Text(p == ReportPreset.custom ? 'Custom…' : p.label),
                selected: range.preset == p,
                onSelected: (_) => p == ReportPreset.custom
                    ? _pickCustom(context, ref)
                    : notifier.preset(p),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          describeRange(range),
          key: const Key('report_range'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

/// Headline figure with supporting totals.
class ReportTotals extends StatelessWidget {
  const ReportTotals({
    super.key,
    required this.label,
    required this.value,
    this.rows = const [],
  });

  final String label;
  final String value;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      color: theme.colorScheme.primary.withValues(alpha: .12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              key: const Key('report_headline'),
              style: theme.textTheme.displaySmall,
            ),
          ),
          if (rows.isNotEmpty) const SizedBox(height: AppSpace.sm),
          for (final (l, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(l)),
                    const SizedBox(width: AppSpace.md),
                    Flexible(
                      child: Text(
                        v,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A breakdown with proportional bars, largest first.
class ReportGroupList extends StatelessWidget {
  const ReportGroupList({
    super.key,
    required this.groups,
    required this.format,
    required this.countLabel,
    this.formatExtra,
    this.formatLabel,
  });

  final List<ReportGroup> groups;
  final String Function(int) format;
  final String Function(int)? formatExtra;
  final String Function(String)? formatLabel;

  /// Singular noun for [ReportGroup.count], e.g. "log".
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const ReportNotice('Nothing in this period.');
    final theme = Theme.of(context);
    final max = groups.map((g) => g.value).fold(0, (a, v) => v > a ? v : a);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, g) in groups.indexed) ...[
            if (i > 0) const Divider(),
            MergeSemantics(
              child: Padding(
                key: Key('report_group_${g.key}'),
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatLabel?.call(g.label) ?? g.label,
                                style: theme.textTheme.titleSmall,
                              ),
                              if (g.detail != null)
                                Text(
                                  g.detail!,
                                  style: theme.textTheme.bodySmall,
                                ),
                              Text(
                                [
                                  '${g.count} $countLabel${g.count == 1 ? '' : 's'}',
                                  if (formatExtra != null)
                                    formatExtra!(g.extra),
                                ].join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Text(
                          format(g.value),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: max == 0 ? 0 : g.value / max,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline message inside a report list (empty, loading or error).
class ReportNotice extends StatelessWidget {
  const ReportNotice(
    this.message, {
    super.key,
    this.icon = Icons.info_outline,
    this.tone = StatusTone.neutral,
  });

  final String message;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Icon(icon, color: AppStatusColors.of(context).forTone(tone)),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

/// Choice chips for a breakdown dimension.
class ReportGroupingChips<T> extends StatelessWidget {
  const ReportGroupingChips({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.sm,
    runSpacing: AppSpace.sm,
    children: [
      for (final v in values)
        ChoiceChip(
          key: Key('report_by_${label(v)}'),
          label: Text(label(v)),
          selected: v == selected,
          onSelected: (_) => onSelected(v),
        ),
    ],
  );
}
