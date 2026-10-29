import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/units.dart';
import '../../billing/presentation/invoice_pdf.dart';
import '../../company/application/company_providers.dart';
import '../../license/application/license_controller.dart';
import '../../work/domain/work_log.dart';
import '../application/reports_providers.dart';
import '../domain/reports.dart';

/// A report as plain tables, for PDF export.
class ReportTable {
  const ReportTable({
    required this.headers,
    required this.rows,
    this.title,
    this.footer,
    this.numeric = const {},
  });

  final String? title;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String>? footer;

  /// Right-aligned column indexes.
  final Set<int> numeric;
}

class ReportDocument {
  const ReportDocument({
    required this.title,
    required this.period,
    required this.summary,
    required this.tables,
  });

  final String title;
  final String period;
  final List<(String, String)> summary;
  final List<ReportTable> tables;
}

final _date = DateFormat('d MMM yyyy');
String reportDate(String key) => _date.format(DateTime.parse(key));

String describeRange(ReportRange r) => r.from == r.to
    ? reportDate(r.from)
    : '${reportDate(r.from)} – ${reportDate(r.to)}';

String flagLabel(AnomalyFlag f) => switch (f) {
  AnomalyFlag.meterBackwards => 'Meter went backwards',
  AnomalyFlag.highHours => 'Unusually long hours',
  AnomalyFlag.duplicateDay => 'Second log that day',
};

/// "+2.5 h not logged" / "1 h overlap" for a meter gap.
String gapLabel(int gap) => gap > 0
    ? '${MeterReading.format(gap)} not logged'
    : '${MeterReading.format(-gap)} overlap';

String _h(int v) => MeterReading.format(v);
String _m(int v) => Money.format(v);

ReportTable _groups(
  String title,
  String header,
  List<ReportGroup> groups, {
  required String valueHeader,
  required String Function(int) format,
  String countHeader = 'Entries',
  String? extraHeader,
  String Function(int)? formatExtra,
}) => ReportTable(
  title: title,
  headers: [header, countHeader, ?extraHeader, valueHeader],
  numeric: extraHeader == null ? {1, 2} : {1, 2, 3},
  rows: [
    for (final g in groups)
      [
        g.detail == null ? g.label : '${g.label} (${g.detail})',
        '${g.count}',
        if (extraHeader != null) formatExtra!(g.extra),
        format(g.value),
      ],
  ],
);

ReportDocument workDocument(WorkReport r, ReportRange range) => ReportDocument(
  title: ReportKind.work.title,
  period: describeRange(range),
  summary: [
    ('Approved hours', _h(r.hours)),
    ('Approved logs', '${r.counted.length}'),
    ('Already invoiced', _h(r.invoicedHours)),
    ('Ready to bill', _h(r.unbilledHours)),
    (
      'Waiting for approval',
      '${r.pending.length} logs · ${_h(r.pendingHours)}',
    ),
    ('Manual entries', '${r.manualCount}'),
  ],
  tables: [
    for (final g in WorkGrouping.values)
      _groups(
        'By ${g.label.toLowerCase()}',
        g.label,
        g == WorkGrouping.day
            ? [
                for (final d in r.by(g))
                  ReportGroup(
                    key: d.key,
                    label: reportDate(d.key),
                    count: d.count,
                    value: d.value,
                  ),
              ]
            : r.by(g),
        countHeader: 'Logs',
        valueHeader: 'Hours',
        format: _h,
      ),
  ],
);

ReportDocument meterDocument(
  MeterReport r,
  ReportRange range,
) => ReportDocument(
  title: ReportKind.meter.title,
  period: describeRange(range),
  summary: [
    ('Machines', '${r.machines.length}'),
    ('Breaks in the meter sequence', '${r.gapCount}'),
  ],
  tables: [
    for (final m in r.machines)
      ReportTable(
        title:
            '${m.machineName}: ${_h(m.firstReading)} to ${_h(m.lastReading)}',
        headers: ['Date', 'Site', 'Start', 'End', 'Hours', 'Check'],
        numeric: {2, 3, 4},
        rows: [
          for (final e in m.entries)
            [
              reportDate(e.log.workDate),
              e.log.siteName,
              _h(e.log.start.reading!),
              _h(e.log.end.reading!),
              _h(e.log.workingHours!),
              if ((e.gap ?? 0) != 0) gapLabel(e.gap!) else '',
            ],
        ],
        footer: ['Total', '', '', '', _h(m.hours), ''],
      ),
  ],
);

