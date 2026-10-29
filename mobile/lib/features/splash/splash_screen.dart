import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/connectivity/connectivity_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/state_views.dart';
import '../auth/application/auth_providers.dart';
import '../company/application/company_providers.dart';
import '../company/application/session.dart';
import 'brand_mark.dart';

/// Shown while the session is restored, or when it can't be. Redirects are
/// handled by the router.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final online = ref.watch(isOnlineProvider).value ?? true;

    void retry() {
      ref.invalidate(authStateProvider);
      ref.invalidate(membershipRefreshProvider);
    }

    return Scaffold(
      body: SafeArea(
        child: switch (session) {
          SessionError() => Column(
            children: [
              Expanded(
                child: online
                    ? ErrorView(
                        title: "Couldn't load your company",
                        message: 'Nothing saved on this phone was changed. Please try again.',
                        onRetry: retry,
                      )
                    : OfflineView(
                        message: 'Connect to the internet once to load your company. After that the app works offline.',
                        onRetry: retry,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: AppButton(
                  label: 'Sign out',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.logout,
                  expand: false,
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ),
            ],
          ),
          _ => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(size: 88),
                SizedBox(height: AppSpace.xl),
                _AppTitle(),
                SizedBox(height: AppSpace.xxl),
                SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) =>
      Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineSmall);
}
