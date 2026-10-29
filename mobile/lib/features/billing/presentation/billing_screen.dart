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
import '../../work/domain/work_log.dart';
import '../application/billing_providers.dart';
import '../domain/invoice.dart';

(StatusTone, IconData) invoiceStateLook(InvoiceState s) => switch (s) {
  InvoiceState.draft => (StatusTone.info, Icons.edit_document),
  InvoiceState.unpaid => (StatusTone.warning, Icons.schedule),
  InvoiceState.partiallyPaid => (StatusTone.warning, Icons.pie_chart_outline),
  InvoiceState.paid => (StatusTone.success, Icons.check_circle_outline),
  InvoiceState.overdue => (StatusTone.danger, Icons.error_outline),
  InvoiceState.cancelled => (StatusTone.neutral, Icons.block),
};

class InvoiceStateChip extends StatelessWidget {
  const InvoiceStateChip(this.state, {super.key});

  final InvoiceState state;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = invoiceStateLook(state);
    return StatusChip(label: state.label, tone: tone, icon: icon);
  }
}

String formatDateKey(String key) =>
    DateFormat('d MMM yyyy').format(DateTime.parse(key));

/// Billing tab: receivables summary and the invoice register.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  InvoiceState? _filter;

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(workActorProvider);
    if (actor != null && !InvoicePolicy.canView(actor.role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Billing')),
        body: const PermissionDeniedView(
          permission: 'Billing',
          reason: 'Invoices and payments are visible to owners, admins, managers and accounts staff.',
        ),
      );
    }
    final canManage = actor != null && InvoicePolicy.canManage(actor.role);
    final invoices = ref.watch(invoiceListProvider);
    final summary = ref.watch(billingSummaryProvider);
    final today = WorkLogRules.dateKey(DateTime.now());
    void create() => context.push(Routes.invoiceNew);

    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              // Unique per tab: tab branches stay alive side by side.
              heroTag: 'fab_billing',
              key: const Key('invoice_add'),
              onPressed: create,
              icon: const Icon(Icons.add),
              label: const Text('New invoice'),
            )
          : null,
      body: switch (invoices) {
        AsyncValue(:final error?) when !invoices.hasValue => ErrorView(
          message: '$error',
        ),
        AsyncValue(:final value?) => () {
          final shown = _filter == null
              ? value
              : value.where((i) => i.stateOn(today) == _filter).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.page,
              0,
              AppSpace.page,
              96,
            ),
            children: [
              _Summary(summary: summary),
              const SizedBox(height: AppSpace.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in <InvoiceState?>[
                      null,
                      ...InvoiceState.values,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpace.sm),
                        child: ChoiceChip(
                          key: Key('invoice_filter_${f?.name ?? 'all'}'),
                          label: Text(f?.label ?? 'All'),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              if (value.isEmpty)
                EmptyView(
                  icon: Icons.receipt_long_outlined,
                  title: 'No invoices yet',
                  message: 'Create an invoice from approved work logs for a client and billing period.',
                  actionLabel: canManage ? 'New invoice' : null,
                  onAction: canManage ? create : null,
                )
              else if (shown.isEmpty)
                EmptyView(
                  icon: Icons.filter_list_off,
                  title: 'No ${_filter!.label.toLowerCase()} invoices',
                )
              else
                for (final i in shown) ...[
                  InvoiceCard(invoice: i, today: today),
                  const SizedBox(height: AppSpace.sm),
                ],
            ],
          );
        }(),
        _ => const LoadingView(),
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final BillingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = AppStatusColors.of(context);
    Widget tile(String label, int paise, {Color? color, Key? key}) => Expanded(
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(paise),
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return AppCard(
      color: theme.colorScheme.primary.withValues(alpha: .12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Outstanding', style: theme.textTheme.labelLarge),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(summary.outstandingPaise),
              key: const Key('billing_outstanding'),
              style: theme.textTheme.displaySmall,
            ),
          ),
          Text(
            '${summary.unpaidCount} ${summary.unpaidCount == 1 ? 'invoice' : 'invoices'} awaiting payment',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              tile(
                'Overdue',
                summary.overduePaise,
                color: summary.overduePaise > 0 ? status.danger : null,
              ),
              const SizedBox(width: AppSpace.md),
              tile(
                'Received this month',
                summary.receivedThisMonthPaise,
                color: status.success,
                key: const Key('billing_received'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({super.key, required this.invoice, required this.today});

  final InvoiceView invoice;
  final String today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = invoice.stateOn(today);
    return AppCard(
      key: Key('invoice_tile_${invoice.id}'),
      onTap: () => context.push(Routes.invoiceDetail(invoice.id)),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.displayNumber,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${invoice.clientName} · ${formatDateKey(invoice.invoiceDate)}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.xs),
                InvoiceStateChip(state),
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
                    Money.format(invoice.totalPaise),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (invoice.outstandingPaise > 0 && invoice.paidPaise > 0)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Due ${Money.format(invoice.outstandingPaise)}',
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
