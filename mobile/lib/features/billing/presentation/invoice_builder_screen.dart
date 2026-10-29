import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pickers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../masters/application/masters_providers.dart';
import '../../masters/data/masters_repository.dart';
import '../../masters/domain/master_kind.dart';
import '../../work/application/work_providers.dart';
import '../../work/data/work_log_repository.dart';
import '../../work/domain/work_log.dart';
import '../../work/presentation/work_widgets.dart';
import '../application/billing_providers.dart';
import '../data/invoice_repository.dart';
import '../domain/invoice.dart';

/// Create ([id] null) or edit a draft invoice.
class InvoiceBuilderScreen extends ConsumerWidget {
  const InvoiceBuilderScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(workActorProvider);
    final clients = ref.watch(
      masterListProvider((
        kind: MasterKind.clients,
        search: '',
        status: StatusFilter.all,
        clientId: null,
      )),
    );
    final sites = ref.watch(
      masterListProvider((
        kind: MasterKind.sites,
        search: '',
        status: StatusFilter.all,
        clientId: null,
      )),
    );
    final existing = id == null ? null : ref.watch(invoiceProvider(id!));

    Widget body;
    if (actor == null ||
        !clients.hasValue ||
        !sites.hasValue ||
        (existing != null && !existing.hasValue)) {
      body = const LoadingView();
    } else if (!InvoicePolicy.canManage(actor.role)) {
      body = const PermissionDeniedView(
        permission: 'Invoicing',
        reason: 'Only owners, admins and accounts staff can create invoices.',
      );
    } else if (existing != null &&
        (existing.value == null ||
            existing.value!.status != InvoiceStatus.draft)) {
      body = const EmptyView(title: 'This invoice can no longer be edited');
    } else {
      body = _Builder(
        actor: actor,
        existing: existing?.value,
        clients: clients.value!,
        siteRates: {
          for (final s in sites.value!)
            s.id: s['defaultHourlyRatePaise'] as int?,
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(id == null ? 'New invoice' : 'Edit draft invoice'),
      ),
      body: body,
    );
  }
}

class _Builder extends ConsumerStatefulWidget {
  const _Builder({
    required this.actor,
    required this.existing,
    required this.clients,
    required this.siteRates,
  });

  final WorkActor actor;
  final InvoiceView? existing;
  final List<MasterRecord> clients;
  final Map<String, int?> siteRates;

  @override
  ConsumerState<_Builder> createState() => _BuilderState();
}

typedef _Group = (String siteId, String machineId);

class _BuilderState extends ConsumerState<_Builder> {
  late final _now = DateTime.now();
  late String? _clientId = widget.existing?.clientId;
  late DateTime _from = widget.existing == null
      ? DateTime(_now.year, _now.month)
      : DateTime.parse(widget.existing!.periodFrom);
  late DateTime _to = widget.existing == null
      ? _now
      : DateTime.parse(widget.existing!.periodTo);
  late DateTime _invoiceDate = widget.existing == null
      ? _now
      : DateTime.parse(widget.existing!.invoiceDate);
  late int _terms = widget.existing?.paymentTermsDays ?? 15;
  late final _discount = TextEditingController(
    text: (widget.existing?.discountPaise ?? 0) == 0
        ? ''
        : Money.toInput(widget.existing!.discountPaise),
  );
  late final _notes = TextEditingController(text: widget.existing?.notes);

  /// Selected work log IDs; null until candidates first load (then all
  /// candidates are selected by default for a new invoice).
  late Set<String>? _selected = widget.existing?.lines
      .map((l) => l.workLogId)
      .toSet();

