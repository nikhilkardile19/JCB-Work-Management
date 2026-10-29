import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Asks the user to confirm. Returns `true` only on explicit confirmation.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Asks for a short reason (rejection, cancellation, correction). Returns the
/// trimmed text, or null if dismissed.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String label,
  String confirmLabel = 'Confirm',
  String? message,
  bool required = true,
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ReasonDialog(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
      message: message,
      required: required,
      destructive: destructive,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.message,
    required this.required,
    required this.destructive,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String? message;
  final bool required;
  final bool destructive;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _controller.text.trim();
    if (widget.required && text.isEmpty) {
      setState(() => _error = 'Please enter a reason');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: AppSpace.lg),
          ],
          TextField(
            key: const Key('reason_field'),
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('reason_confirm'),
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Modal bottom sheet with consistent padding and safe-area handling.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: AppSpace.page,
        right: AppSpace.page,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpace.lg),
          // Scrolls when the content is taller than the screen (large text).
          Flexible(child: SingleChildScrollView(child: builder(context))),
        ],
      ),
    ),
  );
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  StatusTone tone = StatusTone.neutral,
}) {
  final color = AppStatusColors.of(context).forTone(tone);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (tone != StatusTone.neutral) ...[
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: AppSpace.md),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
