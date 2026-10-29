import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/billing/domain/invoice.dart';
import 'package:jcb_work_management/features/billing/presentation/invoice_pdf.dart';
import 'package:pdf/widgets.dart' as pw;

InvoiceView invoice({
  InvoiceStatus status = InvoiceStatus.finalized,
  int lines = 3,
}) => InvoiceView(
  id: 'i1',
  clientId: 'c1',
  clientName: 'Patil',
  invoiceNumber: status == InvoiceStatus.draft ? null : 'SAI/2026-27/0001',
  status: status,
  invoiceDate: '2026-11-01',
  periodFrom: '2026-10-01',
  periodTo: '2026-10-31',
  paymentTermsDays: 15,
  dueDate: '2026-11-16',
  subtotalPaise: 2560000,
  discountPaise: 50000,
  totalPaise: 2510000,
  paidPaise: 500000,
  syncStatus: 'pending',
  notes: 'Thank you for your business.',
  clientSnapshot: const PartySnapshot(
    name: 'Patil Constructions',
    address: 'Hinjewadi, Pune',
    gstin: '27AAAAA0000A1Z5',
  ),
  lines: [
    for (var i = 0; i < lines; i++)
      InvoiceLineView(
        id: 'l$i',
        workLogId: 'w$i',
        workDate: '2026-10-0${(i % 9) + 1}',
        siteId: 's',
        siteName: 'Hinjewadi Yard',
        machineId: 'm',
        machineName: 'JCB 3DX',
        startReading: 100000 + i * 800,
        endReading: 100800 + i * 800,
        workingHours: 800,
        ratePaise: 150000,
        amountPaise: 1200000,
      ),
  ],
);

void main() {
  late InvoicePdfFonts fonts;
  setUpAll(() {
    pw.Font load(String f) => pw.Font.ttf(
      ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync()),
    );
    fonts = InvoicePdfFonts(
      regular: load('NotoSans-Regular.ttf'),
      bold: load('NotoSans-Bold.ttf'),
    );
  });

  const company = PartySnapshot(name: 'Sai Earthmovers', address: 'Pune');
  const client = PartySnapshot(name: 'Live Client');

  test(
    'renders a valid PDF for finalized, draft and cancelled invoices',
    () async {
      for (final s in InvoiceStatus.values) {
        final bytes = await buildInvoicePdf(
          invoice(status: s),
          fonts: fonts,
          company: company,
          client: client,
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: s.name);
        expect(bytes.length, greaterThan(1000));
      }
    },
  );

  test('long invoices flow onto multiple pages', () async {
    final short = await buildInvoicePdf(
      invoice(lines: 3),
      fonts: fonts,
      company: company,
      client: client,
    );
    final long = await buildInvoicePdf(
      invoice(lines: 120),
      fonts: fonts,
      company: company,
      client: client,
    );
    final pages = RegExp(r'/Type\s*/Page\b');
    expect(pages.allMatches(String.fromCharCodes(short)).length, 1);
    expect(pages.allMatches(String.fromCharCodes(long)).length, greaterThan(2));
  });

  test('file name is filesystem-safe', () {
    expect(invoiceFileName(invoice()), 'Invoice_SAI-2026-27-0001.pdf');
    expect(
      invoiceFileName(invoice(status: InvoiceStatus.draft)),
      'Invoice_Draft.pdf',
    );
  });
}
