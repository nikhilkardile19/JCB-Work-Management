import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../../company/application/session.dart';
import '../../company/application/company_providers.dart';
import '../data/evidence_services.dart';
import '../data/work_log_repository.dart';
import '../domain/work_log.dart';

final workLogRepositoryProvider = Provider<WorkLogRepository>(
  (ref) => WorkLogRepository(ref.watch(appDatabaseProvider)),
);

final photoCaptureServiceProvider = Provider<PhotoCaptureService>(
  (ref) => ImagePickerCaptureService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

final photoStoreProvider = Provider<PhotoStore>((ref) => PhotoStore());

/// Current user acting in the active company, or null before onboarding.
final workActorProvider = Provider<WorkActor?>((ref) {
  final s = ref.watch(sessionProvider);
  return s is SessionReady
      ? WorkActor(
          companyId: s.membership.companyId,
          userId: s.user.uid,
          role: s.membership.role,
        )
      : null;
});

enum WorkFilter {
  all('All', null),
  inProgress('In progress', {WorkLogStatus.draft}),
  pending('Pending approval', {WorkLogStatus.submitted}),
  approved('Approved', {WorkLogStatus.approved, WorkLogStatus.invoiced}),
  rejected('Rejected', {WorkLogStatus.rejected}),
  cancelled('Cancelled', {WorkLogStatus.cancelled});

  const WorkFilter(this.label, this.statuses);

  final String label;
  final Set<WorkLogStatus>? statuses;
}

final workLogListProvider = StreamProvider.autoDispose
    .family<List<WorkLogView>, WorkFilter>((ref, filter) {
      final actor = ref.watch(workActorProvider);
      if (actor == null) return Stream.value(const []);
      return ref
          .watch(workLogRepositoryProvider)
          .watchList(actor.companyId, statuses: filter.statuses);
    });

final workLogProvider = StreamProvider.autoDispose.family<WorkLogView?, String>(
  (ref, id) {
    final actor = ref.watch(workActorProvider);
    if (actor == null) return Stream.value(null);
    return ref.watch(workLogRepositoryProvider).watchOne(actor.companyId, id);
  },
);

final workHistoryProvider = StreamProvider.autoDispose
    .family<List<WorkHistoryEntry>, String>((ref, id) {
      final actor = ref.watch(workActorProvider);
      if (actor == null) return Stream.value(const []);
      return ref
          .watch(workLogRepositoryProvider)
          .watchHistory(actor.companyId, id);
    });

final todayHoursProvider = StreamProvider.autoDispose<int>((ref) {
  final actor = ref.watch(workActorProvider);
  if (actor == null) return Stream.value(0);
  return ref
      .watch(workLogRepositoryProvider)
      .watchHoursOn(actor.companyId, WorkLogRules.dateKey(DateTime.now()));
});

final pendingApprovalCountProvider = StreamProvider.autoDispose<int>((ref) {
  final actor = ref.watch(workActorProvider);
  if (actor == null) return Stream.value(0);
  return ref
      .watch(workLogRepositoryProvider)
      .watchCount(actor.companyId, WorkLogStatus.submitted);
});

/// Absolute file for a stored evidence photo.
final evidenceFileProvider = FutureProvider.autoDispose.family<File, String>(
  (ref, relativePath) => ref.watch(photoStoreProvider).resolve(relativePath),
);
