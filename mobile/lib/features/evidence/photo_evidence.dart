import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/dialogs.dart';
import '../work/application/work_providers.dart';
import '../work/data/evidence_services.dart';
import '../work/domain/work_log.dart';

/// A photo kept on the device as evidence (meter reading, fuel receipt),
/// with when and where it was taken.
class PhotoEvidence {
  const PhotoEvidence({
    required this.photoPath,
    required this.capturedAt,
    required this.locationStatus,
    this.lat,
    this.lng,
    this.accuracy,
  });

  /// Relative to the app documents directory.
  final String photoPath;

  /// UTC epoch ms.
  final int capturedAt;
  final LocationStatus locationStatus;
  final double? lat;
  final double? lng;
  final double? accuracy;
}

/// Opens the camera, stores the photo in app-private storage and attaches
/// time and best-effort location. Returns null if cancelled or refused
/// (after explaining how to enable the camera). Never throws for permission
/// problems.
///
/// [onSaving] runs once the photo is taken and any location question is
/// answered: callers show progress from then on, so nothing spins behind
/// the camera or the dialog.
Future<PhotoEvidence?> captureEvidencePhoto(
  BuildContext context,
  WidgetRef ref, {
  required String companyId,
  VoidCallback? onSaving,
}) async {
  try {
    final file = await ref.read(photoCaptureServiceProvider).capture();
    if (file == null) return null;
    final location = ref.read(locationServiceProvider);
    final useLocation =
        !await location.needsPermissionPrompt() ||
        (context.mounted && await _explainLocation(context, ref));
    onSaving?.call();
    final rel = await ref
        .read(photoStoreProvider)
        .keep(file, companyId: companyId, name: const Uuid().v4());
    final fix = useLocation
        ? await location.current()
        : const LocationFix(LocationStatus.denied);
    if (context.mounted && fix.status != LocationStatus.captured) {
      showAppSnackBar(
        context,
        'Photo saved. ${fix.status.label} — the entry is still valid.',
        tone: StatusTone.warning,
      );
    }
    return PhotoEvidence(
      photoPath: rel,
      capturedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      locationStatus: fix.status,
      lat: fix.lat,
      lng: fix.lng,
      accuracy: fix.accuracy,
    );
  } on CameraPermissionDenied {
    // Not awaited: callers stop their progress UI while the sheet is open.
    if (context.mounted) unawaited(_explainCameraDenied(context, ref));
    return null;
  } catch (_) {
    if (context.mounted) {
      showAppSnackBar(
        context,
        "Couldn't take the photo. You can continue without it.",
        tone: StatusTone.danger,
      );
    }
    return null;
  }
}

/// "Not now" is remembered until the app restarts so the question isn't
/// repeated for every photo.
class _LocationDeclined extends Notifier<bool> {
  @override
  bool build() => false;

  void decline() => state = true;
}

final _locationDeclinedProvider = NotifierProvider<_LocationDeclined, bool>(
  _LocationDeclined.new,
);

/// Shown before Android's location permission dialog.
Future<bool> _explainLocation(BuildContext context, WidgetRef ref) async {
  if (ref.read(_locationDeclinedProvider)) return false;
  final ok = await showConfirmDialog(
    context,
    title: 'Add location to photos?',
    message:
        'JCB Works records where each meter or receipt photo was taken, as '
        'evidence for your client. Location is read only when you take a '
        'photo, never in the background. You can say no and still save.',
    confirmLabel: 'Continue',
    cancelLabel: 'Not now',
  );
  if (!ok) ref.read(_locationDeclinedProvider.notifier).decline();
  return ok;
}

Future<void> _explainCameraDenied(BuildContext context, WidgetRef ref) =>
    showAppBottomSheet<void>(
      context,
      title: 'Camera access is off',
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Allow camera access in Settings to take photos, or continue without a photo.',
          ),
          const SizedBox(height: AppSpace.xl),
          AppButton(
            label: 'Open settings',
            icon: Icons.settings_outlined,
            onPressed: () {
              Navigator.of(sheet).pop();
              ref.read(locationServiceProvider).openSettings();
            },
          ),
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: 'Continue without photo',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(sheet).pop(),
          ),
        ],
      ),
    );

/// "29 Oct, 5:41 PM · 18.59120, 73.73890 ±12 m" or the location problem.
String evidenceMeta({
  required int? capturedAt,
  required LocationStatus? status,
  double? lat,
  double? lng,
  double? accuracy,
}) {
  final when = capturedAt == null
      ? ''
      : _timeFormat(DateTime.fromMillisecondsSinceEpoch(capturedAt));
  final where = switch (status) {
    LocationStatus.captured =>
      '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
          '${accuracy == null ? '' : ' ±${accuracy.round()} m'}',
    final s? => s.label,
    null => 'Location not recorded',
  };
  return [when, where].where((s) => s.isNotEmpty).join(' · ');
}

final _timeFormat = DateFormat('d MMM, h:mm a').format;
