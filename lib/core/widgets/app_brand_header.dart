import 'package:flutter/material.dart';

import '../../features/auth/presentation/widgets/auth_theme.dart';
import '../constants/app_assets.dart';

enum AppBrandMarkSize { compact, hero }

/// Login-page brand block — reused on every authenticated screen header.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    super.key,
    this.size = AppBrandMarkSize.compact,
    this.pageLabel,
    this.subtitle,
    this.showIcon = true,
  });

  final AppBrandMarkSize size;
  final String? pageLabel;
  final String? subtitle;
  final bool showIcon;

  bool get _hero => size == AppBrandMarkSize.hero;

  @override
  Widget build(BuildContext context) {
    final titleStyle = _hero
        ? AuthTheme.brandName()
        : AuthTheme.brandName().copyWith(fontSize: 15, height: 1.15);
    final titleBoldStyle = _hero
        ? AuthTheme.brandNameBold()
        : AuthTheme.brandNameBold().copyWith(fontSize: 15, height: 1.15);
    final taglineStyle = AuthTheme.caption(
      Colors.white.withValues(alpha: _hero ? 0.5 : 0.72),
    ).copyWith(fontSize: _hero ? 12 : 10.5, height: 1.2);

    final textBlock = Column(
      crossAxisAlignment:
          _hero ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: titleStyle,
            children: [
              const TextSpan(text: 'Gramik '),
              TextSpan(text: 'Darkstore', style: titleBoldStyle),
            ],
          ),
        ),
        SizedBox(height: _hero ? 4 : 2),
        Text('Stock Audit • Dark Store', style: taglineStyle),
        if (pageLabel != null && pageLabel!.trim().isNotEmpty) ...[
          SizedBox(height: _hero ? 6 : 3),
          Text(
            pageLabel!.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _hero ? 13 : 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
        if (subtitle != null &&
            subtitle!.trim().isNotEmpty &&
            subtitle!.trim() != pageLabel?.trim()) ...[
          const SizedBox(height: 1),
          Text(
            subtitle!.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ],
    );

    if (_hero) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            const AppBrandIcon(size: 72, imageSize: 36),
            const SizedBox(height: 14),
          ],
          textBlock,
        ],
      );
    }

    if (!showIcon) return textBlock;

    return Row(
      children: [
        const AppBrandIcon(),
        const SizedBox(width: 10),
        Expanded(child: textBlock),
      ],
    );
  }
}

class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({super.key, this.size = 40, this.imageSize = 22});

  final double size;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AuthTheme.primary,
          BlendMode.srcIn,
        ),
        child: Image.asset(
          AppAssets.shopIcon,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
