import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Theme-aware tokens for static preview screens — follows app Dark / Default.
class PreviewTheme {
  PreviewTheme._();

  static Color get orange => AppColors.primary;
  static Color get bg => AppColors.background;
  static Color get surface => AppColors.cardBg;
  static Color get field => AppColors.fieldBg;
  static Color get text => AppColors.textPrimary;
  static Color get textSecondary => AppColors.textSecondary;
  static Color get textMuted => AppColors.textMuted;
  static Color get border => AppColors.border;
  static Color get orangeSoft => AppColors.softOrange;

  static Color get green =>
      AppColors.isDark ? const Color(0xFF6BCF8E) : const Color(0xFF15803D);
  static Color get greenSoft =>
      AppColors.isDark ? const Color(0xFF1A3A2A) : const Color(0xFFDCFCE7);
  static Color get red =>
      AppColors.isDark ? const Color(0xFFE88A9A) : const Color(0xFFB91C1C);
  static Color get redSoft =>
      AppColors.isDark ? const Color(0xFF3A1A2A) : const Color(0xFFFEE2E2);
  static Color get blue =>
      AppColors.isDark ? const Color(0xFF7EB8E8) : const Color(0xFF1D4ED8);
  static Color get blueSoft =>
      AppColors.isDark ? const Color(0xFF2A3A4A) : const Color(0xFFDBEAFE);
  static Color get rose =>
      AppColors.isDark ? const Color(0xFFE88A9A) : const Color(0xFFBE123C);
  static Color get roseSoft =>
      AppColors.isDark ? const Color(0xFF3A1A2A) : const Color(0xFFFFE4E6);
  static Color get teal =>
      AppColors.isDark ? const Color(0xFF6BCFBF) : const Color(0xFF047857);
  static Color get tealSoft =>
      AppColors.isDark ? const Color(0xFF1A3A32) : const Color(0xFFD1FAE5);

  static List<BoxShadow> get cardShadow => AppColors.isDark
      ? const [
          BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 4)),
        ]
      : const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 14, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 1)),
        ];
}

/// Select field — light on orange header, or normal card style in body.
class PreviewSelectField extends StatelessWidget {
  const PreviewSelectField({
    super.key,
    required this.icon,
    required this.label,
    this.onHeader = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool onHeader;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onOrange = onHeader && !AppColors.isDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: onOrange
                ? Colors.white.withValues(alpha: 0.18)
                : PreviewTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onOrange
                  ? Colors.white.withValues(alpha: 0.28)
                  : PreviewTheme.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: onOrange ? Colors.white : PreviewTheme.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: onOrange ? Colors.white : PreviewTheme.text,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: onOrange
                      ? Colors.white.withValues(alpha: 0.85)
                      : PreviewTheme.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreviewSearchRow extends StatelessWidget {
  const PreviewSearchRow({
    super.key,
    required this.hint,
    this.onHeader = false,
  });

  final String hint;
  final bool onHeader;

  @override
  Widget build(BuildContext context) {
    final onOrange = onHeader && !AppColors.isDark;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: onOrange
                  ? Colors.white.withValues(alpha: 0.18)
                  : PreviewTheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: onOrange
                    ? Colors.white.withValues(alpha: 0.28)
                    : PreviewTheme.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: onOrange
                      ? Colors.white.withValues(alpha: 0.85)
                      : PreviewTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 13,
                      color: onOrange
                          ? Colors.white.withValues(alpha: 0.7)
                          : PreviewTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: onOrange
                ? Colors.white.withValues(alpha: 0.18)
                : PreviewTheme.orangeSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onOrange
                  ? Colors.white.withValues(alpha: 0.35)
                  : PreviewTheme.orange.withValues(alpha: 0.55),
            ),
          ),
          child: Icon(
            Icons.filter_alt_rounded,
            size: 20,
            color: onOrange ? Colors.white : PreviewTheme.orange,
          ),
        ),
      ],
    );
  }
}

class PreviewStatChip extends StatelessWidget {
  const PreviewStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
  });

  final String label;
  final String value;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
