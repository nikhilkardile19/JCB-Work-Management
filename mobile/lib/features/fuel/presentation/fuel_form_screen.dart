import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pickers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../evidence/photo_evidence.dart';
import '../../masters/application/masters_providers.dart';
import '../../masters/data/masters_repository.dart';
import '../../masters/domain/master_kind.dart';
import '../../work/application/work_providers.dart';
import '../../work/data/work_log_repository.dart';
import '../../work/presentation/work_widgets.dart';
import '../application/fuel_providers.dart';
import '../data/fuel_repository.dart';
import '../domain/fuel_entry.dart';

/// Create ([id] null) or edit a fuel entry.
class FuelFormScreen extends ConsumerWidget {
  const FuelFormScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(workActorProvider);
    final lists = {
      for (final k in [
        MasterKind.machines,
        MasterKind.petrolPumps,
        MasterKind.clients,
        MasterKind.sites,
      ])
        k: ref.watch(
          masterListProvider((
            kind: k,
            search: '',
            status: StatusFilter.all,
            clientId: null,
          )),
        ),
    };
    final existing = id == null ? null : ref.watch(fuelEntryProvider(id!));

    Widget body;
    if (actor == null ||
        lists.values.any((l) => !l.hasValue) ||
        (existing != null && !existing.hasValue)) {
      body = const LoadingView();
    } else if (existing != null && existing.value == null) {
      body = const EmptyView(title: 'Fuel entry not found');
    } else {
      final entry = existing?.value;
      final allowed = entry == null
          ? FuelPolicy.canRecord(actor.role)
          : FuelPolicy.canEdit(actor.role, entry, actor.userId);
      final missing = [
        MasterKind.machines,
        MasterKind.petrolPumps,
      ].where((k) => !lists[k]!.value!.any((r) => r.isActive)).toList();
      if (!allowed) {
        body = const PermissionDeniedView(
          permission: 'Edit',
          reason: 'You can only change fuel entries you recorded.',
        );
      } else if (entry == null && missing.isNotEmpty) {
        body = StateMessage(
          icon: Icons.playlist_add,
          tone: StatusTone.info,
          title: 'Add a ${missing.first.singular.toLowerCase()} first',
          message:
              'A fuel entry needs a machine and a petrol pump or supplier.',
          actionLabel: 'Add ${missing.first.singular.toLowerCase()}',
          onAction: () => context.push(Routes.masterNew(missing.first)),
        );
      } else {
        body = _FuelForm(
          actor: actor,
          existing: entry,
          masters: {for (final e in lists.entries) e.key: e.value.value!},
        );
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? 'Add fuel' : 'Edit fuel')),
      body: body,
    );
  }
}

class _FuelForm extends ConsumerStatefulWidget {
  const _FuelForm({
    required this.actor,
    required this.existing,
    required this.masters,
  });

  final WorkActor actor;
  final FuelView? existing;
  final Map<MasterKind, List<MasterRecord>> masters;

