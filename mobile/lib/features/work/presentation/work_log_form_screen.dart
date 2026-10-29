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
import '../../evidence/photo_evidence.dart';
import '../../masters/application/masters_providers.dart';
import '../../masters/data/masters_repository.dart';
import '../../masters/domain/master_kind.dart';
import '../application/work_providers.dart';
import '../data/work_log_repository.dart';
import '../domain/work_log.dart';
import 'work_widgets.dart';

enum WorkFormMode { edit, correct }

/// Create ([id] null) or edit a work log, or correct an approved one.
class WorkLogFormScreen extends ConsumerWidget {
  const WorkLogFormScreen({super.key, this.id, this.mode = WorkFormMode.edit});

  final String? id;
  final WorkFormMode mode;

  AsyncValue<List<MasterRecord>> _masters(WidgetRef ref, MasterKind kind) =>
      ref.watch(
        masterListProvider((
          kind: kind,
          search: '',
          status: StatusFilter.all,
          clientId: null,
        )),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(workActorProvider);
    final title = mode == WorkFormMode.correct
        ? 'Correct work log'
        : id == null
        ? 'Log work'
        : 'Edit work log';
    final lists = {
      for (final k in [
        MasterKind.clients,
        MasterKind.sites,
        MasterKind.machines,
        MasterKind.operators,
      ])
        k: _masters(ref, k),
    };
    final existing = id == null ? null : ref.watch(workLogProvider(id!));

    Widget body;
    if (actor == null ||
        lists.values.any((l) => !l.hasValue) ||
        (existing != null && !existing.hasValue)) {
      body = const LoadingView();
    } else if (existing != null && existing.value == null) {
      body = const EmptyView(title: 'Work log not found');
    } else {
      final log = existing?.value;
      final allowed = log == null
          ? WorkLogPolicy.canCreate(actor.role)
          : mode == WorkFormMode.correct
          ? WorkLogPolicy.canCorrect(actor.role, log)
          : WorkLogPolicy.canEdit(actor.role, log, actor.userId);
      final active = {
        for (final e in lists.entries)
          e.key: e.value.value!.where((r) => r.isActive).toList(),
      };
      final missing = [
        MasterKind.clients,
        MasterKind.sites,
        MasterKind.machines,
      ].where((k) => active[k]!.isEmpty).toList();

      if (!allowed) {
        body = const PermissionDeniedView(
          permission: 'Edit',
          reason: "You can't change this work log in its current state.",
        );
      } else if (log == null && missing.isNotEmpty) {
        body = StateMessage(
          icon: Icons.playlist_add,
          tone: StatusTone.info,
          title: 'Set up your ${missing.first.plural.toLowerCase()} first',
          message: 'A work log needs a client, a site and a machine. Add them under More → Masters.',
          actionLabel: 'Add ${missing.first.singular.toLowerCase()}',
          onAction: () => context.push(Routes.masterNew(missing.first)),
        );
      } else {
        body = _WorkLogForm(
          actor: actor,
          existing: log,
          mode: mode,
          masters: {for (final e in lists.entries) e.key: e.value.value!},
        );
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}

class _WorkLogForm extends ConsumerStatefulWidget {
  const _WorkLogForm({
    required this.actor,
    required this.existing,
    required this.mode,
    required this.masters,
  });

  final WorkActor actor;
  final WorkLogView? existing;
  final WorkFormMode mode;
  final Map<MasterKind, List<MasterRecord>> masters;

  @override
  ConsumerState<_WorkLogForm> createState() => _WorkLogFormState();
}

class _WorkLogFormState extends ConsumerState<_WorkLogForm> {
  late final WorkLogInput _initial =
      widget.existing?.toInput() ??
      WorkLogInput(
        workDate: WorkLogRules.dateKey(DateTime.now()),
        clientId: null,
        siteId: null,
        machineId: null,
        start: const MeterCapture(),
      );
  late DateTime _date = DateTime.parse(_initial.workDate);
  late String? _clientId = _initial.clientId;
  late String? _siteId = _initial.siteId;
  late String? _machineId = _initial.machineId;
  late String? _operatorId = _initial.operatorId;
  late MeterCapture _start = _initial.start;
  late MeterCapture _end = _initial.end;
  late final _startText = TextEditingController(
    text: _initial.start.reading == null
        ? ''
        : MeterReading.toInput(_initial.start.reading!),
  );
  late final _endText = TextEditingController(
    text: _initial.end.reading == null
        ? ''
        : MeterReading.toInput(_initial.end.reading!),
  );
  late final _reason = TextEditingController(text: _initial.manualReason);
  late final _notes = TextEditingController(text: _initial.notes);

  /// Photos taken in this session; deleted if the form is discarded.
  final _sessionPhotos = <String>{};
  ReadingContext _ctx = const ReadingContext();
  Map<String, String> _errors = {};
  bool? _capturingStart;
  String? _busy;
  bool _dirty = false;

  bool get _isNew => widget.existing == null;
  bool get _correcting => widget.mode == WorkFormMode.correct;
  String? get _excludeId => widget.existing?.id;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _prefillFromLastLog();
    } else {
      _refreshContext();
    }
  }

  @override
  void dispose() {
    for (final c in [_startText, _endText, _reason, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isActive(MasterKind k, String? id) =>
      widget.masters[k]!.any((r) => r.id == id && r.isActive);

  /// Field crews usually repeat yesterday's client/site/machine.
  Future<void> _prefillFromLastLog() async {
    final logs = await ref
        .read(workLogRepositoryProvider)
        .watchList(widget.actor.companyId)
        .first;
    final last = logs
        .where(
          (l) =>
              l.createdBy == widget.actor.userId &&
              l.status != WorkLogStatus.cancelled,
        )
        .firstOrNull;
    if (!mounted) return;
    if (last != null &&
        _isActive(MasterKind.clients, last.clientId) &&
        _isActive(MasterKind.sites, last.siteId) &&
        _isActive(MasterKind.machines, last.machineId)) {
      setState(() {
        _clientId = last.clientId;
        _siteId = last.siteId;
        _machineId = last.machineId;
        if (_isActive(MasterKind.operators, last.operatorId)) {
          _operatorId = last.operatorId;
        }
      });
    } else {
      _autoPickSingle();
    }
    await _refreshContext();
  }

  /// Selects the only active option when there is exactly one.
  void _autoPickSingle() {
    String? only(MasterKind k, {String? clientId}) {
      final options = widget.masters[k]!
          .where(
            (r) => r.isActive && (clientId == null || r.clientId == clientId),
          )
          .toList();
      return options.length == 1 ? options.single.id : null;
    }

    setState(() {
      _clientId ??= only(MasterKind.clients);
      if (_clientId != null) {
        _siteId ??= only(MasterKind.sites, clientId: _clientId);
      }
      _machineId ??= only(MasterKind.machines);
    });
  }

  Future<void> _refreshContext() async {
    final machine = _machineId;
    if (machine == null) return;
    final ctx = await ref
        .read(workLogRepositoryProvider)
        .readingContext(
          widget.actor.companyId,
          machine,
          WorkLogRules.dateKey(_date),
          excludeId: _excludeId,
        );
    if (mounted) setState(() => _ctx = ctx);
  }

  WorkLogInput _input({Set<AnomalyFlag> flags = const {}}) => WorkLogInput(
    workDate: WorkLogRules.dateKey(_date),
    clientId: _clientId,
    siteId: _siteId,
    machineId: _machineId,
    operatorId: _operatorId,
    start: _start.withReading(MeterReading.parse(_startText.text)),
    end: _end.withReading(MeterReading.parse(_endText.text)),
    manualReason: _reason.text,
    notes: _notes.text,
    anomalyFlags: flags,
  );

  void _touch() {
    if (!_dirty || _errors.isNotEmpty) {
      setState(() {
        _dirty = true;
        _errors = {};
      });
    } else {
      setState(() {});
    }
  }

  // --- Photos -----------------------------------------------------------------

  Future<void> _capture({required bool start}) async {
    setState(() => _capturingStart = start);
    try {
      final photo = await captureEvidencePhoto(
        context,
        ref,
        companyId: widget.actor.companyId,
      );
      if (photo == null || !mounted) return;
      _sessionPhotos.add(photo.photoPath);
      final previous = start ? _start : _end;
      if (_sessionPhotos.remove(previous.photoPath)) {
        await ref.read(photoStoreProvider).discard(previous.photoPath!);
      }
      final cap = MeterCapture(
        photoPath: photo.photoPath,
        capturedAt: photo.capturedAt,
        lat: photo.lat,
        lng: photo.lng,
        accuracy: photo.accuracy,
        locationStatus: photo.locationStatus,
      );
      setState(() => start ? _start = cap : _end = cap);
      _touch();
    } finally {
      if (mounted) setState(() => _capturingStart = null);
    }
  }

  Future<void> _removePhoto({required bool start}) async {
    final path = (start ? _start : _end).photoPath;
    if (_sessionPhotos.remove(path)) {
      await ref.read(photoStoreProvider).discard(path!);
    }
    setState(() {
      if (start) {
        _start = _start.withoutPhoto();
      } else {
        _end = _end.withoutPhoto();
      }
    });
    _touch();
  }

  // --- Saving -----------------------------------------------------------------

  Map<String, String> _localErrors({required bool submitting}) => {
    if (_clientId == null) 'clientId': 'Select a client',
    if (_siteId == null) 'siteId': 'Select a site',
    if (_machineId == null) 'machineId': 'Select a machine',
    if (MeterReading.parse(_startText.text) == null &&
        _startText.text.trim().isNotEmpty)
      'start': 'Enter hours like 1234 or 1234.5',
    if (MeterReading.parse(_endText.text) == null &&
        _endText.text.trim().isNotEmpty)
      'end': 'Enter hours like 1234 or 1234.5',
    ...WorkLogRules.readingErrors(_input(), requireEnd: submitting),
  };

  Future<void> _run(
    String busy,
    Future<String> Function(Set<AnomalyFlag> flags) action,
  ) async {
    FocusScope.of(context).unfocus();
    final errors = _localErrors(submitting: busy != 'draft');
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      showAppSnackBar(context, errors.values.first, tone: StatusTone.danger);
      return;
    }
    setState(() => _busy = busy);
    var flags = <AnomalyFlag>{};
    try {
      while (true) {
        try {
          final message = await action(flags);
          if (!mounted) return;
          _sessionPhotos.clear();
          setState(() => _dirty = false);
          showAppSnackBar(context, message, tone: StatusTone.success);
          context.pop();
          return;
        } on WorkLogNeedsConfirmation catch (e) {
          if (!mounted) return;
          // Not "busy" while the user reads the warnings.
          setState(() => _busy = null);
          final ok = await showConfirmDialog(
            context,
            title: 'Please check',
            message: e.warnings.map((w) => '• ${w.message}').join('\n\n'),
            confirmLabel: 'Save anyway',
            cancelLabel: 'Review',
          );
          if (!ok || !mounted) return;
          setState(() => _busy = busy);
          flags = {...flags, ...e.warnings.map((w) => w.flag)};
        }
      }
    } on WorkLogException catch (e) {
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
      if (mounted) setState(() => _busy = null);
    }
  }

  WorkLogRepository get _repo => ref.read(workLogRepositoryProvider);

  Future<void> _saveDraft() => _run('draft', (_) async {
    await _repo.saveDraft(widget.actor, _input(), id: _excludeId);
    return 'Saved. Add the end reading when the shift is over.';
  });

  Future<void> _submit() => _run('submit', (flags) async {
    final (_, status) = await _repo.submit(
      widget.actor,
      _input(flags: flags),
      id: _excludeId,
    );
    return status == WorkLogStatus.approved
        ? 'Work log approved'
        : 'Submitted for approval';
  });

  Future<void> _saveCorrection() async {
    final reason = await showReasonDialog(
      context,
      title: 'Reason for correction',
      label: 'What was wrong?',
      message: 'Corrections to approved logs are recorded in the history.',
      confirmLabel: 'Save correction',
    );
    if (reason == null) return;
    await _run('submit', (flags) async {
      await _repo.correct(
        widget.actor,
        _excludeId!,
        _input(flags: flags),
        reason: reason,
      );
      return 'Correction saved';
    });
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showConfirmDialog(
      context,
      title: 'Discard changes?',
      message: "Your changes and any new photos haven't been saved.",
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
    );
    if (discard) {
      final store = ref.read(photoStoreProvider);
      for (final p in _sessionPhotos) {
        await store.discard(p);
      }
      _sessionPhotos.clear();
    }
    return discard;
  }

  // --- UI ---------------------------------------------------------------------

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
    final input = _input();
    final warnings = WorkLogRules.warnings(input, _ctx);
    final approver =
        WorkLogPolicy.submitStatus(widget.actor.role) == WorkLogStatus.approved;
    final canDraft =
        !_correcting &&
        (_isNew ||
            widget.existing!.status == WorkLogStatus.draft ||
            widget.existing!.status == WorkLogStatus.rejected);
    const gap = SizedBox(height: AppSpace.lg);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_correcting) ...[
              const SizedBox(height: AppSpace.sm),
              const _Banner(
                icon: Icons.history_edu,
                text: 'You are correcting an approved log. You will be asked for a reason, and the change is kept in the history.',
              ),
            ],
            if (widget.existing?.status == WorkLogStatus.rejected) ...[
              const SizedBox(height: AppSpace.sm),
              _Banner(
                icon: Icons.report_outlined,
                tone: StatusTone.danger,
                text: 'Rejected: ${widget.existing!.statusReason ?? ''}',
              ),
            ],
            const SectionHeader('Job'),
            AppDateField(
              key: const Key('work_date'),
              label: 'Work date',
              value: _date,
              lastDate: DateTime.now(),
              onChanged: (d) {
                setState(() => _date = d);
                _touch();
                _refreshContext();
              },
            ),
            gap,
            AppDropdownField<String>(
              key: const Key('work_client'),
              label: 'Client',
              prefixIcon: MasterKind.clients.icon,
              value: _clientId,
              options: _options(MasterKind.clients, _clientId),
              validator: (_) => _errors['clientId'],
              onChanged: (v) {
                setState(() {
                  _clientId = v;
                  _siteId = null;
                });
                _autoPickSingle();
                _touch();
              },
            ),
            if (_errors['clientId'] case final e?) _FieldError(e),
            gap,
            AppDropdownField<String>(
              key: Key('work_site_$_clientId'),
              label: 'Site',
              prefixIcon: MasterKind.sites.icon,
              value: _siteId,
              hint: _clientId == null ? 'Select a client first' : null,
              options: _clientId == null
                  ? const []
                  : _options(MasterKind.sites, _siteId, clientId: _clientId),
              onChanged: _clientId == null
                  ? null
                  : (v) {
                      setState(() => _siteId = v);
                      _touch();
                    },
            ),
            if (_errors['siteId'] case final e?) _FieldError(e),
            gap,
            AppDropdownField<String>(
              key: const Key('work_machine'),
              label: 'Machine',
              prefixIcon: MasterKind.machines.icon,
              value: _machineId,
              options: _options(MasterKind.machines, _machineId),
              onChanged: (v) {
                setState(() => _machineId = v);
                _touch();
                _refreshContext();
              },
            ),
            if (_errors['machineId'] case final e?) _FieldError(e),
            gap,
            AppDropdownField<String?>(
              key: const Key('work_operator'),
              label: 'Operator (optional)',
              prefixIcon: MasterKind.operators.icon,
              value: _operatorId,
              options: [
                const AppDropdownOption<String?>(null, 'Not recorded'),
                for (final o in _options(MasterKind.operators, _operatorId))
                  AppDropdownOption<String?>(o.value, o.label),
              ],
              onChanged: (v) {
                setState(() => _operatorId = v);
                _touch();
              },
            ),
            const SectionHeader('Start of work'),
            _ReadingEditor(
              key: const Key('start_reading'),
              capture: _start,
              controller: _startText,
              error: _errors['start'],
              capturing: _capturingStart == true,
              busy: _capturingStart != null,
              lastReading: _ctx.lastReading,
              onCapture: () => _capture(start: true),
              onRemovePhoto: () => _removePhoto(start: true),
              onChanged: _touch,
            ),
            const SectionHeader('End of work'),
            _ReadingEditor(
              key: const Key('end_reading'),
              capture: _end,
              controller: _endText,
              error: _errors['end'],
              capturing: _capturingStart == false,
              busy: _capturingStart != null,
              helper:
                  'Add when the shift is over. You can save and finish later.',
              onCapture: () => _capture(start: false),
              onRemovePhoto: () => _removePhoto(start: false),
              onChanged: _touch,
            ),
            const SizedBox(height: AppSpace.lg),
            _HoursSummary(input: input),
            if (input.entryMode == EntryMode.manual) ...[
              const SectionHeader('Manual entry'),
              Text(
                'One or both readings have no photo, so this is recorded as a manual entry.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                key: const Key('work_manual_reason'),
                label: 'Reason for manual entry',
                hint: 'e.g. Meter glass broken, phone camera not working',
                controller: _reason,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                errorText: _errors['manualReason'],
                onChanged: (_) => _touch(),
              ),
            ],
            gap,
            AppTextField(
              key: const Key('work_notes'),
              label: 'Work description / notes (optional)',
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _touch(),
            ),
            for (final w in warnings) ...[
              const SizedBox(height: AppSpace.md),
              _Banner(
                icon: Icons.warning_amber_rounded,
                tone: StatusTone.warning,
                text: w.message,
              ),
            ],
            if (_errors['status'] case final e?) ...[
              const SizedBox(height: AppSpace.md),
              _FieldError(e),
            ],
            const SizedBox(height: AppSpace.xl),
            AppButton(
              key: const Key('work_submit'),
              label: _correcting
                  ? 'Save correction'
                  : approver
                  ? 'Submit & approve'
                  : 'Submit for approval',
              icon: Icons.check_circle_outline,
              loading: _busy == 'submit',
              onPressed: _busy != null || _capturingStart != null
                  ? null
                  : _correcting
                  ? _saveCorrection
                  : _submit,
            ),
            if (canDraft) ...[
              const SizedBox(height: AppSpace.md),
              AppButton(
                key: const Key('work_save_draft'),
                label: 'Save and finish later',
                icon: Icons.save_outlined,
                variant: AppButtonVariant.secondary,
                loading: _busy == 'draft',
                onPressed: _busy != null || _capturingStart != null
                    ? null
                    : _saveDraft,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadingEditor extends StatelessWidget {
  const _ReadingEditor({
    super.key,
    required this.capture,
    required this.controller,
    required this.capturing,
    required this.busy,
    required this.onCapture,
    required this.onRemovePhoto,
    required this.onChanged,
    this.error,
    this.lastReading,
    this.helper,
  });

  final MeterCapture capture;
  final TextEditingController controller;
  final bool capturing;
  final bool busy;
  final VoidCallback onCapture;
  final VoidCallback onRemovePhoto;
  final VoidCallback onChanged;
  final String? error;
  final int? lastReading;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggest = lastReading != null && controller.text.trim().isEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 88,
                child: capturing
                    ? const Center(child: CircularProgressIndicator())
                    : capture.photoPath != null
                    ? EvidencePhoto(path: capture.photoPath!, size: 88)
                    : Material(
                        color: theme.colorScheme.primary.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: InkWell(
                          key: const Key('reading_take_photo'),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          onTap: busy ? null : onCapture,
                          // Scales down with large accessibility text.
                          child: const Padding(
                            padding: EdgeInsets.all(AppSpace.sm),
                            child: FittedBox(
                              child: Column(
                                children: [
                                  Icon(Icons.photo_camera_outlined, size: 32),
                                  SizedBox(height: AppSpace.xs),
                                  Text('Photo'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: AppTextField(
                  key: const Key('reading_value'),
                  label: 'Meter reading (hours)',
                  helper: helper,
                  controller: controller,
                  prefixIcon: Icons.speed,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  errorText: error,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            capturing ? 'Saving photo and location…' : captureMeta(capture),
            style: theme.textTheme.bodySmall,
          ),
          Wrap(
            spacing: AppSpace.sm,
            children: [
              if (suggest)
                ActionChip(
                  key: const Key('reading_use_last'),
                  avatar: const Icon(Icons.history, size: 18),
                  label: Text('Use last: ${MeterReading.format(lastReading!)}'),
                  onPressed: () {
                    controller.text = MeterReading.toInput(lastReading!);
                    onChanged();
                  },
                ),
              if (capture.photoPath != null) ...[
                TextButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Retake'),
                  onPressed: busy ? null : onCapture,
                ),
                TextButton.icon(
                  key: const Key('reading_remove_photo'),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove photo'),
                  onPressed: busy ? null : onRemovePhoto,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HoursSummary extends StatelessWidget {
  const _HoursSummary({required this.input});

  final WorkLogInput input;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = input.workingHours;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        color: theme.colorScheme.primary.withValues(alpha: .12),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, size: AppSize.iconLg),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Working hours', style: theme.textTheme.labelLarge),
                  Text(
                    hours == null
                        ? 'Add both readings'
                        : hours < 0
                        ? 'Check readings'
                        : MeterReading.format(hours),
                    key: const Key('work_hours_total'),
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    this.tone = StatusTone.info,
  });

  final IconData icon;
  final String text;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = AppStatusColors.of(context).forTone(tone);
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(text)),
        ],
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
