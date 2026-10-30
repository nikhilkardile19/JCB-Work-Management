import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database_provider.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'session_store.dart';

/// REST API root, e.g. `https://api.example.com/api/v1`.
final apiBaseUrlProvider = Provider<String>((ref) => AppConfig.apiBaseUrl);

final secretStoreProvider = Provider<SecretStore>(
  (ref) => const SecureSecretStore(),
);

/// The signed-in session, shared by the auth repository and the API client.
final sessionStoreProvider = Provider<SessionStore>((ref) {
  final store = SessionStore(ref.watch(secretStoreProvider));
  ref.onDispose(store.dispose);
  return store;
});

/// One HTTP client for every server call.
final apiClientProvider = Provider<ApiClient>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final client = ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    session: ref.watch(sessionStoreProvider),
    deviceId: db.installationId,
  );
  ref.onDispose(client.close);
  return client;
});
