import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../company/presentation/company_profile_form.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';

/// Self sign-up: the account and its company in one step. The company waits
/// for developer-admin approval; the owner then gets an activation code by
/// email, signs in and activates the phone.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// The registered company's name, once sign-up succeeded.
  String? _registered;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? v) {
    if ((v ?? '').isEmpty) return 'Enter the password again';
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: AppSpace.lg);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        top: false,
        child: _registered != null
            ? StateMessage(
                icon: Icons.mark_email_read_outlined,
                tone: StatusTone.success,
                title: 'Registration submitted',
                message:
                    "We'll review $_registered and email an activation code to ${_email.text.trim()}. "
                    'Then sign in and enter the code to start using JCB Works.',
                actionLabel: 'Go to sign in',
                onAction: () => context.go(Routes.login),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSize.maxContentWidth,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.page,
                      AppSpace.sm,
                      AppSpace.page,
                      AppSpace.xxl,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      Text(
                        'Register your business. We review it and email you an activation code — usually within one working day.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AutofillGroup(
                        child: CompanyProfileForm(
                          submitLabel: 'Create account',
                          leading: [
                            const SectionHeader('Account'),
                            AppTextField(
                              key: const Key('signup_email'),
                              label: 'Email',
                              controller: _email,
                              prefixIcon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: AuthValidators.email,
                            ),
                            gap,
                            AppTextField(
                              key: const Key('signup_password'),
                              label: 'Password',
                              controller: _password,
                              prefixIcon: Icons.lock_outline,
                              obscure: true,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (v) => AuthValidators.password(
                                v,
                                minLength: AppConfig.minNewPasswordLength,
                              ),
                            ),
                            gap,
                            AppTextField(
                              key: const Key('signup_confirm'),
                              label: 'Confirm password',
                              controller: _confirm,
                              prefixIcon: Icons.lock_outline,
                              obscure: true,
                              textInputAction: TextInputAction.next,
                              validator: _confirmValidator,
                            ),
                          ],
                          errorMessage: (e) => e is AuthException ? e.message : "Couldn't create the account. Check your connection and try again.",
                          onSubmit: (profile) async {
                            await ref
                                .read(authRepositoryProvider)
                                .signUp(
                                  email: _email.text,
                                  password: _password.text,
                                  profile: profile,
                                );
                            if (mounted) {
                              setState(() => _registered = profile.name);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
