import 'package:flutter/material.dart' show DateUtils;

import '../../billing/domain/invoice.dart';
import '../../company/domain/permissions.dart';
import '../../fuel/domain/fuel_entry.dart';
import '../../work/domain/work_log.dart';

/// Reports (sprint doc §4.13). Every figure is derived from the same local
/// records the rest of the app shows, so reports reconcile with the
/// dashboard, the lists and the invoices.

enum ReportPreset {
  today('Today'),
  thisWeek('This week'),
  thisMonth('This month'),
  lastMonth('Last month'),
  financialYear('This financial year'),
  custom('Custom');

  const ReportPreset(this.label);

  final String label;
}

/// Inclusive range of local `yyyy-MM-dd` dates.
class ReportRange {
  const ReportRange(this.from, this.to, {this.preset = ReportPreset.custom});

  factory ReportRange.preset(ReportPreset preset, DateTime now) {
    final today = DateUtils.dateOnly(now);
    final (from, to) = switch (preset) {
      ReportPreset.today || ReportPreset.custom => (today, today),
      ReportPreset.thisWeek => (
        today.subtract(Duration(days: today.weekday - 1)),
        today,
      ),
      ReportPreset.thisMonth => (DateTime(today.year, today.month), today),
      ReportPreset.lastMonth => (
        DateTime(today.year, today.month - 1),
        DateTime(today.year, today.month, 0),
      ),
      // Indian financial year: 1 April – 31 March.
      ReportPreset.financialYear => (
        DateTime(today.month >= 4 ? today.year : today.year - 1, 4),
        today,
      ),
    };
    return ReportRange(
      WorkLogRules.dateKey(from),
      WorkLogRules.dateKey(to),
      preset: preset,
    );
  }

  final String from;
  final String to;
  final ReportPreset preset;

  bool contains(String dateKey) =>
      dateKey.compareTo(from) >= 0 && dateKey.compareTo(to) <= 0;

  @override
  bool operator ==(Object other) =>
      other is ReportRange &&
      other.from == from &&
      other.to == to &&
      other.preset == preset;

  @override
  int get hashCode => Object.hash(from, to, preset);
}

enum ReportKind {
  work('Work hours', 'By machine, site, client, operator and day'),
  meter('Meter readings', 'Machine-wise readings and gaps between logs'),
  fuel('Fuel expenses', 'By machine, petrol pump and site'),
  invoices('Invoice register', 'Invoices issued in the period'),
  payments('Payment register', 'Payments received in the period'),
  outstanding(
    'Outstanding and aging',
    'Unpaid invoices by how overdue they are',
  ),
  manual('Manual entries', 'Work entered without photos, or with warnings');

  const ReportKind(this.title, this.description);

  final String title;
  final String description;

  static ReportKind? parse(String? s) =>
      values.where((k) => k.name == s).firstOrNull;

  /// Outstanding is always as of today; the others cover a period.
  bool get usesPeriod => this != outstanding;
}

abstract final class ReportPolicy {
  static bool canView(CompanyRole r) => r.can(Permission.viewReports);
}

/// One line of a breakdown: a label with a count and a total.
class ReportGroup {
  const ReportGroup({
    required this.key,
    required this.label,
    required this.count,
    required this.value,
    this.detail,
    this.extra = 0,
  });

  final String key;
  final String label;
  final String? detail;
  final int count;

  /// Hours (hundredths) for work, paise for money.
  final int value;

  /// Secondary quantity, e.g. litres (hundredths) for fuel.
  final int extra;
}

/// Groups [items] by [key], largest [value] first (or by key when
/// [sortByKey], e.g. dates).
List<ReportGroup> groupBy<T>(
  Iterable<T> items, {
  required String Function(T) key,
  required String Function(T) label,
  required int Function(T) value,
  String? Function(T)? detail,
  int Function(T)? extra,
  bool sortByKey = false,
}) {
  final groups = <String, ({T first, int count, int value, int extra})>{};
  for (final i in items) {
    final k = key(i);
    final g = groups[k];
    groups[k] = (
      first: g?.first ?? i,
      count: (g?.count ?? 0) + 1,
      value: (g?.value ?? 0) + value(i),
      extra: (g?.extra ?? 0) + (extra?.call(i) ?? 0),
    );
  }
  final out = [
    for (final MapEntry(key: k, value: g) in groups.entries)
      ReportGroup(
        key: k,
        label: label(g.first),
        detail: detail?.call(g.first),
        count: g.count,
        value: g.value,
        extra: g.extra,
      ),
  ];
  out.sort(
    sortByKey
        ? (a, b) => a.key.compareTo(b.key)
        : (a, b) => b.value != a.value
              ? b.value.compareTo(a.value)
              : a.label.compareTo(b.label),
  );
  return out;
}

