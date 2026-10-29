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
import '../license/presentation/license_widgets.dart';
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
    final theme = Theme.of(context);
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
    final license = ref.watch(licenseAccessProvider).value;
    final now = ref.watch(clockProvider)();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(greetingFor(now))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
            sliver: SliverList.list(
              children: [
                Wrap(
                  spacing: AppSpace.md,
                  runSpacing: AppSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      [
                        DateFormat('EEEE, d MMMM').format(now),
                        ?company?.name,
                      ].join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const AppSyncIndicator(),
                    if (license != null) LicenseChip(license),
                  ],
                ),
                const SectionHeader('Today'),
                _MetricGrid(
                  tiles: [
                    MetricTile(
                      key: const Key('dash_today_hours'),
                      label: 'Work hours',
                      value: todayHours == 0
                          ? '—'
                          : MeterReading.format(todayHours),
                      icon: Icons.timer_outlined,
                      caption: todayHours == 0
                          ? 'No work logged today'
                          : 'Logged today',
                      onTap: () => context.go(Routes.work),
                    ),
                    MetricTile(
                      key: const Key('dash_pending'),
                      label: 'Pending approval',
                      value: pending == 0 ? '—' : '$pending',
                      icon: Icons.pending_actions_outlined,
                      caption: pending == 0
                          ? 'Nothing to review'
                          : 'Work logs to review',
                      onTap: () => context.go(Routes.work),
                    ),
                  ],
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
                  const SectionHeader('Billing'),
                  _MetricGrid(
                    tiles: [
                      MetricTile(
                        key: const Key('dash_outstanding'),
                        label: 'Outstanding',
                        value: billing.outstandingPaise == 0
                            ? '—'
                            : Money.format(billing.outstandingPaise),
                        icon: Icons.account_balance_wallet_outlined,
                        caption: billing.unpaidCount == 0
                            ? 'Nothing outstanding'
                            : '${billing.unpaidCount} unpaid'
                                  '${billing.overduePaise > 0 ? ' · ${Money.format(billing.overduePaise)} overdue' : ''}',
                        onTap: () => context.go(Routes.billing),
                      ),
                      MetricTile(
                        key: const Key('dash_received'),
                        label: 'Received this month',
                        value: billing.receivedThisMonthPaise == 0
                            ? '—'
                            : Money.format(billing.receivedThisMonthPaise),
                        icon: Icons.payments_outlined,
                        caption: 'Payments recorded',
                        onTap: () => context.go(Routes.billing),
                      ),
                      MetricTile(
                        key: const Key('dash_invoiced'),
                        label: 'Invoiced this month',
                        value: (invoices?.invoicedPaise ?? 0) == 0
                            ? '—'
                            : Money.format(invoices!.invoicedPaise),
                        icon: Icons.receipt_long_outlined,
                        caption: switch (invoices?.finalizedCount ?? 0) {
                          0 => 'No invoices issued yet',
                          1 => '1 invoice issued',
                          final n => '$n invoices issued',
                        },
                        onTap: () => context.go(Routes.billing),
                      ),
                    ],
                  ),
                ],
                if (showReports) ...[
                  const SectionHeader('Fuel'),
                  _MetricGrid(
                    tiles: [
                      MetricTile(
                        key: const Key('dash_fuel'),
                        label: 'Fuel this month',
                        value: fuel.count == 0
                            ? '—'
                            : Money.format(fuel.totalPaise),
                        icon: Icons.local_gas_station_outlined,
                        caption: fuel.count == 0
                            ? 'No fuel entries yet'
                            : Litres.format(fuel.litresCl),
                        onTap: () => context.go(Routes.fuel),
                      ),
                    ],
                  ),
                ],
                if (showReports) ...[
                  const SizedBox(height: AppSpace.lg),
                  OutlinedButton.icon(
                    key: const Key('dash_reports'),
                    onPressed: () => context.go(Routes.reports),
                    icon: const Icon(Icons.insert_chart_outlined),
                    label: const Text('All reports'),
                  ),
                ],
                const SizedBox(height: AppSpace.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two columns on phones, four on wide screens.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        final width =
            (constraints.maxWidth - AppSpace.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.md,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}
