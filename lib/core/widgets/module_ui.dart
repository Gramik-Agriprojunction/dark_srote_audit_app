import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import 'app_brand_header.dart';
import 'app_ui.dart';

/// Shared design language lifted from the Orders screen so every module
/// (Home, Stock, Transactions, Variance) reads the same.
///
/// Tokens: compact orange header sheet, horizontal colour stat cards,
/// stadium filter chips, white list cards with a left status strip.
class ModuleTokens {
  ModuleTokens._();

  static const cardRadius = 16.0;
  static const cardBorder = Color(0xFFE8ECF1);
  static const chipBorder = Color(0xFFD1D9E6);
  static const mutedText = Color(0xFF64748B);
  static const strongText = Color(0xFF0F172A);
  static const faintText = Color(0xFF94A3B8);

  static const listPadding = EdgeInsets.symmetric(horizontal: 10);

  static const cardShadow = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const statShadow = [
    BoxShadow(color: Color(0x1F0F172A), blurRadius: 6, offset: Offset(0, 2)),
  ];
}

/// Compact orange header sheet with Gramik brand, actions and optional search.
class ModuleHeader extends StatelessWidget {
  const ModuleHeader({
    super.key,
    this.pageLabel,
    this.subtitle,
    this.onBack,
    this.onLogout,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.showNotifications = true,
    this.actions = const [],
    this.searchController,
    this.searchHint,
    this.searchValue = '',
    this.onSearchChanged,
    this.onClearSearch,
    this.bottom,
  });

  /// Screen-specific line under the brand tagline (e.g. Orders, Stock).
  final String? pageLabel;
  final String? subtitle;

  /// When set, the leading circle becomes a back button instead of the brand icon.
  final VoidCallback? onBack;
  final Future<void> Function()? onLogout;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final bool showNotifications;

  /// Extra header actions shown before user menu and notifications.
  final List<Widget> actions;

  /// Provide all four search params together to render the search pill.
  final TextEditingController? searchController;
  final String? searchHint;
  final String searchValue;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearSearch;

  /// Extra content pinned inside the sheet, below the search pill.
  final Widget? bottom;

  bool get _hasSearch => searchController != null && onSearchChanged != null;

  List<Widget> get _trailingActions {
    final items = <Widget>[...actions];
    if (onLogout != null) {
      items.add(ModuleUserMenuAction(onLogout: onLogout!));
    }
    if (showNotifications) {
      items.add(
        ModuleHeaderAction(
          icon: Icons.notifications_none_rounded,
          badgeCount: notificationCount,
          tooltip: 'Notifications',
          onTap: onNotificationTap ?? () {},
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          8,
          MediaQuery.paddingOf(context).top + 8,
          8,
          8,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (onBack != null)
                  ModuleHeaderAction(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onTap: onBack!,
                  )
                else
                  const AppBrandIcon(),
                const SizedBox(width: 10),
                Expanded(
                  child: AppBrandMark(
                    showIcon: false,
                    pageLabel: pageLabel,
                    subtitle: subtitle,
                  ),
                ),
                for (final action in _trailingActions) ...[
                  const SizedBox(width: 8),
                  action,
                ],
              ],
            ),
            if (_hasSearch) ...[
              const SizedBox(height: 6),
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          // App-wide InputDecorationTheme fills fields; the
                          // header pill already provides the surface.
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: searchHint ?? 'Search...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (searchValue.isNotEmpty && onClearSearch != null)
                      GestureDetector(
                        onTap: onClearSearch,
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (bottom != null) ...[const SizedBox(height: 8), bottom!],
          ],
        ),
      ),
    );
  }
}

/// Circular translucent action button for [ModuleHeader].
class ModuleHeaderAction extends StatelessWidget {
  const ModuleHeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );

    final wrapped = badgeCount <= 0
        ? button
        : Stack(
            clipBehavior: Clip.none,
            children: [
              button,
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: ModuleTokens.strongText,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );

    if (tooltip == null) return wrapped;
    return Tooltip(message: tooltip!, child: wrapped);
  }
}

