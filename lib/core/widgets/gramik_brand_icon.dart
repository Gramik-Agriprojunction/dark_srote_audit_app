import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

class GramikBrandIcon extends StatelessWidget {
  const GramikBrandIcon({
    super.key,
    this.size = 42,
    this.borderRadius = 13,
    this.padding = 4,
    this.showBackground = true,
  });

  final double size;
  final double borderRadius;
  final double padding;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AppAssets.gramikIcon,
      width: size - (padding * 2),
      height: size - (padding * 2),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!showBackground) return SizedBox(width: size, height: size, child: image);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: image,
    );
  }
}

class GramikLogo extends StatelessWidget {
  const GramikLogo({
    super.key,
    this.height = 28,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.gramikLogo,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.high,
    );
  }
}
