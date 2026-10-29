import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pickers.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/sync_indicator.dart';

/// Live catalogue of the design system for design review (dev builds only).
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _machine;
  DateTime? _date;

  Future<void> _simulateSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);
    showAppSnackBar(context, 'Form is valid', tone: StatusTone.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design system')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.page),
        children: [
          const SectionHeader('Status'),
          const Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              StatusChip(label: 'Approved', tone: StatusTone.success),
              StatusChip(label: 'Submitted', tone: StatusTone.info),
              StatusChip(
                label: 'Manual entry',
                tone: StatusTone.warning,
                icon: Icons.edit_note,
              ),
              StatusChip(label: 'Rejected', tone: StatusTone.danger),
              StatusChip(label: 'Draft'),
              SyncIndicator(state: SyncState.synced),
              SyncIndicator(state: SyncState.pending),
              SyncIndicator(state: SyncState.error),
            ],
          ),
          const SectionHeader('Form controls'),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Starting meter reading',
                  hint: 'e.g. 1234.5',
                  prefixIcon: Icons.speed,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => double.tryParse(v ?? '') == null
                      ? 'Enter the reading shown on the hour meter'
                      : null,
                ),
                const SizedBox(height: AppSpace.lg),
                AppDropdownField<String>(
                  label: 'Machine',
                  prefixIcon: Icons.agriculture_outlined,
                  value: _machine,
                  options: const [
                    AppDropdownOption('jcb-1', 'JCB 3DX · MH12 AB 1234'),
                    AppDropdownOption('jcb-2', 'JCB 4DX · MH14 CD 5678'),
                  ],
                  validator: (v) => v == null ? 'Select a machine' : null,
                  onChanged: (v) => setState(() => _machine = v),
                ),
                const SizedBox(height: AppSpace.lg),
                AppDateField(
                  label: 'Work date',
                  value: _date,
                  validator: (_) =>
                      _date == null ? 'Select the work date' : null,
                  onChanged: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: 'Validate form',
                  icon: Icons.check,
                  loading: _loading,
                  onPressed: _simulateSave,
                ),
              ],
            ),
          ),
          const SectionHeader('Buttons'),
          AppButton(
            label: 'Secondary',
            variant: AppButtonVariant.secondary,
            onPressed: () => showAppSnackBar(context, 'Secondary pressed'),
          ),
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: 'Open bottom sheet',
            variant: AppButtonVariant.tonal,
            onPressed: () => showAppBottomSheet<void>(
              context,
              title: 'Select site',
              builder: (_) => const Text(
                'Bottom sheets are used for quick pickers in field workflows.',
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: 'Cancel invoice',
            variant: AppButtonVariant.destructive,
            icon: Icons.block,
            onPressed: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Cancel invoice?',
                message: 'The invoice will be kept with a cancelled status.',
                confirmLabel: 'Cancel invoice',
                cancelLabel: 'Keep',
                destructive: true,
              );
              if (context.mounted) {
                showAppSnackBar(
                  context,
                  ok ? 'Confirmed' : 'Dismissed',
                  tone: ok ? StatusTone.danger : StatusTone.neutral,
                );
              }
            },
          ),
          const SectionHeader('States'),
          for (final view in <Widget>[
            const EmptyView(
              title: 'No clients yet',
              message: 'Add one to start.',
            ),
            ErrorView(message: 'Could not load.', onRetry: () {}),
            const OfflineView(),
            const PermissionDeniedView(
              permission: 'Camera',
              reason: 'Allow camera access to photograph meter readings.',
            ),
          ]) ...[
            AppCard(child: SizedBox(height: 300, child: view)),
            const SizedBox(height: AppSpace.md),
          ],
        ],
      ),
    );
  }
}
