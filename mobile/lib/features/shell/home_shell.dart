import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/sync_indicator.dart';
import '../license/presentation/license_widgets.dart';
import '../sync/application/sync_controller.dart';

/// Bottom-navigation shell hosting the four top-level tabs.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.engineering_outlined),
      selectedIcon: Icon(Icons.engineering),
      label: 'Work',
    ),
    NavigationDestination(
      icon: Icon(Icons.local_gas_station_outlined),
      selectedIcon: Icon(Icons.local_gas_station),
      label: 'Fuel',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Billing',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_rounded),
      selectedIcon: Icon(Icons.menu_open_rounded),
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps background sync running while the user is in the app.
    ref.watch(syncControllerProvider);
    return Scaffold(
      body: Column(
        children: [
          const SafeArea(
            bottom: false,
            child: Column(children: [OfflineBanner(), LicenseBanner()]),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: MediaQuery.paddingOf(context).top > 0,
              // Own messenger so snack bars render in each page's Scaffold,
              // above its FAB, instead of in this outer shell Scaffold.
              child: ScaffoldMessenger(child: navigationShell),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: _destinations,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
