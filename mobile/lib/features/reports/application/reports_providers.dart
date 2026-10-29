import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/application/billing_providers.dart';
import '../../fuel/application/fuel_providers.dart';
import '../../license/application/license_controller.dart';
import '../../work/application/work_providers.dart';
import '../../work/domain/work_log.dart';
import '../domain/reports.dart';

/// The period shared by the reports hub and every report (default: this
/// month).
class ReportRangeNotifier extends Notifier<ReportRange> {
  @override
  ReportRange build() =>
      ReportRange.preset(ReportPreset.thisMonth, ref.read(clockProvider)());

  void preset(ReportPreset p) =>
      state = ReportRange.preset(p, ref.read(clockProvider)());

  void custom(DateTimeRange r) => state = ReportRange(
    WorkLogRules.dateKey(r.start),
    WorkLogRules.dateKey(r.end),
  );
}

final reportRangeProvider = NotifierProvider<ReportRangeNotifier, ReportRange>(
  ReportRangeNotifier.new,
);

final _todayProvider = Provider.autoDispose<String>(
  (ref) => WorkLogRules.dateKey(ref.watch(clockProvider)()),
);

final _logsInRangeProvider = StreamProvider.autoDispose<List<WorkLogView>>((
  ref,
) {
  final actor = ref.watch(workActorProvider);
  final range = ref.watch(reportRangeProvider);
  if (actor == null) return Stream.value(const []);
  return ref
      .watch(workLogRepositoryProvider)
      .watchBetween(actor.companyId, from: range.from, to: range.to);
});

final workReportProvider = Provider.autoDispose<AsyncValue<WorkReport>>(
  (ref) => ref
      .watch(_logsInRangeProvider)
      .whenData(
        (logs) => WorkReport.from(logs, ref.watch(reportRangeProvider)),
      ),
);

final meterReportProvider = Provider.autoDispose<AsyncValue<MeterReport>>(
  (ref) => ref
      .watch(_logsInRangeProvider)
      .whenData(
        (logs) => MeterReport.from(logs, ref.watch(reportRangeProvider)),
      ),
);

final manualReportProvider = Provider.autoDispose<AsyncValue<ManualReport>>(
  (ref) => ref
      .watch(_logsInRangeProvider)
      .whenData(
        (logs) => ManualReport.from(logs, ref.watch(reportRangeProvider)),
      ),
);

final fuelReportProvider = StreamProvider.autoDispose<FuelReport>((ref) {
  final actor = ref.watch(workActorProvider);
  final range = ref.watch(reportRangeProvider);
  if (actor == null) return Stream.value(const FuelReport([]));
  return ref
      .watch(fuelRepositoryProvider)
      .watchList(actor.companyId, from: range.from, to: range.to)
      .map(FuelReport.new);
});

final invoiceRegisterProvider =
    Provider.autoDispose<AsyncValue<InvoiceRegister>>(
      (ref) => ref
          .watch(invoiceListProvider)
          .whenData(
            (invoices) =>
                InvoiceRegister.from(invoices, ref.watch(reportRangeProvider)),
          ),
    );

final paymentRegisterProvider = StreamProvider.autoDispose<PaymentRegister>((
  ref,
) {
  final actor = ref.watch(workActorProvider);
  final range = ref.watch(reportRangeProvider);
  if (actor == null) return Stream.value(PaymentRegister(const []));
  return ref
      .watch(invoiceRepositoryProvider)
      .watchPaymentRecords(actor.companyId, from: range.from, to: range.to)
      .map(PaymentRegister.new);
});

final outstandingReportProvider =
    Provider.autoDispose<AsyncValue<OutstandingReport>>(
      (ref) => ref
          .watch(invoiceListProvider)
          .whenData(
            (invoices) =>
                OutstandingReport.from(invoices, ref.watch(_todayProvider)),
          ),
    );

ReportRange _thisMonth(Ref ref) =>
    ReportRange.preset(ReportPreset.thisMonth, ref.watch(clockProvider)());

/// This month's approved work, for the dashboard (independent of the
/// period chosen in Reports).
final monthWorkReportProvider = StreamProvider.autoDispose<WorkReport>((ref) {
  final actor = ref.watch(workActorProvider);
  final range = _thisMonth(ref);
  if (actor == null) return Stream.value(WorkReport.from(const [], range));
  return ref
      .watch(workLogRepositoryProvider)
      .watchBetween(actor.companyId, from: range.from, to: range.to)
      .map((logs) => WorkReport.from(logs, range));
});

/// This month's invoices, for the dashboard.
final monthInvoiceRegisterProvider = Provider.autoDispose<InvoiceRegister?>(
  (ref) => switch (ref.watch(invoiceListProvider).value) {
    final invoices? => InvoiceRegister.from(invoices, _thisMonth(ref)),
    null => null,
  },
);