  /// Rate text per (site, machine) group.
  final _rates = <_Group, TextEditingController>{};
  Map<String, String> _errors = {};
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    for (final l in widget.existing?.lines ?? const <InvoiceLineView>[]) {
      _rates.putIfAbsent((
        l.siteId,
        l.machineId,
      ), () => TextEditingController(text: Money.toInput(l.ratePaise)));
    }
  }

  @override
  void dispose() {
    for (final c in [..._rates.values, _discount, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _rateFor(_Group g) => _rates.putIfAbsent(g, () {
    final def = widget.siteRates[g.$1];
    return TextEditingController(text: def == null ? '' : Money.toInput(def));
  });

  void _touch() => setState(() {
    _dirty = true;
    _errors = {};
  });

  Future<void> _save(List<WorkLogView> candidates) async {
    FocusScope.of(context).unfocus();
    final chosen = candidates
        .where((l) => _selected?.contains(l.id) ?? false)
        .toList();
    final errors = <String, String>{
      if (_clientId == null) 'clientId': 'Select a client',
      if (chosen.isEmpty) 'workLogs': 'Select at least one work log',
    };
    final rates = <String, int>{};
    for (final l in chosen) {
      final text = _rateFor((l.siteId, l.machineId)).text;
      final r = text.trim().isEmpty ? 0 : Money.parse(text);
      if (r == null) {
        errors['rates'] = 'Enter rates like 1500 or 1500.50';
      } else {
        rates[l.id] = r;
      }
    }
    final discount = _discount.text.trim().isEmpty
        ? 0
        : Money.parse(_discount.text);
    if (discount == null) errors['discount'] = 'Enter a discount like 500';
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      showAppSnackBar(context, errors.values.first, tone: StatusTone.danger);
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(invoiceRepositoryProvider)
          .saveDraft(
            widget.actor,
            InvoiceDraftInput(
              clientId: _clientId!,
              periodFrom: WorkLogRules.dateKey(_from),
              periodTo: WorkLogRules.dateKey(_to),
              invoiceDate: WorkLogRules.dateKey(_invoiceDate),
              paymentTermsDays: _terms,
              discountPaise: discount!,
              notes: _notes.text,
              workLogRates: rates,
            ),
            id: widget.existing?.id,
          );
      if (!mounted) return;
      setState(() => _dirty = false);
      showAppSnackBar(context, 'Draft invoice saved', tone: StatusTone.success);
      if (widget.existing == null) {
        context.pushReplacement(Routes.invoiceDetail(id));
      } else {
        context.pop();
      }
    } on InvoiceException catch (e) {
      if (mounted) {
        setState(() => _errors = e.fieldErrors);
        showAppSnackBar(context, e.message, tone: StatusTone.danger);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = _clientId == null
        ? const AsyncValue<List<WorkLogView>>.data([])
        : ref.watch(
            invoiceCandidatesProvider((
              clientId: _clientId!,
              from: WorkLogRules.dateKey(_from),
              to: WorkLogRules.dateKey(_to),
              invoiceId: widget.existing?.id,
            )),
          );
    final list = candidates.value ?? const <WorkLogView>[];
    // New invoices start with everything billable selected.
    if (_selected == null && candidates.hasValue && _clientId != null) {
      _selected = list.map((l) => l.id).toSet();
    }
    final selected = _selected ?? const <String>{};

    final groups = <_Group, List<WorkLogView>>{};
    for (final l in list) {
      groups.putIfAbsent((l.siteId, l.machineId), () => []).add(l);
    }
    var subtotal = 0;
    for (final l in list.where((l) => selected.contains(l.id))) {
      final rate = Money.parse(_rateFor((l.siteId, l.machineId)).text) ?? 0;
      subtotal += InvoiceMath.lineAmount(l.workingHours!, rate);
    }
    final discount = Money.parse(_discount.text) ?? 0;
    const gap = SizedBox(height: AppSpace.lg);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showConfirmDialog(
          context,
          title: 'Discard changes?',
          message: "This invoice hasn't been saved.",
          confirmLabel: 'Discard',
          cancelLabel: 'Keep editing',
          destructive: true,
        );
        if (discard && mounted) {
          setState(() => _dirty = false);
          if (context.mounted) context.pop();
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          0,
          AppSpace.page,
          AppSpace.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Client and period'),
            AppDropdownField<String>(
              key: const Key('invoice_client'),
              label: 'Client',
              prefixIcon: MasterKind.clients.icon,
              value: _clientId,
              options: [
                for (final c in widget.clients)
                  if (c.isActive || c.id == _clientId)
                    AppDropdownOption(c.id, c.name),
              ],
              onChanged: (v) {
                setState(() {
                  _clientId = v;
                  _selected = null;
                });
                _touch();
              },
            ),
            if (_errors['clientId'] case final e?) _FieldError(e),
            gap,
            Row(
              children: [
                Expanded(
                  child: AppDateField(
                    key: const Key('invoice_from'),
                    label: 'From',
                    value: _from,
                    lastDate: _now,
                    onChanged: (d) {
                      setState(() {
                        _from = d;
                        if (widget.existing == null) _selected = null;
                      });
                      _touch();
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: AppDateField(
                    key: const Key('invoice_to'),
                    label: 'To',
                    value: _to,
                    lastDate: _now,
                    onChanged: (d) {
                      setState(() {
                        _to = d;
                        if (widget.existing == null) _selected = null;
                      });
                      _touch();
                    },
                  ),
                ),
              ],
            ),
            if (_errors['period'] case final e?) _FieldError(e),
            const SectionHeader('Work to bill'),
            if (_clientId == null)
              const Text(
                'Select a client to see approved work that has not been billed.',
              )
            else if (!candidates.hasValue)
              const LoadingView()
            else if (list.isEmpty)
              const StateMessage(
                icon: Icons.inventory_2_outlined,
                title: 'Nothing to bill',
                message: 'There is no approved, unbilled work for this client in this period.',
              )
            else
              for (final MapEntry(key: g, value: logs) in groups.entries) ...[
                _GroupCard(
                  key: Key('invoice_group_${g.$1}_${g.$2}'),
                  logs: logs,
                  selected: selected,
                  rate: _rateFor(g),
                  onToggle: (id, on) {
                    setState(
                      () => on
                          ? _selected = {...selected, id}
                          : _selected = ({...selected}..remove(id)),
                    );
                    _touch();
                  },
                  onToggleAll: (on) {
                    final ids = logs.map((l) => l.id);
                    setState(
                      () => _selected = on
                          ? {...selected, ...ids}
                          : ({...selected}..removeAll(ids)),
                    );
                    _touch();
                  },
                  onRateChanged: _touch,
                ),
                const SizedBox(height: AppSpace.md),
              ],
            if (_errors['workLogs'] case final e?) _FieldError(e),
            if (_errors['rates'] case final e?) _FieldError(e),
            const SectionHeader('Invoice details'),
            Row(
              children: [
                Expanded(
                  child: AppDateField(
                    key: const Key('invoice_date'),
                    label: 'Invoice date',
                    value: _invoiceDate,
                    onChanged: (d) {
                      setState(() => _invoiceDate = d);
                      _touch();
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: AppDropdownField<int>(
                    key: const Key('invoice_terms'),
                    label: 'Payment due',
                    value: _terms,
                    options: [
                      for (final d in {0, 7, 15, 30, 45, 60, _terms})
                        AppDropdownOption(
                          d,
                          d == 0 ? 'On receipt' : 'In $d days',
                        ),
                    ],
                    onChanged: (v) {
                      setState(() => _terms = v ?? 15);
                      _touch();
                    },
                  ),
                ),
              ],
            ),
            gap,
            AppTextField(
              key: const Key('invoice_discount'),
              label: 'Discount ₹ (optional)',
              controller: _discount,
              prefixIcon: Icons.discount_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              errorText: _errors['discount'],
              onChanged: (_) => _touch(),
            ),
            gap,
            AppTextField(
              key: const Key('invoice_notes'),
              label: 'Notes / terms (optional)',
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _touch(),
            ),
            gap,
            AppCard(
              color: theme.colorScheme.primary.withValues(alpha: .12),
              child: Column(
                children: [
                  _TotalRow('Subtotal', Money.format(subtotal)),
                  if (discount > 0)
                    _TotalRow('Discount', '− ${Money.format(discount)}'),
                  const Divider(height: AppSpace.lg),
                  _TotalRow(
                    'Total',
                    Money.format(subtotal - discount),
                    strong: true,
                    valueKey: const Key('invoice_builder_total'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            AppButton(
              key: const Key('invoice_save'),
              label: 'Save draft',
              icon: Icons.save_outlined,
              loading: _saving,
              onPressed: () => _save(list),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Rates entered here apply to this invoice only; site rates are not changed.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    super.key,
    required this.logs,
    required this.selected,
    required this.rate,
    required this.onToggle,
    required this.onToggleAll,
    required this.onRateChanged,
  });

  final List<WorkLogView> logs;
  final Set<String> selected;
  final TextEditingController rate;
  final void Function(String id, bool on) onToggle;
  final ValueChanged<bool> onToggleAll;
  final VoidCallback onRateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = logs.first;
    final chosen = logs.where((l) => selected.contains(l.id)).toList();
    final hours = chosen.fold(0, (a, l) => a + l.workingHours!);
    final all = chosen.length == logs.length;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: all ? true : (chosen.isEmpty ? false : null),
            tristate: true,
            onChanged: (_) => onToggleAll(!all),
            title: Text(
              '${first.siteName} · ${first.machineName}',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              '${chosen.length} of ${logs.length} logs · ${formatHours(hours)}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpace.sm),
            child: AppTextField(
              key: const Key('group_rate'),
              label: 'Rate per hour (₹)',
              controller: rate,
              prefixIcon: Icons.currency_rupee,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => onRateChanged(),
            ),
          ),
          for (final l in logs)
            CheckboxListTile(
              key: Key('invoice_log_${l.id}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: selected.contains(l.id),
              onChanged: (v) => onToggle(l.id, v ?? false),
              title: Text(formatWorkDate(l.workDate)),
              secondary: Text(formatHours(l.workingHours)),
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.strong = false, this.valueKey});

  final String label;
  final String value;
  final bool strong;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final style = strong
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value, key: valueKey, style: style),
          ),
        ),
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: AppSpace.lg, top: AppSpace.xs),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
