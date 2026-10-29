import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../company/presentation/company_profile_form.dart';
import '../application/license_controller.dart';
import '../data/license_service.dart';
import '../data/replacement_service.dart';

/// Asks to move a license place to this phone when the license is full
/// (old phone lost, damaged or replaced). An admin approves or rejects.
class ReplacementScreen extends ConsumerStatefulWidget {
  const ReplacementScreen({super.key, this.activationCode});

  final String? activationCode;

  @override
  ConsumerState<ReplacementScreen> createState() => _ReplacementScreenState();
}

const _reasons = [
  'Phone lost',
  'Phone damaged',
  'Phone stolen',
  'New phone',
  'Other',
];

class _ReplacementScreenState extends ConsumerState<ReplacementScreen> {
  late final _code = TextEditingController(text: widget.activationCode);
  final _details = TextEditingController();
  String? _reason;
  String? _error;
  String? _rejection;
  bool _busy = false;
  bool? _pending;

  LicenseController get _license =>
      ref.read(licenseControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _license.pendingRequestId().then((id) {
      if (mounted) setState(() => _pending = id != null);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final reason = [
      ?_reason,
      if (_details.text.trim().isNotEmpty) _details.text.trim(),
    ].join(': ');
    if (_code.text.replaceAll(RegExp(r'[\s-]'), '').length < 12) {
      setState(() => _error = 'Enter the company’s activation code');
      return;
    }
    if (_reason == null) {
      setState(() => _error = 'Choose why this phone is replacing another');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _license.requestReplacement(
        activationCode: _code.text,
        reason: reason,
      );
      if (!mounted) return;
      if (r.status == ReplacementStatus.alreadyActive) {
        showAppSnackBar(
          context,
          'This phone is already activated',
          tone: StatusTone.success,
        );
      } else {
        setState(() {
          _pending = true;
          _rejection = null;
        });
      }
    } on LicenseDenied catch (e) {
      setState(() => _error = e.message);
    } on LicenseServerUnavailable catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final r = await _license.checkReplacement();
      if (!mounted) return;
      switch (r?.status) {
        case ReplacementStatus.approved:
          showAppSnackBar(
            context,
            'Approved — this phone is activated',
            tone: StatusTone.success,
          );
        case ReplacementStatus.rejected:
          setState(() {
            _pending = false;
            _rejection = r!.reviewReason ?? 'No reason given.';
          });
        default:
          showAppSnackBar(context, 'Still waiting for approval');
      }
    } on LicenseServerUnavailable {
      if (mounted) {
        showAppSnackBar(
          context,
          "Couldn't reach the server. Try again when online.",
          tone: StatusTone.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offline = ref.watch(isOnlineProvider).value == false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replace a phone'),
        leading: BackButton(onPressed: () => context.go(Routes.activate)),
      ),
      body: _pending == null
          ? const LoadingView()
          : _pending!
          ? StateMessage(
              icon: Icons.hourglass_top_rounded,
              tone: StatusTone.info,
              title: 'Request sent',
              message:
                  'A JCB Works administrator will review it, usually within one working day. '
                  'When approved, the old phone is deactivated and this one can be used. Your data on the old phone is not deleted.',
              actionLabel: offline ? null : 'Check again',
              onAction: _busy ? null : _check,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpace.page),
              children: [
                if (_rejection != null) ...[
                  AppCard(
                    color: AppStatusColors.of(context).danger
                        .withValues(alpha: .1),
                    child: Text(
                      'Your last request was rejected: $_rejection',
                      key: const Key('replacement_rejected'),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                ],
                Text(
                  'All phones allowed by your license are in use. If this phone replaces one that was lost, damaged or retired, ask for a replacement.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SectionHeader('Why?'),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final r in _reasons)
                      ChoiceChip(
                        key: Key('replacement_reason_$r'),
                        label: Text(r),
                        selected: _reason == r,
                        onSelected: (_) => setState(() {
                          _reason = r;
                          _error = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  key: const Key('replacement_details'),
                  label: 'Details (optional)',
                  hint: 'e.g. which phone it replaces',
                  controller: _details,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  key: const Key('replacement_code'),
                  label: 'Activation code',
                  controller: _code,
                  prefixIcon: Icons.key_outlined,
                  inputFormatters: [
                    UpperCaseFormatter(),
                    LengthLimitingTextInputFormatter(24),
                  ],
                  errorText: _error,
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  key: const Key('replacement_submit'),
                  label: offline ? 'Waiting for internet' : 'Send request',
                  icon: Icons.send_outlined,
                  loading: _busy,
                  onPressed: offline ? null : _submit,
                ),
              ],
            ),
    );
  }
}
