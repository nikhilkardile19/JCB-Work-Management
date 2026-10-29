import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_card.dart';
import '../../evidence/photo_evidence.dart';
import '../application/work_providers.dart';
import '../domain/work_log.dart';

(String, StatusTone) workStatusLook(WorkLogStatus s) => switch (s) {
  WorkLogStatus.draft => (s.label, StatusTone.info),
  WorkLogStatus.submitted => (s.label, StatusTone.warning),
  WorkLogStatus.approved => (s.label, StatusTone.success),
  WorkLogStatus.rejected => (s.label, StatusTone.danger),
  WorkLogStatus.invoiced => (s.label, StatusTone.success),
  WorkLogStatus.cancelled => (s.label, StatusTone.neutral),
};

class WorkStatusChip extends StatelessWidget {
  const WorkStatusChip(this.status, {super.key});

  final WorkLogStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = workStatusLook(status);
    return StatusChip(label: label, tone: tone);
  }
}

/// "Today", "Yesterday" or "Thu, 23 Oct 2026".
String formatWorkDate(String key, {DateTime? now}) {
  final d = DateTime.parse(key);
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEE, d MMM yyyy').format(d);
}

String formatHours(int? hundredths) =>
    hundredths == null ? '—' : MeterReading.format(hundredths);

String formatCaptureTime(int epochMs) =>
    DateFormat('d MMM, h:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(epochMs));

/// One-line description of where/when a reading's photo was taken.
String captureMeta(MeterCapture c) => c.hasPhoto
    ? evidenceMeta(
        capturedAt: c.capturedAt,
        status: c.locationStatus,
        lat: c.lat,
        lng: c.lng,
        accuracy: c.accuracy,
      )
    : 'No photo — entered manually';

/// Thumbnail of an evidence photo; tap to view full screen. Photos are
/// device-local, so a missing file shows a clear placeholder.
class EvidencePhoto extends ConsumerWidget {
  const EvidencePhoto({super.key, required this.path, this.size = 72});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(evidenceFileProvider(path)).value;
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: size,
      height: size,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined),
    );
    return Semantics(
      button: true,
      label: 'Meter photo. Tap to enlarge',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: file == null
            ? placeholder
            : InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => _PhotoViewer(path: path),
                  ),
                ),
                child: Image.file(
                  file,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  cacheWidth: (size * 3).round(),
                  errorBuilder: (_, _, _) => placeholder,
                ),
              ),
      ),
    );
  }
}

class _PhotoViewer extends ConsumerWidget {
  const _PhotoViewer({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(evidenceFileProvider(path)).value;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Meter photo'),
      ),
      body: file == null
          ? const SizedBox.shrink()
          : InteractiveViewer(
              maxScale: 6,
              child: Center(
                child: Image.file(
                  file,
                  errorBuilder: (_, _, _) => const Text(
                    'This photo is not on this device.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Read-only summary of a reading for the detail screen.
class MeterReadingTile extends StatelessWidget {
  const MeterReadingTile({
    super.key,
    required this.title,
    required this.capture,
  });

  final String title;
  final MeterCapture capture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (capture.photoPath != null)
          EvidencePhoto(path: capture.photoPath!)
        else
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.edit_note),
          ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelLarge),
              Text(
                capture.reading == null
                    ? 'Not entered yet'
                    : MeterReading.format(capture.reading!),
                style: theme.textTheme.titleLarge,
              ),
              Text(captureMeta(capture), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
