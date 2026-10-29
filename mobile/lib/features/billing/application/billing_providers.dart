import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/local/database_provider.dart';
import '../../company/application/company_providers.dart';
import '../../work/application/work_providers.dart';
import '../../work/data/work_log_repository.dart';
import '../../work/domain/work_log.dart';
import '../data/invoice_number_service.dart';
import '../data/invoice_repository.dart';
import '../domain/invoice.dart';
import '../presentation/invoice_pdf.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => InvoiceRepository(ref.watch(appDatabaseProvider)),
);

final invoiceNumberServiceProvider = Provider<InvoiceNumberService>(
  (ref) => CloudInvoiceNumberService(),
);

final invoiceListProvider = StreamProvider.autoDispose<List<InvoiceView>>((
  ref,
) {
  final actor = ref.watch(workActorProvider);
  if (actor == null) return Stream.value(const []);
  return ref.watch(invoiceRepositoryProvider).watchList(actor.companyId);
});

final invoiceProvider = StreamProvider.autoDispose.family<InvoiceView?, String>(
  (ref, id) {
    final actor = ref.watch(workActorProvider);
    if (actor == null) return Stream.value(null);
    return ref.watch(invoiceRepositoryProvider).watchOne(actor.companyId, id);
  },
);

final invoiceHistoryProvider = StreamProvider.autoDispose
    .family<List<WorkHistoryEntry>, String>((ref, id) {
      final actor = ref.watch(workActorProvider);
      if (actor == null) return Stream.value(const []);
      return ref
          .watch(invoiceRepositoryProvider)
          .watchHistory(actor.companyId, id);
    });

typedef CandidateQuery = ({
  String clientId,
  String from,
  String to,
  String? invoiceId,
});

final invoiceCandidatesProvider = StreamProvider.autoDispose
    .family<List<WorkLogView>, CandidateQuery>((ref, q) {
      final actor = ref.watch(workActorProvider);
      if (actor == null) return Stream.value(const []);
      return ref
          .watch(invoiceRepositoryProvider)
          .watchCandidates(
            actor.companyId,
            clientId: q.clientId,
            from: q.from,
            to: q.to,
            invoiceId: q.invoiceId,
          );
    });

final _receivedThisMonthProvider = StreamProvider.autoDispose<int>((ref) {
  final actor = ref.watch(workActorProvider);
  if (actor == null) return Stream.value(0);
  final now = DateTime.now();
  return ref
      .watch(invoiceRepositoryProvider)
      .watchReceived(
        actor.companyId,
        from: WorkLogRules.dateKey(DateTime(now.year, now.month)),
        to: WorkLogRules.dateKey(now),
      );
});

final billingSummaryProvider = Provider.autoDispose<BillingSummary>((ref) {
  final invoices = ref.watch(invoiceListProvider).value ?? const [];
  final today = WorkLogRules.dateKey(DateTime.now());
  var outstanding = 0, overdue = 0, unpaid = 0;
  for (final i in invoices) {
    if (i.outstandingPaise <= 0) continue;
    outstanding += i.outstandingPaise;
    unpaid++;
    if (i.stateOn(today) == InvoiceState.overdue) overdue += i.outstandingPaise;
  }
  return BillingSummary(
    outstandingPaise: outstanding,
    overduePaise: overdue,
    receivedThisMonthPaise: ref.watch(_receivedThisMonthProvider).value ?? 0,
    unpaidCount: unpaid,
  );
});

/// The active company's current details, used on drafts and frozen on
/// finalized invoices.
final companySnapshotProvider = Provider<PartySnapshot?>((ref) {
  final p = ref.watch(currentMembershipProvider)?.company.profile;
  if (p == null) return null;
  return PartySnapshot(
    name: p.name,
    contactPerson: p.contactPerson,
    phone: p.phone,
    email: p.email,
    address: p.address,
    gstin: p.gstin,
  );
});

final pdfFontsProvider = FutureProvider<InvoicePdfFonts>((ref) async {
  Future<pw.Font> load(String name) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$name'));
  return InvoicePdfFonts(
    regular: await load('NotoSans-Regular.ttf'),
    bold: await load('NotoSans-Bold.ttf'),
  );
});
