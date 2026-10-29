import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/widgets/state_views.dart';
import '../../billing/application/billing_providers.dart';
import '../../license/application/license_controller.dart';
import '../domain/reports.dart';
import 'report_document.dart';

/// PDF preview of a report with the platform's print and share actions.
class ReportPdfScreen extends ConsumerWidget {
  const ReportPdfScreen({super.key, required this.kind});

  final ReportKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(reportDocumentProvider(kind));
    final fonts = ref.watch(pdfFontsProvider);
    final company = ref.watch(reportCompanyNameProvider);
    return Scaffold(
      appBar: AppBar(title: Text('${kind.title} PDF')),
      body: switch ((doc, fonts)) {
        (AsyncValue(:final error?), _) || (_, AsyncValue(:final error?)) =>
          ErrorView(message: "Couldn't prepare the report. $error"),
        (AsyncValue(value: final d?), AsyncValue(value: final f?)) =>
          PdfPreview(
            build: (_) => buildReportPdf(
              d,
              fonts: f,
              companyName: company,
              generatedAt: ref.read(clockProvider)(),
            ),
            pdfFileName: reportFileName(kind, d),
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            loadingWidget: const LoadingView(message: 'Preparing PDF…'),
            onError: (context, error) =>
                ErrorView(message: "Couldn't create the PDF. $error"),
          ),
        _ => const LoadingView(message: 'Preparing PDF…'),
      },
    );
  }
}
