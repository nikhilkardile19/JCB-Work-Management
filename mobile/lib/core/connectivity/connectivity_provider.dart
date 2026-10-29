import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity *hint* only — a network interface being up does not prove the
/// backend is reachable. Sync code must still attempt the real call.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool hasNetwork(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  yield hasNetwork(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(hasNetwork);
});