  @override
  ConsumerState<_FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends ConsumerState<_FuelForm> {
  late final FuelInput? _initial = widget.existing?.toInput();
  late DateTime _filledAt = _initial?.filledAt ?? DateTime.now();
  late String? _machineId =
      _initial?.machineId ?? _onlyActive(MasterKind.machines);
  late String? _pumpId =
      _initial?.pumpId ?? _onlyActive(MasterKind.petrolPumps);
  late String? _clientId = _initial?.clientId;
  late String? _siteId = _initial?.siteId;
  late PhotoEvidence? _receipt = _initial?.receipt;
  late final _litres = TextEditingController(
    text: _initial?.litresCl == null ? '' : Litres.toInput(_initial!.litresCl!),
  );
  late final _price = TextEditingController(
    text: _initial?.pricePerLitrePaise == null
        ? ''
        : Money.toInput(_initial!.pricePerLitrePaise!),
  );
  late final _notes = TextEditingController(text: _initial?.notes);

  final _sessionPhotos = <String>{};
  Map<String, String> _errors = {};
  bool _capturing = false;

  /// The receipt photo is taken and being stored with its location.
  bool _savingReceipt = false;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing == null && _pumpId != null) _prefillPrice(_pumpId!);
  }

  @override
  void dispose() {
    for (final c in [_litres, _price, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _onlyActive(MasterKind k) {
    final active = widget.masters[k]!.where((r) => r.isActive).toList();
    return active.length == 1 ? active.single.id : null;
  }

  /// Fuel prices rarely change between fills at the same pump.
  Future<void> _prefillPrice(String pumpId) async {
    final last = await ref
        .read(fuelRepositoryProvider)
        .lastPrice(widget.actor.companyId, pumpId);
    if (last != null && mounted && _price.text.trim().isEmpty) {
      setState(() => _price.text = Money.toInput(last));
    }
  }

  FuelInput _input() => FuelInput(
    filledAt: _filledAt,
    machineId: _machineId,
    pumpId: _pumpId,
    litresCl: Litres.parse(_litres.text),
    pricePerLitrePaise: Money.parse(_price.text),
    clientId: _clientId,
    siteId: _siteId,
    receipt: _receipt,
    notes: _notes.text,
  );

  void _touch() => setState(() {
    _dirty = true;
    _errors = {};
  });

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_filledAt),
    );
    if (t == null) return;
    setState(
      () => _filledAt = DateTime(
        _filledAt.year,
        _filledAt.month,
        _filledAt.day,
        t.hour,
        t.minute,
      ),
    );
    _touch();
  }

  Future<void> _captureReceipt() async {
    setState(() => _capturing = true);
    try {
      final photo = await captureEvidencePhoto(
        context,
        ref,
        companyId: widget.actor.companyId,
        onSaving: () {
          if (mounted) setState(() => _savingReceipt = true);
        },
      );
      if (photo == null || !mounted) return;
      _sessionPhotos.add(photo.photoPath);
      if (_sessionPhotos.remove(_receipt?.photoPath)) {
        await ref.read(photoStoreProvider).discard(_receipt!.photoPath);
      }
      setState(() => _receipt = photo);
      _touch();
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
          _savingReceipt = false;
        });
      }
    }
  }

  Future<void> _removeReceipt() async {
    if (_sessionPhotos.remove(_receipt?.photoPath)) {
      await ref.read(photoStoreProvider).discard(_receipt!.photoPath);
    }
    setState(() => _receipt = null);
    _touch();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final input = _input();
    final errors = {
      if (_litres.text.trim().isNotEmpty && input.litresCl == null)
        'litres': 'Enter litres like 50 or 50.5',
      if (_price.text.trim().isNotEmpty && input.pricePerLitrePaise == null)
        'price': 'Enter a price like 95.50',
      ...FuelRules.errors(input),
    };
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      showAppSnackBar(context, errors.values.first, tone: StatusTone.danger);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(fuelRepositoryProvider)
          .save(widget.actor, input, id: widget.existing?.id);
      if (!mounted) return;
      _sessionPhotos.clear();
      setState(() => _dirty = false);
      showAppSnackBar(context, 'Fuel entry saved', tone: StatusTone.success);
      context.pop();
    } on FuelException catch (e) {
      if (mounted) {
        setState(() => _errors = e.fieldErrors);
        showAppSnackBar(
          context,
          e.fieldErrors.values.first,
          tone: StatusTone.danger,
        );
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          "Couldn't save. Please try again.",
          tone: StatusTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<AppDropdownOption<String>> _options(
    MasterKind k,
    String? current, {
    String? clientId,
  }) => [
    for (final r in widget.masters[k]!)
      if ((r.isActive || r.id == current) &&
          (clientId == null || r.clientId == clientId))
        AppDropdownOption(r.id, r.isActive ? r.name : '${r.name} (inactive)'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _input().totalPaise;
    const gap = SizedBox(height: AppSpace.lg);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showConfirmDialog(
          context,
          title: 'Discard changes?',
          message: "This fuel entry hasn't been saved.",
          confirmLabel: 'Discard',
          cancelLabel: 'Keep editing',
          destructive: true,
        );
        if (!discard || !mounted) return;
        final store = ref.read(photoStoreProvider);
        for (final p in _sessionPhotos) {
          await store.discard(p);
        }
        _sessionPhotos.clear();
        setState(() => _dirty = false);
        if (context.mounted) context.pop();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          0,
          AppSpace.page,
          AppSpace.xxl,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Fill'),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppDateField(
                    key: const Key('fuel_date'),
                    label: 'Date',
                    value: _filledAt,
                    lastDate: DateTime.now(),
                    onChanged: (d) {
                      setState(
                        () => _filledAt = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          _filledAt.hour,
                          _filledAt.minute,
                        ),
                      );
                      _touch();
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    key: const Key('fuel_time'),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time'),
                      child: Text(
                        DateFormat('h:mm a').format(_filledAt),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_errors['filledAt'] case final e?) _FieldError(e),
            gap,
            AppDropdownField<String>(
              key: const Key('fuel_machine'),
              label: 'Machine',
              prefixIcon: MasterKind.machines.icon,
              value: _machineId,
              options: _options(MasterKind.machines, _machineId),
              onChanged: (v) {
                setState(() => _machineId = v);
                _touch();
              },
            ),
            if (_errors['machineId'] case final e?) _FieldError(e),
            gap,
            AppDropdownField<String>(
              key: const Key('fuel_pump'),
              label: 'Petrol pump / supplier',
              prefixIcon: MasterKind.petrolPumps.icon,
              value: _pumpId,
              options: _options(MasterKind.petrolPumps, _pumpId),
              onChanged: (v) {
                setState(() => _pumpId = v);
                _touch();
                if (v != null) _prefillPrice(v);
              },
            ),
            if (_errors['pumpId'] case final e?) _FieldError(e),
            gap,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    key: const Key('fuel_litres'),
                    label: 'Litres',
                    controller: _litres,
                    prefixIcon: Icons.water_drop_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    errorText: _errors['litres'],
                    onChanged: (_) => _touch(),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: AppTextField(
                    key: const Key('fuel_price'),
                    label: '₹ per litre',
                    controller: _price,
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    errorText: _errors['price'],
                    onChanged: (_) => _touch(),
                  ),
                ),
              ],
            ),
            gap,
            Semantics(
              liveRegion: true,
              child: AppCard(
                color: theme.colorScheme.primary.withValues(alpha: .12),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: AppSize.iconLg),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: theme.textTheme.labelLarge),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              total == null
                                  ? 'Enter litres and price'
                                  : Money.format(total),
                              key: const Key('fuel_total'),
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          Text(
                            'Calculated as litres × price',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeader('Receipt'),
            AppCard(
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 72,
                    child: _savingReceipt
                        ? const Center(child: CircularProgressIndicator())
                        : _receipt != null
                        ? EvidencePhoto(path: _receipt!.photoPath)
                        : const Icon(
                            Icons.receipt_long_outlined,
                            size: AppSize.iconLg,
                          ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _receipt == null
                              ? 'Optional, but recommended as proof of purchase.'
                              : evidenceMeta(
                                  capturedAt: _receipt!.capturedAt,
                                  status: _receipt!.locationStatus,
                                  lat: _receipt!.lat,
                                  lng: _receipt!.lng,
                                  accuracy: _receipt!.accuracy,
                                ),
                          style: theme.textTheme.bodySmall,
                        ),
                        Wrap(
                          spacing: AppSpace.sm,
                          children: [
                            TextButton.icon(
                              key: const Key('fuel_receipt_photo'),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(
                                _receipt == null ? 'Take photo' : 'Retake',
                              ),
                              onPressed: _capturing ? null : _captureReceipt,
                            ),
                            if (_receipt != null)
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove'),
                                onPressed: _capturing ? null : _removeReceipt,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader('Allocate (optional)'),
            AppDropdownField<String?>(
              key: const Key('fuel_client'),
              label: 'Client',
              prefixIcon: MasterKind.clients.icon,
              value: _clientId,
              options: [
                const AppDropdownOption<String?>(null, 'Not allocated'),
                for (final o in _options(MasterKind.clients, _clientId))
                  AppDropdownOption<String?>(o.value, o.label),
              ],
              onChanged: (v) {
                setState(() {
                  _clientId = v;
                  _siteId = null;
                });
                _touch();
              },
            ),
            if (_clientId != null) ...[
              gap,
              AppDropdownField<String?>(
                key: Key('fuel_site_$_clientId'),
                label: 'Site',
                prefixIcon: MasterKind.sites.icon,
                value: _siteId,
                options: [
                  const AppDropdownOption<String?>(null, 'Any site'),
                  for (final o in _options(
                    MasterKind.sites,
                    _siteId,
                    clientId: _clientId,
                  ))
                    AppDropdownOption<String?>(o.value, o.label),
                ],
                onChanged: (v) {
                  setState(() => _siteId = v);
                  _touch();
                },
              ),
              if (_errors['siteId'] case final e?) _FieldError(e),
            ],
            gap,
            AppTextField(
              key: const Key('fuel_notes'),
              label: 'Notes (optional)',
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _touch(),
            ),
            if (_errors['status'] case final e?) ...[gap, _FieldError(e)],
            const SizedBox(height: AppSpace.xl),
            AppButton(
              key: const Key('fuel_save'),
              label: 'Save fuel entry',
              icon: Icons.check,
              loading: _saving,
              onPressed: _capturing ? null : _save,
            ),
          ],
        ),
      ),
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
