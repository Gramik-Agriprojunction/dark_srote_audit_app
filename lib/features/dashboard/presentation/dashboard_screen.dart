import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/l10n/app_strings.dart';
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
      if (!mounted) return;
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
    final s = ref.watch(appStringsProvider);
    final state = ref.watch(dashboardControllerProvider);
    final data = state.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: s.navHome,
            subtitle: () {
              final store = ref.watch(headerGreetingProvider);
              if (store.isNotEmpty) return store;
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
            searchHint: s.searchProductSku,
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
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
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
                                  child: Text(
                                    s.retry,
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
                              strings: s,
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
                            const SizedBox(height: 12),
                          ],
                          _AuditProgressCard(
                            strings: s,
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
                          const SizedBox(height: 12),
                          _SummaryGrid(
                            strings: s,
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
                          const SizedBox(height: 18),
                          Text(
                            s.quickActions,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _QuickActionsRow(strings: s),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.recentOrders,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: AppColors.textPrimary,
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
                                child: Text(
                                  s.viewAll,
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
                            ModuleEmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: s.noRecentOrders,
                              message: s.ordersWillAppearHere,
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
  const _MismatchCard({
    required this.strings,
    required this.alert,
    required this.onTap,
  });

  final AppStrings strings;
  final DashboardMismatchAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final first = alert.items.isNotEmpty ? alert.items.first : null;
    final danger = const Color(0xFFDC2626);
    final dangerDeep = const Color(0xFF9F1239);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.isDark
                  ? const [Color(0xFF3B1418), Color(0xFF1C0F14)]
                  : const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
            ),
            border: Border.all(
              color: AppColors.isDark
                  ? const Color(0xFF7F1D1D)
                  : const Color(0xFFFECACA),
            ),
            boxShadow: [
              BoxShadow(
                color: danger.withValues(alpha: AppColors.isDark ? 0.28 : 0.14),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              ...AppColors.cardShadow,
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                top: -22,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: danger.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [danger, dangerDeep],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: danger.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            strings.productMismatchFound(alert.count),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppColors.errorText,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: danger.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            '${alert.count}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.errorText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (first != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        strings.mismatchDetailMessage(
                          first.displayName,
                          first.difference,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg.withValues(
                            alpha: AppColors.isDark ? 0.72 : 0.92,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.errorBorder.withValues(alpha: 0.7),
                          ),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ProductImageThumb(
                                  imageUrl: first.image,
                                  width: 52,
                                  height: 52,
                                  borderRadius: 14,
                                  iconSize: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        first.productName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if ((first.variantLabel ?? '')
                                          .trim()
                                          .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            first.variantLabel!.trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFCE7F3),
                                        Color(0xFFFBCFE8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    first.status,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFBE185D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _metricChip(
                                  strings.system,
                                  _fmt(first.systemStock),
                                ),
                                const SizedBox(width: 8),
                                _metricChip(
                                  strings.physical,
                                  _fmt(first.physicalStock),
                                ),
                                const SizedBox(width: 8),
                                _metricChip(
                                  strings.diff,
                                  '${first.difference}',
                                  valueColor: danger,
                                  emphasize: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricChip(
    String label,
    String value, {
    Color? valueColor,
    bool emphasize = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: emphasize
              ? const Color(0xFFDC2626).withValues(alpha: 0.08)
              : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: emphasize
                ? const Color(0xFFDC2626).withValues(alpha: 0.18)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
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
    required this.strings,
    required this.progress,
    required this.onTap,
  });

  final AppStrings strings;
  final DashboardAuditProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.percent.clamp(0, 100)) / 100.0;
    const green = Color(0xFF16A34A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.isDark
                  ? [AppColors.cardBg, const Color(0xFF12261A)]
                  : [Colors.white, const Color(0xFFF0FDF4)],
            ),
            border: Border.all(
              color: AppColors.isDark
                  ? AppColors.successBorder
                  : const Color(0xFFBBF7D0),
            ),
            boxShadow: [
              BoxShadow(
                color: green.withValues(alpha: AppColors.isDark ? 0.18 : 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              ...AppColors.cardShadow,
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF4ADE80), green],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ADE80), green],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: green.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.task_alt_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.todaysAudit,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.skuAuditedProgress(
                                    progress.auditedToday,
                                    progress.totalSkus,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${progress.percent}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: -0.3,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Stack(
                          children: [
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.isDark
                                    ? const Color(0xFF1F4D32)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4ADE80), green],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: green.withValues(alpha: 0.45),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.strings,
    required this.summary,
    required this.onStockTap,
  });

  final AppStrings strings;
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
            title: strings.orders,
            lines: [
              _SummaryLine(strings.statTotal(summary.ordersTotal)),
              _SummaryLine(
                strings.statPending(summary.ordersPending),
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
            title: strings.stock,
            lines: [
              _SummaryLine(strings.statTotalSku(summary.stockTotalSkus)),
              _SummaryLine(
                strings.statMismatch(summary.stockMismatch),
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
            title: strings.dc,
            lines: [
              _SummaryLine(
                strings.statIncoming(summary.dcIncoming),
                color: const Color(0xFF059669),
              ),
              _SummaryLine(
                strings.statReceived(summary.dcReceived),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cardBg,
                Color.lerp(AppColors.cardBg, iconBg, 0.55) ?? AppColors.cardBg,
              ],
            ),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(
                  alpha: AppColors.isDark ? 0.18 : 0.10,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              ...AppColors.cardShadow,
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor,
                        iconColor.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 18, color: iconColor),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < lines.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == lines.length - 1 ? 0 : 4,
                          ),
                          child: Text(
                            lines[i].text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: i == 0 ? 12.5 : 11.5,
                              fontWeight:
                                  i == 0 ? FontWeight.w700 : FontWeight.w600,
                              color: lines[i].color ?? AppColors.textSecondary,
                            ),
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
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, String route, Color bg, Color fg})>[
      (
        icon: Icons.add_box_rounded,
        label: strings.stocks,
        route: '/my-products',
        bg: AppColors.softOrange,
        fg: AppColors.primary,
      ),
      (
        icon: Icons.receipt_long_rounded,
        label: strings.viewOrders,
        route: '/orders',
        bg: AppColors.softPurple,
        fg: const Color(0xFF7C3AED),
      ),
      (
        icon: Icons.fact_check_rounded,
        label: strings.startAudit,
        route: '/audit',
        bg: AppColors.softGreen,
        fg: const Color(0xFF16A34A),
      ),
      (
        icon: Icons.local_shipping_rounded,
        label: strings.dcTransfers,
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
              color: Colors.transparent,
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
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.cardBg,
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: actions[i].fg.withValues(
                          alpha: AppColors.isDark ? 0.16 : 0.08,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                      ...AppColors.cardShadow,
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              actions[i].bg,
                              Color.lerp(
                                    actions[i].bg,
                                    actions[i].fg,
                                    0.18,
                                  ) ??
                                  actions[i].bg,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: actions[i].fg.withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          actions[i].icon,
                          color: actions[i].fg,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actions[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
    final accent = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/orders/${order.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cardBg,
                  Color.lerp(AppColors.cardBg, AppColors.softOrange, 0.35) ??
                      AppColors.cardBg,
                ],
              ),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(
                    alpha: AppColors.isDark ? 0.14 : 0.08,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                ...AppColors.cardShadow,
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent,
                            accent.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ProductImageThumb(
                                imageUrl: order.firstProductImage,
                                width: 52,
                                height: 52,
                                borderRadius: 14,
                                iconSize: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.code.isEmpty
                                        ? '#${order.id}'
                                        : order.code,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if ((order.createdAt ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Text(
                                        formatOrderDate(order.createdAt!),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 7),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 5,
                                    children: [
                                      if (order.hasDemandId)
                                        _pill(
                                          kDemandOrderBadgeLabel,
                                          kDemandOrderBadgeFg,
                                          kDemandOrderBadgeBg,
                                        ),
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softOrange,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Text(
                                formatMoney(order.grandTotal),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.14)),
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
