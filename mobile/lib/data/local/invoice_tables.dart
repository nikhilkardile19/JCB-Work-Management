import 'package:drift/drift.dart';

import 'master_tables.dart';
import 'work_log_tables.dart';

/// Client invoice (sprint doc §4.11). Money in paise. Drafts are editable;
/// finalized invoices are immutable except through audited cancellation.
@TableIndex(name: 'invoices_company_client', columns: {#companyId, #clientId})
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get clientId => text().references(Clients, #id)();

  /// Official number, issued by the server when finalized.
  TextColumn get invoiceNumber => text().nullable()();

  /// draft, finalized, cancelled. Payment state is derived from payments.
  TextColumn get status => text()();
  TextColumn get invoiceDate => text()();
  TextColumn get periodFrom => text()();
  TextColumn get periodTo => text()();
  IntColumn get paymentTermsDays => integer()();
  TextColumn get dueDate => text()();
  TextColumn get notes => text().nullable()();

  IntColumn get subtotalPaise => integer()();
  IntColumn get discountPaise => integer().withDefault(const Constant(0))();
  IntColumn get totalPaise => integer()();

  /// JSON snapshots captured at finalization.
  TextColumn get companySnapshot => text().nullable()();
  TextColumn get clientSnapshot => text().nullable()();

  IntColumn get finalizedAt => integer().nullable()();
  TextColumn get finalizedBy => text().nullable()();
  IntColumn get cancelledAt => integer().nullable()();
  TextColumn get cancelledBy => text().nullable()();
  TextColumn get cancelReason => text().nullable()();

  /// Last generated PDF, relative to the documents directory; device-only.
  TextColumn get pdfPath => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One billed work log, with the values used for billing (snapshot).
@TableIndex(name: 'invoice_lines_invoice', columns: {#invoiceId})
class InvoiceLines extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get workLogId => text().references(WorkLogs, #id)();
  TextColumn get workDate => text()();
  TextColumn get siteId => text()();
  TextColumn get siteName => text()();
  TextColumn get machineId => text()();
  TextColumn get machineName => text()();
  IntColumn get startReading => integer()();
  IntColumn get endReading => integer()();
  IntColumn get workingHours => integer()();

  /// Rate for this invoice only; never written back to the site.
  IntColumn get ratePaise => integer()();
  IntColumn get amountPaise => integer()();
  TextColumn get description => text().nullable()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'payments_invoice', columns: {#companyId, #invoiceId})
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get paymentDate => text()();
  IntColumn get amountPaise => integer()();

  /// cash, bank, upi, cheque, other.
  TextColumn get method => text()();
  TextColumn get reference => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Reversed payments are kept for the audit trail but not counted.
  IntColumn get reversedAt => integer().nullable()();
  TextColumn get reversedBy => text().nullable()();
  TextColumn get reverseReason => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
