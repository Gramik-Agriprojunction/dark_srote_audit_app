import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/alert_banner.dart';
import '../data/models/order_model.dart';
import 'providers/order_detail_provider.dart';
import 'utils/order_status_helper.dart';
import 'widgets/cancel_order_sheet.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderDetailControllerProvider(widget.orderId).notifier).load();
    });
  }

  Future<void> _openCancelSheet(OrderDetailModel order) async {
    final controller = ref.read(orderDetailControllerProvider(widget.orderId).notifier);
    await controller.loadCancelReasons();
    if (!mounted) return;
    final state = ref.read(orderDetailControllerProvider(widget.orderId));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancelOrderSheet(
        orderCode: order.code,
        customerName: order.shippingAddress.displayName.isEmpty
            ? 'Customer'
            : order.shippingAddress.displayName,
        reasons: state.cancelReasons,
        isLoading: state.cancelReasons.isEmpty && state.isActionLoading,
        onConfirm: (reason) async {
          Navigator.of(ctx).pop();
          final ok = await controller.cancelOrder(reason);
          if (!mounted || !ok) return;
          final message = ref
                  .read(orderDetailControllerProvider(widget.orderId))
                  .successMessage ??
              'Order cancelled';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      ),
    );
  }

  Future<void> _callPhone(String? phone) async {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return;
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailControllerProvider(widget.orderId));
    final order = state.order;
    final top = MediaQuery.paddingOf(context).top;

    if (state.isLoading && order == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Order Details'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.error != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AlertBanner(message: state.error!, isError: true),
                ),
              ],
              ElevatedButton(
                onPressed: () => ref
                    .read(orderDetailControllerProvider(widget.orderId).notifier)
                    .load(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final status = mapOrderStatus(order.orderStatus);
    final statusUpper = order.orderStatus.toUpperCase();
    final isPending = statusUpper == 'PENDING';
    final isManifested = statusUpper == 'MANIFESTED';
    final showReadyToPick =
        !order.isCounterSale && (isPending || isManifested) && !order.pickReady;
    final showCancel =
        order.isCounterSale && statusUpper == 'DELIVERED';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: status.color),
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: (showReadyToPick || showCancel)
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: showReadyToPick
                      ? _ActionButton(
                          label: 'Ready to Pick',
                          icon: Icons.local_shipping_outlined,
                          color: status.color,
                          loading: state.isActionLoading,
                          onPressed: () async {
                            final ok = await ref
                                .read(orderDetailControllerProvider(widget.orderId).notifier)
                                .markReadyToPick();
                            if (!mounted || !ok) return;
                            final message = ref
                                    .read(orderDetailControllerProvider(widget.orderId))
                                    .successMessage ??
                                'Ready to pick';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          },
                        )
                      : _ActionButton(
                          label: 'Cancel Order',
                          icon: Icons.cancel_outlined,
                          color: const Color(0xFFEF4444),
                          loading: state.isActionLoading,
                          onPressed: () => _openCancelSheet(order),
                        ),
                ),
              )
            : null,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref
              .read(orderDetailControllerProvider(widget.orderId).notifier)
              .load(refresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _DetailHeader(
                  topPadding: top,
                  order: order,
                  status: status,
                  onBack: () => context.pop(),
                ),
              ),
              if (state.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AlertBanner(message: state.error!, isError: true),
                  ),
                ),
              if (state.successMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AlertBanner(message: state.successMessage!, isError: false),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _TimelineCard(order: order, statusColor: status.color),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _CustomerCard(
                    order: order,
                    onCall: () => _callPhone(order.shippingAddress.phone),
                  ),
                ),
              ),
              if ((order.deliveryPartner.name ?? '').isNotEmpty &&
                  !order.isCounterSale)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _DeliveryPartnerCard(
                      partner: order.deliveryPartner,
                      onCall: () => _callPhone(order.deliveryPartner.phone),
                    ),
                  ),
                ),
              if (_otpEntries(order).isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _OtpCard(entries: _otpEntries(order)),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _ProductsCard(products: order.products),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: _BillCard(order: order, statusColor: status.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<({String label, String value})> _otpEntries(OrderDetailModel order) {
    final entries = <({String label, String value})>[];
    void add(String label, String? value) {
      final v = (value ?? '').trim();
      if (v.isNotEmpty) entries.add((label: label, value: v));
    }

    add('Order OTP', order.otp);
    add('Delivery OTP', order.deliverOtp);
    add('Pickup OTP', order.pickupOtp);
    return entries;
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.topPadding,
    required this.order,
    required this.status,
    required this.onBack,
  });

  final double topPadding;
  final OrderDetailModel order;
  final OrderStatusInfo status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final paid = isPaidStatus(order.paymentStatus);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.code.isNotEmpty ? order.code : '#${order.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatOrderDate(order.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatMoney(order.grandTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                icon: paid ? Icons.check_circle_outline : Icons.error_outline,
                label: paid ? 'Paid' : paymentStatusPill(order.paymentStatus),
              ),
              _MetaPill(
                icon: Icons.payments_outlined,
                label: paymentLabel(order.paymentType),
              ),
              _MetaPill(
                icon: Icons.inventory_2_outlined,
                label: '${order.sumQuantity} items',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.order, required this.statusColor});

  final OrderDetailModel order;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    const steps = ['Pending', 'Out', 'Delivered'];
    final current = _stepIndex(order.orderStatus);

    return _SectionCard(
      title: 'Order Progress',
      child: Row(
        children: List.generate(steps.length, (index) {
          final done = index <= current;
          final active = index == current;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done ? statusColor : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: active
                        ? Border.all(color: statusColor.withValues(alpha: 0.3), width: 3)
                        : null,
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : Icons.circle,
                    size: 14,
                    color: done ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: done ? statusColor : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  int _stepIndex(String status) {
    final s = status.toUpperCase();
    if (s == 'DELIVERED' || s == 'RTO') return 2;
    if (s == 'INTRANSIT' || s == 'PICKUP' || s == 'MANIFESTED') return 1;
    return 0;
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order, required this.onCall});

  final OrderDetailModel order;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final ship = order.shippingAddress;
    return _SectionCard(
      title: 'Customer',
      trailing: (ship.phone ?? '').isNotEmpty
          ? IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.call_rounded, color: AppColors.primary),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ship.displayName.isEmpty ? '--' : ship.displayName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          if ((ship.phone ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(ship.phone!, style: const TextStyle(color: Color(0xFF64748B))),
          ],
          if (ship.fullAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ship.fullAddress,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliveryPartnerCard extends StatelessWidget {
  const _DeliveryPartnerCard({required this.partner, required this.onCall});

  final OrderDeliveryPartnerModel partner;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Delivery Partner',
      trailing: (partner.phone ?? '').isNotEmpty
          ? IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.call_rounded, color: AppColors.primary),
            )
          : null,
      child: Text(
        partner.name ?? '--',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class _OtpCard extends StatelessWidget {
  const _OtpCard({required this.entries});

  final List<({String label, String value})> entries;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'OTPs',
      child: Column(
        children: entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({required this.products});

  final List<OrderProductLineModel> products;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Products (${products.length})',
      child: Column(
        children: [
          for (var i = 0; i < products.length; i++) ...[
            if (i > 0) const Divider(height: 16, color: Color(0xFFE2E8F0)),
            _ProductLine(product: products[i]),
          ],
        ],
      ),
    );
  }
}

class _ProductLine extends StatelessWidget {
  const _ProductLine({required this.product});

  final OrderProductLineModel product;

  @override
  Widget build(BuildContext context) {
    final lineTotal = product.price == null
        ? null
        : product.price! * product.quantity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: product.thumbnailImg != null && product.thumbnailImg!.isNotEmpty
              ? CachedNetworkImage(imageUrl: product.thumbnailImg!, fit: BoxFit.cover)
              : const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Qty ${product.quantity}${product.price != null ? ' · ${formatMoney(product.price!)}' : ''}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        Text(
          lineTotal == null ? '--' : formatMoney(lineTotal),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.order, required this.statusColor});

  final OrderDetailModel order;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Bill Summary',
      child: Column(
        children: [
          _BillRow(label: 'Subtotal', value: formatMoney(order.subtotal)),
          if (order.discount > 0)
            _BillRow(label: 'Discount', value: '- ${formatMoney(order.discount)}'),
          if (order.shippingCost > 0)
            _BillRow(label: 'Shipping', value: formatMoney(order.shippingCost)),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          _BillRow(
            label: 'Grand Total',
            value: formatMoney(order.grandTotal),
            bold: true,
            accent: statusColor,
          ),
          if ((order.transactionId ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _BillRow(label: 'Transaction', value: order.transactionId!),
          ],
          if ((order.utr ?? '').isNotEmpty)
            _BillRow(label: 'UTR', value: order.utr!),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.accent,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: accent ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
