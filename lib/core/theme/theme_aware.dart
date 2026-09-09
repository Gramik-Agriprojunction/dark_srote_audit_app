import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import 'theme_mode_provider.dart';

/// Wraps a routed screen so it rebuilds as soon as theme mode changes.
///
/// AppColors are static getters (not InheritedWidget), so screens that are
/// already mounted under the navigator do not rebuild on theme flip unless
/// something in their subtree watches [appThemeModeProvider].
class ThemeAware extends ConsumerWidget {
  const ThemeAware({super.key, required this.builder});

  final Widget Function(BuildContext context, AppThemeMode mode) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    AppColors.apply(mode);
    return KeyedSubtree(
      key: ValueKey(mode),
      child: builder(context, mode),
    );
  }
}
