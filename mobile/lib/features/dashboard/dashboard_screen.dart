import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/units.dart';
import '../../core/widgets/app_card.dart';
import '../billing/application/billing_providers.dart';
import '../billing/domain/invoice.dart';
import '../company/application/company_providers.dart';
import '../fuel/application/fuel_providers.dart';
import '../fuel/domain/fuel_entry.dart';
import '../license/application/license_controller.dart';
import '../reports/application/reports_providers.dart';
import '../reports/domain/reports.dart';
import '../reports/presentation/report_widgets.dart';
import '../sync/presentation/sync_screen.dart';
import '../work/application/work_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static String greetingFor(DateTime now) => switch (now.hour) {
    < 12 => 'Good morning',
    < 17 => 'Good afternoon',
    _ => 'Good evening',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(currentMembershipProvider);
    final company = membership?.company;
    final role = membership?.role;
    // Money figures only for roles that may see billing (sprint doc §3.2).
    final showBilling = role != null && InvoicePolicy.canView(role);
    final showReports = role != null && ReportPolicy.canView(role);
    final todayHours = ref.watch(todayHoursProvider).value ?? 0;
    final pending = ref.watch(pendingApprovalCountProvider).value ?? 0;
    final billing = ref.watch(billingSummaryProvider);
    final invoices = ref.watch(monthInvoiceRegisterProvider);
    final machines =
        ref.watch(monthWorkReportProvider).value?.by(WorkGrouping.machine) ??
        const <ReportGroup>[];
    final fuel =
        ref.watch(fuelSummaryProvider(FuelPeriod.thisMonth)).value ??
        FuelSummary.empty;
    final now = ref.watch(clockProvider)();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.lg,
          AppSpace.page,
          AppSpace.xxl,
        ),
        children: [
          _Header(
            greeting: greetingFor(now),
            subtitle: [
              DateFormat('EEEE, d MMMM').format(now),
              ?company?.name,
            ].join(' · '),
          ),
          const SectionHeader('Today'),
          AppCard(
            padding: EdgeInsets.zero,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Stat(
                      key: const Key('dash_today_hours'),
                      value: todayHours == 0
                          ? '—'
                          : MeterReading.format(todayHours),
                      label: 'Work hours',
                      onTap: () => context.go(Routes.work),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _Stat(
                      key: const Key('dash_pending'),
                      value: pending == 0 ? '—' : '$pending',
                      label: 'Pending approval',
                      onTap: () => context.go(Routes.work),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (machines.isNotEmpty) ...[
            SectionHeader(
              'Machines this month',
              trailing: showReports
                  ? TextButton(
                      key: const Key('dash_work_report'),
                      onPressed: () =>
                          context.go(Routes.report(ReportKind.work)),
                      child: const Text('Work report'),
                    )
                  : null,
            ),
            ReportGroupList(
              key: const Key('dash_machines'),
              groups: machines.take(5).toList(),
              format: MeterReading.format,
              countLabel: 'log',
            ),
          ],
          if (showBilling) ...[
            SectionHeader(showReports ? 'Billing & fuel' : 'Billing'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _StatRow(
                    key: const Key('dash_outstanding'),
                    label: 'Outstanding',
                    value: billing.outstandingPaise == 0
                        ? '—'
                        : Money.format(billing.outstandingPaise),
                    caption: billing.unpaidCount == 0
                        ? null
                        : '${billing.unpaidCount} unpaid'
                              '${billing.overduePaise > 0 ? ' · ${Money.format(billing.overduePaise)} overdue' : ''}',
                    onTap: () => context.go(Routes.billing),
                  ),
                  const Divider(),
                  _StatRow(
                    key: const Key('dash_received'),
                    label: 'Received this month',
                    value: billing.receivedThisMonthPaise == 0
                        ? '—'
                        : Money.format(billing.receivedThisMonthPaise),
                    onTap: () => context.go(Routes.billing),
                  ),
                  const Divider(),
                  _StatRow(
                    key: const Key('dash_invoiced'),
                    label: 'Invoiced this month',
                    value: (invoices?.invoicedPaise ?? 0) == 0
                        ? '—'
                        : Money.format(invoices!.invoicedPaise),
                    caption: switch (invoices?.finalizedCount ?? 0) {
                      0 => null,
                      1 => '1 invoice issued',
                      final n => '$n invoices issued',
                    },
                    onTap: () => context.go(Routes.billing),
                  ),
                  if (showReports) ...[
                    const Divider(),
                    _StatRow(
                      key: const Key('dash_fuel'),
                      label: 'Fuel this month',
                      value: fuel.count == 0
                          ? '—'
                          : Money.format(fuel.totalPaise),
                      caption: fuel.count == 0
                          ? null
                          : Litres.format(fuel.litresCl),
                      onTap: () => context.go(Routes.fuel),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (showReports) ...[
            const SizedBox(height: AppSpace.xl),
            OutlinedButton.icon(
              key: const Key('dash_reports'),
              onPressed: () => context.go(Routes.reports),
              icon: const Icon(Icons.insert_chart_outlined),
              label: const Text('All reports'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Greeting, sync state and date. Replaces a large app bar, which left a
/// tall empty band above the content.
class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.subtitle});

  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The sync chip drops below the greeting when they don't fit on one
        // line (small phones, large text).
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          children: [
            Semantics(
              header: true,
              child: Text(greeting, style: theme.textTheme.headlineSmall),
            ),
            const AppSyncIndicator(),
          ],
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Big number over a label; one half of the Today card.
class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shrinks rather than wraps at large text sizes.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label (and optional caption) on the left, figure on the right.
class _StatRow extends StatelessWidget {
  const _StatRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyLarge),
                    if (caption != null)
                      Text(
                        caption!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              // Caps the figure so a long amount at large text sizes shrinks
              // instead of pushing the label out of the row.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * .55,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
