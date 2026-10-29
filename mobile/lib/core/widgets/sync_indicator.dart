import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_provider.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';

enum SyncState {
  /// Saved on this device and not synced yet (e.g. never connected).
  localOnly,
  synced,
  pending,
  syncing,
  offline,
  conflict,
  error,
}

/// Sync state of one record from its `syncStatus` column.
SyncState recordSyncState(String syncStatus) => switch (syncStatus) {
  'synced' => SyncState.synced,
  'conflict' => SyncState.conflict,
  'error' => SyncState.error,
  _ => SyncState.pending,
};

extension SyncStateLook on SyncState {
  (String, StatusTone, IconData) get look => switch (this) {
    SyncState.localOnly => (
      'Saved on device',
      StatusTone.info,
      Icons.phone_android,
    ),
    SyncState.synced => ('Synced', StatusTone.success, Icons.cloud_done),
    SyncState.pending => (
      'Pending sync',
      StatusTone.warning,
      Icons.cloud_upload_outlined,
    ),
    SyncState.syncing => ('Syncing…', StatusTone.info, Icons.sync),
    SyncState.offline => (
      'Offline',
      StatusTone.warning,
      Icons.cloud_off_outlined,
    ),
    SyncState.conflict => (
      'Sync conflict',
      StatusTone.danger,
      Icons.call_split,
    ),
    SyncState.error => ('Sync error', StatusTone.danger, Icons.sync_problem),
  };
}

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key, required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = state.look;
    return StatusChip(label: label, tone: tone, icon: icon);
  }
}

/// Slim banner shown at the top of the shell while the device is offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOnlineProvider).value == false;
    final status = AppStatusColors.of(context);
    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.curve,
      child: offline
          ? Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                color: status.warning.withValues(alpha: .16),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.page,
                  vertical: AppSpace.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: AppSize.iconSm,
                      color: status.warning,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        'Offline — your work is saved on this device.',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
