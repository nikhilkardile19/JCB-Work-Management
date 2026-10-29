import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/local/database_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../company/application/company_providers.dart';
import '../../company/presentation/company_profile_form.dart';
import '../../splash/brand_mark.dart';
import '../application/license_controller.dart';
import '../data/license_service.dart';

/// One-time, online activation of this phone with the company's code.
class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _full = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    FocusScope.of(context).unfocus();
    final code = _code.text.replaceAll(RegExp(r'[\s-]'), '');
    if (code.length < 12) {
      setState(() => _error = 'Enter the full code, e.g. JCBW-7KQ2-M9XD-PA4H');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(licenseControllerProvider.notifier).activate(_code.text);
      if (mounted) {
        showAppSnackBar(
          context,
          'This phone is activated',
          tone: StatusTone.success,
        );
      }
    } on LicenseDenied catch (e) {
      setState(() {
        _error = e.message;
        _full = e.reason == 'device_limit';
      });
    } on LicenseServerUnavailable catch (e) {
      setState(
        () => _error =
            '${e.message} Check your internet connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offline = ref.watch(isOnlineProvider).value == false;
    final company = ref.watch(currentMembershipProvider)?.company.name;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BrandMark(),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Text(
                    'Activate this phone',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'Enter the activation code for ${company ?? 'your company'}\'s JCB Works license. '
                    'This is needed once per phone and requires internet.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  AppTextField(
                    key: const Key('activation_code'),
                    label: 'Activation code',
                    hint: 'JCBW-XXXX-XXXX-XXXX',
                    controller: _code,
                    prefixIcon: Icons.key_outlined,
                    inputFormatters: [
                      UpperCaseFormatter(),
                      LengthLimitingTextInputFormatter(24),
                    ],
                    textInputAction: TextInputAction.done,
                    errorText: _error,
                    onChanged: (_) => setState(() => _error = null),
                    onFieldSubmitted: (_) => offline ? null : _activate(),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  AppButton(
                    key: const Key('activation_submit'),
                    label: offline ? 'Waiting for internet' : 'Activate',
                    icon: Icons.verified_outlined,
                    loading: _busy,
                    onPressed: offline ? null : _activate,
                  ),
                  if (_full) ...[
                    const SizedBox(height: AppSpace.md),
                    AppButton(
                      key: const Key('activation_request_replacement'),
                      label: 'Request a replacement',
                      icon: Icons.swap_horiz,
                      variant: AppButtonVariant.tonal,
                      onPressed: () =>
                          context.go(Routes.replacement, extra: _code.text),
                    ),
                  ],
                  const SizedBox(height: AppSpace.md),
                  AppButton(
                    label: 'Sign out',
                    icon: Icons.logout,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Text(
                    switch (ref.watch(installationIdProvider).value) {
                      final id? =>
                        'Device ID for support: ${shortDeviceId(id)}',
                      null => '',
                    },
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
