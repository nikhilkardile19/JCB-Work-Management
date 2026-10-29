import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/company.dart';
import '../domain/company_validators.dart';

/// Company profile form used for first-time setup and later edits.
/// Saving needs the server, so the submit button is disabled while offline.
class CompanyProfileForm extends ConsumerStatefulWidget {
  const CompanyProfileForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
  });

  final CompanyProfile? initial;
  final String submitLabel;

  /// Throws to show an error message under the form.
  final Future<void> Function(CompanyProfile profile) onSubmit;

  @override
  ConsumerState<CompanyProfileForm> createState() => _CompanyProfileFormState();
}

class _CompanyProfileFormState extends ConsumerState<CompanyProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _contact = TextEditingController(
    text: widget.initial?.contactPerson,
  );
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late final _email = TextEditingController(text: widget.initial?.email);
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _gstin = TextEditingController(text: widget.initial?.gstin);
  late final _prefix = TextEditingController(
    text: widget.initial?.invoicePrefix,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _name,
      _contact,
      _phone,
      _email,
      _address,
      _gstin,
      _prefix,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _opt(TextEditingController c, {bool upper = false}) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return upper ? t.toUpperCase() : t;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        CompanyProfile(
          name: _name.text.trim(),
          contactPerson: _contact.text.trim(),
          phone: _phone.text.trim(),
          email: _opt(_email),
          address: _address.text.trim(),
          gstin: _opt(_gstin, upper: true),
          invoicePrefix: _prefix.text.trim().toUpperCase(),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = "Couldn't save the company profile. Check your connection and try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(isOnlineProvider).value == false;
    final upper = [UpperCaseFormatter()];
    const gap = SizedBox(height: AppSpace.lg);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Business'),
          AppTextField(
            key: const Key('company_name'),
            label: 'Company name',
            controller: _name,
            prefixIcon: Icons.business_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: CompanyValidators.name,
          ),
          gap,
          AppTextField(
            key: const Key('company_address'),
            label: 'Address',
            controller: _address,
            prefixIcon: Icons.place_outlined,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            validator: CompanyValidators.address,
          ),
          gap,
          AppTextField(
            key: const Key('company_gstin'),
            label: 'GSTIN (optional)',
            controller: _gstin,
            prefixIcon: Icons.receipt_outlined,
            inputFormatters: [...upper, LengthLimitingTextInputFormatter(15)],
            textInputAction: TextInputAction.next,
            validator: CompanyValidators.optionalGstin,
          ),
          const SectionHeader('Contact'),
          AppTextField(
            key: const Key('company_contact'),
            label: 'Contact person',
            controller: _contact,
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: CompanyValidators.contactPerson,
          ),
          gap,
          AppTextField(
            key: const Key('company_phone'),
            label: 'Phone',
            controller: _phone,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: CompanyValidators.phone,
          ),
          gap,
          AppTextField(
            key: const Key('company_email'),
            label: 'Email (optional)',
            controller: _email,
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: CompanyValidators.optionalEmail,
          ),
          const SectionHeader('Invoicing'),
          AppTextField(
            key: const Key('company_prefix'),
            label: 'Invoice prefix',
            helper:
                'Shown at the start of invoice numbers, e.g. JCB/2026-27/0001',
            controller: _prefix,
            prefixIcon: Icons.tag,
            inputFormatters: [...upper, LengthLimitingTextInputFormatter(10)],
            textInputAction: TextInputAction.done,
            validator: CompanyValidators.invoicePrefix,
          ),
          gap,
          const _ReadOnlyRow(
            icon: Icons.currency_rupee,
            label: 'Currency',
            value: 'Indian Rupee (INR)',
          ),
          const SizedBox(height: AppSpace.xl),
          if (_error != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          if (offline) ...[
            const StatusChip(
              label: 'Connect to the internet to save',
              tone: StatusTone.warning,
              icon: Icons.cloud_off_outlined,
            ),
            const SizedBox(height: AppSpace.md),
          ],
          AppButton(
            key: const Key('company_submit'),
            label: widget.submitLabel,
            icon: Icons.check,
            loading: _saving,
            onPressed: offline ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        enabled: false,
      ),
      child: Text(value),
    );
  }
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
