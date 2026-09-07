import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/module_ui.dart';
import '../data/models/order_model.dart';
import '../services/thermal_printer_service.dart';
import 'providers/order_detail_provider.dart';
import 'utils/order_detail_helpers.dart';
import 'utils/order_status_helper.dart';
import 'widgets/bluetooth_printer_sheet.dart';
import 'widgets/cancel_order_overlay.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _printBusy = false;

  static const _stickyThreshold = 64.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderDetailControllerProvider(widget.orderId).notifier).load();
    });
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() => _scrollOffset = _scrollController.offset);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  double get _compactOpacity =>
      (_scrollOffset / _stickyThreshold).clamp(0.0, 1.0);

  double get _heroFadeOpacity =>
      (1 - (_scrollOffset / _stickyThreshold)).clamp(0.0, 1.0);

  double get _statusNavOpacity =>
      (1 - (_scrollOffset / (_stickyThreshold * 0.7))).clamp(0.0, 1.0);

  Future<void> _callPhone(String? phone) async {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return;
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String? phone) async {
    final n = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (n.isEmpty) return;
    final cc = n.length == 10 ? '91$n' : n;
    final uri = Uri.parse('https://wa.me/$cc');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openCancelOverlay(OrderDetailModel order) async {
    final controller = ref.read(orderDetailControllerProvider(widget.orderId).notifier);
    await controller.loadCancelReasons();
    if (!mounted) return;
    final state = ref.read(orderDetailControllerProvider(widget.orderId));

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      pageBuilder: (ctx, _, _) => CancelOrderOverlay(
        orderCode: order.code.isNotEmpty ? order.code : '#${order.id}',
        customerName: order.shippingAddress.displayName.isEmpty
            ? 'Customer'
            : order.shippingAddress.displayName,
        customerPhone: order.shippingAddress.phone ?? '',
        customerAddress: order.shippingAddress.fullAddress,
        itemsCount: order.sumQuantity,
        amount: order.grandTotal,
        products: order.products,
        reasons: state.cancelReasons,
        isLoading: state.cancelReasons.isEmpty && state.isActionLoading,
        onClose: () => Navigator.of(ctx).pop(),
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

  Future<void> _printReceipt(OrderDetailModel order) async {
    if (_printBusy) return;
    setState(() => _printBusy = true);
    try {
      final controller =
          ref.read(orderDetailControllerProvider(widget.orderId).notifier);
      final ok = await controller.markReadyToPick();
      if (!mounted || !ok) return;

      try {
        await ThermalPrinterService.printOrderReceipt(order);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt printed')),
        );
      } on PrinterException catch (e) {
        if (!mounted) return;
        if (e.shouldOpenPicker) {
          await _openPrinterPicker(order);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.userMessage)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _printBusy = false);
    }
  }

  Future<void> _openPrinterPicker(OrderDetailModel order) async {
    await BluetoothPrinterSheet.show(
      context,
      onSelect: (device) => _onPrinterSelected(order, device),
    );
  }

  Future<void> _onPrinterSelected(
    OrderDetailModel order,
    BluetoothInfo device,
  ) async {
    await ThermalPrinterService.connectPrinter(
      address: device.macAdress,
      name: device.name,
    );
    await ThermalPrinterService.printOrderReceipt(
      order,
      explicitAddress: device.macAdress,
    );
    if (!mounted) return;
    await ref
        .read(orderDetailControllerProvider(widget.orderId).notifier)
        .load(refresh: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt printed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailControllerProvider(widget.orderId));
    final order = state.order;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final navTop = top + 12;

    if (state.isLoading && order == null) {
      return const Scaffold(
        backgroundColor: kDetailScreenBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: kDetailScreenBg,
        body: Column(
          children: [
            _FixedNavBar(
              topPadding: navTop,
              backgroundColor: const Color(0xFF64748B),
              code: 'Order Details',
              compactOpacity: 0,
              statusNavOpacity: 0,
              positioned: false,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: AlertBanner(message: state.error!, isError: true),
                      ),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(orderDetailControllerProvider(widget.orderId).notifier)
                          .load(),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final status = orderDetailStatus(order);
    final statusUpper = order.orderStatus.toUpperCase();
    final isPending = statusUpper == 'PENDING';
    final isManifested = statusUpper == 'MANIFESTED';
    final showPrintReceipt = !order.isCounterSale && (isPending || isManifested);
    final showCancel = order.isCounterSale && statusUpper == 'DELIVERED';
    final showBottom = showPrintReceipt || showCancel || !isPending;
    final topPickupOtps = collectTopPickupOtps(order);
    final otpList = collectOrderOtps(order);
    final paid = isPaidStatus(order.paymentStatus);
    final payLabel = paymentLabel(order.paymentType);
    final code = order.code.isNotEmpty ? order.code : '#${order.id}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: status.color),
      child: Scaffold(
        backgroundColor: kDetailScreenBg,
        body: Stack(
          children: [
            RefreshIndicator(
              color: status.color,
              onRefresh: () => ref
                  .read(orderDetailControllerProvider(widget.orderId).notifier)
                  .load(refresh: true),
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.only(
                  top: navTop + 44,
                  bottom: showBottom ? 58 + bottom : 16 + bottom,
                ),
                children: [
                  _HeroExpand(
                    backgroundColor: status.color,
                    opacity: _heroFadeOpacity,
                    date: formatOrderDate(order.createdAt),
                    amount: formatMoney(order.grandTotal),
                    paid: paid,
                    payLabel: payLabel,
                    items: order.sumQuantity,
                    paymentStatus: order.paymentStatus,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Column(
                      children: [
                        if (state.error != null) ...[
                          AlertBanner(message: state.error!, isError: true),
                          const SizedBox(height: 8),
                        ],
                        if (state.successMessage != null) ...[
                          AlertBanner(message: state.successMessage!, isError: false),
                          const SizedBox(height: 8),
                        ],
                        if (_hasOrderMeta(order))
                          _OrderMetaCard(order: order),
                        if (topPickupOtps.isNotEmpty)
                          _DetailSectionCard(
                            statusColor: status.color,
                            icon: Icons.key_outlined,
                            title: 'Pickup OTP',
                            compact: true,
                            child: Column(
                              children: [
                                for (var i = 0; i < topPickupOtps.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 4),
                                  _OtpRow(entry: topPickupOtps[i], compact: true),
                                ],
                              ],
                            ),
                          ),
                        _DetailSectionCard(
                          statusColor: status.color,
                          icon: Icons.account_tree_outlined,
                          title: 'Order Progress',
                          child: _TimelineBlock(order: order, statusColor: status.color),
                        ),
                        _DetailSectionCard(
                          statusColor: status.color,
                          icon: Icons.person_outline,
                          title: 'Customer',
                          child: _CustomerBlock(
                            order: order,
                            onCall: () => _callPhone(order.shippingAddress.phone),
                            onWhatsApp: () => _openWhatsApp(order.shippingAddress.phone),
                          ),
                        ),
                        _DetailSectionCard(
                          statusColor: status.color,
                          icon: Icons.shopping_bag_outlined,
                          title: 'Items',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusTint(kItemsAccent, 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${order.products.length}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: statusLight(kItemsAccent),
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              for (final product in order.products)
                                _ProductItem(product: product),
                            ],
                          ),
                        ),
                        if ((order.deliveryPartner.name ?? '').isNotEmpty &&
                            !order.isCounterSale)
                          _DetailSectionCard(
                            statusColor: status.color,
                            icon: Icons.pedal_bike_outlined,
                            title: 'Delivery Partner',
                            child: _DeliveryPartnerBlock(
                              partner: order.deliveryPartner,
                              statusColor: status.color,
                              onCall: () => _callPhone(order.deliveryPartner.phone),
                              onWhatsApp: () => _openWhatsApp(order.deliveryPartner.phone),
                            ),
                          ),
                        if (otpList.isNotEmpty)
                          _DetailSectionCard(
                            statusColor: status.color,
                            icon: Icons.key_outlined,
                            title: otpList.length == 1 ? otpList.first.label : 'OTP',
                            child: Column(
                              children: [
                                for (var i = 0; i < otpList.length; i++) ...[
                                  if (i > 0)
                                    const Divider(height: 16, color: Color(0xFFF1F5F9)),
                                  _OtpRow(entry: otpList[i]),
                                ],
                              ],
                            ),
                          ),
                        _DetailSectionCard(
                          statusColor: status.color,
                          icon: Icons.receipt_long_outlined,
                          title: 'Payment Summary',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusTint(status.color, 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  paid ? Icons.check_circle : Icons.error_outline,
                                  size: 10,
                                  color: paid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  payLabel,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: statusLight(status.color),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: _PaymentSummaryBlock(order: order, statusColor: status.color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _FixedNavBar(
              topPadding: navTop,
              backgroundColor: status.color,
              code: code,
              showCopyIcon: true,
              statusLabel: status.label,
              statusIcon: statusIcon(order.orderStatus),
              amount: formatMoney(order.grandTotal),
              compactOpacity: _compactOpacity,
              statusNavOpacity: _statusNavOpacity,
              onBack: () => context.pop(),
            ),
            if (showBottom)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomActionBar(
                  bottomInset: bottom,
                  showPrintReceipt: showPrintReceipt,
                  showCancel: showCancel,
                  statusColor: status.color,
                  loading: state.isActionLoading || _printBusy,
                  onPrintReceipt: () => _printReceipt(order),
                  onCancel: () => _openCancelOverlay(order),
                  onBack: () => context.pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasOrderMeta(OrderDetailModel order) {
    return (order.markStatus ?? '').trim().isNotEmpty ||
        (order.scheduleDate ?? '').trim().isNotEmpty ||
        (order.selectedDeliveryDate ?? '').trim().isNotEmpty;
  }
}

class _FixedNavBar extends StatelessWidget {
  const _FixedNavBar({
    required this.topPadding,
    required this.backgroundColor,
    required this.code,
    required this.compactOpacity,
    required this.statusNavOpacity,
    required this.onBack,
    this.statusLabel,
    this.statusIcon,
    this.amount,
    this.showCopyIcon = false,
    this.positioned = true,
  });

  final double topPadding;
  final Color backgroundColor;
  final String code;
  final String? statusLabel;
  final IconData? statusIcon;
  final String? amount;
  final bool showCopyIcon;
  final double compactOpacity;
  final double statusNavOpacity;
  final VoidCallback onBack;
  final bool positioned;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(14, topPadding, 14, 8),
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                _HeroBackButton(onTap: onBack),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                      if (showCopyIcon) ...[
                        const SizedBox(width: 4),
                        _CopyCodeButton(text: code),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ModuleHeaderAction(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Notifications',
                  onTap: () {},
                ),
                if (statusLabel != null && statusIcon != null) ...[
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: statusNavOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 10, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            statusLabel!,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (amount != null)
              Positioned(
                right: 0,
                child: Opacity(
                  opacity: compactOpacity,
                  child: Text(
                    amount!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!positioned) return bar;
    return Positioned(top: 0, left: 0, right: 0, child: bar);
  }
}

class _CopyCodeButton extends StatelessWidget {
  const _CopyCodeButton({required this.text});

  final String text;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order code copied'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _copy(context),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.content_copy_rounded, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

class _HeroBackButton extends StatelessWidget {
  const _HeroBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _HeroExpand extends StatelessWidget {
  const _HeroExpand({
    required this.backgroundColor,
    required this.opacity,
    required this.date,
    required this.amount,
    required this.paid,
    required this.payLabel,
    required this.items,
    required this.paymentStatus,
  });

  final Color backgroundColor;
  final double opacity;
  final String date;
  final String amount;
  final bool paid;
  final String payLabel;
  final int items;
  final String? paymentStatus;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 4),
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 10, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    date.isEmpty ? '--' : date,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDER TOTAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          amount,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    children: [
                      _MetaPill(
                        icon: paid ? Icons.check_circle_outline : Icons.error_outline,
                        label: paid ? 'Paid' : paymentStatusPill(paymentStatus),
                        bg: paid
                            ? Colors.white.withValues(alpha: 0.18)
                            : const Color(0x73DC2626),
                      ),
                      _MetaPill(
                        icon: Icons.payments_outlined,
                        label: payLabel,
                        bg: Colors.white.withValues(alpha: 0.14),
                      ),
                      _MetaPill(
                        icon: Icons.inventory_2_outlined,
                        label: '$items item${items == 1 ? '' : 's'}',
                        bg: Colors.white.withValues(alpha: 0.14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, required this.bg});

  final IconData icon;
  final String label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white.withValues(alpha: 0.95)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.statusColor,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.compact = false,
  });

  final Color statusColor;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusTint(statusColor, 0.18)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
              decoration: BoxDecoration(
                color: statusTint(statusColor, 0.12),
                border: Border(
                  bottom: BorderSide(color: statusTint(statusColor, 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: statusTint(statusColor, 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 12, color: statusColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: statusLight(statusColor),
                    ),
                  ),
                  if (trailing != null) ...[
                    const Spacer(),
                    trailing!,
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 12,
                compact ? 6 : 10,
                compact ? 10 : 12,
                compact ? 6 : 10,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderMetaCard extends StatelessWidget {
  const _OrderMetaCard({required this.order});

  final OrderDetailModel order;

  @override
  Widget build(BuildContext context) {
    final mark = (order.markStatus ?? '').trim();
    final schedule = formatOrderDay(order.scheduleDate);
    final delivery = formatOrderDay(order.selectedDeliveryDate);
    final style = markStatusStyle(mark);
    final hasDates = schedule.isNotEmpty || delivery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EEF4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (mark.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: style.bg,
                  border: hasDates
                      ? Border(bottom: BorderSide(color: style.border))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: mark.toLowerCase() == 'disputed'
                            ? const Color(0x38F87171)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        mark.toLowerCase() == 'disputed'
                            ? Icons.error_outline
                            : Icons.flag_outlined,
                        size: 16,
                        color: style.text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MARK STATUS',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.35,
                            ),
                          ),
                          Text(
                            capitalizeWords(mark),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: style.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (hasDates)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  children: [
                    if (schedule.isNotEmpty)
                      _MetaDateLine(
                        icon: Icons.calendar_today_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        text: 'Order scheduled for ',
                        strong: schedule,
                      ),
                    if (schedule.isNotEmpty && delivery.isNotEmpty)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 38, top: 8, bottom: 8),
                        color: const Color(0xFFEEF2F7),
                      ),
                    if (delivery.isNotEmpty)
                      _MetaDateLine(
                        icon: Icons.local_shipping_outlined,
                        iconBg: const Color(0xFFF0FDFA),
                        iconColor: const Color(0xFF0D9488),
                        text: 'Order to be delivered on ',
                        strong: delivery,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaDateLine extends StatelessWidget {
  const _MetaDateLine({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.text,
    required this.strong,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String text;
  final String strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
              children: [
                TextSpan(text: text),
                TextSpan(
                  text: strong,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineBlock extends StatelessWidget {
  const _TimelineBlock({required this.order, required this.statusColor});

  final OrderDetailModel order;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final steps = timelineSteps(order);
    final cur = timelineStepIndex(order);
    final failedAt = timelineFailedAt(order);
    final cancelled = isCancelledStatus(order.orderStatus);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F7)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(top: 13),
                      decoration: BoxDecoration(
                        color: (i <= cur || failedAt >= i)
                            ? (failedAt == i ? const Color(0xFFEF4444) : statusColor)
                            : const Color(0xFFE8EDF2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                _StepNode(
                  step: steps[i],
                  index: i,
                  lastIndex: steps.length - 1,
                  current: cur,
                  failedAt: failedAt,
                  statusColor: statusColor,
                  orderStatus: order.orderStatus,
                ),
              ],
            ],
          ),
          if (cancelled)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel_outlined, size: 11, color: Color(0xFFB91C1C)),
                  const SizedBox(width: 5),
                  Text(
                    'Order ${orderDetailStatus(order).label.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w500,
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

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.step,
    required this.index,
    required this.lastIndex,
    required this.current,
    required this.failedAt,
    required this.statusColor,
    required this.orderStatus,
  });

  final String step;
  final int index;
  final int lastIndex;
  final int current;
  final int failedAt;
  final Color statusColor;
  final String orderStatus;

  @override
  Widget build(BuildContext context) {
    final isFailed = failedAt == index;
    final done = index <= current;
    final isLastSuccess = index == lastIndex && current == lastIndex && !isFailed;
    final showCheck = isLastSuccess || (step == 'Delivered' && done && !isFailed);
    final dotColor = isFailed
        ? const Color(0xFFEF4444)
        : showCheck || done
            ? statusColor
            : const Color(0xFFE2E8F0);

    var label = step;
    if (isFailed && orderStatus.toUpperCase() == 'RTO') label = 'Returned';

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: done || isFailed ? dotColor : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              isFailed
                  ? Icons.close
                  : showCheck
                      ? Icons.check
                      : stepIcon(step),
              size: 11,
              color: done || isFailed ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: done || isFailed ? FontWeight.w600 : FontWeight.w500,
              color: isFailed
                  ? const Color(0xFFDC2626)
                  : done
                      ? statusColor
                      : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerBlock extends StatelessWidget {
  const _CustomerBlock({
    required this.order,
    required this.onCall,
    required this.onWhatsApp,
  });

  final OrderDetailModel order;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final ship = order.shippingAddress;
    final name = ship.displayName;
    final phone = ship.phone ?? '';
    final addr = [ship.address, ship.block, ship.city, ship.state]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .join(', ');

    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: statusTint(kCustomerAccent, 0.1),
              child: Text(
                (name.isEmpty ? '?' : name[0]).toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kCustomerAccent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '--' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.call_outlined, size: 10, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Text(
                        maskPhone(phone),
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (phone.isNotEmpty) ...[
              _ContactButton(color: AppColors.primary, icon: Icons.call, onTap: onCall),
              const SizedBox(width: 6),
              _ContactButton(
                color: const Color(0xFF25D366),
                icon: Icons.chat,
                onTap: onWhatsApp,
              ),
            ],
          ],
        ),
        if (addr.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EEF4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: statusTint(kCustomerAccent, 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.navigation_outlined, size: 12, color: kCustomerAccent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    addr,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _DeliveryPartnerBlock extends StatelessWidget {
  const _DeliveryPartnerBlock({
    required this.partner,
    required this.statusColor,
    required this.onCall,
    required this.onWhatsApp,
  });

  final OrderDeliveryPartnerModel partner;
  final Color statusColor;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final phone = partner.phone ?? '';
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: statusTint(statusColor, 0.1),
          child: Icon(Icons.pedal_bike_outlined, size: 15, color: statusColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner.name ?? 'Delivery partner',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.call_outlined, size: 10, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 3),
                  Text(
                    maskPhone(phone),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (phone.isNotEmpty) ...[
          _ContactButton(color: AppColors.primary, icon: Icons.call, onTap: onCall),
          const SizedBox(width: 6),
          _ContactButton(
            color: const Color(0xFF25D366),
            icon: Icons.chat,
            onTap: onWhatsApp,
          ),
        ],
      ],
    );
  }
}

class _OtpRow extends StatelessWidget {
  const _OtpRow({required this.entry, this.compact = false});

  final OrderOtpEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(compact ? 9 : 11),
        border: Border.all(color: const Color(0xFFEEF2F7)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 18 : 22,
            height: compact ? 18 : 22,
            decoration: BoxDecoration(
              color: statusTint(entry.color, 0.14),
              borderRadius: BorderRadius.circular(compact ? 5 : 7),
            ),
            child: Icon(entry.icon, size: compact ? 10 : 11, color: entry.color),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              entry.label,
              style: TextStyle(
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
                color: statusDark(entry.color),
              ),
            ),
          ),
          Row(
            children: entry.value.split('').map((ch) {
              return Container(
                width: compact ? 22 : 28,
                height: compact ? 24 : 32,
                margin: const EdgeInsets.only(left: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusTint(entry.color, 0.08),
                  borderRadius: BorderRadius.circular(compact ? 6 : 8),
                  border: Border.all(color: statusTint(entry.color, 0.35)),
                ),
                child: Text(
                  ch,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: entry.color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  const _ProductItem({required this.product});

  final OrderProductLineModel product;

  @override
  Widget build(BuildContext context) {
    final sku = (product.variantName ?? product.variantSku ?? '').trim();
    final lineTotal = product.price == null ? null : product.price! * product.quantity;
    final comboList = product.comboProducts;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: product.isCombo ? const Color(0xFFFFFCF7) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: product.isCombo
              ? const Color(0x47F59E0B)
              : const Color(0xFFEEF2F7),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0xFFE8EEF4)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.thumbnailImg != null && product.thumbnailImg!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.thumbnailImg!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.inventory_2_outlined, size: 17, color: Color(0xFFCBD5E1)),
                  ),
                  if (product.quantity > 1)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: kItemsAccent,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '×${product.quantity}',
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
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
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (product.isCombo)
                          _SkuChip(label: 'Combo', color: kItemsAccent),
                        if (sku.isNotEmpty) _SkuChip(label: sku, color: kItemsAccent),
                        if (product.price != null)
                          Text(
                            '${formatMoney(product.price!)} each',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lineTotal == null ? '--' : formatMoney(lineTotal),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (product.quantity > 1)
                    Text(
                      '${product.quantity} pcs',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ],
          ),
          if (comboList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusTint(kItemsAccent, 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusTint(kItemsAccent, 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.layers_outlined, size: 12, color: Color(0xFFB45309)),
                      const SizedBox(width: 5),
                      Text(
                        'Includes ${comboList.length} product${comboList.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < comboList.length; i++)
                    _ComboLine(combo: comboList[i], parentQty: product.quantity),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkuChip extends StatelessWidget {
  const _SkuChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusTint(color, 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _ComboLine extends StatelessWidget {
  const _ComboLine({required this.combo, required this.parentQty});

  final OrderComboProductModel combo;
  final int parentQty;

  @override
  Widget build(BuildContext context) {
    final qty = combo.quantity * parentQty;
    final line = combo.price == null ? null : combo.price! * combo.quantity * parentQty;
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: statusTint(kItemsAccent, 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEF2F7)),
            ),
            clipBehavior: Clip.antiAlias,
            child: combo.image != null && combo.image!.isNotEmpty
                ? CachedNetworkImage(imageUrl: combo.image!, fit: BoxFit.cover)
                : const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  combo.displayName.isEmpty ? '--' : combo.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Wrap(
                  spacing: 5,
                  children: [
                    if (combo.displayVariant.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          combo.displayVariant,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                      ),
                    if (qty > 0)
                      Text('×$qty', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          if (line != null)
            Text(
              formatMoney(line),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentSummaryBlock extends StatelessWidget {
  const _PaymentSummaryBlock({required this.order, required this.statusColor});

  final OrderDetailModel order;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BillLine(label: 'Subtotal', value: formatMoney(order.subtotal)),
        if (order.discount > 0)
          _BillLine(
            label: 'Discount',
            value: '−${formatMoney(order.discount)}',
            accent: const Color(0xFF16A34A),
          ),
        if (order.shippingCost > 0)
          _BillLine(label: 'Shipping', value: formatMoney(order.shippingCost)),
        const Divider(height: 12, color: Color(0xFFE2E8F0)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: statusTint(statusColor, 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, size: 11, color: Colors.white),
              ),
              const SizedBox(width: 7),
              Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusLight(statusColor),
                ),
              ),
              const Spacer(),
              Text(
                formatMoney(order.grandTotal),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: statusDark(statusColor),
                ),
              ),
            ],
          ),
        ),
        if ((order.transactionId ?? '').isNotEmpty)
          _RefRow(label: 'Transaction', value: order.transactionId!),
        if ((order.utr ?? '').isNotEmpty) _RefRow(label: 'UTR', value: order.utr!),
      ],
    );
  }
}

class _BillLine extends StatelessWidget {
  const _BillLine({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: accent ?? const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefRow extends StatelessWidget {
  const _RefRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF475569),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.bottomInset,
    required this.showPrintReceipt,
    required this.showCancel,
    required this.statusColor,
    required this.loading,
    required this.onPrintReceipt,
    required this.onCancel,
    required this.onBack,
  });

  final double bottomInset;
  final bool showPrintReceipt;
  final bool showCancel;
  final Color statusColor;
  final bool loading;
  final VoidCallback onPrintReceipt;
  final VoidCallback onCancel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        bottomInset > 0 ? bottomInset : 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF5FFFFFF),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: showPrintReceipt
          ? _BottomButton(
              label: 'Print Receipt',
              icon: Icons.print_outlined,
              color: statusColor,
              loading: loading,
              onTap: onPrintReceipt,
            )
          : showCancel
              ? _BottomButton(
                  label: 'Cancel Order',
                  icon: Icons.cancel_outlined,
                  color: const Color(0xFFF25146),
                  loading: loading,
                  onTap: onCancel,
                )
              : _BottomButton(
                  label: 'Go Back',
                  icon: Icons.arrow_back_rounded,
                  color: statusColor,
                  onTap: onBack,
                ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
