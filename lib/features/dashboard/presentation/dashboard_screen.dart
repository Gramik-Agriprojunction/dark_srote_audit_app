import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/product_image_thumb.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../orders/presentation/utils/order_status_helper.dart';
import '../../stock_audit/presentation/providers/my_products_provider.dart';
import '../../stock_audit/presentation/providers/stock_audit_provider.dart';
import '../data/models/dashboard_model.dart';
import 'providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeModeProvider);
    final state = ref.watch(dashboardControllerProvider);
    final data = state.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: data?.header.greeting ?? 'Dashboard',
            subtitle: () {
              final storeName = (data?.header.storeName ?? '').trim();
              final storeCode = (data?.header.storeCode ?? '').trim();
              if (storeName.isNotEmpty && storeCode.isNotEmpty) {
                return '$storeName ($storeCode)';
              }
              if (storeName.isNotEmpty) return storeName;
              if (storeCode.isNotEmpty) return storeCode;
              return null;
            }(),
            onLogout: _logout,
            searchController: _searchController,
            searchHint: 'Product ya SKU search karo...',
            searchValue: _searchController.text,
            onSearchChanged: (_) => setState(() {}),
            onClearSearch: () {
              _searchController.clear();
              setState(() {});
            },
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref
                  .read(dashboardControllerProvider.notifier)
                  .load(refresh: true),
              child: state.isLoading && data == null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 140),
                        Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      children: [
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => ref
                                      .read(dashboardControllerProvider.notifier)
                                      .load(refresh: true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (data != null) ...[
                          if (data.mismatchAlert.count > 0) ...[
                            _MismatchCard(
                              alert: data.mismatchAlert,
                              onTap: () {
                                ref
                                    .read(
                                      myProductsControllerProvider.notifier,
                                    )
                                    .setStatusFilter(StockStatusFilter.short);
                                context.go('/my-products?filter=short');
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                          _AuditProgressCard(
                            progress: data.auditProgress,
                            onTap: () {
                              ref
                                  .read(stockAuditControllerProvider.notifier)
                                  .setAuditStatusFilter(
                                    AuditStatusFilter.audited,
                                  );
                              context.go('/audit');
                            },
                          ),
                          const SizedBox(height: 10),
                          _SummaryGrid(
                            summary: data.summary,
                            onStockTap: () {
                              if (data.summary.stockMismatch > 0) {
                                ref
                                    .read(
                                      myProductsControllerProvider.notifier,
                                    )
                                    .setStatusFilter(StockStatusFilter.short);
                                context.go('/my-products?filter=short');
                              } else {
                                context.go('/my-products');
                              }
                            },
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _QuickActionsRow(),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Recent Orders',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/orders'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'View All →',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (data.recentOrders.isEmpty)
                            const ModuleEmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No recent orders',
                              message: 'Orders yahan dikhenge',
                            )
                          else
                            for (final order in data.recentOrders)
                              _RecentOrderTile(order: order),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MismatchCard extends StatelessWidget {
  const _MismatchCard({required this.alert, required this.onTap});

  final DashboardMismatchAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final first = alert.items.isNotEmpty ? alert.items.first : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.errorBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.errorBorder),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${alert.count} Product Mismatch Found',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.errorText,
                  ),
                ),
              ),
            ],
          ),
          if (first != null) ...[
            const SizedBox(height: 8),
            Text(
              '${first.displayName} me ${first.difference} units ka mismatch paya gaya hai. Please verify physical count and approve.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: Row(
                children: [
                  ProductImageThumb(
                    imageUrl: first.image,
                    width: 48,
                    height: 48,
                    borderRadius: 10,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if ((first.variantLabel ?? '').trim().isNotEmpty)
                          Text(
                            first.variantLabel!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _metric('System', _fmt(first.systemStock)),
                            _metric('Physical', _fmt(first.physicalStock)),
                            _metric(
                              'Diff',
                              '${first.difference}',
                              valueColor: const Color(0xFFDC2626),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE7F3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      first.status,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBE185D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.abs().toString();
    if (s.length <= 3) return '${n < 0 ? '-' : ''}$s';
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${n < 0 ? '-' : ''}${parts.join(',')},$last3';
  }
}

class _AuditProgressCard extends StatelessWidget {
  const _AuditProgressCard({
    required this.progress,
    required this.onTap,
  });

  final DashboardAuditProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.percent.clamp(0, 100)) / 100.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 18,
                  color: AppColors.successText,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Today's Audit",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${progress.percent}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.auditedToday} of ${progress.totalSkus} SKU audited',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.summary,
    required this.onStockTap,
  });

  final DashboardSummary summary;
  final VoidCallback onStockTap;

  @override
  Widget build(BuildContext context) {
    // 3 equal cards in one row — no orphan half-width tile.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryTile(
            icon: Icons.receipt_long_rounded,
            iconBg: AppColors.softOrange,
            iconColor: AppColors.primary,
            title: 'Orders',
            lines: [
              _SummaryLine('${summary.ordersTotal} Total'),
              _SummaryLine(
                '${summary.ordersPending} Pending',
                color: AppColors.primary,
              ),
            ],
            onTap: () => context.go('/orders'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            icon: Icons.inventory_2_rounded,
            iconBg: AppColors.softBlue,
            iconColor: const Color(0xFF2563EB),
            title: 'Stock',
            lines: [
              _SummaryLine('${summary.stockTotalSkus} Total SKU'),
              _SummaryLine(
                '${summary.stockMismatch} Mismatch',
                color: summary.stockMismatch > 0
                    ? const Color(0xFFDC2626)
                    : null,
              ),
            ],
            onTap: onStockTap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            icon: Icons.local_shipping_rounded,
            iconBg: AppColors.softGreen,
            iconColor: const Color(0xFF059669),
            title: 'DC',
            lines: [
              _SummaryLine(
                '${summary.dcIncoming} Incoming',
                color: const Color(0xFF059669),
              ),
              _SummaryLine(
                '${summary.dcReceived} Received',
                color: const Color(0xFF0284C7),
              ),
            ],
            onTap: () => context.push('/dc'),
          ),
        ),
      ],
    );
  }
}

