import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../features/auth/presentation/code_sign_in_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/billing/presentation/billing_screen.dart';
import '../features/billing/presentation/invoice_builder_screen.dart';
import '../features/billing/presentation/invoice_detail_screen.dart';
import '../features/billing/presentation/invoice_pdf_screen.dart';
import '../features/company/application/company_providers.dart';
import '../features/company/application/session.dart';
import '../features/company/presentation/company_profile_screen.dart';
import '../features/company/presentation/company_setup_screen.dart';
import '../features/company/presentation/company_status_screen.dart';
import '../features/company/presentation/select_company_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../core/widgets/state_views.dart';
import '../features/fuel/presentation/fuel_detail_screen.dart';
import '../features/fuel/presentation/fuel_form_screen.dart';
import '../features/fuel/presentation/fuel_screen.dart';
import '../features/license/application/license_controller.dart';
import '../features/license/domain/license.dart';
import '../features/license/presentation/activation_screen.dart';
import '../features/license/presentation/license_screen.dart';
import '../features/license/presentation/replacement_screen.dart';
import '../features/masters/domain/master_kind.dart';
import '../features/masters/presentation/master_detail_screen.dart';
import '../features/masters/presentation/master_form_screen.dart';
import '../features/masters/presentation/master_list_screen.dart';
import '../features/more/component_gallery_screen.dart';
import '../features/more/more_screen.dart';
import '../features/more/privacy_screen.dart';
import '../features/reports/domain/reports.dart';
import '../features/reports/presentation/report_pdf_screen.dart';
import '../features/reports/presentation/report_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/sync/presentation/sync_screen.dart';
import '../features/users/presentation/users_screen.dart';
import '../features/work/presentation/work_log_detail_screen.dart';
import '../features/work/presentation/work_log_form_screen.dart';
import '../features/work/presentation/work_logs_screen.dart';
import 'routes.dart';

/// Screens reachable without signing in.
const _signedOutRoutes = {Routes.login, Routes.loginCode, Routes.signUp};