ReportDocument fuelDocument(FuelReport r, ReportRange range) => ReportDocument(
  title: ReportKind.fuel.title,
  period: describeRange(range),
  summary: [
    ('Fuel cost', _m(r.totalPaise)),
    ('Litres', Litres.format(r.litresCl)),
    ('Entries', '${r.count}'),
    if (r.averagePricePaise case final avg?)
      ('Average price', '${_m(avg)} per litre'),
  ],
  tables: [
    for (final (title, header, groups) in [
      ('By machine', 'Machine', r.byMachine),
      ('By petrol pump', 'Petrol pump', r.byPump),
      ('By site', 'Site', r.bySite),
    ])
      _groups(
        title,
        header,
        groups,
        valueHeader: 'Amount',
        format: _m,
        extraHeader: 'Litres',
        formatExtra: Litres.format,
      ),
    ReportTable(
      title: 'Entries',
      headers: ['Date', 'Machine', 'Pump', 'Litres', 'Price/L', 'Amount'],
      numeric: {3, 4, 5},
      rows: [
        for (final e in r.entries.reversed)
          [
            reportDate(e.fuelDate),
            e.machineName,
            e.pumpName,
            Litres.format(e.litresCl),
            _m(e.pricePerLitrePaise),
            _m(e.totalPaise),
          ],
      ],
      footer: [
        'Total',
        '',
        '',
        Litres.format(r.litresCl),
        '',
        _m(r.totalPaise),
      ],
    ),
  ],
);

ReportDocument invoiceDocument(
  InvoiceRegister r,
  ReportRange range,
  String today,
) => ReportDocument(
  title: ReportKind.invoices.title,
  period: describeRange(range),
  summary: [
    ('Invoiced', _m(r.invoicedPaise)),
    ('Received on these invoices', _m(r.receivedPaise)),
    ('Still outstanding', _m(r.outstandingPaise)),
    ('Invoices', '${r.finalizedCount} issued · ${r.cancelledCount} cancelled'),
    if (r.draftCount > 0) ('Drafts (not counted)', '${r.draftCount}'),
  ],
  tables: [
    ReportTable(
      title: 'Invoices',
      headers: ['Number', 'Date', 'Client', 'Total', 'Paid', 'Status'],
      numeric: {3, 4},
      rows: [
        for (final i in r.rows)
          [
            i.displayNumber,
            reportDate(i.invoiceDate),
            i.clientName,
            _m(i.totalPaise),
            _m(i.paidPaise),
            i.stateOn(today).label,
          ],
      ],
      footer: [
        'Total (excl. cancelled)',
        '',
        '',
        _m(r.invoicedPaise),
        _m(r.receivedPaise),
        '',
      ],
    ),
    _groups(
      'By client',
      'Client',
      r.byClient,
      countHeader: 'Invoices',
      valueHeader: 'Invoiced',
      format: _m,
    ),
  ],
);

ReportDocument paymentDocument(PaymentRegister r, ReportRange range) =>
    ReportDocument(
      title: ReportKind.payments.title,
      period: describeRange(range),
      summary: [
        ('Received', _m(r.totalPaise)),
        ('Payments', '${r.valid.length}'),
        if (r.reversed.isNotEmpty)
          ('Reversed (not counted)', '${r.reversed.length}'),
      ],
      tables: [
        ReportTable(
          title: 'Payments',
          headers: [
            'Date',
            'Invoice',
            'Client',
            'Method',
            'Reference',
            'Amount',
          ],
          numeric: {5},
          rows: [
            for (final p in r.valid)
              [
                reportDate(p.paymentDate),
                p.invoiceNumber ?? 'Draft',
                p.clientName,
                p.method.label,
                p.reference ?? '',
                _m(p.amountPaise),
              ],
          ],
          footer: ['Total', '', '', '', '', _m(r.totalPaise)],
        ),
        _groups(
          'By method',
          'Method',
          r.byMethod,
          countHeader: 'Payments',
          valueHeader: 'Amount',
          format: _m,
        ),
        if (r.reversed.isNotEmpty)
          ReportTable(
            title: 'Reversed payments (not counted)',
            headers: ['Date', 'Invoice', 'Client', 'Reason', 'Amount'],
            numeric: {4},
            rows: [
              for (final p in r.reversed)
                [
                  reportDate(p.paymentDate),
                  p.invoiceNumber ?? 'Draft',
                  p.clientName,
                  p.reverseReason ?? 'Invoice cancelled',
                  _m(p.amountPaise),
                ],
            ],
          ),
      ],
    );

ReportDocument outstandingDocument(OutstandingReport r) => ReportDocument(
  title: ReportKind.outstanding.title,
  period: 'As of ${reportDate(r.today)}',
  summary: [
    ('Outstanding', _m(r.totalPaise)),
    ('Overdue', _m(r.overduePaise)),
    for (final MapEntry(key: b, value: v) in r.buckets.entries)
      (b.label, _m(v)),
  ],
  tables: [
    ReportTable(
      title: 'Unpaid invoices',
      headers: ['Number', 'Client', 'Due', 'Days overdue', 'Outstanding'],
      numeric: {3, 4},
      rows: [
        for (final a in r.rows)
          [
            a.invoice.displayNumber,
            a.invoice.clientName,
            reportDate(a.invoice.dueDate),
            a.daysOverdue == 0 ? '—' : '${a.daysOverdue}',
            _m(a.invoice.outstandingPaise),
          ],
      ],
      footer: ['Total', '', '', '', _m(r.totalPaise)],
    ),
    _groups(
      'By client',
      'Client',
      r.byClient,
      countHeader: 'Invoices',
      valueHeader: 'Outstanding',
      format: _m,
    ),
  ],
);

