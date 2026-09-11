import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav.dart';

/// Bottom-nav shell that keeps tab screens alive via [StatefulNavigationShell]
/// (IndexedStack) so switching Home ↔ Stock ↔ Orders ↔ Audit feels instant.
class MainTabShell extends StatelessWidget {
  const MainTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    AppTab.dashboard,
    AppTab.stock,
    AppTab.orders,
    AppTab.audit,
  ];

  void _go(int index) {
    navigationShell.goBranch(
      index,
      // Re-tapping the active tab returns to that branch's root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _handleSystemBack(BuildContext context) {
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0, initialLocation: true);
      return;
    }
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex.clamp(0, _tabs.length - 1);
    final onDashboard = current == 0;

    return PopScope(
      canPop: onDashboard && context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack(context);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: AppBottomNav(
          currentTab: _tabs[current],
          onDashboardTap: () => _go(0),
          onStockTap: () => _go(1),
          onOrdersTap: () => _go(2),
          onHomeTap: () => _go(3),
        ),
      ),
    );
  }
}
