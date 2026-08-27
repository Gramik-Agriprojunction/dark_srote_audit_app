import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// The StockShield app icon rendered inline. A hairline white ring keeps it
/// separated from the green header behind it.
class GramikBrandIcon extends StatelessWidget {
  const GramikBrandIcon({
    super.key,
    this.size = 42,
    this.borderRadius = 13,
    this.padding = 0,
    this.showBackground = true,
  });

  final double size;
  final double borderRadius;
  final double padding;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AppAssets.icon,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );

    if (!showBackground) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33062F1B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

/// Full StockShield badge, for large brand areas.
class GramikLogo extends StatelessWidget {
  const GramikLogo({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
