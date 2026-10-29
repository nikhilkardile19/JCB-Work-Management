import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../company/domain/permissions.dart';

enum WorkLogStatus {
  draft('In progress'),
  submitted('Pending approval'),
  approved('Approved'),
  rejected('Rejected'),
  invoiced('Invoiced'),
  cancelled('Cancelled');

  const WorkLogStatus(this.label);

  final String label;

  static WorkLogStatus parse(String v) =>
      WorkLogStatus.values.firstWhere((s) => s.name == v);
}

enum EntryMode { photo, manual }

/// Outcome of trying to attach location to a reading. Location is optional
/// evidence: every outcome other than [captured] still lets the user save.
enum LocationStatus {
  captured('Location recorded'),
  denied('Location permission denied'),
  serviceOff('Location services off'),
  unavailable('Location unavailable');

  const LocationStatus(this.label);

  final String label;

  static LocationStatus? parse(String? v) =>
      LocationStatus.values.where((s) => s.name == v).firstOrNull;
}

/// One meter reading with its optional photo evidence.
class MeterCapture {
  const MeterCapture({
    this.reading,
    this.photoPath,
    this.capturedAt,
    this.lat,
    this.lng,
    this.accuracy,
    this.locationStatus,
  });

  /// Hundredths of an hour.
  final int? reading;

  /// Relative to the app documents directory.
  final String? photoPath;

  /// UTC epoch ms when the photo was taken.
  final int? capturedAt;
  final double? lat;
  final double? lng;
  final double? accuracy;
  final LocationStatus? locationStatus;

  bool get hasPhoto => photoPath != null;

  MeterCapture withReading(int? value) => MeterCapture(
    reading: value,
    photoPath: photoPath,
    capturedAt: capturedAt,
    lat: lat,
    lng: lng,
    accuracy: accuracy,
    locationStatus: locationStatus,
  );

  MeterCapture withoutPhoto() => MeterCapture(reading: reading);

  @override
  bool operator ==(Object other) =>
      other is MeterCapture &&
      other.reading == reading &&
      other.photoPath == photoPath &&
      other.capturedAt == capturedAt &&
      other.lat == lat &&
      other.lng == lng &&
      other.locationStatus == locationStatus;

  @override
  int get hashCode =>
      Object.hash(reading, photoPath, capturedAt, lat, lng, locationStatus);
}

/// What the user entered on the work-log form.
class WorkLogInput {
  const WorkLogInput({
    required this.workDate,
    required this.clientId,
    required this.siteId,
    required this.machineId,
    required this.start,
    this.end = const MeterCapture(),
    this.operatorId,
    this.manualReason,
    this.notes,
    this.anomalyFlags = const {},
  });

  /// `yyyy-MM-dd`.
  final String workDate;
  final String? clientId;
  final String? siteId;
  final String? machineId;
  final String? operatorId;
  final MeterCapture start;
  final MeterCapture end;
  final String? manualReason;
  final String? notes;

  /// Warnings the user has seen and confirmed.
  final Set<AnomalyFlag> anomalyFlags;

  EntryMode get entryMode =>
      start.hasPhoto && end.hasPhoto ? EntryMode.photo : EntryMode.manual;

  int? get workingHours => WorkLogRules.hours(start.reading, end.reading);
}

/// A stored work log joined with display names.
class WorkLogView {
  const WorkLogView({
    required this.id,
    required this.workDate,
    required this.clientId,
    required this.clientName,
    required this.siteId,
    required this.siteName,
    required this.machineId,
    required this.machineName,
    required this.start,
    required this.end,
    required this.entryMode,
    required this.status,
    required this.createdBy,
    required this.updatedAt,
    required this.syncStatus,
    this.operatorId,
    this.operatorName,
    this.workingHours,
    this.manualReason,
    this.notes,
    this.anomalyFlags = const {},
    this.statusReason,
    this.approvedBy,
    this.approvedAt,
    this.invoiceId,
  });

  final String id;
  final String workDate;
  final String clientId;
  final String clientName;
  final String siteId;
  final String siteName;
  final String machineId;
  final String machineName;
  final String? operatorId;
  final String? operatorName;
  final MeterCapture start;
  final MeterCapture end;
  final int? workingHours;
  final EntryMode entryMode;
  final String? manualReason;
  final String? notes;
  final Set<AnomalyFlag> anomalyFlags;
  final WorkLogStatus status;
  final String? statusReason;
  final String? approvedBy;
  final int? approvedAt;

  /// Set while the log is on a draft or finalized invoice.
  final String? invoiceId;
  final String createdBy;
  final int updatedAt;
  final String syncStatus;

  bool get inProgress => end.reading == null;

  WorkLogInput toInput() => WorkLogInput(
    workDate: workDate,
    clientId: clientId,
    siteId: siteId,
    machineId: machineId,
    operatorId: operatorId,
    start: start,
    end: end,
    manualReason: manualReason,
    notes: notes,
    anomalyFlags: anomalyFlags,
  );
}