class _SummaryLine {
  const _SummaryLine(this.text, {this.color});

  final String text;
  final Color? color;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.lines,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final List<_SummaryLine> lines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    line.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: line.color ?? AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, String route, Color bg, Color fg})>[
      (
        icon: Icons.add_box_rounded,
        label: 'Stocks',
        route: '/my-products',
        bg: AppColors.softOrange,
        fg: AppColors.primary,
      ),
      (
        icon: Icons.receipt_long_rounded,
        label: 'View Orders',
        route: '/orders',
        bg: AppColors.softPurple,
        fg: const Color(0xFF7C3AED),
      ),
      (
        icon: Icons.fact_check_rounded,
        label: 'Start Audit',
        route: '/audit',
        bg: AppColors.softGreen,
        fg: const Color(0xFF16A34A),
      ),
      (
        icon: Icons.local_shipping_rounded,
        label: 'DC Transfers',
        route: '/dc',
        bg: AppColors.softBlue,
        fg: const Color(0xFF0284C7),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  final route = actions[i].route;
                  // DC is outside the tab shell — push so back returns to dashboard.
                  if (route == '/dc') {
                    context.push(route);
                  } else {
                    context.go(route);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: actions[i].bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          actions[i].icon,
                          color: actions[i].fg,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        actions[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final DashboardRecentOrder order;

  @override
  Widget build(BuildContext context) {
    final city = order.customerCity.trim();
    final subtitle = city.isEmpty
        ? order.customerName
        : '${order.customerName} · $city';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.push('/orders/${order.id}'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ProductImageThumb(
                  imageUrl: order.firstProductImage,
                  width: 48,
                  height: 48,
                  borderRadius: 10,
                  iconSize: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.code.isEmpty ? '#${order.id}' : order.code,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if ((order.createdAt ?? '').isNotEmpty)
                        Text(
                          formatOrderDate(order.createdAt!),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _pill(
                            order.paymentStatus.toUpperCase(),
                            const Color(0xFFDC2626),
                            const Color(0xFFFEE2E2),
                          ),
                          _pill(
                            order.paymentType.toUpperCase(),
                            AppColors.primary,
                            const Color(0xFFFFE4D2),
                          ),
                          _pill(
                            order.orderStatus,
                            const Color(0xFFB45309),
                            const Color(0xFFFEF3C7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  formatMoney(order.grandTotal),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
