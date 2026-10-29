import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../work/data/work_log_repository.dart';
import '../../work/domain/work_log.dart';
import '../domain/invoice.dart';
import 'invoice_number_service.dart';

/// Refused change; keys: clientId, period, workLogs, rates, discount, terms,
/// amount, reason, status.
class InvoiceException implements Exception {
  const InvoiceException(this.fieldErrors);

  final Map<String, String> fieldErrors;

  String get message => fieldErrors.values.first;

  @override
  String toString() => fieldErrors.values.join('; ');
}

class PaymentInput {
  const PaymentInput({
    required this.paymentDate,
    required this.amountPaise,
    required this.method,
    this.reference,
    this.notes,
  });

  final String paymentDate;
  final int amountPaise;
  final PaymentMethod method;
  final String? reference;
  final String? notes;
}

/// Sanity limit for a billing rate (catches an extra zero).
const maxRatePaise = 10000000; // ₹1,00,000 per hour

/// Invoices, lines and payments, stored offline-first.
///
/// A work log is *reserved* (its `invoiceId` set) while it is on a draft, and
/// becomes `invoiced` when the invoice is finalized, so it can never be on
/// two invoices. Cancelling releases it for re-billing.
class InvoiceRepository {
  InvoiceRepository(
    this._db, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4,
       _workLogs = WorkLogRepository(_db, clock: clock);

  final AppDatabase _db;
  final DateTime Function() _clock;
  final String Function() _newId;
  final WorkLogRepository _workLogs;

  static const _entity = 'invoices';

  int _now() => _clock().toUtc().millisecondsSinceEpoch;

  // --- Reads ------------------------------------------------------------------

  /// Approved work logs for [clientId] in the period that are not on any
  /// other invoice (logs already on [invoiceId] are included).
  Stream<List<WorkLogView>> watchCandidates(
    String companyId, {
    required String clientId,
    required String from,
    required String to,
    String? invoiceId,
  }) => _workLogs
      .watchList(companyId, statuses: {WorkLogStatus.approved})
      .map(
        (logs) =>
            logs
                .where(
                  (l) =>
                      l.clientId == clientId &&
                      l.workDate.compareTo(from) >= 0 &&
                      l.workDate.compareTo(to) <= 0 &&
                      (l.invoiceId == null || l.invoiceId == invoiceId),
                )
                .toList()
              ..sort((a, b) => a.workDate.compareTo(b.workDate)),
      );

  static const _headerSql = '''
SELECT i.*, c.name AS client_name,
  COALESCE((SELECT SUM(p.amount_paise) FROM payments p
            WHERE p.invoice_id = i.id AND p.reversed_at IS NULL), 0) AS paid
FROM invoices i JOIN clients c ON c.id = i.client_id
WHERE i.company_id = ? AND i.deleted_at IS NULL''';

  InvoiceView _header(
    QueryRow row, {
    List<InvoiceLineView> lines = const [],
    List<PaymentView> payments = const [],
  }) {
    final i = _db.invoices.map(row.data);
    return InvoiceView(
      id: i.id,
      clientId: i.clientId,
      clientName: row.read<String>('client_name'),
      invoiceNumber: i.invoiceNumber,
      status: InvoiceStatus.parse(i.status),
      invoiceDate: i.invoiceDate,
      periodFrom: i.periodFrom,
      periodTo: i.periodTo,
      paymentTermsDays: i.paymentTermsDays,
      dueDate: i.dueDate,
      notes: i.notes,
      subtotalPaise: i.subtotalPaise,
      discountPaise: i.discountPaise,
      totalPaise: i.totalPaise,
      paidPaise: row.read<int>('paid'),
      companySnapshot: PartySnapshot.fromJson(i.companySnapshot),
      clientSnapshot: PartySnapshot.fromJson(i.clientSnapshot),
      finalizedAt: i.finalizedAt,
      cancelReason: i.cancelReason,
      pdfPath: i.pdfPath,
      syncStatus: i.syncStatus,
      lines: lines,
      payments: payments,
    );
  }

  Stream<List<InvoiceView>> watchList(String companyId) => _db
      .customSelect(
        '$_headerSql ORDER BY i.invoice_date DESC, i.created_at DESC',
        variables: [Variable(companyId)],
        readsFrom: {_db.invoices, _db.clients, _db.payments},
      )
      .watch()
      .map((rows) => rows.map(_header).toList());

  Stream<InvoiceView?> watchOne(String companyId, String id) => _db
      .customSelect(
        '$_headerSql AND i.id = ?',
        variables: [Variable(companyId), Variable(id)],
        readsFrom: {_db.invoices, _db.clients, _db.payments, _db.invoiceLines},
      )
      .watchSingleOrNull()
      .asyncMap(
        (row) async => row == null
            ? null
            : _header(
                row,
                lines: await _lines(id),
                payments: await _payments(id),
              ),
      );

  Future<InvoiceView?> _get(String companyId, String id) =>
      watchOne(companyId, id).first;

  Future<List<InvoiceLineView>> _lines(String invoiceId) async {
    final rows =
        await (_db.select(_db.invoiceLines)
              ..where((t) => t.invoiceId.equals(invoiceId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return [
      for (final l in rows)
        InvoiceLineView(
          id: l.id,
          workLogId: l.workLogId,
          workDate: l.workDate,
          siteId: l.siteId,
          siteName: l.siteName,
          machineId: l.machineId,
          machineName: l.machineName,
          startReading: l.startReading,
          endReading: l.endReading,
          workingHours: l.workingHours,
          ratePaise: l.ratePaise,
          amountPaise: l.amountPaise,
          description: l.description,
        ),
    ];
  }

  Future<List<PaymentView>> _payments(String invoiceId) async {
    final rows =
        await (_db.select(_db.payments)
              ..where((t) => t.invoiceId.equals(invoiceId))
              ..orderBy([
                (t) => OrderingTerm.asc(t.paymentDate),
                (t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();
    return [
      for (final p in rows)
        PaymentView(
          id: p.id,
          paymentDate: p.paymentDate,
          amountPaise: p.amountPaise,
          method: PaymentMethod.values.byName(p.method),
          reference: p.reference,
          notes: p.notes,
          reversedAt: p.reversedAt,
          reverseReason: p.reverseReason,
          createdBy: p.createdBy,
        ),
    ];
  }

  /// Valid payments received between [from] and [to] (inclusive).
  Stream<int> watchReceived(
    String companyId, {
    required String from,
    required String to,
  }) {
    final sum = _db.payments.amountPaise.sum();
    final q =
        _db.selectOnly(_db.payments).join([
            innerJoin(
              _db.invoices,
              _db.invoices.id.equalsExp(_db.payments.invoiceId),
            ),
          ])
          ..addColumns([sum])
          ..where(
            _db.payments.companyId.equals(companyId) &
                _db.payments.reversedAt.isNull() &
                _db.invoices.status.equals(InvoiceStatus.cancelled.name).not() &
                _db.payments.paymentDate.isBetweenValues(from, to),
          );
    return q.watchSingle().map((r) => r.read(sum) ?? 0);
  }

  /// Every payment dated between [from] and [to] (inclusive), reversed ones
  /// included, oldest first.
  Stream<List<PaymentRecord>> watchPaymentRecords(
    String companyId, {
    required String from,
    required String to,
  }) => _db
      .customSelect(
        '''
SELECT p.*, i.invoice_number, i.client_id, i.status AS invoice_status,
  c.name AS client_name
FROM payments p
JOIN invoices i ON i.id = p.invoice_id
JOIN clients c ON c.id = i.client_id
WHERE p.company_id = ? AND p.payment_date BETWEEN ? AND ?
ORDER BY p.payment_date, p.created_at''',
        variables: [Variable(companyId), Variable(from), Variable(to)],
        readsFrom: {_db.payments, _db.invoices, _db.clients},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            () {
              final p = _db.payments.map(r.data);
              return PaymentRecord(
                id: p.id,
                paymentDate: p.paymentDate,
                amountPaise: p.amountPaise,
                method: PaymentMethod.values.byName(p.method),
                invoiceId: p.invoiceId,
                invoiceNumber: r.read<String?>('invoice_number'),
                clientId: r.read<String>('client_id'),
                clientName: r.read<String>('client_name'),
                reference: p.reference,
                reversedAt: p.reversedAt,
                reverseReason: p.reverseReason,
                invoiceCancelled:
                    r.read<String>('invoice_status') ==
                    InvoiceStatus.cancelled.name,
              );
            }(),
        ],
      );

  Stream<List<WorkHistoryEntry>> watchHistory(String companyId, String id) =>
      (_db.select(_db.auditLogs)
            ..where(
              (t) =>
                  t.companyId.equals(companyId) &
                  t.entityType.equals(_entity) &
                  t.entityId.equals(id),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                WorkHistoryEntry(
                  action: r.action,
                  actorId: r.actorId,
                  at: r.createdAt,
                  details: r.details == null
                      ? null
                      : jsonDecode(r.details!) as Map<String, dynamic>,
                ),
            ],
          );

  // --- Drafts -----------------------------------------------------------------

  /// Creates or updates a draft, reserving its work logs and releasing any
  /// that were removed. Rates are stored on the lines only.
  Future<String> saveDraft(
    WorkActor actor,
    InvoiceDraftInput input, {
    String? id,
  }) => _db.transaction(() async {
    _require(InvoicePolicy.canManage(actor.role), 'create invoices');
    final current = id == null ? null : await _existing(actor, id);
    if (current != null && current.status != InvoiceStatus.draft) {
      throw const InvoiceException({
        'status': 'Only draft invoices can be edited.',
      });
    }

    final errors = <String, String>{};
    final client =
        await (_db.select(_db.clients)..where(
              (t) =>
                  t.id.equals(input.clientId) &
                  t.companyId.equals(actor.companyId) &
                  t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (client == null) errors['clientId'] = 'Select a client';
    if (input.periodFrom.compareTo(input.periodTo) > 0) {
      errors['period'] = 'Billing period start must be before its end';
    }
    if (input.workLogRates.isEmpty) {
      errors['workLogs'] = 'Select at least one approved work log';
    }
    if (input.workLogRates.values.any((r) => r < 0 || r > maxRatePaise)) {
      errors['rates'] = 'Check the hourly rates';
    }
    if (input.paymentTermsDays < 0 || input.paymentTermsDays > 365) {
      errors['terms'] = 'Payment terms must be 0–365 days';
    }
    if (input.discountPaise < 0) {
      errors['discount'] = 'Discount cannot be negative';
    }
    if (errors.isNotEmpty) throw InvoiceException(errors);

    final logs =
        await (_db.select(_db.workLogs)
              ..where(
                (t) =>
                    t.id.isIn(input.workLogRates.keys) &
                    t.companyId.equals(actor.companyId) &
                    t.deletedAt.isNull(),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.workDate),
                (t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();
    final eligible =
        logs.length == input.workLogRates.length &&
        logs.every(
          (l) =>
              l.status == WorkLogStatus.approved.name &&
              l.clientId == input.clientId &&
              (l.invoiceId == null || l.invoiceId == id) &&
              l.workDate.compareTo(input.periodFrom) >= 0 &&
              l.workDate.compareTo(input.periodTo) <= 0,
        );
    if (!eligible) {
      throw const InvoiceException({
        'workLogs': 'Some work logs are no longer available to bill. Refresh and select again.',
      });
    }

    final siteNames = {
      for (final s in await _db.select(_db.sites).get()) s.id: s.name,
    };
    final machineNames = {
      for (final m in await _db.select(_db.machines).get()) m.id: m.name,
    };
    final invoiceId = id ?? _newId();
    final lines = [
      for (final (i, l) in logs.indexed)
        InvoiceLinesCompanion.insert(
          id: _newId(),
          companyId: actor.companyId,
          invoiceId: invoiceId,
          workLogId: l.id,
          workDate: l.workDate,
          siteId: l.siteId,
          siteName: siteNames[l.siteId] ?? '',
          machineId: l.machineId,
          machineName: machineNames[l.machineId] ?? '',
          startReading: l.startReading,
          endReading: l.endReading!,
          workingHours: l.workingHours!,
          ratePaise: input.workLogRates[l.id]!,
          amountPaise: InvoiceMath.lineAmount(
            l.workingHours!,
            input.workLogRates[l.id]!,
          ),
          description: Value(l.notes),
          sortOrder: i,
        ),
    ];
    final subtotal = lines.fold(0, (a, l) => a + l.amountPaise.value);
    if (input.discountPaise > subtotal) {
      throw const InvoiceException({
        'discount': 'Discount cannot be more than the subtotal',
      });
    }

    final now = _now();
    final header = InvoicesCompanion(
      clientId: Value(input.clientId),
      status: Value(InvoiceStatus.draft.name),
      invoiceDate: Value(input.invoiceDate),
      periodFrom: Value(input.periodFrom),
      periodTo: Value(input.periodTo),
      paymentTermsDays: Value(input.paymentTermsDays),
      dueDate: Value(
        InvoiceMath.addDays(input.invoiceDate, input.paymentTermsDays),
      ),
      notes: Value(
        input.notes == null || input.notes!.trim().isEmpty
            ? null
            : input.notes!.trim(),
      ),
      subtotalPaise: Value(subtotal),
      discountPaise: Value(input.discountPaise),
      totalPaise: Value(subtotal - input.discountPaise),
      updatedAt: Value(now),
      updatedBy: Value(actor.userId),
      syncStatus: const Value('pending'),
    );
    if (current == null) {
      await _db
          .into(_db.invoices)
          .insert(
            header.copyWith(
              id: Value(invoiceId),
              companyId: Value(actor.companyId),
              createdAt: Value(now),
              createdBy: Value(actor.userId),
              version: const Value(1),
            ),
          );
    } else {
      await (_db.update(
        _db.invoices,
      )..where((t) => t.id.equals(invoiceId))).write(
        header.copyWith(version: Value(await _version(invoiceId) + 1)),
      );
      await (_db.delete(
        _db.invoiceLines,
      )..where((t) => t.invoiceId.equals(invoiceId))).go();
    }
    await _db.batch((b) => b.insertAll(_db.invoiceLines, lines));

    final selected = input.workLogRates.keys.toSet();
    final previously =
        current?.lines.map((l) => l.workLogId).toSet() ?? <String>{};
    await _reserve(actor, previously.difference(selected), null);
    await _reserve(actor, selected.difference(previously), invoiceId);

    await _audit(actor, invoiceId, current == null ? 'create' : 'update', {
      'lines': lines.length,
      'subtotalPaise': subtotal,
      'discountPaise': input.discountPaise,
      'totalPaise': subtotal - input.discountPaise,
    });
    return invoiceId;
  });

  /// Deletes a draft and releases its work logs.
  Future<void> deleteDraft(
    WorkActor actor,
    String id,
  ) => _db.transaction(() async {
    _require(InvoicePolicy.canManage(actor.role), 'delete invoices');
    final current = await _existing(actor, id);
    if (current.status != InvoiceStatus.draft) {
      throw const InvoiceException({
        'status': 'Finalized invoices cannot be deleted; cancel them instead.',
      });
    }
    await _reserve(actor, current.lines.map((l) => l.workLogId).toSet(), null);
    await _touchInvoice(actor, id, InvoicesCompanion(deletedAt: Value(_now())));
    await _audit(actor, id, 'delete', {'totalPaise': current.totalPaise});
  });

  // --- Finalize / cancel ------------------------------------------------------

  /// Issues the official number (needs the server), freezes company and
  /// client details and marks the work logs as invoiced.
  Future<String> finalize(
    WorkActor actor,
    String id, {
    required InvoiceNumberService numbers,
    required PartySnapshot company,
  }) async {
    _require(InvoicePolicy.canManage(actor.role), 'finalize invoices');
    final draft = await _existing(actor, id);
    if (draft.status != InvoiceStatus.draft) {
      throw const InvoiceException({
        'status': 'This invoice is already finalized.',
      });
    }
    if (draft.lines.isEmpty) {
      throw const InvoiceException({'workLogs': 'Add at least one work log'});
    }
    if (draft.lines.any((l) => l.ratePaise <= 0)) {
      throw const InvoiceException({
        'rates': 'Enter an hourly rate for every site and machine',
      });
    }

    final number = await numbers.allocate(
      companyId: actor.companyId,
      invoiceId: id,
      financialYear: InvoiceMath.financialYear(draft.invoiceDate),
      deviceId: await _db.installationId(),
    );

    return _db.transaction(() async {
      final again = await _existing(actor, id);
      if (again.status != InvoiceStatus.draft) {
        throw const InvoiceException({
          'status': 'This invoice is already finalized.',
        });
      }
      final client = await (_db.select(
        _db.clients,
      )..where((t) => t.id.equals(again.clientId))).getSingle();
      final clientSnapshot = PartySnapshot(
        name: client.name,
        contactPerson: client.contactPerson,
        phone: client.phone,
        email: client.email,
        address: client.billingAddress,
        gstin: client.gstin,
      );
      final logIds = again.lines.map((l) => l.workLogId).toList();
      final logs = await (_db.select(
        _db.workLogs,
      )..where((t) => t.id.isIn(logIds))).get();
      if (logs.any(
        (l) => l.status != WorkLogStatus.approved.name || l.invoiceId != id,
      )) {
        throw const InvoiceException({
          'workLogs': 'A work log on this invoice was changed. Edit the draft and try again.',
        });
      }
      final now = _now();
      await _touchInvoice(
        actor,
        id,
        InvoicesCompanion(
          invoiceNumber: Value(number),
          status: Value(InvoiceStatus.finalized.name),
          companySnapshot: Value(company.toJson()),
          clientSnapshot: Value(clientSnapshot.toJson()),
          finalizedAt: Value(now),
          finalizedBy: Value(actor.userId),
        ),
      );
      await _setLogs(
        actor,
        logIds,
        status: WorkLogStatus.invoiced,
        invoiceId: Value(id),
      );
      await _audit(actor, id, 'finalize', {
        'invoiceNumber': number,
        'totalPaise': again.totalPaise,
      });
      return number;
    });
  }

  /// Cancels a finalized invoice. The record and its number are kept; its
  /// work logs become billable again.
  Future<void> cancel(
    WorkActor actor,
    String id, {
    required String reason,
  }) => _db.transaction(() async {
    _require(InvoicePolicy.canManage(actor.role), 'cancel invoices');
    final current = await _existing(actor, id);
    if (current.status != InvoiceStatus.finalized) {
      throw const InvoiceException({
        'status': 'Only finalized invoices can be cancelled.',
      });
    }
    if (reason.trim().isEmpty) {
      throw const InvoiceException({'reason': 'Enter a reason for cancelling'});
    }
    if (current.paidPaise > 0) {
      throw const InvoiceException({
        'status': 'Reverse the payments on this invoice before cancelling it.',
      });
    }
    final now = _now();
    await _touchInvoice(
      actor,
      id,
      InvoicesCompanion(
        status: Value(InvoiceStatus.cancelled.name),
        cancelledAt: Value(now),
        cancelledBy: Value(actor.userId),
        cancelReason: Value(reason.trim()),
      ),
    );
    await _setLogs(
      actor,
      current.lines.map((l) => l.workLogId).toList(),
      status: WorkLogStatus.approved,
      invoiceId: const Value(null),
    );
    await _audit(actor, id, 'cancel', {
      'reason': reason.trim(),
      'invoiceNumber': current.invoiceNumber,
    });
  });

  Future<void> setPdfPath(String companyId, String id, String path) =>
      (_db.update(_db.invoices)
            ..where((t) => t.id.equals(id) & t.companyId.equals(companyId)))
          .write(InvoicesCompanion(pdfPath: Value(path)));

  // --- Payments ---------------------------------------------------------------

  Future<String> recordPayment(
    WorkActor actor,
    String invoiceId,
    PaymentInput input,
  ) => _db.transaction(() async {
    _require(InvoicePolicy.canRecordPayment(actor.role), 'record payments');
    final invoice = await _existing(actor, invoiceId);
    if (invoice.status != InvoiceStatus.finalized) {
      throw const InvoiceException({
        'status': 'Payments can only be recorded on finalized invoices.',
      });
    }
    if (input.amountPaise <= 0) {
      throw const InvoiceException({
        'amount': 'Enter an amount more than zero',
      });
    }
    if (input.amountPaise > invoice.outstandingPaise) {
      throw const InvoiceException({
        'amount': 'Amount is more than the outstanding balance',
      });
    }
    final id = _newId();
    final now = _now();
    String? clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
    await _db
        .into(_db.payments)
        .insert(
          PaymentsCompanion.insert(
            id: id,
            companyId: actor.companyId,
            invoiceId: invoiceId,
            paymentDate: input.paymentDate,
            amountPaise: input.amountPaise,
            method: input.method.name,
            reference: Value(clean(input.reference)),
            notes: Value(clean(input.notes)),
            createdAt: now,
            updatedAt: now,
            createdBy: actor.userId,
            updatedBy: actor.userId,
          ),
        );
    await _audit(actor, invoiceId, 'payment', {
      'paymentId': id,
      'amountPaise': input.amountPaise,
      'method': input.method.name,
      'paymentDate': input.paymentDate,
    });
    return id;
  });

  /// Marks a payment as reversed (kept for the record, no longer counted).
  Future<void> reversePayment(
    WorkActor actor,
    String paymentId, {
    required String reason,
  }) => _db.transaction(() async {
    _require(InvoicePolicy.canRecordPayment(actor.role), 'reverse payments');
    final p =
        await (_db.select(_db.payments)..where(
              (t) =>
                  t.id.equals(paymentId) & t.companyId.equals(actor.companyId),
            ))
            .getSingleOrNull();
    if (p == null) throw StateError('Payment $paymentId not found');
    if (p.reversedAt != null) {
      throw const InvoiceException({
        'status': 'This payment is already reversed.',
      });
    }
    if (reason.trim().isEmpty) {
      throw const InvoiceException({
        'reason': 'Enter a reason for the reversal',
      });
    }
    final now = _now();
    await (_db.update(
      _db.payments,
    )..where((t) => t.id.equals(paymentId))).write(
      PaymentsCompanion(
        reversedAt: Value(now),
        reversedBy: Value(actor.userId),
        reverseReason: Value(reason.trim()),
        updatedAt: Value(now),
        updatedBy: Value(actor.userId),
        syncStatus: const Value('pending'),
        version: Value(p.version + 1),
      ),
    );
    await _audit(actor, p.invoiceId, 'payment_reverse', {
      'paymentId': paymentId,
      'amountPaise': p.amountPaise,
      'reason': reason.trim(),
    });
  });

  // ---------------------------------------------------------------------------

  static void _require(bool allowed, String what) {
    if (!allowed) {
      throw InvoiceException({'status': "You don't have permission to $what."});
    }
  }

  Future<InvoiceView> _existing(WorkActor actor, String id) async {
    final v = await _get(actor.companyId, id);
    if (v == null) throw StateError('Invoice $id not found');
    return v;
  }

  Future<int> _version(String id) async => (await (_db.select(
    _db.invoices,
  )..where((t) => t.id.equals(id))).getSingle()).version;

  Future<void> _touchInvoice(
    WorkActor actor,
    String id,
    InvoicesCompanion changes,
  ) async {
    await (_db.update(_db.invoices)
          ..where((t) => t.id.equals(id) & t.companyId.equals(actor.companyId)))
        .write(
          changes.copyWith(
            updatedAt: Value(_now()),
            updatedBy: Value(actor.userId),
            syncStatus: const Value('pending'),
            version: Value(await _version(id) + 1),
          ),
        );
  }

  /// Sets or clears the invoice reservation on work logs.
  Future<void> _reserve(
    WorkActor actor,
    Set<String> logIds,
    String? invoiceId,
  ) async {
    if (logIds.isEmpty) return;
    await _setLogs(actor, logIds.toList(), invoiceId: Value(invoiceId));
  }

  Future<void> _setLogs(
    WorkActor actor,
    List<String> ids, {
    WorkLogStatus? status,
    required Value<String?> invoiceId,
  }) async {
    final now = _now();
    for (final id in ids) {
      final log = await (_db.select(
        _db.workLogs,
      )..where((t) => t.id.equals(id))).getSingle();
      await (_db.update(_db.workLogs)..where((t) => t.id.equals(id))).write(
        WorkLogsCompanion(
          status: status == null ? const Value.absent() : Value(status.name),
          invoiceId: invoiceId,
          updatedAt: Value(now),
          updatedBy: Value(actor.userId),
          syncStatus: const Value('pending'),
          version: Value(log.version + 1),
        ),
      );
    }
  }

  Future<void> _audit(
    WorkActor actor,
    String id,
    String action,
    Map<String, Object?> details,
  ) => _db
      .into(_db.auditLogs)
      .insert(
        AuditLogsCompanion.insert(
          id: _newId(),
          companyId: Value(actor.companyId),
          actorId: actor.userId,
          action: action,
          entityType: _entity,
          entityId: id,
          details: Value(jsonEncode(details)),
          createdAt: _now(),
        ),
      );
}
