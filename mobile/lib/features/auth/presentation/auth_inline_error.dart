import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// A server error shown above the sign-in buttons, announced to screen
/// readers.
class AuthInlineError extends StatelessWidget {
  const AuthInlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Space for [AuthInlineError] that animates in when [message] is set.
class AuthErrorSlot extends StatelessWidget {
  const AuthErrorSlot(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.of(context, AppMotion.fast),
    child: message == null
        ? const SizedBox(height: AppSpace.xl)
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: AuthInlineError(message!),
          ),
  );
}
