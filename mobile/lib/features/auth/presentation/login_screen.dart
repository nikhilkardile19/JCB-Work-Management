import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../splash/brand_mark.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import 'auth_inline_error.dart';

/// Sign-in step 1: the email address. Once the server accepts it, the
/// activation code screen asks for the code (there are no passwords).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final email = _email.text.trim();
    try {
      await ref.read(authRepositoryProvider).checkEmail(email);
      if (mounted) context.go(Routes.loginCodeFor(email));
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offline = ref.watch(isOnlineProvider).value == false;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BrandMark(size: 64),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      Text('Welcome back', style: theme.textTheme.displaySmall),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        'Enter the email address registered with JCB Works. '
                        "Next, you'll enter your activation code.",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      AppTextField(
                        key: const Key('login_email'),
                        label: 'Email',
                        controller: _email,
                        prefixIcon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: AuthValidators.email,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      AuthErrorSlot(_error),
                      AppButton(
                        key: const Key('login_submit'),
                        label: 'Continue',
                        icon: Icons.arrow_forward,
                        loading: _submitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'New to JCB Works?',
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            key: const Key('login_sign_up'),
                            onPressed: () => context.go(Routes.signUp),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                      if (offline) ...[
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          'You appear to be offline. Signing in for the first time needs internet.',
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
      ),
    );
  }
}