ReportDocument manualDocument(ManualReport r, ReportRange range) =>
    ReportDocument(
      title: ReportKind.manual.title,
      period: describeRange(range),
      summary: [
        ('Manual entries', '${r.manualCount} · ${_h(r.manualHours)}'),
        ('Saved with warnings', '${r.flaggedCount}'),
      ],
      tables: [
        ReportTable(
          headers: [
            'Date',
            'Machine',
            'Site',
            'Hours',
            'Reason or warning',
            'Status',
          ],
          numeric: {3},
          rows: [
            for (final l in r.rows)
              [
                reportDate(l.workDate),
                l.machineName,
                l.siteName,
                l.workingHours == null ? '—' : _h(l.workingHours!),
                [
                  if (l.entryMode == EntryMode.manual)
                    'Manual: ${l.manualReason ?? 'no reason'}',
                  for (final f in l.anomalyFlags) flagLabel(f),
                ].join('; '),
                l.status.label,
              ],
          ],
        ),
      ],
    );

/// The current data of [kind] as a document (for the PDF screen).
final reportDocumentProvider = Provider.autoDispose
    .family<AsyncValue<ReportDocument>, ReportKind>((ref, kind) {
      final range = ref.watch(reportRangeProvider);
      final today = WorkLogRules.dateKey(ref.watch(clockProvider)());
      return switch (kind) {
        ReportKind.work =>
          ref.watch(workReportProvider).whenData((r) => workDocument(r, range)),
        ReportKind.meter =>
          ref
              .watch(meterReportProvider)
              .whenData((r) => meterDocument(r, range)),
        ReportKind.fuel =>
          ref.watch(fuelReportProvider).whenData((r) => fuelDocument(r, range)),
        ReportKind.invoices =>
          ref
              .watch(invoiceRegisterProvider)
              .whenData((r) => invoiceDocument(r, range, today)),
        ReportKind.payments =>
          ref
              .watch(paymentRegisterProvider)
              .whenData((r) => paymentDocument(r, range)),
        ReportKind.outstanding =>
          ref.watch(outstandingReportProvider).whenData(outstandingDocument),
        ReportKind.manual =>
          ref
              .watch(manualReportProvider)
              .whenData((r) => manualDocument(r, range)),
      };
    });

final reportCompanyNameProvider = Provider.autoDispose<String>(
  (ref) => ref.watch(currentMembershipProvider)?.company.name ?? '',
);

String reportFileName(ReportKind kind, ReportDocument doc) =>
    '${kind.title.replaceAll(' ', '-')}_${doc.period.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.pdf';

/// Renders [doc] as an A4 PDF with the company name in the header.
Future<Uint8List> buildReportPdf(
  ReportDocument doc, {
  required InvoicePdfFonts fonts,
  required String companyName,
  required DateTime generatedAt,
}) async {
  final grey = PdfColor.fromHex('#5F6368');
  final line = PdfColor.fromHex('#DADCE0');
  final shade = PdfColor.fromHex('#F5F5F5');
  final base = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);
  final theme = base.copyWith(
    defaultTextStyle: base.defaultTextStyle.copyWith(fontSize: 9),
  );
  final pdf = pw.Document(
    title: '${doc.title} · ${doc.period}',
    author: companyName,
    theme: theme,
  );
  const bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);

  // Title and table are separate page-level widgets so long tables can
  // continue on the next page.
  List<pw.Widget> table(ReportTable t) {
    pw.Widget cell(String text, int col, {bool strong = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: t.numeric.contains(col)
            ? pw.TextAlign.right
            : pw.TextAlign.left,
        style: strong ? bold : null,
      ),
    );
    return [
      if (t.title != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(
            t.title!,
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      if (t.rows.isEmpty)
        pw.Text('Nothing in this period.', style: pw.TextStyle(color: grey))
      else
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: line, width: .5),
            bottom: pw.BorderSide(color: line, width: .5),
          ),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: shade),
              children: [
                for (final (i, h) in t.headers.indexed)
                  cell(h, i, strong: true),
              ],
            ),
            for (final r in t.rows)
              pw.TableRow(
                children: [for (final (i, v) in r.indexed) cell(v, i)],
              ),
            if (t.footer case final f?)
              pw.TableRow(
                decoration: pw.BoxDecoration(color: shade),
                children: [
                  for (final (i, v) in f.indexed) cell(v, i, strong: true),
                ],
              ),
          ],
        ),
    ];
  }

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
      ),
      header: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(companyName, style: pw.TextStyle(color: grey)),
                pw.Text(
                  doc.title,
                  style: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            pw.Text(doc.period, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated ${DateFormat('d MMM yyyy, h:mm a').format(generatedAt)} with JCB Works',
            style: pw.TextStyle(color: grey, fontSize: 8),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(color: grey, fontSize: 8),
          ),
        ],
      ),
      build: (ctx) => [
        pw.Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final (label, value) in doc.summary)
              pw.Container(
                width: 160,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: shade,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(label, style: pw.TextStyle(color: grey)),
                    pw.Text(
                      value,
                      style: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        for (final t in doc.tables) ...table(t),
      ],
    ),
  );
  return pdf.save();
}
