import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/connectivity/connectivity_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/state_views.dart';
import '../auth/application/auth_providers.dart';
import '../company/application/company_providers.dart';
import '../company/application/session.dart';

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

    return switch (session) {
      SessionError() => Scaffold(
        body: SafeArea(
          child: Column(
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
        ),
      ),
      _ => const _LaunchView(),
    };
  }
}

const _launchImage = 'assets/images/splash.webp';

/// On-screen size of [_launchImage]. Must match
/// android/app/src/main/res/drawable-v21/launch_background.xml, which shows
/// the same image before Flutter starts.
const _launchImageSize = Size(360, 288);

/// Decodes the launch image so the splash's first frame already shows it,
/// instead of it blinking in after Android's launch screen.
Future<void> precacheLaunchImage() {
  final done = Completer<void>();
  final stream = const AssetImage(_launchImage)
      .resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void finish() {
    stream.removeListener(listener);
    if (!done.isCompleted) done.complete();
  }

  listener = ImageStreamListener(
    (_, _) => finish(),
    onError: (_, _) => finish(),
  );
  stream.addListener(listener);
  return done.future;
}

/// Continues Android's launch screen: same image, size and dark background,
/// whatever the app's theme.
class _LaunchView extends StatelessWidget {
  const _LaunchView();

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Image.asset(
                _launchImage,
                width: _launchImageSize.width,
                height: _launchImageSize.height,
                excludeFromSemantics: true,
              ),
            ),
            const SafeArea(
              minimum: EdgeInsets.only(bottom: AppSpace.xxxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _AppTitle(),
                  SizedBox(height: AppSpace.lg),
                  SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) =>
      Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineSmall);
}