Future<bool> confirmModuleLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Logout'),
      content: const Text('Kya aap logout karna chahte hain?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// User icon that opens a menu with Logout (confirmation before sign-out).
class ModuleUserMenuAction extends StatelessWidget {
  const ModuleUserMenuAction({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value != 'logout') return;
        HapticFeedback.selectionClick();
        final confirmed = await confirmModuleLogout(context);
        if (!context.mounted || !confirmed) return;
        await onLogout();
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'logout',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ModuleTokens.strongText,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Material(
        color: Colors.white.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.person_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Logout action using the Darkstore logout glyph.
class ModuleLogoutAction extends StatelessWidget {
  const ModuleLogoutAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Logout',
      child: Material(
        color: Colors.white.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 40,
            height: 40,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                AppAssets.logoutIcon,
                fit: BoxFit.contain,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModuleStat {
  const ModuleStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.background,
    required this.labelColor,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color background;
  final Color labelColor;
  final bool isActive;
  final VoidCallback? onTap;
}

/// Horizontally scrolling row of solid colour stat cards.
/// Up to three stats expand equally to fill the row width; more use horizontal scroll.
class ModuleStatsRow extends StatelessWidget {
  const ModuleStatsRow({super.key, required this.stats});

  final List<ModuleStat> stats;

  static const _maxExpandedCount = 3;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    if (stats.length <= _maxExpandedCount) {
      return SizedBox(
        height: 78,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _ModuleStatCard(stat: stats[i], expanded: true),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        itemCount: stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _ModuleStatCard(stat: stats[index]),
      ),
    );
  }
}

class _ModuleStatCard extends StatelessWidget {
  const _ModuleStatCard({required this.stat, this.expanded = false});

  final ModuleStat stat;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: expanded ? double.infinity : null,
      constraints: expanded ? null : const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: stat.background,
        borderRadius: BorderRadius.circular(11),
        boxShadow: ModuleTokens.statShadow,
        border: stat.isActive
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(stat.icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          if (expanded)
            Expanded(
              child: _ModuleStatText(stat: stat),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: _ModuleStatText(stat: stat),
            ),
          if (stat.isActive) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_rounded, color: Colors.white, size: 16),
          ],
        ],
      ),
    );

    if (stat.onTap == null) return card;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          stat.onTap!();
        },
        child: card,
      ),
    );
  }
}

class _ModuleStatText extends StatelessWidget {
  const _ModuleStatText({required this.stat});

  final ModuleStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: stat.labelColor,
            fontSize: 8.5,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          stat.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class ModuleChip {
  const ModuleChip({
    required this.label,
    required this.icon,
    required this.tone,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tone;
  final bool isActive;
  final VoidCallback onTap;
}

/// Horizontally scrolling stadium filter chips.
class ModuleChipsRow extends StatelessWidget {
  const ModuleChipsRow({super.key, required this.chips});

  final List<ModuleChip> chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Row(
        children: chips.map((chip) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: chip.isActive ? chip.tone : Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: chip.isActive ? chip.tone : ModuleTokens.chipBorder,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  chip.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chip.icon,
                        size: 13,
                        color: chip.isActive
                            ? Colors.white
                            : ModuleTokens.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chip.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: chip.isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: chip.isActive
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Shimmer placeholders matching [ModuleStatsRow] while counts load.
class ModuleStatsRowSkeleton extends StatelessWidget {
  const ModuleStatsRowSkeleton({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= ModuleStatsRow._maxExpandedCount) {
      return SizedBox(
        height: 78,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _skeletonCard()),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => SizedBox(width: 148, child: _skeletonCard()),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModuleTokens.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSkeleton(height: 10, width: 72),
          SizedBox(height: 8),
          AppSkeleton(height: 18, width: 44),
        ],
      ),
    );
  }
}

/// Shimmer placeholder matching [ModuleCard] list rows.
class ModuleCardSkeleton extends StatelessWidget {
  const ModuleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ModuleTokens.cardRadius),
          border: Border.all(color: ModuleTokens.cardBorder),
          boxShadow: ModuleTokens.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ModuleTokens.cardRadius),
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AppSkeleton(height: 92, width: 4, radius: 0),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Expanded(
                          child: AppSkeleton(height: 14, width: 160),
                        ),
                        SizedBox(width: 10),
                        AppSkeleton(height: 20, width: 56, radius: 999),
                      ],
                    ),
                    SizedBox(height: 10),
                    AppSkeleton(height: 44, radius: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Native-style list loading — stats + cards instead of a lone spinner.
class ModuleListLoadingBody extends StatelessWidget {
  const ModuleListLoadingBody({
    super.key,
    this.showStats = true,
    this.itemCount = 4,
  });

  final bool showStats;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showStats) const ModuleStatsRowSkeleton(),
        for (var i = 0; i < itemCount; i++) const ModuleCardSkeleton(),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// White list card with a coloured status strip on the left edge.
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.child,
    required this.statusColor,
    this.onTap,
    this.margin = const EdgeInsets.fromLTRB(10, 0, 10, 8),
  });

  final Widget child;
  final Color statusColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ModuleTokens.cardRadius),
          border: Border.all(color: ModuleTokens.cardBorder),
          boxShadow: ModuleTokens.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ModuleTokens.cardRadius),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: statusColor),
              ),
              if (onTap == null)
                child
              else
                Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap, child: child),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small status pill used inside [ModuleCard] headers.
class ModuleStatusPill extends StatelessWidget {
  const ModuleStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.filled = true,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Orders-style centred empty placeholder.
class ModuleEmptyState extends StatelessWidget {
  const ModuleEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: ModuleTokens.faintText),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: ModuleTokens.faintText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
