import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/product_image_thumb.dart';

import '../../data/models/order_model.dart';
import '../utils/order_status_helper.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.expanded,
    required this.onToggleExpand,
    required this.onOpenDetail,
  });

  final OrderListItemModel order;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final status = mapOrderStatus(order.orderStatus);
    final customer = order.shippingAddress.displayName;
    final city = order.shippingAddress.city ?? order.shippingAddress.address ?? '';
    final locShort = [customer, city].where((e) => e.trim().isNotEmpty).join(' · ');
    final payPill = paymentStatusPill(order.paymentStatus);
    final payColor = isPaidStatus(order.paymentStatus)
        ? const Color(0xFF16A34A)
        : const Color(0xFFE11D48);
    final hasProducts = order.products.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: status.color),
              ),
              Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenDetail,
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Thumb(
                          imageUrl: order.firstProductImage,
                          badgeCount: order.sumQuantity > 1 ? order.sumQuantity : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.code.isNotEmpty ? order.code : '#${order.id}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatMoney(order.grandTotal),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                locShort.isEmpty ? '--' : locShort,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatOrderDate(order.createdAt).isEmpty
                                    ? '--'
                                    : formatOrderDate(order.createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hasProducts ? onToggleExpand : null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 14, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _FootPill(label: payPill, color: payColor),
                                  _FootPill(
                                    label: paymentLabel(order.paymentType),
                                    color: const Color(0xFFEA5800),
                                  ),
                                  _FootPill(label: status.label, color: status.color),
                                ],
                              ),
                            ),
                            if (hasProducts) ...[
                              const SizedBox(width: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: expanded
                                      ? status.color
                                      : AppColors.background,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  expanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: expanded
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (expanded && hasProducts)
                    Column(
                      children: [
                        for (var i = 0; i < order.products.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: AppColors.border),
                          _ProductRow(product: order.products[i]),
                        ],
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.imageUrl, this.badgeCount});

  final String? imageUrl;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProductImageThumb(
          imageUrl: imageUrl,
          width: 48,
          height: 48,
          borderRadius: 12,
          iconSize: 20,
        ),
        if (badgeCount != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEC5800),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FootPill extends StatelessWidget {
  const _FootPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final OrderProductLineModel product;

  @override
  Widget build(BuildContext context) {
    final lineTotal = product.price == null
        ? null
        : product.price! * product.quantity;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImageThumb(
            imageUrl: product.thumbnailImg,
            width: 34,
            height: 34,
            borderRadius: 8,
            iconSize: 13,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name.isEmpty ? '--' : product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty ${product.quantity}${product.price != null ? ' · ${formatMoney(product.price!)}' : ''}',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            lineTotal == null ? '--' : formatMoney(lineTotal),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
