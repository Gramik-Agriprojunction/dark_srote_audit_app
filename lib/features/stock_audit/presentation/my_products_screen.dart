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
import '../../static_previews/presentation/preview_theme.dart';
import '../data/models/product_mismatch_model.dart';
import 'providers/my_products_provider.dart';

/// Design tokens matching the Live Stock mock (light + dark).
class _StockUi {
  static Color get matched =>
      AppColors.isDark ? const Color(0xFF6BCF8E) : const Color(0xFF15803D);
  static Color get shortage =>
      AppColors.isDark ? const Color(0xFFE88A9A) : const Color(0xFFDC2626);
  static Color get excess =>
      AppColors.isDark ? const Color(0xFF7EB8E8) : const Color(0xFF2563EB);
  static Color get live =>
      AppColors.isDark ? const Color(0xFF6BCF8E) : const Color(0xFF16A34A);

  static Color get onHandAccent =>
      AppColors.isDark ? const Color(0xFF9BB4D4) : const Color(0xFF1E3A5F);
  static Color get onHandSoft =>
      AppColors.isDark ? const Color(0xFF2A3548) : const Color(0xFFE8EEF7);

  static Color get damageAccent =>
      AppColors.isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED);
  static Color get damageSoft =>
      AppColors.isDark ? const Color(0xFF2A1F40) : const Color(0xFFF3E8FF);
  static Color get damageMutedAccent =>
      AppColors.isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9);
  static Color get damageMutedSoft =>
      AppColors.isDark ? const Color(0xFF241B38) : const Color(0xFFF5F3FF);
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
    // Prefer latest audit timestamp from loaded rows (data), then client refresh.
    final lastUpdated =
        _latestRowUpdate(rows) ?? _lastRefreshedAt ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: s.stock,
            subtitle: () {
              final store = ref.watch(headerGreetingProvider);
              return store.isEmpty ? null : store;
            }(),
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
                          businessLocationId: state.selectedStoreId,
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
                      decoration: BoxDecoration(
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
    required this.businessLocationId,
    required this.formatter,
    required this.strings,
  });

  final ProductMismatchRow row;
  final int? businessLocationId;
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
    final skuLine = _stockDisplayPack(row.sku);
    final variant = _stockDisplayPack(row.variantLabel);
    final packLabel = variant != '—'
        ? variant
        : (skuLine != '—' ? skuLine : '');
    final store = (row.storeName ?? '').trim();
    // Same source as Lens ON HAND QTY (warehouse on-hand).
    final liveQty = row.onHandQty;
    final relative = _relativeAgo(row.auditUpdatedAt);

    return ModuleCard(
      statusColor: statusColor,
      onTap: () {
        context.push(
          '/preview/stock-ledger',
          extra: {
            'productName': row.productName,
            'variantLabel': packLabel.isNotEmpty ? packLabel : '—',
            'sku': skuLine != '—' ? skuLine : '—',
            'storeName': store.isNotEmpty ? store : 'Dark Store',
            'imageUrl': row.image,
            'variantId': row.variantId,
            'businessLocationId': businessLocationId,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: PreviewTheme.blue.withValues(alpha: 0.28),
                    ),
                  ),
                  child: ProductImageThumb(
                    imageUrl: row.image,
                    width: 54,
                    height: 54,
                    borderRadius: 12,
                    showBorder: false,
                    backgroundColor: PreviewTheme.blueSoft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.2,
                          color: ModuleTokens.strongText,
                        ),
                      ),
                      if (packLabel.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: PreviewTheme.orangeSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              packLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: PreviewTheme.orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _StockUi.live,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          strings.liveBadge,
                          style: TextStyle(
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
                      filled: true,
                    ),
                  ],
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: ModuleTokens.faintText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StockMetricTile(
                  icon: Icons.storage_rounded,
                  label: strings.system,
                  value: formatter.format(row.systemStock),
                  accent: PreviewTheme.blue,
                  soft: PreviewTheme.blueSoft,
                ),
                const SizedBox(width: 8),
                _StockMetricTile(
                  icon: Icons.back_hand_outlined,
                  label: strings.onHand,
                  value: formatter.format(row.onHandQty),
                  accent: _StockUi.onHandAccent,
                  soft: _StockUi.onHandSoft,
                ),
                const SizedBox(width: 8),
                _StockMetricTile(
                  icon: Icons.inventory_2_outlined,
                  label: strings.physical,
                  value: formatter.format(row.totalPhysicalStock),
                  accent: _StockUi.onHandAccent,
                  soft: _StockUi.onHandSoft,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StockMetricTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: strings.usable,
                  value: formatter.format(row.physicalStock),
                  accent: PreviewTheme.green,
                  soft: PreviewTheme.greenSoft,
                ),
                const SizedBox(width: 8),
                _StockMetricTile(
                  icon: Icons.warning_amber_rounded,
                  label: strings.damage,
                  value: formatter.format(row.damageStock),
                  accent: hasDamage
                      ? _StockUi.damageAccent
                      : _StockUi.damageMutedAccent,
                  soft: hasDamage
                      ? _StockUi.damageSoft
                      : _StockUi.damageMutedSoft,
                ),
                const SizedBox(width: 8),
                _StockMetricTile(
                  icon: Icons.monitor_heart_outlined,
                  label: strings.liveStock,
                  value: formatter.format(liveQty),
                  accent: statusColor,
                  soft: AppColors.isDark
                      ? statusColor.withValues(alpha: 0.18)
                      : statusColor.withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 1,
              color: PreviewTheme.border.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (store.isNotEmpty) ...[
                  Icon(
                    Icons.storefront_outlined,
                    size: 13,
                    color: ModuleTokens.faintText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ModuleTokens.faintText,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: ModuleTokens.faintText,
                ),
                const SizedBox(width: 3),
                Text(
                  strings.updatedAgo(relative),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

String _stockDisplayPack(String? raw) {
  var value = (raw ?? '').trim();
  if (value.isEmpty) return '—';
  value = value.replaceFirst(
    RegExp(r'^sku\s*[:\-]?\s*', caseSensitive: false),
    '',
  );
  return value.trim().isEmpty ? '—' : value.trim();
}

class _StockMetricTile extends StatelessWidget {
  const _StockMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.soft,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1,
                color: PreviewTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
