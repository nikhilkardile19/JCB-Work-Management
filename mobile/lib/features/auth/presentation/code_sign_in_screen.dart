import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../company/presentation/company_profile_form.dart';
import '../../splash/brand_mark.dart';
import '../application/auth_providers.dart';
import '../application/code_sign_in.dart';
import '../data/auth_repository.dart';
import 'auth_inline_error.dart';

/// Sign-in step 2: the activation code for [email]. On success the phone is
/// activated and the router opens the dashboard.
class CodeSignInScreen extends ConsumerStatefulWidget {
  const CodeSignInScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CodeSignInScreen> createState() => _CodeSignInScreenState();
}

class _CodeSignInScreenState extends ConsumerState<CodeSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(codeSignInProvider)
          .signIn(email: widget.email, activationCode: _code.text);
      // The router redirects to the dashboard on auth state change.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offline = ref.watch(isOnlineProvider).value == false;
    final muted = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          key: const Key('code_back'),
          onPressed: () => context.go(Routes.login),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              0,
              AppSpace.xl,
              AppSpace.xl,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BrandMark(),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Text(
                      'Enter activation code',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text.rich(
                      TextSpan(
                        text: 'Signing in as ',
                        children: [
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      style: muted,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const Key('code_change_email'),
                        onPressed: () => context.go(Routes.login),
                        child: const Text('Use a different email'),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      'Use the code from the approval email sent to your company owner. '
                      'Each code works on one phone, and signing in needs internet.',
                      style: muted,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    AppTextField(
                      key: const Key('code_activation'),
                      label: 'Activation code',
                      hint: 'JCBW-XXXX-XXXX-XXXX',
                      controller: _code,
                      prefixIcon: Icons.key_outlined,
                      inputFormatters: [
                        UpperCaseFormatter(),
                        LengthLimitingTextInputFormatter(24),
                      ],
                      textInputAction: TextInputAction.done,
                      validator: AuthValidators.activationCode,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onFieldSubmitted: (_) => offline ? null : _submit(),
                    ),
                    AuthErrorSlot(_error),
                    AppButton(
                      key: const Key('code_submit'),
                      label: offline ? 'Waiting for internet' : 'Sign in',
                      icon: Icons.login,
                      loading: _submitting,
                      onPressed: offline ? null : _submit,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Text(
                      'Just registered? We email the code once your business is approved, usually within one working day.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
