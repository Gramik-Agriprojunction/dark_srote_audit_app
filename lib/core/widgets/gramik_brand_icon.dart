import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

/// Darkstore shop icon inside a white tile — matches RN header monogram.
class GramikBrandIcon extends StatelessWidget {
  const GramikBrandIcon({
    super.key,
    this.size = 42,
    this.borderRadius = 14,
    this.padding = 8,
    this.showBackground = true,
  });

  final double size;
  final double borderRadius;
  final double padding;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final iconSize = size - (padding * 2);
    final icon = ColorFiltered(
      colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
      child: Image.asset(
        AppAssets.shopIcon,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );

    if (!showBackground) return icon;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      alignment: Alignment.center,
      child: icon,
    );
  }
}

/// Shop glyph for large brand areas.
class GramikLogo extends StatelessWidget {
  const GramikLogo({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 2.1,
      height: size * 2.1,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
        child: Image.asset(
          AppAssets.shopIcon,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
