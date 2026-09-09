import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'routing/app_router.dart';

class StockShieldApp extends ConsumerWidget {
  const StockShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final router = ref.watch(appRouterProvider);
    AppColors.apply(themeMode);

    // Keep GoRouter pages in sync when theme flips (stack screens otherwise
    // keep the previous build until a manual refresh/navigation).
    ref.listen<AppThemeMode>(appThemeModeProvider, (prev, next) {
      if (prev == next) return;
      AppColors.apply(next);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.refresh();
      });
    });

    return MaterialApp.router(
      title: 'StockShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forMode(themeMode),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: router,
      builder: (context, child) {
        // Keep typography stable regardless of the OS font-size setting.
        final scale = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          // Remount the navigator subtree so every open screen picks up
          // AppColors immediately — no pull-to-refresh needed.
          child: KeyedSubtree(
            key: ValueKey(themeMode),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Momentum scrolling on every platform, without the Android glow overlay.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}
