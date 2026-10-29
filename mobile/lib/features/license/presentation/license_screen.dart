import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/local/database_provider.dart';
import '../application/license_controller.dart';
import '../data/license_service.dart';
import '../domain/license.dart';
import 'license_widgets.dart';

final _date = DateFormat('d MMM yyyy');
final _dateTime = DateFormat('d MMM yyyy, h:mm a');

class LicenseScreen extends ConsumerStatefulWidget {
  const LicenseScreen({super.key});

  @override
  ConsumerState<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends ConsumerState<LicenseScreen> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      await ref.read(licenseControllerProvider.notifier).refresh();
      if (mounted) {
        showAppSnackBar(context, 'License checked', tone: StatusTone.success);
      }
    } on LicenseServerUnavailable {
      if (mounted) {
        showAppSnackBar(
          context,
          "Couldn't reach the server. Try again when online.",
          tone: StatusTone.warning,
        );
      }
    } on LicenseDenied catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: StatusTone.danger);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = ref.watch(licenseControllerProvider).value;
    final access = ref.watch(licenseAccessProvider).value;
    final offline = ref.watch(isOnlineProvider).value == false;

    return Scaffold(
      appBar: AppBar(title: const Text('License')),
      body: access == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(AppSpace.page),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LicenseChip(access, key: const Key('license_state')),
                      if (access case LicenseReadOnly(:final reason)) ...[
                        const SizedBox(height: AppSpace.md),
                        Text(
                          reason.message,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpace.xs),
                        const Text(
                          'You can still view, print and share your records. Creating or changing records is paused until the license is active and checked again.',
                        ),
                      ],
                      const SizedBox(height: AppSpace.lg),
                      AppButton(
                        key: const Key('license_check'),
                        label: offline
                            ? 'Waiting for internet'
                            : 'Check license now',
                        icon: Icons.refresh,
                        loading: _checking,
                        onPressed: offline ? null : _check,
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Details'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Valid until'),
                        subtitle: Text(
                          snapshot?.validUntil == null
                              ? '—'
                              : _date.format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    snapshot!.validUntil!,
                                  ),
                                ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.update),
                        title: const Text('Last checked with server'),
                        subtitle: Text(
                          snapshot == null
                              ? 'Never'
                              : _dateTime.format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    snapshot.lastValidatedAt,
                                  ),
                                ),
                          key: const Key('license_last_checked'),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.devices_other),
                        title: const Text('Phones allowed'),
                        subtitle: Text(snapshot?.maxDevices?.toString() ?? '—'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone_android),
                        title: const Text('This phone'),
                        subtitle: FutureBuilder<String>(
                          future: ref
                              .read(appDatabaseProvider)
                              .installationId(),
                          builder: (_, s) => Text(
                            s.hasData
                                ? 'Device ID ${s.data!.substring(0, 8).toUpperCase()}'
                                : '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  'The license is checked with the server every day when online. Without internet you can keep working for '
                  '7 days; after that the app becomes read-only until it can check again.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