int _sum<T>(Iterable<T> items, int Function(T) f) =>
    items.fold(0, (a, i) => a + f(i));

// --- Work --------------------------------------------------------------------

enum WorkGrouping {
  machine('Machine'),
  site('Site'),
  client('Client'),
  operator('Operator'),
  day('Day');

  const WorkGrouping(this.label);

  final String label;
}

/// Approved work (approved + invoiced logs) in a period, with what is still
/// waiting for approval shown separately.
class WorkReport {
  WorkReport._(this.counted, this.pending, this.inProgress);

  factory WorkReport.from(Iterable<WorkLogView> logs, ReportRange range) {
    final inRange = logs.where((l) => range.contains(l.workDate)).toList();
    return WorkReport._(
      [
        for (final l in inRange)
          if (_approved.contains(l.status) && l.workingHours != null) l,
      ],
      [
        for (final l in inRange)
          if (l.status == WorkLogStatus.submitted) l,
      ],
      [
        for (final l in inRange)
          if (l.status == WorkLogStatus.draft) l,
      ],
    );
  }

  static const _approved = {WorkLogStatus.approved, WorkLogStatus.invoiced};

  /// Logs whose hours count: approved or already invoiced.
  final List<WorkLogView> counted;
  final List<WorkLogView> pending;
  final List<WorkLogView> inProgress;

  int get hours => _sum(counted, (l) => l.workingHours!);
  int get invoicedHours => _sum(
    counted.where((l) => l.status == WorkLogStatus.invoiced),
    (l) => l.workingHours!,
  );

  /// Approved but not yet on a finalized invoice.
  int get unbilledHours => hours - invoicedHours;
  int get pendingHours => _sum(pending, (l) => l.workingHours ?? 0);
  int get manualCount =>
      counted.where((l) => l.entryMode == EntryMode.manual).length;

  List<ReportGroup> by(WorkGrouping g) => switch (g) {
    WorkGrouping.machine => groupBy(
      counted,
      key: (l) => l.machineId,
      label: (l) => l.machineName,
      value: (l) => l.workingHours!,
    ),
    WorkGrouping.site => groupBy(
      counted,
      key: (l) => l.siteId,
      label: (l) => l.siteName,
      detail: (l) => l.clientName,
      value: (l) => l.workingHours!,
    ),
    WorkGrouping.client => groupBy(
      counted,
      key: (l) => l.clientId,
      label: (l) => l.clientName,
      value: (l) => l.workingHours!,
    ),
    WorkGrouping.operator => groupBy(
      counted,
      key: (l) => l.operatorId ?? l.operatorName ?? '',
      label: (l) => l.operatorName ?? 'No operator recorded',
      value: (l) => l.workingHours!,
    ),
    WorkGrouping.day => groupBy(
      counted,
      key: (l) => l.workDate,
      label: (l) => l.workDate,
      value: (l) => l.workingHours!,
      sortByKey: true,
    ),
  };
}

// --- Meter readings ------------------------------------------------------------

class MeterEntry {
  const MeterEntry(this.log, this.gap);

  final WorkLogView log;

  /// This log's start minus the previous log's end, in hundredths of an
  /// hour: positive means hours the meter ran without a log, negative an
  /// overlap. Null for the machine's first log in the period.
  final int? gap;
}

class MachineMeter {
  const MachineMeter({
    required this.machineId,
    required this.machineName,
    required this.entries,
  });

  final String machineId;
  final String machineName;

  /// Oldest first.
  final List<MeterEntry> entries;

  int get firstReading => entries.first.log.start.reading!;
  int get lastReading => entries.last.log.end.reading!;
  int get hours => _sum(entries, (e) => e.log.workingHours!);
  int get gapCount => entries.where((e) => (e.gap ?? 0) != 0).length;
}

/// Submitted, approved and invoiced logs per machine in reading order,
/// flagging breaks in the meter sequence. Drafts, cancelled and rejected
/// logs are left out.
class MeterReport {
  const MeterReport(this.machines);

