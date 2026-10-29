import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../application/license_controller.dart';
import '../domain/license.dart';

(String, StatusTone, IconData) licenseLook(LicenseAccess a) => switch (a) {
  LicenseOk(daysToExpiry: final d?) => (
    'Active · ends in $d ${d == 1 ? 'day' : 'days'}',
    StatusTone.warning,
    Icons.event_busy,
  ),
  LicenseOk() => ('Active', StatusTone.success, Icons.verified_outlined),
  LicenseGrace(:final daysLeft) => (
    'Offline grace · $daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
    StatusTone.warning,
    Icons.wifi_off,
  ),
  LicenseReadOnly() => ('Read-only', StatusTone.danger, Icons.lock_outline),
  LicenseNeedsActivation() => (
    'Not activated',
    StatusTone.neutral,
    Icons.key_off_outlined,
  ),
};

class LicenseChip extends StatelessWidget {
  const LicenseChip(this.access, {super.key});

  final LicenseAccess access;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = licenseLook(access);
    return StatusChip(label: label, tone: tone, icon: icon);
  }
}

/// Shown at the top of the app when the license needs attention.
class LicenseBanner extends ConsumerWidget {
  const LicenseBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(licenseAccessProvider).value;
    final (String text, StatusTone tone)? content = switch (access) {
      LicenseReadOnly(:final reason) => (
        '${reason.message} You can view records but not change them.',
        StatusTone.danger,
      ),
      LicenseGrace(:final daysLeft) => (
        'License not checked recently. Connect within $daysLeft ${daysLeft == 1 ? 'day' : 'days'} to keep editing.',
        StatusTone.warning,
      ),
      LicenseOk(daysToExpiry: final d?) => (
        'Your license ends in $d ${d == 1 ? 'day' : 'days'}. Contact support to renew.',
        StatusTone.info,
      ),
      _ => null,
    };
    final status = AppStatusColors.of(context);
    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.medium),
      child: content == null
          ? const SizedBox(width: double.infinity)
          : Material(
              key: const Key('license_banner'),
              color: status.forTone(content.$2).withValues(alpha: .16),
              child: InkWell(
                onTap: () => context.push(Routes.license),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page,
                    vertical: AppSpace.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.key_outlined,
                        size: AppSize.iconSm,
                        color: status.forTone(content.$2),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          content.$1,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: AppSize.iconSm),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Call before any action that changes data. Returns false (after telling
/// the user why) when the license only allows viewing.
Future<bool> ensureCanWrite(BuildContext context, WidgetRef ref) async {
  if (ref.read(canWriteProvider)) return true;
  final access = ref.read(licenseAccessProvider).value;
  final reason = access is LicenseReadOnly
      ? access.reason.message
      : 'The license on this phone is not active.';
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.lock_outline),
      title: const Text('Read-only mode'),
      content: Text('$reason Your records are safe and can still be viewed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('OK'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('License details'),
        ),
      ],
    ),
  );
  if (open == true && context.mounted) await context.push(Routes.license);
  return false;
}