/// Pure redirect decision so the guard can be unit-tested. [license] is
/// null while the cached license state is loading.
String? sessionRedirect(
  SessionState session,
  String location, {
  LicenseAccess? license,
}) {
  String? only(String target) => location == target ? null : target;
  return switch (session) {
    // Splash shows progress, or the error with a retry.
    SessionLoading() || SessionError() => only(Routes.splash),
    SessionSignedOut() =>
      _signedOutRoutes.contains(location) ? null : Routes.login,
    SessionNeedsCompany() => only(Routes.companySetup),
    SessionPickCompany() => only(Routes.selectCompany),
    SessionPendingApproval() ||
    SessionSuspended() => only(Routes.companyStatus),
    SessionReady() => switch (license) {
      null => only(Routes.splash),
      LicenseNeedsActivation() =>
        location == Routes.replacement ? null : only(Routes.activate),
      _ when Routes.gate.contains(location) => Routes.dashboard,
      // Read-only: data stays viewable, but forms that change it are closed.
      final l when !l.canWrite && Routes.isWriteRoute(location) =>
        Routes.license,
      _ when location == Routes.components && !AppConfig.isDev => Routes.more,
      _ => null,
    },
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  // Re-run redirects after Riverpod finishes its update pass; redirecting
  // synchronously would read providers that are still being rebuilt.
  void notify() => scheduleMicrotask(() => refresh.value++);
  ref.listen(sessionProvider, (_, _) => notify());
  ref.listen(licenseAccessProvider, (_, _) => notify());

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => sessionRedirect(
      ref.read(sessionProvider),
      state.matchedLocation,
      license: ref.read(licenseAccessProvider).value,
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.dashboard),
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'code',
            // Without an email (e.g. a stale deep link) start over.
            redirect: (_, state) =>
                (state.uri.queryParameters['email'] ?? '').trim().isEmpty
                ? Routes.login
                : null,
            builder: (_, state) =>
                CodeSignInScreen(email: state.uri.queryParameters['email']!),
          ),
          GoRoute(path: 'signup', builder: (_, _) => const SignUpScreen()),
        ],
      ),
      GoRoute(
        path: Routes.companySetup,
        builder: (_, _) => const CompanySetupScreen(),
      ),
      GoRoute(
        path: Routes.selectCompany,
        builder: (_, _) => const SelectCompanyScreen(),
      ),
      GoRoute(
        path: Routes.companyStatus,
        builder: (_, _) => const CompanyStatusScreen(),
      ),
      GoRoute(
        path: Routes.activate,
        builder: (_, _) => const ActivationScreen(),
      ),
      GoRoute(
        path: Routes.replacement,
        builder: (_, state) =>
            ReplacementScreen(activationCode: state.extra as String?),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.work,
                builder: (_, _) => const WorkLogsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const WorkLogFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        WorkLogDetailScreen(id: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) =>
                            WorkLogFormScreen(id: state.pathParameters['id']),
                      ),
                      GoRoute(
                        path: 'correct',
                        builder: (_, state) => WorkLogFormScreen(
                          id: state.pathParameters['id'],
                          mode: WorkFormMode.correct,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.fuel,
                builder: (_, _) => const FuelScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const FuelFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        FuelDetailScreen(id: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) =>
                            FuelFormScreen(id: state.pathParameters['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.billing,
                builder: (_, _) => const BillingScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const InvoiceBuilderScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        InvoiceDetailScreen(id: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) => InvoiceBuilderScreen(
                          id: state.pathParameters['id'],
                        ),
                      ),
                      GoRoute(
                        path: 'pdf',
                        builder: (_, state) =>
                            InvoicePdfScreen(id: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.more,
                builder: (_, _) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'company',
                    builder: (_, _) => const CompanyProfileScreen(),
                  ),
                  GoRoute(
                    path: 'masters/:kind',
                    builder: (_, state) =>
                        _withKind(state, (k) => MasterListScreen(kind: k)),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (_, state) => _withKind(
                          state,
                          (k) => MasterFormScreen(
                            kind: k,
                            presetClientId:
                                state.uri.queryParameters['clientId'],
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => _withKind(
                          state,
                          (k) => MasterDetailScreen(
                            kind: k,
                            id: state.pathParameters['id']!,
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: 'edit',
                            builder: (_, state) => _withKind(
                              state,
                              (k) => MasterFormScreen(
                                kind: k,
                                id: state.pathParameters['id'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'users',
                    builder: (_, _) => const UsersScreen(),
                  ),
                  GoRoute(
                    path: 'license',
                    builder: (_, _) => const LicenseScreen(),
                  ),
                  GoRoute(path: 'sync', builder: (_, _) => const SyncScreen()),
                  GoRoute(
                    path: 'privacy',
                    builder: (_, _) => const PrivacyScreen(),
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (_, _) => const ReportsScreen(),
                    routes: [
                      GoRoute(
                        path: ':kind',
                        builder: (_, state) =>
                            _withReport(state, (k) => ReportScreen(kind: k)),
                        routes: [
                          GoRoute(
                            path: 'pdf',
                            builder: (_, state) => _withReport(
                              state,
                              (k) => ReportPdfScreen(kind: k),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'components',
                    builder: (_, _) => const ComponentGalleryScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

Widget _withKind(GoRouterState state, Widget Function(MasterKind) build) {
  final kind = MasterKind.fromSlug(state.pathParameters['kind']);
  return kind == null
      ? const Scaffold(body: EmptyView(title: 'Page not found'))
      : build(kind);
}

Widget _withReport(GoRouterState state, Widget Function(ReportKind) build) {
  final kind = ReportKind.parse(state.pathParameters['kind']);
  return kind == null
      ? const Scaffold(body: EmptyView(title: 'Page not found'))
      : build(kind);
}
