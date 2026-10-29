import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/errors/error_log.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_pickers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../company/presentation/company_profile_form.dart';
import '../application/masters_providers.dart';
import '../data/masters_repository.dart';
import '../domain/master_kind.dart';
import '../domain/master_validators.dart';

/// Create ([id] null) or edit a master record.
class MasterFormScreen extends ConsumerWidget {
  const MasterFormScreen({
    super.key,
    required this.kind,
    this.id,
    this.presetClientId,
  });

  final MasterKind kind;
  final String? id;
  final String? presetClientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = id == null
        ? 'New ${kind.singular.toLowerCase()}'
        : 'Edit ${kind.singular.toLowerCase()}';
    if (!ref.watch(canManageMastersProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const PermissionDeniedView(
          permission: 'Edit',
          reason: 'Only company owners and admins can change master data.',
        ),
      );
    }

    final existing = id == null
        ? null
        : ref.watch(masterRecordProvider((kind, id!)));
    final clients = kind == MasterKind.sites
        ? ref.watch(
            masterListProvider((
              kind: MasterKind.clients,
              search: '',
              status: StatusFilter.all,
              clientId: null,
            )),
          )
        : null;

    final Widget body;
    if ((existing != null && !existing.hasValue) ||
        (clients != null && !clients.hasValue)) {
      body = const LoadingView();
    } else if (existing != null && existing.value == null) {
      body = EmptyView(icon: kind.icon, title: '${kind.singular} not found');
    } else if (clients != null &&
        !clients.value!.any((c) => c.isActive) &&
        id == null) {
      body = EmptyView(
        icon: MasterKind.clients.icon,
        title: 'Add a client first',
        message: 'Every site belongs to a client.',
        actionLabel: 'Add client',
        onAction: () => context.push(Routes.masterNew(MasterKind.clients)),
      );
    } else {
      body = _MasterForm(
        kind: kind,
        initial: existing?.value,
        presetClientId: presetClientId,
        clients: clients?.value ?? const [],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}

class _MasterForm extends ConsumerStatefulWidget {
  const _MasterForm({
    required this.kind,
    required this.initial,
    required this.presetClientId,
    required this.clients,
  });

  final MasterKind kind;
  final MasterRecord? initial;
  final String? presetClientId;
  final List<MasterRecord> clients;

  @override
  ConsumerState<_MasterForm> createState() => _MasterFormState();
}

class _MasterFormState extends ConsumerState<_MasterForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.kind.fields.where(
      (f) => f.type != FieldType.clientRef,
    ))
      f.key: TextEditingController(
        text: toMasterInput(f, widget.initial?[f.key]),
      ),
  };
  late String? _clientId = widget.initial?.clientId ?? widget.presetClientId;
  Map<String, String> _serverErrors = {};
  bool _saving = false;
  bool _dirty = false;

  MasterKind get kind => widget.kind;

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed(String key) {
    // Rebuild so PopScope starts guarding as soon as anything is typed.
    if (!_dirty || _serverErrors.containsKey(key)) {
      setState(() {
        _dirty = true;
        _serverErrors = {..._serverErrors}..remove(key);
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final values = {
      for (final f in kind.fields)
        f.key: f.type == FieldType.clientRef
            ? _clientId
            : parseMasterField(f, _text[f.key]!.text),
    };
    try {
      await ref
          .read(mastersRepositoryProvider)
          .save(
            kind,
            ref.read(masterScopeProvider)!,
            values,
            id: widget.initial?.id,
          );
      if (!mounted) return;
      setState(() => _dirty = false);
      showAppSnackBar(
        context,
        '${kind.singular} saved',
        tone: StatusTone.success,
      );
      context.pop();
    } on MasterSaveException catch (e) {
      setState(() => _serverErrors = e.fieldErrors);
    } catch (e, stack) {
      unawaited(
        ref
            .read(errorLogProvider)
            .record(e, stack, context: 'Saving ${kind.singular}'),
      );
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

  List<TextInputFormatter>? _formatters(FieldSpec f) => switch (f.type) {
    FieldType.money ||
    FieldType.meter => [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    FieldType.code => [UpperCaseFormatter()],
    FieldType.gstin => [
      UpperCaseFormatter(),
      LengthLimitingTextInputFormatter(15),
    ],
    FieldType.phone => [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
    ],
    _ => null,
  };

  TextInputType _keyboard(FieldSpec f) => switch (f.type) {
    FieldType.money ||
    FieldType.meter => const TextInputType.numberWithOptions(decimal: true),
    FieldType.phone => TextInputType.phone,
    FieldType.email => TextInputType.emailAddress,
    FieldType.multiline => TextInputType.multiline,
    _ => TextInputType.text,
  };

  Widget _field(FieldSpec f) {
    final label = f.required ? f.label : '${f.label} (optional)';
    if (f.type == FieldType.clientRef) {
      final options = widget.clients
          .where((c) => c.isActive || c.id == _clientId)
          .map((c) => AppDropdownOption(c.id, c.name))
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDropdownField<String>(
            key: Key('field_${f.key}'),
            label: label,
            prefixIcon: f.icon,
            value: _clientId,
            options: options,
            validator: (v) => validateMasterField(f, v),
            onChanged: (v) {
              setState(() => _clientId = v);
              _changed(f.key);
            },
          ),
          if (_serverErrors[f.key] case final err?)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpace.lg,
                top: AppSpace.xs,
              ),
              child: Text(
                err,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      );
    }
    return AppTextField(
      key: Key('field_${f.key}'),
      label: label,
      helper: f.helper,
      controller: _text[f.key],
      prefixIcon: f.icon,
      keyboardType: _keyboard(f),
      maxLines: f.type == FieldType.multiline ? 3 : 1,
      textCapitalization: switch (f.type) {
        FieldType.text => TextCapitalization.words,
        FieldType.multiline => TextCapitalization.sentences,
        _ => TextCapitalization.none,
      },
      textInputAction: f.type == FieldType.multiline
          ? TextInputAction.newline
          : TextInputAction.next,
      inputFormatters: _formatters(f),
      validator: (v) => validateMasterField(f, v),
      errorText: _serverErrors[f.key],
      onChanged: (_) => _changed(f.key),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showConfirmDialog(
          context,
          title: 'Discard changes?',
          message: "Your changes haven't been saved.",
          confirmLabel: 'Discard',
          cancelLabel: 'Keep editing',
          destructive: true,
        );
        if (discard && mounted) {
          setState(() => _dirty = false);
          if (context.mounted) context.pop();
        }
      },
      child: Form(
        key: _formKey,
        // Not a lazy ListView: every field must stay built so Form.validate()
        // checks fields that are scrolled off-screen.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.sm,
            AppSpace.page,
            AppSpace.xxl,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in kind.fields) ...[
                _field(f),
                const SizedBox(height: AppSpace.lg),
              ],
              const SizedBox(height: AppSpace.sm),
              AppButton(
                key: const Key('master_save'),
                label: 'Save ${kind.singular.toLowerCase()}',
                icon: Icons.check,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