  factory MeterReport.from(Iterable<WorkLogView> logs, ReportRange range) {
    final byMachine = <String, List<WorkLogView>>{};
    for (final l in logs) {
      if (!range.contains(l.workDate) ||
          l.end.reading == null ||
          l.status == WorkLogStatus.draft ||
          l.status == WorkLogStatus.cancelled ||
          l.status == WorkLogStatus.rejected) {
        continue;
      }
      (byMachine[l.machineId] ??= []).add(l);
    }
    final machines = [
      for (final list in byMachine.values)
        () {
          list.sort(
            (a, b) => a.workDate != b.workDate
                ? a.workDate.compareTo(b.workDate)
                : a.start.reading!.compareTo(b.start.reading!),
          );
          return MachineMeter(
            machineId: list.first.machineId,
            machineName: list.first.machineName,
            entries: [
              for (final (i, l) in list.indexed)
                MeterEntry(
                  l,
                  i == 0 ? null : l.start.reading! - list[i - 1].end.reading!,
                ),
            ],
          );
        }(),
    ]..sort((a, b) => a.machineName.compareTo(b.machineName));
    return MeterReport(machines);
  }

  final List<MachineMeter> machines;

  int get gapCount => _sum(machines, (m) => m.gapCount);
}

// --- Fuel ----------------------------------------------------------------------

class FuelReport {
  const FuelReport(this.entries);

  /// [entries] are the period's entries (already filtered by date).
  final List<FuelView> entries;

  int get totalPaise => _sum(entries, (e) => e.totalPaise);
  int get litresCl => _sum(entries, (e) => e.litresCl);
  int get count => entries.length;

  /// Weighted average price in paise per litre (same rule as the Fuel tab).
  int? get averagePricePaise =>
      litresCl == 0 ? null : (totalPaise * 100 + litresCl ~/ 2) ~/ litresCl;

  List<ReportGroup> get byMachine => groupBy(
    entries,
    key: (e) => e.machineId,
    label: (e) => e.machineName,
    value: (e) => e.totalPaise,
    extra: (e) => e.litresCl,
  );

  List<ReportGroup> get byPump => groupBy(
    entries,
    key: (e) => e.pumpId,
    label: (e) => e.pumpName,
    value: (e) => e.totalPaise,
    extra: (e) => e.litresCl,
  );

  List<ReportGroup> get bySite => groupBy(
    entries,
    key: (e) => e.siteId ?? '',
    label: (e) => e.siteName ?? 'Not allocated to a site',
    detail: (e) => e.clientName,
    value: (e) => e.totalPaise,
    extra: (e) => e.litresCl,
  );
}

// --- Invoices ------------------------------------------------------------------

/// Finalized and cancelled invoices dated in the period (drafts have no
/// number yet and are only counted).
class InvoiceRegister {
  InvoiceRegister._(this.rows, this.draftCount);

  factory InvoiceRegister.from(
    Iterable<InvoiceView> invoices,
    ReportRange range,
  ) {
    final inRange = invoices.where((i) => range.contains(i.invoiceDate));
    final rows =
        [
          for (final i in inRange)
            if (i.status != InvoiceStatus.draft) i,
        ]..sort(
          (a, b) => a.invoiceDate != b.invoiceDate
              ? a.invoiceDate.compareTo(b.invoiceDate)
              : a.displayNumber.compareTo(b.displayNumber),
        );
    return InvoiceRegister._(
      rows,
      inRange.where((i) => i.status == InvoiceStatus.draft).length,
    );
  }

  final List<InvoiceView> rows;
  final int draftCount;

  Iterable<InvoiceView> get _finalized =>
      rows.where((i) => i.status == InvoiceStatus.finalized);

  int get finalizedCount => _finalized.length;
  int get cancelledCount => rows.length - finalizedCount;
  int get invoicedPaise => _sum(_finalized, (i) => i.totalPaise);
  int get receivedPaise => _sum(_finalized, (i) => i.paidPaise);
  int get outstandingPaise => _sum(_finalized, (i) => i.outstandingPaise);

  List<ReportGroup> get byClient => groupBy(
    _finalized,
    key: (i) => i.clientId,
    label: (i) => i.clientName,
    value: (i) => i.totalPaise,
  );
}

// --- Payments ------------------------------------------------------------------

