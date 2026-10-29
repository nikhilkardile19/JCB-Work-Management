import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../billing/presentation/billing_screen.dart' show InvoiceStateChip;
import '../../license/application/license_controller.dart';
import '../../work/application/work_providers.dart';
import '../../work/domain/work_log.dart';
import '../../work/presentation/work_widgets.dart' show WorkStatusChip;
import '../application/reports_providers.dart';
import '../domain/reports.dart';
import 'report_document.dart';
import 'report_widgets.dart';

String _h(int v) => MeterReading.format(v);
String _m(int v) => Money.format(v);

enum _FuelBy {
  machine('Machine'),
  pump('Petrol pump'),
  site('Site');

  const _FuelBy(this.label);

  final String label;
}

/// One report for the shared period, with PDF export.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.kind});

  final ReportKind kind;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  WorkGrouping _workBy = WorkGrouping.machine;
  _FuelBy _fuelBy = _FuelBy.machine;

  /// Loading and error states inside the scrolling report.
  List<Widget> _async<T>(AsyncValue<T> v, List<Widget> Function(T) build) =>
      switch (v) {
        AsyncValue(:final value?) => build(value),
        AsyncValue(:final error?) => [
          ReportNotice(
            "Couldn't load this report. $error",
            icon: Icons.error_outline,
            tone: StatusTone.danger,
          ),
        ],
        _ => const [
          Padding(
            padding: EdgeInsets.all(AppSpace.xxl),
            child: LoadingView(message: 'Adding up…'),
          ),
        ],
      };

  List<Widget> _content() => switch (widget.kind) {
    ReportKind.work => _async(ref.watch(workReportProvider), _work),
    ReportKind.meter => _async(ref.watch(meterReportProvider), _meter),
    ReportKind.fuel => _async(ref.watch(fuelReportProvider), _fuel),
    ReportKind.invoices => _async(
      ref.watch(invoiceRegisterProvider),
      _invoices,
    ),
    ReportKind.payments => _async(
      ref.watch(paymentRegisterProvider),
      _payments,
    ),
    ReportKind.outstanding => _async(
      ref.watch(outstandingReportProvider),
      _outstanding,
    ),
    ReportKind.manual => _async(ref.watch(manualReportProvider), _manual),
  };

  List<Widget> _work(WorkReport r) => [
    ReportTotals(
      label: 'Approved hours',
      value: _h(r.hours),
      rows: [
        ('Approved logs', '${r.counted.length}'),
        ('Already invoiced', _h(r.invoicedHours)),
        ('Ready to bill', _h(r.unbilledHours)),
        ('Waiting for approval', '${r.pending.length} · ${_h(r.pendingHours)}'),
        if (r.inProgress.isNotEmpty)
          ('Still in progress', '${r.inProgress.length}'),
        ('Manual entries', '${r.manualCount}'),
      ],
    ),
    const SectionHeader('Breakdown'),
    ReportGroupingChips(
      values: WorkGrouping.values,
      selected: _workBy,
      label: (g) => g.label,
      onSelected: (g) => setState(() => _workBy = g),
    ),
    const SizedBox(height: AppSpace.md),
    ReportGroupList(
      groups: r.by(_workBy),
      format: _h,
      countLabel: 'log',
      formatLabel: _workBy == WorkGrouping.day ? reportDate : null,
    ),
  ];

  List<Widget> _meter(MeterReport r) => [
    if (r.machines.isEmpty)
      const ReportNotice('No completed work logs in this period.')
    else ...[
      ReportTotals(
        label: 'Breaks in the meter sequence',
        value: '${r.gapCount}',
        rows: [('Machines', '${r.machines.length}')],
      ),
      for (final m in r.machines) ...[
        SectionHeader(m.machineName),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text('${_h(m.firstReading)} → ${_h(m.lastReading)}'),
                subtitle: Text(
                  '${_h(m.hours)} logged in ${m.entries.length} '
                  '${m.entries.length == 1 ? 'log' : 'logs'}',
                ),
              ),
              for (final e in m.entries) ...[
                const Divider(),
                _MeterRow(entry: e),
              ],
            ],
          ),
        ),
      ],
    ],
  ];

  List<Widget> _fuel(FuelReport r) => [
    ReportTotals(
      label: 'Fuel cost',
      value: _m(r.totalPaise),
      rows: [
        ('Litres', Litres.format(r.litresCl)),
        ('Entries', '${r.count}'),
        if (r.averagePricePaise case final avg?)
          ('Average price', '${_m(avg)} per litre'),
      ],
    ),
    const SectionHeader('Breakdown'),
    ReportGroupingChips(
      values: _FuelBy.values,
      selected: _fuelBy,
      label: (g) => g.label,
      onSelected: (g) => setState(() => _fuelBy = g),
    ),
    const SizedBox(height: AppSpace.md),
    ReportGroupList(
      groups: switch (_fuelBy) {
        _FuelBy.machine => r.byMachine,
        _FuelBy.pump => r.byPump,
        _FuelBy.site => r.bySite,
      },
      format: _m,
      formatExtra: Litres.format,
      countLabel: 'fill',
    ),
  ];

  List<Widget> _invoices(InvoiceRegister r) {
    final today = WorkLogRules.dateKey(ref.read(clockProvider)());
    return [
      ReportTotals(
        label: 'Invoiced',
        value: _m(r.invoicedPaise),
        rows: [
          ('Received on these invoices', _m(r.receivedPaise)),
          ('Still outstanding', _m(r.outstandingPaise)),
          ('Invoices issued', '${r.finalizedCount}'),
          if (r.cancelledCount > 0) ('Cancelled', '${r.cancelledCount}'),
          if (r.draftCount > 0) ('Drafts (not counted)', '${r.draftCount}'),
        ],
      ),
      const SectionHeader('By client'),
      ReportGroupList(groups: r.byClient, format: _m, countLabel: 'invoice'),
      const SectionHeader('Invoices'),
      if (r.rows.isEmpty)
        const ReportNotice('No invoices issued in this period.')
      else
        _RecordList(
          children: [
            for (final i in r.rows)
              _RecordRow(
                key: Key('report_invoice_${i.id}'),
                title: '${i.displayNumber} · ${i.clientName}',
                subtitle: reportDate(i.invoiceDate),
                amount: _m(i.totalPaise),
                trailing: InvoiceStateChip(i.stateOn(today)),
                onTap: () => context.go(Routes.invoiceDetail(i.id)),
              ),
          ],
        ),
    ];
  }

  List<Widget> _payments(PaymentRegister r) => [
    ReportTotals(
      label: 'Received',
      value: _m(r.totalPaise),
      rows: [
        ('Payments', '${r.valid.length}'),
        if (r.reversed.isNotEmpty)
          ('Reversed (not counted)', '${r.reversed.length}'),
      ],
    ),
    const SectionHeader('By method'),
    ReportGroupList(groups: r.byMethod, format: _m, countLabel: 'payment'),
    const SectionHeader('Payments'),
    if (r.valid.isEmpty)
      const ReportNotice('No payments received in this period.')
    else
      _RecordList(
        children: [
          for (final p in r.valid)
            _RecordRow(
              key: Key('report_payment_${p.id}'),
              title: '${p.invoiceNumber ?? 'Draft'} · ${p.clientName}',
              subtitle: [
                reportDate(p.paymentDate),
                p.method.label,
                ?p.reference,
              ].join(' · '),
              amount: _m(p.amountPaise),
            ),
        ],
      ),
    if (r.reversed.isNotEmpty) ...[
      const SectionHeader('Reversed — not counted'),
      _RecordList(
        children: [
          for (final p in r.reversed)
            _RecordRow(
              title: '${p.invoiceNumber ?? 'Draft'} · ${p.clientName}',
              subtitle:
                  '${reportDate(p.paymentDate)} · '
                  '${p.reverseReason ?? 'Invoice cancelled'}',
              amount: _m(p.amountPaise),
              struck: true,
            ),
        ],
      ),
    ],
  ];

  List<Widget> _outstanding(OutstandingReport r) {
    final colors = AppStatusColors.of(context);
    return [
      ReportTotals(
        label: 'Outstanding',
        value: _m(r.totalPaise),
        rows: [
          ('Overdue', _m(r.overduePaise)),
          ('Unpaid invoices', '${r.rows.length}'),
        ],
      ),
      const SectionHeader('Aging'),
      AppCard(
        child: Column(
          children: [
            for (final MapEntry(key: b, value: v) in r.buckets.entries)
              Padding(
                key: Key('aging_${b.name}'),
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                child: MergeSemantics(
                  child: Row(
                    children: [
                      Expanded(child: Text(b.label)),
                      Text(
                        _m(v),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: b != AgingBucket.notDue && v > 0
                              ? colors.danger
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      const SectionHeader('By client'),
      ReportGroupList(groups: r.byClient, format: _m, countLabel: 'invoice'),
      const SectionHeader('Invoices'),
      if (r.rows.isEmpty)
        const ReportNotice('Nothing outstanding. Every invoice is paid.')
      else
        _RecordList(
          children: [
            for (final a in r.rows)
              _RecordRow(
                key: Key('report_outstanding_${a.invoice.id}'),
                title: '${a.invoice.displayNumber} · ${a.invoice.clientName}',
                subtitle:
                    'Due ${reportDate(a.invoice.dueDate)}'
                    '${a.daysOverdue > 0 ? ' · ${a.daysOverdue} days overdue' : ''}',
                amount: _m(a.invoice.outstandingPaise),
                amountColor: a.daysOverdue > 0 ? colors.danger : null,
                onTap: () => context.go(Routes.invoiceDetail(a.invoice.id)),
              ),
          ],
        ),
    ];
  }

  List<Widget> _manual(ManualReport r) => [
    ReportTotals(
      label: 'Manual entries',
      value: '${r.manualCount}',
      rows: [
        ('Hours entered manually', _h(r.manualHours)),
        ('Saved with warnings', '${r.flaggedCount}'),
      ],
    ),
    const SectionHeader('Entries to check'),
    if (r.rows.isEmpty)
      const ReportNotice(
        'Every work log in this period has both meter photos and no warnings.',
        icon: Icons.verified_outlined,
        tone: StatusTone.success,
      )
    else
      _RecordList(
        children: [
          for (final l in r.rows)
            _RecordRow(
              key: Key('report_manual_${l.id}'),
              title: '${l.machineName} · ${l.siteName}',
              subtitle: [
                reportDate(l.workDate),
                if (l.entryMode == EntryMode.manual)
                  'Manual: ${l.manualReason ?? 'no reason'}',
                for (final f in l.anomalyFlags) flagLabel(f),
              ].join(' · '),
              amount: l.workingHours == null ? '—' : _h(l.workingHours!),
              trailing: WorkStatusChip(l.status),
              onTap: () => context.go(Routes.workDetail(l.id)),
            ),
        ],
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(workActorProvider);
    final kind = widget.kind;
    if (actor == null || !ReportPolicy.canView(actor.role)) {
      return Scaffold(
        appBar: AppBar(title: Text(kind.title)),
        body: const EmptyView(
          icon: Icons.lock_outline,
          title: 'Reports are not available for your role',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(kind.title),
        actions: [
          IconButton(
            key: const Key('report_pdf'),
            tooltip: 'Share or print as PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => context.push(Routes.reportPdf(kind)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.sm,
          AppSpace.page,
          AppSpace.xxl,
        ),
        children: [
          if (kind.usesPeriod)
            const ReportPeriodBar()
          else
            Text(
              'As of today, '
              '${reportDate(WorkLogRules.dateKey(ref.watch(clockProvider)()))}',
              key: const Key('report_range'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          const SizedBox(height: AppSpace.md),
          ..._content(),
        ],
      ),
    );
  }
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({required this.entry});

  final MeterEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = entry.log;
    final gap = entry.gap ?? 0;
    return MergeSemantics(
      child: Padding(
        key: Key('meter_${l.id}'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reportDate(l.workDate)),
                  Text(l.siteName, style: theme.textTheme.bodySmall),
                  if (gap != 0)
                    Text(
                      gapLabel(gap),
                      key: Key('meter_gap_${l.id}'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppStatusColors.of(context).warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_h(l.start.reading!)} → ${_h(l.end.reading!)}',
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    _h(l.workingHours!),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const Divider(),
          c,
        ],
      ],
    ),
  );
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.trailing,
    this.onTap,
    this.amountColor,
    this.struck = false,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? amountColor;
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strike = struck
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                  if (trailing != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    trailing!,
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Text(
              amount,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: amountColor)
                  .merge(strike),
            ),
          ],
        ),
      ),
    );
  }
}
