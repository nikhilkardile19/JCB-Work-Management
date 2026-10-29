import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Couldn't send the email. Please try again.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offline = ref.watch(isOnlineProvider).value == false;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        top: false,
        child: _sent
            ? StateMessage(
                icon: Icons.mark_email_read_outlined,
                tone: StatusTone.success,
                title: 'Check your email',
                message:
                    'If an account exists for ${_email.text.trim()}, a password reset link is on its way.',
                actionLabel: 'Back to sign in',
                onAction: () => context.go(Routes.login),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Enter your account email and we'll send you a link to set a new password.",
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpace.xl),
                          AppTextField(
                            key: const Key('forgot_email'),
                            label: 'Email',
                            controller: _email,
                            prefixIcon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.send,
                            validator: AuthValidators.email,
                            onFieldSubmitted: (_) => _send(),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: AppSpace.lg),
                          ],
                          AppButton(
                            key: const Key('forgot_submit'),
                            label: 'Send reset link',
                            icon: Icons.send_outlined,
                            loading: _sending,
                            onPressed: offline ? null : _send,
                          ),
                          if (offline) ...[
                            const SizedBox(height: AppSpace.md),
                            Text(
                              'Connect to the internet to send the reset email.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
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
