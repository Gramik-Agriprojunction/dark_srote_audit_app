import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

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

/// Compact orange header sheet with icon, title, actions and optional search.
class ModuleHeader extends StatelessWidget {
  const ModuleHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.searchController,
    this.searchHint,
    this.searchValue = '',
    this.onSearchChanged,
    this.onClearSearch,
    this.bottom,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// When set, the leading circle becomes a back button instead of [icon].
  final VoidCallback? onBack;
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
              children: [
                if (onBack != null)
                  ModuleHeaderAction(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onTap: onBack!,
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final action in actions) ...[
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color background;
  final Color labelColor;
}

/// Horizontally scrolling row of solid colour stat cards.
class ModuleStatsRow extends StatelessWidget {
  const ModuleStatsRow({super.key, required this.stats});

  final List<ModuleStat> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

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
  const _ModuleStatCard({required this.stat});

  final ModuleStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: stat.background,
        borderRadius: BorderRadius.circular(11),
        boxShadow: ModuleTokens.statShadow,
      ),
      child: Row(
        // Horizontal scroll gives unbounded width, so the card must shrink-wrap.
        mainAxisSize: MainAxisSize.min,
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Column(
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
            ),
          ),
        ],
      ),
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
