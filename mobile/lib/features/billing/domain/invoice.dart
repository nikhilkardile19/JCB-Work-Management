import 'dart:convert';

import '../../company/domain/permissions.dart';

enum InvoiceStatus {
  draft,
  finalized,
  cancelled;

  static InvoiceStatus parse(String v) => InvoiceStatus.values.byName(v);
}

/// What the user sees: lifecycle combined with payments and due date.
enum InvoiceState {
  draft('Draft'),
  unpaid('Unpaid'),
  partiallyPaid('Partially paid'),
  paid('Paid'),
  overdue('Overdue'),
  cancelled('Cancelled');

  const InvoiceState(this.label);

  final String label;
}

enum PaymentMethod {
  cash('Cash'),
  bank('Bank transfer'),
  upi('UPI'),
  cheque('Cheque'),
  other('Other');

  const PaymentMethod(this.label);

  final String label;
}

abstract final class InvoiceMath {
  /// Paise for [hours] (hundredths) at [ratePaise] per hour, half-up.
  static int lineAmount(int hours, int ratePaise) =>
      (hours * ratePaise + 50) ~/ 100;

  /// Indian financial year (April–March) for a `yyyy-MM-dd` date: "2026-27".
  static String financialYear(String dateKey) {
    final d = DateTime.parse(dateKey);
    final start = d.month >= 4 ? d.year : d.year - 1;
    return '$start-${((start + 1) % 100).toString().padLeft(2, '0')}';
  }

  static String addDays(String dateKey, int days) {
    final d = DateTime.parse(dateKey).add(Duration(days: days));
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static InvoiceState state({
    required InvoiceStatus status,
    required int totalPaise,
    required int paidPaise,
    required String dueDate,
    required String today,
  }) => switch (status) {
    InvoiceStatus.draft => InvoiceState.draft,
    InvoiceStatus.cancelled => InvoiceState.cancelled,
    InvoiceStatus.finalized when paidPaise >= totalPaise => InvoiceState.paid,
    InvoiceStatus.finalized when today.compareTo(dueDate) > 0 =>
      InvoiceState.overdue,
    InvoiceStatus.finalized when paidPaise > 0 => InvoiceState.partiallyPaid,
    InvoiceStatus.finalized => InvoiceState.unpaid,
  };
}

/// Company or client details frozen onto a finalized invoice.
class PartySnapshot {
  const PartySnapshot({
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.gstin,
  });

  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstin;

  String toJson() => jsonEncode({
    'name': name,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'gstin': gstin,
  });

  static PartySnapshot? fromJson(String? json) {
    if (json == null) return null;
    final m = jsonDecode(json) as Map<String, dynamic>;
    return PartySnapshot(
      name: m['name'] as String,
      contactPerson: m['contactPerson'] as String?,
      phone: m['phone'] as String?,
      email: m['email'] as String?,
      address: m['address'] as String?,
      gstin: m['gstin'] as String?,
    );
  }
}

/// Draft invoice as edited by the user.
class InvoiceDraftInput {
  const InvoiceDraftInput({
    required this.clientId,
    required this.periodFrom,
    required this.periodTo,
    required this.invoiceDate,
    required this.workLogRates,
    this.paymentTermsDays = 15,
    this.discountPaise = 0,
    this.notes,
  });

  final String clientId;
  final String periodFrom;
  final String periodTo;
  final String invoiceDate;
  final int paymentTermsDays;
  final int discountPaise;
  final String? notes;

  /// Selected work log → invoice-only rate (paise per hour).
  final Map<String, int> workLogRates;
}

class InvoiceLineView {
  const InvoiceLineView({
    required this.id,
    required this.workLogId,
    required this.workDate,
    required this.siteId,
    required this.siteName,
    required this.machineId,
    required this.machineName,
    required this.startReading,
    required this.endReading,
    required this.workingHours,
    required this.ratePaise,
    required this.amountPaise,
    this.description,
  });

