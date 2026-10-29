import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pickers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/sync_indicator.dart';
import '../../work/application/work_providers.dart';
import '../../work/data/work_log_repository.dart';
import '../../work/domain/work_log.dart';
import '../../work/presentation/work_widgets.dart';
import '../../license/presentation/license_widgets.dart';
import '../application/billing_providers.dart';
import '../data/invoice_number_service.dart';
import '../data/invoice_repository.dart';
import '../domain/invoice.dart';
import 'billing_screen.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(invoiceProvider(id));
    final actor = ref.watch(workActorProvider);
    final v = invoice.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(v?.displayNumber ?? 'Invoice'),
        actions: [
          if (v != null)
            IconButton(
              key: const Key('invoice_pdf'),
              tooltip: v.status == InvoiceStatus.draft
                  ? 'Preview PDF'
                  : 'View, print or share PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => context.push(Routes.invoicePdf(id)),
            ),
        ],
      ),
      body: switch (invoice) {
        AsyncValue(:final error?) when !invoice.hasValue => ErrorView(
          message: '$error',
        ),
        AsyncValue(hasValue: true) when v == null || actor == null =>
          const EmptyView(
            icon: Icons.receipt_long_outlined,
            title: 'Invoice not found',
          ),
        AsyncValue(hasValue: true) => _Body(invoice: v!, actor: actor!),
        _ => const LoadingView(),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.invoice, required this.actor});

  final InvoiceView invoice;
  final WorkActor actor;

  InvoiceRepository _repo(WidgetRef ref) => ref.read(invoiceRepositoryProvider);

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    try {
      await action();
      if (context.mounted) {
        showAppSnackBar(context, done, tone: StatusTone.success);
      }
    } on InvoiceException catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message, tone: StatusTone.danger);
      }
    } on InvoiceNumberUnavailable catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message, tone: StatusTone.warning);
      }
    }
  }

  Future<void> _finalize(BuildContext context, WidgetRef ref) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    if (ref.read(isOnlineProvider).value == false) {
      showAppSnackBar(
        context,
        'Connect to the internet to finalize — the invoice number is issued by the server.',
        tone: StatusTone.warning,
      );
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Finalize invoice?',
      message:
          'An official invoice number is issued and the invoice can no longer be edited. '
          'Company and client details are saved as they are now.',
      confirmLabel: 'Finalize',
    );
    if (!ok || !context.mounted) return;
    final company = ref.read(companySnapshotProvider);
    if (company == null) return;
    await _run(
      context,
      () => _repo(ref).finalize(
        actor,
        invoice.id,
        numbers: ref.read(invoiceNumberServiceProvider),
        company: company,
      ),
      'Invoice finalized',
    );
  }

  Future<void> _deleteDraft(BuildContext context, WidgetRef ref) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete draft?',
      message: 'The work logs on it become available to bill again.',
      confirmLabel: 'Delete draft',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await _repo(ref).deleteDraft(actor, invoice.id);
      if (context.mounted) {
        showAppSnackBar(context, 'Draft deleted');
        context.pop();
      }
    } on InvoiceException catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message, tone: StatusTone.danger);
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    final reason = await showReasonDialog(
      context,
      title: 'Cancel invoice ${invoice.displayNumber}?',
      label: 'Reason',
      message: 'The invoice and its number are kept with a Cancelled status. Its work logs can be billed again.',
      confirmLabel: 'Cancel invoice',
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    await _run(
      context,
      () => _repo(ref).cancel(actor, invoice.id, reason: reason),
      'Invoice cancelled',
    );
  }

  Future<void> _reverse(
    BuildContext context,
    WidgetRef ref,
    PaymentView p,
  ) async {
    if (!await ensureCanWrite(context, ref) || !context.mounted) return;
    final reason = await showReasonDialog(
      context,
      title: 'Reverse ${Money.format(p.amountPaise)}?',
      label: 'Reason',
      message: 'The payment stays on record but no longer counts towards the invoice.',
      confirmLabel: 'Reverse payment',
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    await _run(
      context,
      () => _repo(ref).reversePayment(actor, p.id, reason: reason),
      'Payment reversed',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = WorkLogRules.dateKey(DateTime.now());
    final state = invoice.stateOn(today);
    final canManage = InvoicePolicy.canManage(actor.role);
    final canPay = InvoicePolicy.canRecordPayment(actor.role);
    final draft = invoice.status == InvoiceStatus.draft;
    final finalized = invoice.status == InvoiceStatus.finalized;
    final client = invoice.clientSnapshot?.name ?? invoice.clientName;

    return ListView(
      padding: const EdgeInsets.all(AppSpace.page),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client, style: theme.textTheme.titleLarge),
              Text(
                'Invoice date ${formatDateKey(invoice.invoiceDate)} · Due ${formatDateKey(invoice.dueDate)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Work from ${formatDateKey(invoice.periodFrom)} to ${formatDateKey(invoice.periodTo)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpace.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Money.format(invoice.totalPaise),
                  key: const Key('invoice_total'),
                  style: theme.textTheme.displaySmall,
                ),
              ),
              if (finalized)
                Text(
                  invoice.outstandingPaise == 0
                      ? 'Fully paid'
                      : 'Paid ${Money.format(invoice.paidPaise)} · Outstanding ${Money.format(invoice.outstandingPaise)}',
                  key: const Key('invoice_balance'),
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  InvoiceStateChip(state),
                  SyncIndicator(state: recordSyncState(invoice.syncStatus)),
                ],
              ),
            ],
          ),
        ),
        if (invoice.status == InvoiceStatus.cancelled &&
            invoice.cancelReason != null) ...[
          const SizedBox(height: AppSpace.md),
          AppCard(
            color: AppStatusColors.of(context).neutral.withValues(alpha: .12),
            child: Text('Cancelled: ${invoice.cancelReason}'),
          ),
        ],
        if (draft && canManage) ...[
          const SizedBox(height: AppSpace.lg),
          AppButton(
            key: const Key('invoice_finalize'),
            label: 'Finalize invoice',
            icon: Icons.verified_outlined,
            onPressed: () => _finalize(context, ref),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const Key('invoice_edit'),
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(Routes.invoiceEdit(invoice.id)),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: AppButton(
                  key: const Key('invoice_delete'),
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _deleteDraft(context, ref),
                ),
              ),
            ],
          ),
        ],
        if (finalized && canPay && invoice.outstandingPaise > 0) ...[
          const SizedBox(height: AppSpace.lg),
          AppButton(
            key: const Key('invoice_record_payment'),
            label: 'Record payment',
            icon: Icons.payments_outlined,
            onPressed: () async {
              if (!await ensureCanWrite(context, ref) || !context.mounted) {
                return;
              }
              await showAppBottomSheet<void>(
                context,
                title: 'Record payment',
                builder: (_) => PaymentForm(invoice: invoice, actor: actor),
              );
            },
          ),
        ],
        const SectionHeader('Work billed'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final l in invoice.lines)
                _AmountRow(
                  title: '${formatWorkDate(l.workDate)} · ${l.siteName}',
                  subtitle:
                      '${l.machineName} · ${formatHours(l.workingHours)} × ${Money.format(l.ratePaise)}/h',
                  amount: Money.format(l.amountPaise),
                ),
              const Divider(),
              _AmountRow(
                title: 'Subtotal',
                amount: Money.format(invoice.subtotalPaise),
              ),
              if (invoice.discountPaise > 0)
                _AmountRow(
                  title: 'Discount',
                  amount: '− ${Money.format(invoice.discountPaise)}',
                ),
              _AmountRow(
                title: 'Total',
                amount: Money.format(invoice.totalPaise),
                strong: true,
              ),
              const SizedBox(height: AppSpace.sm),
            ],
          ),
        ),
        if (invoice.notes != null) ...[
          const SectionHeader('Notes'),
          Text(invoice.notes!),
        ],
        if (invoice.payments.isNotEmpty) ...[
          const SectionHeader('Payments'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final p in invoice.payments)
                  ListTile(
                    key: Key('payment_${p.id}'),
                    leading: Icon(
                      p.isValid ? Icons.check_circle_outline : Icons.undo,
                    ),
                    title: Text(
                      Money.format(p.amountPaise),
                      style: p.isValid
                          ? null
                          : const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            ),
                    ),
                    subtitle: Text(
                      [
                        '${formatDateKey(p.paymentDate)} · ${p.method.label}',
                        if (p.reference != null) 'Ref ${p.reference}',
                        if (!p.isValid) 'Reversed: ${p.reverseReason}',
                      ].join('\n'),
                    ),
                    trailing:
                        p.isValid &&
                            canPay &&
                            invoice.status != InvoiceStatus.cancelled
                        ? IconButton(
                            tooltip: 'Reverse payment',
                            icon: const Icon(Icons.undo),
                            onPressed: () => _reverse(context, ref, p),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ],
        if (finalized && canManage) ...[
          const SizedBox(height: AppSpace.lg),
          TextButton.icon(
            key: const Key('invoice_cancel'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            icon: const Icon(Icons.block),
            label: const Text('Cancel invoice'),
            onPressed: () => _cancel(context, ref),
          ),
        ],
        const SectionHeader('History'),
        _History(id: invoice.id, me: actor.userId),
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.id, required this.me});

  final String id;
  final String me;

  static String _label(WorkHistoryEntry e) => switch (e.action) {
    'create' => 'Draft created',
    'update' => 'Draft edited',
    'finalize' => 'Finalized as ${e.details?['invoiceNumber'] ?? ''}',
    'payment' =>
      'Payment ${Money.format((e.details?['amountPaise'] as int?) ?? 0)}',
    'payment_reverse' => 'Payment reversed: ${e.details?['reason'] ?? ''}',
    'cancel' => 'Cancelled: ${e.details?['reason'] ?? ''}',
    'delete' => 'Draft deleted',
    _ => e.action,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries =
        ref.watch(invoiceHistoryProvider(id)).value ??
        const <WorkHistoryEntry>[];
    return Column(
      children: [
        for (final e in entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.circle, size: 12),
            title: Text(_label(e)),
            subtitle: Text(
              '${e.actorId == me ? 'You' : 'Team member'} · ${formatCaptureTime(e.at)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

/// Bottom-sheet form for recording a payment against [invoice].
class PaymentForm extends ConsumerStatefulWidget {
  const PaymentForm({super.key, required this.invoice, required this.actor});

  final InvoiceView invoice;
  final WorkActor actor;

  @override
  ConsumerState<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<PaymentForm> {
  late final _amount = TextEditingController(
    text: Money.toInput(widget.invoice.outstandingPaise),
  );
  final _reference = TextEditingController();
  DateTime _date = DateTime.now();
  PaymentMethod _method = PaymentMethod.upi;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = Money.parse(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount more than zero');
      return;
    }
    if (amount > widget.invoice.outstandingPaise) {
      setState(
        () => _error =
            'Amount is more than the outstanding ${Money.format(widget.invoice.outstandingPaise)}',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(invoiceRepositoryProvider)
          .recordPayment(
            widget.actor,
            widget.invoice.id,
            PaymentInput(
              paymentDate: WorkLogRules.dateKey(_date),
              amountPaise: amount,
              method: _method,
              reference: _reference.text,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(
        context,
        'Payment of ${Money.format(amount)} recorded',
        tone: StatusTone.success,
      );
    } on InvoiceException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: const Key('payment_amount'),
            label: 'Amount (₹)',
            helper:
                'Outstanding ${Money.format(widget.invoice.outstandingPaise)}',
            controller: _amount,
            prefixIcon: Icons.currency_rupee,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            errorText: _error,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: AppSpace.lg),
          AppDateField(
            key: const Key('payment_date'),
            label: 'Payment date',
            value: _date,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _date = d),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final m in PaymentMethod.values)
                ChoiceChip(
                  key: Key('payment_method_${m.name}'),
                  label: Text(m.label),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            key: const Key('payment_reference'),
            label: 'Reference (UTR, cheque no.) — optional',
            controller: _reference,
          ),
          const SizedBox(height: AppSpace.xl),
          AppButton(
            key: const Key('payment_save'),
            label: 'Save payment',
            icon: Icons.check,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

/// Label (and optional detail) with a right-aligned amount that scales
/// down instead of overflowing with large text.
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.title,
    required this.amount,
    this.subtitle,
    this.strong = false,
  });

  final String title;
  final String? subtitle;
  final String amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = strong
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: style),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  style: strong ? style : theme.textTheme.titleSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
