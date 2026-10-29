import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/units.dart';
import '../domain/invoice.dart';

class InvoicePdfFonts {
  const InvoicePdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}

final _date = DateFormat('d MMM yyyy');
String _d(String key) => _date.format(DateTime.parse(key));

/// Renders an invoice as an A4 PDF. Finalized invoices use their frozen
/// snapshots; drafts use [company]/[client] and carry a DRAFT watermark.
Future<Uint8List> buildInvoicePdf(
  InvoiceView invoice, {
  required InvoicePdfFonts fonts,
  required PartySnapshot company,
  required PartySnapshot client,
}) async {
  final seller = invoice.companySnapshot ?? company;
  final buyer = invoice.clientSnapshot ?? client;
  final draft = invoice.status == InvoiceStatus.draft;
  final cancelled = invoice.status == InvoiceStatus.cancelled;
  final amber = PdfColor.fromHex('#F5B400');
  final grey = PdfColor.fromHex('#5F6368');

  final doc = pw.Document(
    title: 'Invoice ${invoice.displayNumber}',
    author: seller.name,
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
  );

  pw.Widget party(String label, PartySnapshot p) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: pw.TextStyle(color: grey, fontSize: 9)),
      pw.Text(
        p.name,
        style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
      ),
      if (p.address != null) pw.Text(p.address!),
      if (p.phone != null) pw.Text('Phone: ${p.phone}'),
      if (p.email != null) pw.Text(p.email!),
      if (p.gstin != null) pw.Text('GSTIN: ${p.gstin}'),
    ],
  );

  pw.Widget totalRow(String label, String value, {bool strong = false}) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: strong
                ? const pw.TextStyle(fontWeight: pw.FontWeight.bold)
                : null,
          ),
          pw.Text(
            value,
            style: strong
                ? const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                  )
                : null,
          ),
        ],
      );

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
        buildBackground: draft || cancelled
            ? (_) => pw.Center(
                child: pw.Transform.rotate(
                  angle: 0.5,
                  child: pw.Text(
                    draft ? 'DRAFT' : 'CANCELLED',
                    style: pw.TextStyle(
                      fontSize: 96,
                      color: PdfColor.fromHex('#EEEEEE'),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
      ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated with JCB Works',
            style: pw.TextStyle(color: grey, fontSize: 8),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(color: grey, fontSize: 8),
          ),
        ],
      ),
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: party('From', seller)),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  color: amber,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'INVOICE',
                    style: const pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'No. ${invoice.displayNumber}',
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Date: ${_d(invoice.invoiceDate)}'),
                pw.Text('Due: ${_d(invoice.dueDate)}'),
                pw.Text(
                  'Period: ${_d(invoice.periodFrom)} – ${_d(invoice.periodTo)}',
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        party('Bill to', buyer),
        pw.SizedBox(height: 18),
        pw.TableHelper.fromTextArray(
          headerStyle: const pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FFF3CC'),
          ),
          cellAlignments: {
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
            6: pw.Alignment.centerRight,
            7: pw.Alignment.centerRight,
          },
          headers: [
            'Date',
            'Site',
            'Machine',
            'Start',
            'End',
            'Hours',
            'Rate/h',
            'Amount',
          ],
          data: [
            for (final l in invoice.lines)
              [
                _d(l.workDate),
                l.siteName,
                l.machineName,
                MeterReading.toInput(l.startReading),
                MeterReading.toInput(l.endReading),
                MeterReading.toInput(l.workingHours),
                Money.format(l.ratePaise),
                Money.format(l.amountPaise),
              ],
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 220,
            child: pw.Column(
              children: [
                totalRow('Subtotal', Money.format(invoice.subtotalPaise)),
                if (invoice.discountPaise > 0)
                  totalRow(
                    'Discount',
                    '− ${Money.format(invoice.discountPaise)}',
                  ),
                pw.Divider(),
                totalRow(
                  'Total',
                  Money.format(invoice.totalPaise),
                  strong: true,
                ),
                if (invoice.paidPaise > 0) ...[
                  totalRow('Paid', Money.format(invoice.paidPaise)),
                  totalRow(
                    'Balance due',
                    Money.format(invoice.outstandingPaise),
                    strong: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (invoice.notes != null) ...[
          pw.SizedBox(height: 18),
          pw.Text('Notes', style: pw.TextStyle(color: grey, fontSize: 9)),
          pw.Text(invoice.notes!),
        ],
        if (cancelled && invoice.cancelReason != null) ...[
          pw.SizedBox(height: 12),
          pw.Text(
            'Cancelled: ${invoice.cancelReason}',
            style: const pw.TextStyle(color: PdfColors.red),
          ),
        ],
      ],
    ),
  );
  return doc.save();
}

/// File name for sharing/saving, e.g. `Invoice_SAI-2026-27-0001.pdf`.
String invoiceFileName(InvoiceView v) =>
    'Invoice_${v.displayNumber.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '-')}.pdf';
