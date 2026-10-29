import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../core/widgets/state_views.dart';
import '../../masters/application/masters_providers.dart';
import '../../masters/domain/master_kind.dart';
import '../../work/application/work_providers.dart';
import '../application/billing_providers.dart';
import '../domain/invoice.dart';
import 'invoice_pdf.dart';

/// Preview with the platform's print and share actions. Finalized and
/// cancelled invoices also keep a local copy of the PDF on the device.
class InvoicePdfScreen extends ConsumerWidget {
  const InvoicePdfScreen({super.key, required this.id});

  final String id;

  Future<Uint8List> _build(
    WidgetRef ref,
    InvoiceView v,
    InvoicePdfFonts fonts,
  ) async {
    final company = ref.read(companySnapshotProvider)!;
    final clientRecord = await ref
        .read(mastersRepositoryProvider)
        .watchOne(
          MasterKind.clients,
          ref.read(workActorProvider)!.companyId,
          v.clientId,
        )
        .first;
    final client = PartySnapshot(
      name: clientRecord?.name ?? v.clientName,
      contactPerson: clientRecord?['contactPerson'] as String?,
      phone: clientRecord?['phone'] as String?,
      email: clientRecord?['email'] as String?,
      address: clientRecord?['billingAddress'] as String?,
      gstin: clientRecord?['gstin'] as String?,
    );
    final bytes = await buildInvoicePdf(
      v,
      fonts: fonts,
      company: company,
      client: client,
    );
    if (v.status != InvoiceStatus.draft) {
      final actor = ref.read(workActorProvider)!;
      final rel = p.join('invoices', actor.companyId, invoiceFileName(v));
      final file = File(
        p.join((await getApplicationDocumentsDirectory()).path, rel),
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      await ref
          .read(invoiceRepositoryProvider)
          .setPdfPath(actor.companyId, v.id, rel);
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(invoiceProvider(id)).value;
    final fonts = ref.watch(pdfFontsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(invoice == null ? 'Invoice PDF' : invoiceFileName(invoice)),
      ),
      body: invoice == null || !fonts.hasValue
          ? (fonts.hasError
                ? ErrorView(message: '${fonts.error}')
                : const LoadingView(message: 'Preparing PDF…'))
          : PdfPreview(
              build: (_) => _build(ref, invoice, fonts.value!),
              pdfFileName: invoiceFileName(invoice),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              loadingWidget: const LoadingView(message: 'Preparing PDF…'),
              onError: (context, error) =>
                  ErrorView(message: "Couldn't create the PDF. $error"),
            ),
    );
  }
}
