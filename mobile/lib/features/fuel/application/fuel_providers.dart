import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../../work/application/work_providers.dart';
import '../../work/data/work_log_repository.dart';
import '../data/fuel_repository.dart';
import '../domain/fuel_entry.dart';

final fuelRepositoryProvider = Provider<FuelRepository>(
  (ref) => FuelRepository(ref.watch(appDatabaseProvider)),
);

final fuelListProvider = StreamProvider.autoDispose
    .family<List<FuelView>, FuelPeriod>((ref, period) {
      final actor = ref.watch(workActorProvider);
      if (actor == null) return Stream.value(const []);
      final (from, to) = period.range(DateTime.now());
      return ref
          .watch(fuelRepositoryProvider)
          .watchList(actor.companyId, from: from, to: to);
    });

final fuelSummaryProvider = StreamProvider.autoDispose
    .family<FuelSummary, FuelPeriod>((ref, period) {
      final actor = ref.watch(workActorProvider);
      if (actor == null) return Stream.value(FuelSummary.empty);
      final (from, to) = period.range(DateTime.now());
      return ref
          .watch(fuelRepositoryProvider)
          .watchSummary(actor.companyId, from: from, to: to);
    });

final fuelEntryProvider = StreamProvider.autoDispose.family<FuelView?, String>((
  ref,
  id,
) {
  final actor = ref.watch(workActorProvider);
  if (actor == null) return Stream.value(null);
  return ref.watch(fuelRepositoryProvider).watchOne(actor.companyId, id);
});

final fuelHistoryProvider = StreamProvider.autoDispose
    .family<List<WorkHistoryEntry>, String>((ref, id) {
      final actor = ref.watch(workActorProvider);
      if (actor == null) return Stream.value(const []);
      return ref
          .watch(fuelRepositoryProvider)
          .watchHistory(actor.companyId, id);
    });