/// Payments dated in the period. Reversed payments are listed but never
/// counted (same rule as the dashboard's "received").
class PaymentRegister {
  PaymentRegister(Iterable<PaymentRecord> records)
    : valid = [
        for (final r in records)
          if (r.counts) r,
      ],
      reversed = [
        for (final r in records)
          if (!r.counts) r,
      ];

  final List<PaymentRecord> valid;
  final List<PaymentRecord> reversed;

  int get totalPaise => _sum(valid, (p) => p.amountPaise);

  List<ReportGroup> get byMethod => groupBy(
    valid,
    key: (p) => p.method.name,
    label: (p) => p.method.label,
    value: (p) => p.amountPaise,
  );

  List<ReportGroup> get byClient => groupBy(
    valid,
    key: (p) => p.clientId,
    label: (p) => p.clientName,
    value: (p) => p.amountPaise,
  );
}

// --- Outstanding ---------------------------------------------------------------

enum AgingBucket {
  notDue('Not yet due'),
  d1to30('1–30 days overdue'),
  d31to60('31–60 days overdue'),
  d61to90('61–90 days overdue'),
  over90('Over 90 days overdue');

  const AgingBucket(this.label);

  final String label;

  static AgingBucket of(int daysOverdue) => switch (daysOverdue) {
    <= 0 => notDue,
    <= 30 => d1to30,
    <= 60 => d31to60,
    <= 90 => d61to90,
    _ => over90,
  };
}

class AgingRow {
  const AgingRow(this.invoice, this.daysOverdue);

  final InvoiceView invoice;

  /// Days past the due date (0 when not yet due).
  final int daysOverdue;

  AgingBucket get bucket => AgingBucket.of(daysOverdue);
}

/// Every finalized invoice with money still owed, as of [today].
class OutstandingReport {
  OutstandingReport._(this.today, this.rows);

  factory OutstandingReport.from(Iterable<InvoiceView> invoices, String today) {
    final asOf = DateTime.parse(today);
    final rows =
        [
          for (final i in invoices)
            if (i.outstandingPaise > 0)
              AgingRow(
                i,
                asOf
                    .difference(DateTime.parse(i.dueDate))
                    .inDays
                    .clamp(0, 1 << 30),
              ),
        ]..sort(
          (a, b) => b.daysOverdue != a.daysOverdue
              ? b.daysOverdue.compareTo(a.daysOverdue)
              : b.invoice.outstandingPaise.compareTo(
                  a.invoice.outstandingPaise,
                ),
        );
    return OutstandingReport._(today, rows);
  }

  final String today;
  final List<AgingRow> rows;

  int get totalPaise => _sum(rows, (r) => r.invoice.outstandingPaise);
  int get overduePaise => _sum(
    rows.where((r) => r.bucket != AgingBucket.notDue),
    (r) => r.invoice.outstandingPaise,
  );

  /// Outstanding per bucket; every bucket is present.
  Map<AgingBucket, int> get buckets => {
    for (final b in AgingBucket.values)
      b: _sum(
        rows.where((r) => r.bucket == b),
        (r) => r.invoice.outstandingPaise,
      ),
  };

  List<ReportGroup> get byClient => groupBy(
    rows,
    key: (r) => r.invoice.clientId,
    label: (r) => r.invoice.clientName,
    value: (r) => r.invoice.outstandingPaise,
  );
}

// --- Manual entries -------------------------------------------------------------

/// Work entered without both meter photos, or saved despite reading
/// warnings — the entries an owner should check (sprint doc §4.9).
class ManualReport {
  ManualReport._(this.rows);

  factory ManualReport.from(Iterable<WorkLogView> logs, ReportRange range) =>
      ManualReport._(
        [
          for (final l in logs)
            if (range.contains(l.workDate) &&
                l.status != WorkLogStatus.cancelled &&
                (l.entryMode == EntryMode.manual || l.anomalyFlags.isNotEmpty))
              l,
        ]..sort((a, b) => b.workDate.compareTo(a.workDate)),
      );

  /// Newest first.
  final List<WorkLogView> rows;

  int get manualCount =>
      rows.where((l) => l.entryMode == EntryMode.manual).length;
  int get flaggedCount => rows.where((l) => l.anomalyFlags.isNotEmpty).length;
  int get manualHours => _sum(
    rows.where((l) => l.entryMode == EntryMode.manual),
    (l) => l.workingHours ?? 0,
  );
}