enum AnomalyFlag {
  meterBackwards,
  highHours,
  duplicateDay;

  static Set<AnomalyFlag> parse(String? csv) => {
    for (final p in (csv ?? '').split(','))
      ?AnomalyFlag.values.where((f) => f.name == p).firstOrNull,
  };

  static String? encode(Set<AnomalyFlag> flags) => flags.isEmpty
      ? null
      : (flags.map((f) => f.name).toList()..sort()).join(',');
}

/// A warning shown before saving; the user must confirm to continue.
class WorkLogWarning {
  const WorkLogWarning(this.flag, this.message);

  final AnomalyFlag flag;
  final String message;
}

/// Context needed to check a work log against other records.
class ReadingContext {
  const ReadingContext({this.lastReading, this.sameDayLogs = 0});

  /// Highest known reading for the machine (initial reading or previous
  /// logs), in hundredths.
  final int? lastReading;

  /// Other live logs for the same machine on the same date.
  final int sameDayLogs;
}

abstract final class WorkLogRules {
  static final dateFormat = DateFormat('yyyy-MM-dd');

  static String dateKey(DateTime d) => dateFormat.format(d);

  /// end − start in hundredths, or null until both readings exist.
  static int? hours(int? start, int? end) =>
      start == null || end == null ? null : end - start;

  /// Blocking errors for the readings. [requireEnd] is true when submitting.
  static Map<String, String> readingErrors(
    WorkLogInput input, {
    required bool requireEnd,
  }) {
    final errors = <String, String>{};
    final start = input.start.reading;
    final end = input.end.reading;
    if (start == null) errors['start'] = 'Enter the starting meter reading';
    if (requireEnd && end == null) {
      errors['end'] = 'Enter the ending meter reading to submit';
    }
    if (start != null && end != null && end < start) {
      errors['end'] =
          'Ending reading must not be less than the starting reading';
    }
    if (requireEnd &&
        input.entryMode == EntryMode.manual &&
        (input.manualReason?.trim().isEmpty ?? true)) {
      errors['manualReason'] =
          'Say why there is no meter photo (e.g. meter not readable)';
    }
    return errors;
  }

  /// Non-blocking warnings the user must confirm.
  static List<WorkLogWarning> warnings(
    WorkLogInput input,
    ReadingContext ctx, {
    int highHoursThreshold = AppConfig.highDailyHours,
  }) {
    final w = <WorkLogWarning>[];
    final start = input.start.reading;
    final last = ctx.lastReading;
    if (start != null && last != null && start < last) {
      w.add(
        const WorkLogWarning(
          AnomalyFlag.meterBackwards,
          'Starting reading is below this machine\'s last reading. '
          'Confirm only if the meter was replaced or reset.',
        ),
      );
    }
    final h = input.workingHours;
    if (h != null && h > highHoursThreshold) {
      w.add(
        WorkLogWarning(
          AnomalyFlag.highHours,
          'More than ${highHoursThreshold ~/ 100} hours in one log. '
          'Check both readings.',
        ),
      );
    }
    if (ctx.sameDayLogs > 0) {
      w.add(
        const WorkLogWarning(
          AnomalyFlag.duplicateDay,
          'This machine already has a log for this date. '
          'Fine for split shifts — otherwise check for a duplicate.',
        ),
      );
    }
    return w;
  }
}

/// Which actions a role may take on a log in its current state.
abstract final class WorkLogPolicy {
  static bool canCreate(CompanyRole r) => r.can(Permission.createWorkLogs);

  static bool canEdit(CompanyRole r, WorkLogView log, String uid) =>
      switch (log.status) {
        WorkLogStatus.draft || WorkLogStatus.rejected =>
          r.can(Permission.approveWorkLogs) ||
              (r.can(Permission.createWorkLogs) && log.createdBy == uid),
        WorkLogStatus.submitted => r.can(Permission.approveWorkLogs),
        _ => false,
      };

  static bool canReview(CompanyRole r, WorkLogView log) =>
      log.status == WorkLogStatus.submitted &&
      r.can(Permission.approveWorkLogs);

  /// Corrections of approved logs: owner/admin only, with a reason.
  static bool canCorrect(CompanyRole r, WorkLogView log) =>
      log.status == WorkLogStatus.approved &&
      log.invoiceId == null &&
      r.can(Permission.manageCompany);

  static bool canCancel(CompanyRole r, WorkLogView log, String uid) =>
      switch (log.status) {
        WorkLogStatus.draft ||
        WorkLogStatus.submitted ||
        WorkLogStatus.rejected => canEdit(r, log, uid),
        WorkLogStatus.approved =>
          log.invoiceId == null && r.can(Permission.manageCompany),
        WorkLogStatus.invoiced || WorkLogStatus.cancelled => false,
      };

  /// Status a submission lands in: approvers' own entries are approved
  /// immediately (product decision #6).
  static WorkLogStatus submitStatus(CompanyRole r) =>
      r.can(Permission.approveWorkLogs)
      ? WorkLogStatus.approved
      : WorkLogStatus.submitted;
}