  final String id;
  final String workLogId;
  final String workDate;
  final String siteId;
  final String siteName;
  final String machineId;
  final String machineName;
  final int startReading;
  final int endReading;
  final int workingHours;
  final int ratePaise;
  final int amountPaise;
  final String? description;
}

class PaymentView {
  const PaymentView({
    required this.id,
    required this.paymentDate,
    required this.amountPaise,
    required this.method,
    required this.createdBy,
    this.reference,
    this.notes,
    this.reversedAt,
    this.reverseReason,
  });

  final String id;
  final String paymentDate;
  final int amountPaise;
  final PaymentMethod method;
  final String createdBy;
  final String? reference;
  final String? notes;
  final int? reversedAt;
  final String? reverseReason;

  bool get isValid => reversedAt == null;
}

/// A payment with its invoice and client, for the payment register.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.paymentDate,
    required this.amountPaise,
    required this.method,
    required this.invoiceId,
    required this.clientId,
    required this.clientName,
    this.invoiceNumber,
    this.reference,
    this.reversedAt,
    this.reverseReason,
    this.invoiceCancelled = false,
  });

  final String id;
  final String paymentDate;
  final int amountPaise;
  final PaymentMethod method;
  final String invoiceId;
  final String? invoiceNumber;
  final String clientId;
  final String clientName;
  final String? reference;
  final int? reversedAt;
  final String? reverseReason;
  final bool invoiceCancelled;

  /// Counted as received: not reversed and on a live invoice.
  bool get counts => reversedAt == null && !invoiceCancelled;
}

class InvoiceView {
  const InvoiceView({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.invoiceDate,
    required this.periodFrom,
    required this.periodTo,
    required this.paymentTermsDays,
    required this.dueDate,
    required this.subtotalPaise,
    required this.discountPaise,
    required this.totalPaise,
    required this.paidPaise,
    required this.syncStatus,
    this.invoiceNumber,
    this.notes,
    this.companySnapshot,
    this.clientSnapshot,
    this.finalizedAt,
    this.cancelReason,
    this.pdfPath,
    this.lines = const [],
    this.payments = const [],
  });

  final String id;
  final String clientId;
  final String clientName;
  final String? invoiceNumber;
  final InvoiceStatus status;
  final String invoiceDate;
  final String periodFrom;
  final String periodTo;
  final int paymentTermsDays;
  final String dueDate;
  final String? notes;
  final int subtotalPaise;
  final int discountPaise;
  final int totalPaise;
  final int paidPaise;
  final PartySnapshot? companySnapshot;
  final PartySnapshot? clientSnapshot;
  final int? finalizedAt;
  final String? cancelReason;
  final String? pdfPath;
  final String syncStatus;
  final List<InvoiceLineView> lines;
  final List<PaymentView> payments;

  int get outstandingPaise =>
      status == InvoiceStatus.finalized ? totalPaise - paidPaise : 0;

  String get displayNumber => invoiceNumber ?? 'Draft';

  InvoiceState stateOn(String today) => InvoiceMath.state(
    status: status,
    totalPaise: totalPaise,
    paidPaise: paidPaise,
    dueDate: dueDate,
    today: today,
  );
}

abstract final class InvoicePolicy {
  static bool canView(CompanyRole r) =>
      r.can(Permission.manageInvoices) || r.can(Permission.viewReports);

  static bool canManage(CompanyRole r) => r.can(Permission.manageInvoices);

  static bool canRecordPayment(CompanyRole r) =>
      r.can(Permission.recordPayments);
}

class BillingSummary {
  const BillingSummary({
    required this.outstandingPaise,
    required this.overduePaise,
    required this.receivedThisMonthPaise,
    required this.unpaidCount,
  });

  static const empty = BillingSummary(
    outstandingPaise: 0,
    overduePaise: 0,
    receivedThisMonthPaise: 0,
    unpaidCount: 0,
  );

  final int outstandingPaise;
  final int overduePaise;
  final int receivedThisMonthPaise;
  final int unpaidCount;
}
