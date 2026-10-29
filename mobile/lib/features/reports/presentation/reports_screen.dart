import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../work/application/work_providers.dart';
import '../application/reports_providers.dart';
import '../domain/reports.dart';
import 'report_widgets.dart';

/// Reports hub: one period for all reports, each with its headline figure.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(workActorProvider);
    if (actor == null || !ReportPolicy.canView(actor.role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: const EmptyView(
          icon: Icons.lock_outline,
          title: 'Reports are not available for your role',
          message: 'Ask the company owner or an admin if you need them.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.sm,
          AppSpace.page,
          AppSpace.xxl,
        ),
        children: [
          const ReportPeriodBar(),
          const SectionHeader('Reports'),
          for (final k in ReportKind.values) ...[
            _ReportCard(kind: k),
            const SizedBox(height: AppSpace.sm),
          ],
          const SectionHeader('Troubleshooting'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              key: const Key('report_device_sync'),
              leading: const Icon(Icons.phonelink_setup_outlined),
              title: const Text('Device and sync status'),
              subtitle: const Text(
                'Upload queue, sync problems, this phone and recent errors',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.sync),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.kind});

  final ReportKind kind;

  String? _headline(WidgetRef ref) => switch (kind) {
    ReportKind.work => switch (ref.watch(workReportProvider).value) {
      final r? =>
        '${MeterReading.format(r.hours)} approved'
            '${r.pending.isEmpty ? '' : ' · ${r.pending.length} waiting'}',
      null => null,
    },
    ReportKind.meter => switch (ref.watch(meterReportProvider).value) {
      final r? =>
        '${r.machines.length} machines · ${r.gapCount} '
            '${r.gapCount == 1 ? 'break' : 'breaks'} in readings',
      null => null,
    },
    ReportKind.fuel => switch (ref.watch(fuelReportProvider).value) {
      final r? =>
        '${Money.format(r.totalPaise)} · ${Litres.format(r.litresCl)}',
      null => null,
    },
    ReportKind.invoices => switch (ref.watch(invoiceRegisterProvider).value) {
      final r? =>
        '${Money.format(r.invoicedPaise)} · ${r.finalizedCount} '
            '${r.finalizedCount == 1 ? 'invoice' : 'invoices'}',
      null => null,
    },
    ReportKind.payments => switch (ref.watch(paymentRegisterProvider).value) {
      final r? => '${Money.format(r.totalPaise)} received',
      null => null,
    },
    ReportKind.outstanding => switch (ref
        .watch(outstandingReportProvider)
        .value) {
      final r? =>
        '${Money.format(r.totalPaise)} · '
            '${Money.format(r.overduePaise)} overdue',
      null => null,
    },
    ReportKind.manual => switch (ref.watch(manualReportProvider).value) {
      final r? => '${r.manualCount} manual · ${r.flaggedCount} with warnings',
      null => null,
    },
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final headline = _headline(ref);
    return AppCard(
      key: Key('report_${kind.name}'),
      onTap: () => context.push(Routes.report(kind)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(reportIcon(kind)),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kind.title, style: theme.textTheme.titleMedium),
                Text(kind.description, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpace.xs),
                Text(
                  headline ?? ' ',
                  key: Key('report_${kind.name}_headline'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
