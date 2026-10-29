import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/product_image_thumb.dart';
import '../../../core/widgets/scroll_pagination_footer.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/product_mismatch_model.dart';
import 'providers/my_products_provider.dart';

/// Design tokens matching the Live Stock mock.
class _StockUi {
  static const matched = Color(0xFF15803D);
  static const shortage = Color(0xFFDC2626);
  static const excess = Color(0xFF2563EB);
  static const live = Color(0xFF16A34A);
}

class MyProductsScreen extends ConsumerStatefulWidget {
  const MyProductsScreen({super.key, this.initialStatusFilter});

  /// Optional route query (`filter=short|excess|matched|all`).
  final String? initialStatusFilter;

  @override
  ConsumerState<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends ConsumerState<MyProductsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _initialized = false;
  DateTime? _lastRefreshedAt;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didUpdateWidget(covariant MyProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatusFilter != widget.initialStatusFilter) {
      _applyRouteStatusFilter();
    }
  }

  StockStatusFilter? _parseStatusFilter(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'short':
        return StockStatusFilter.short;
      case 'excess':
        return StockStatusFilter.excess;
      case 'matched':
        return StockStatusFilter.matched;
      case 'all':
        return StockStatusFilter.all;
      default:
        return null;
    }
  }

  void _applyRouteStatusFilter() {
    final filter = _parseStatusFilter(widget.initialStatusFilter);
    if (filter == null) return;
    ref.read(myProductsControllerProvider.notifier).setStatusFilter(filter);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.extentAfter <= 220) {
      ref.read(myProductsControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted || _initialized) return;
    _initialized = true;
    ref.read(authControllerProvider.notifier).touchActivity();
    _applyRouteStatusFilter();
    final storage = ref.read(sessionStorageProvider);
    final preferredStoreId = await storage.getSelectedStoreId();
    if (!mounted) return;
    await ref
        .read(myProductsControllerProvider.notifier)
        .initialize(preferredStoreId: preferredStoreId);
    if (!mounted) return;
    _applyRouteStatusFilter();
    setState(() => _lastRefreshedAt = DateTime.now());
    final selectedId = ref.read(myProductsControllerProvider).selectedStoreId;
    if (selectedId != null) {
      await storage.saveSelectedStoreId(selectedId);
    }
  }

  Future<void> _refresh() async {
    await ref.read(myProductsControllerProvider.notifier).loadReport();
    if (mounted) setState(() => _lastRefreshedAt = DateTime.now());
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  DateTime? _latestRowUpdate(List<ProductMismatchRow> rows) {
    DateTime? latest;
    for (final row in rows) {
      if (row.auditUpdatedAt.millisecondsSinceEpoch <= 0) continue;
      if (latest == null || row.auditUpdatedAt.isAfter(latest)) {
        latest = row.auditUpdatedAt;
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final state = ref.watch(myProductsControllerProvider);
    final rows = state.rows;
    final formatter = NumberFormat.decimalPattern('en_IN');

    if (_searchController.text != state.searchQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    final notifier = ref.read(myProductsControllerProvider.notifier);
    final lastUpdated =
        _lastRefreshedAt ?? _latestRowUpdate(rows) ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: s.stock,
            subtitle: ref.watch(headerGreetingProvider),
            onLogout: _logout,
            searchController: _searchController,
            searchHint: s.searchProductSku,
            searchValue: state.searchQuery,
            onSearchChanged: notifier.setSearch,
            onClearSearch: () => notifier.setSearch(''),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _statsRow(state, formatter, notifier, s),
                  ),
                  SliverToBoxAdapter(
                    child: _LiveStockSectionHeader(
                      strings: s,
                      lastUpdated: lastUpdated,
                      refreshing: state.isLoading && rows.isNotEmpty,
                      onRefresh: _refresh,
                    ),
                  ),
                  if (state.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                        child: AlertBanner(
                          message: state.error!,
                          isError: true,
                        ),
                      ),
                    ),
                  if (state.isLoading && rows.isEmpty)
                    const SliverToBoxAdapter(
                      child: ModuleListLoadingBody(showStats: false),
                    )
                  else if (rows.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: state.searchQuery.isNotEmpty
                            ? s.noMatchingSku
                            : _emptyTitle(state.statusFilter, s),
                        message: state.searchQuery.isNotEmpty
                            ? s.searchNoMatch(state.searchQuery)
                            : _emptyMessage(state.statusFilter, s),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ProductCard(
                          key: ValueKey('${rows[index].sku}-$index'),
                          row: rows[index],
                          formatter: formatter,
                          strings: s,
                        ),
                        childCount: rows.length,
                      ),
                    ),
                  if (rows.isNotEmpty)
                    SliverToBoxAdapter(
                      child: ScrollPaginationFooter(
                        isLoadingMore: state.isLoadingMore,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(
    MyProductsState state,
    NumberFormat formatter,
    MyProductsController notifier,
    AppStrings s,
  ) {
    final filter = state.statusFilter;
    return ModuleStatsRow(
      stats: [
        ModuleStat(
          icon: Icons.inventory_2_rounded,
          label: s.totalSku,
          value: formatter.format(state.totalSkuCount),
          background: AppColors.primary,
          labelColor: const Color(0xFFFFE4D2),
          isActive: filter == StockStatusFilter.all,
          onTap: () => notifier.setStatusFilter(StockStatusFilter.all),
        ),
        ModuleStat(
          icon: Icons.check_circle_rounded,
          label: s.matched,
          value: formatter.format(state.matchedCount),
          background: _StockUi.matched,
          labelColor: const Color(0xFFBBF7D0),
          isActive: filter == StockStatusFilter.matched,
          onTap: () => notifier.setStatusFilter(StockStatusFilter.matched),
        ),
        ModuleStat(
          icon: Icons.trending_down_rounded,
          label: s.shortage,
          value: formatter.format(state.shortCount),
          background: _StockUi.shortage,
          labelColor: const Color(0xFFFECACA),
          isActive: filter == StockStatusFilter.short,
          onTap: () => notifier.setStatusFilter(StockStatusFilter.short),
        ),
        ModuleStat(
          icon: Icons.trending_up_rounded,
          label: s.excess,
          value: formatter.format(state.excessCount),
          background: _StockUi.excess,
          labelColor: const Color(0xFFBFDBFE),
          isActive: filter == StockStatusFilter.excess,
          onTap: () => notifier.setStatusFilter(StockStatusFilter.excess),
        ),
      ],
    );
  }

  String _emptyTitle(StockStatusFilter filter, AppStrings s) {
    switch (filter) {
      case StockStatusFilter.matched:
        return s.stockEmptyMatchedTitle;
      case StockStatusFilter.short:
        return s.stockEmptyShortTitle;
      case StockStatusFilter.excess:
        return s.stockEmptyExcessTitle;
      case StockStatusFilter.all:
        return s.stockEmptyAuditedTitle;
    }
  }

  String _emptyMessage(StockStatusFilter filter, AppStrings s) {
    switch (filter) {
      case StockStatusFilter.matched:
        return s.stockEmptyMatchedMessage;
      case StockStatusFilter.short:
        return s.stockEmptyShortMessage;
      case StockStatusFilter.excess:
        return s.stockEmptyExcessMessage;
      case StockStatusFilter.all:
        return s.stockEmptyAllMessage;
    }
  }
}

class _LiveStockSectionHeader extends StatelessWidget {
  const _LiveStockSectionHeader({
    required this.strings,
    required this.lastUpdated,
    required this.onRefresh,
    this.refreshing = false,
  });

  final AppStrings strings;
  final DateTime lastUpdated;
  final VoidCallback onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final stamp = DateFormat('d MMM yyyy, hh:mm a').format(lastUpdated.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        strings.liveStockRealtime,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: ModuleTokens.strongText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _StockUi.live,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  strings.stockUpdatesAutomatically,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.25,
                    color: ModuleTokens.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${strings.lastUpdatedLabel}: $stamp',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ModuleTokens.faintText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: refreshing ? null : onRefresh,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                  boxShadow: ModuleTokens.cardShadow,
                ),
                child: refreshing
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    super.key,
    required this.row,
    required this.formatter,
    required this.strings,
  });

  final ProductMismatchRow row;
  final NumberFormat formatter;
  final AppStrings strings;

  Color get _statusColor {
    switch (row.status) {
      case ReconStatus.matched:
        return _StockUi.matched;
      case ReconStatus.excess:
        return _StockUi.excess;
      case ReconStatus.short:
        return _StockUi.shortage;
    }
  }

  String get _statusLabel {
    switch (row.status) {
      case ReconStatus.matched:
        return strings.matched;
      case ReconStatus.excess:
        return strings.excess;
      case ReconStatus.short:
        return strings.shortage;
    }
  }

  String _relativeAgo(DateTime at) {
    if (at.millisecondsSinceEpoch <= 0) return '—';
    final diff = DateTime.now().difference(at.toLocal());
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return '$m min ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1 ? '1 hr ago' : '$h hrs ago';
    }
    final d = diff.inDays;
    return d == 1 ? '1 day ago' : '$d days ago';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    final hasDamage = row.damageStock > 0;
    final skuLine = (row.sku ?? '').trim();
    final variant = (row.variantLabel ?? '').trim();
    final store = (row.storeName ?? '').trim();
    final liveQty = row.totalPhysicalStock;
    final relative = _relativeAgo(row.auditUpdatedAt);

    return ModuleCard(
      statusColor: statusColor,
      onTap: () {
        context.push(
          '/preview/stock-ledger',
          extra: {
            'productName': row.productName,
            'variantLabel': variant.isNotEmpty ? variant : '—',
            'sku': skuLine.isNotEmpty ? skuLine : '—',
            'storeName': store.isNotEmpty
                ? store
                : 'DS#31 - Unnao (Safipur) - Gramik',
            'imageUrl': row.image,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageThumb(
                  imageUrl: row.image,
                  width: 52,
                  height: 52,
                  borderRadius: 12,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: ModuleTokens.strongText,
                        ),
                      ),
                      if (variant.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          variant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ModuleTokens.mutedText,
                          ),
                        ),
                      ],
                      if (skuLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'SKU: $skuLine',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: ModuleTokens.faintText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: _StockUi.live,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          strings.liveBadge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: _StockUi.live,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ModuleStatusPill(
                      label: _statusLabel,
                      color: statusColor,
                      filled: false,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _MetricStrip(
                    cells: [
                      _MetricCell(
                        label: strings.system,
                        value: formatter.format(row.systemStock),
                      ),
                      _MetricCell(
                        label: strings.physical,
                        value: formatter.format(row.totalPhysicalStock),
                      ),
                      _MetricCell(
                        label: strings.usable,
                        value: formatter.format(row.physicalStock),
                      ),
                      _MetricCell(
                        label: strings.damage,
                        value: formatter.format(row.damageStock),
                        valueColor:
                            hasDamage ? _StockUi.shortage : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _LiveStockBadge(
                  label: strings.liveStock,
                  value: formatter.format(liveQty),
                  color: statusColor,
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: ModuleTokens.faintText,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (store.isNotEmpty) ...[
                  Icon(
                    Icons.storefront_outlined,
                    size: 12,
                    color: ModuleTokens.faintText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: ModuleTokens.faintText,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                Icon(
                  Icons.schedule_rounded,
                  size: 11,
                  color: ModuleTokens.faintText,
                ),
                const SizedBox(width: 3),
                Text(
                  strings.updatedAgo(relative),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: ModuleTokens.faintText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStockBadge extends StatelessWidget {
  const _LiveStockBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: color.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell {
  const _MetricCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.cells});

  final List<_MetricCell> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ModuleTokens.cardBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 26,
                color: ModuleTokens.cardBorder,
              ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    cells[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ModuleTokens.tileMetricLabelFontSize,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: ModuleTokens.faintText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cells[i].value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: cells[i].valueColor ?? ModuleTokens.strongText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
