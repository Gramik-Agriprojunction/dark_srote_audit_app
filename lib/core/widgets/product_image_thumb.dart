import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Product thumbnail with a consistent placeholder when URL is missing or fails.
class ProductImageThumb extends StatelessWidget {
  const ProductImageThumb({
    super.key,
    this.imageUrl,
    this.width = 48,
    this.height = 48,
    this.borderRadius = 12,
    this.iconSize,
    this.backgroundColor,
    this.showBorder = true,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final double? iconSize;
  final Color? backgroundColor;
  final bool showBorder;

  bool get _hasUrl {
    final trimmed = imageUrl?.trim() ?? '';
    return trimmed.isNotEmpty;
  }

  double get _iconSize => iconSize ?? (width * 0.42).clamp(14.0, 26.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.fieldBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder ? Border.all(color: AppColors.border) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasUrl
          ? CachedNetworkImage(
              imageUrl: imageUrl!.trim(),
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (_, _) =>
                  ProductImagePlaceholder(iconSize: _iconSize),
              errorWidget: (_, _, _) =>
                  ProductImagePlaceholder(iconSize: _iconSize),
            )
          : ProductImagePlaceholder(iconSize: _iconSize),
    );
  }
}

class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({
    super.key,
    this.iconSize = 22,
    this.backgroundColor,
  });

  final double iconSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? AppColors.fieldBg,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: iconSize,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
