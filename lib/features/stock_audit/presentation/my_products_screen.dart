import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/scroll_pagination_footer.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/product_mismatch_model.dart';
import 'providers/my_products_provider.dart';

class MyProductsScreen extends ConsumerStatefulWidget {
  const MyProductsScreen({super.key});

  @override
  ConsumerState<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends ConsumerState<MyProductsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 220) {
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
    if (_initialized) return;
    _initialized = true;
    ref.read(authControllerProvider.notifier).touchActivity();
    final storage = ref.read(sessionStorageProvider);
    final preferredStoreId = await storage.getSelectedStoreId();
    await ref
        .read(myProductsControllerProvider.notifier)
        .initialize(preferredStoreId: preferredStoreId);
    final selectedId = ref.read(myProductsControllerProvider).selectedStoreId;
    if (selectedId != null) {
      await storage.saveSelectedStoreId(selectedId);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(myProductsControllerProvider);
    final userName = auth.user?.displayName ?? 'User';
    final rows = state.visibleRows;
    final formatter = NumberFormat.decimalPattern('en_IN');

    if (_searchController.text != state.searchQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    final notifier = ref.read(myProductsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'Stock',
            subtitle: 'Namaste, $userName',
            onLogout: _logout,
            searchController: _searchController,
            searchHint: 'Product ya SKU search karo...',
            searchValue: state.searchQuery,
            onSearchChanged: notifier.setSearch,
            onClearSearch: () => notifier.setSearch(''),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => notifier.loadReport(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _statsRow(state, formatter, notifier),
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
                            ? 'Koi matching SKU nahi mila'
                            : _emptyTitle(state.statusFilter),
                        message: state.searchQuery.isNotEmpty
                            ? '"${state.searchQuery}" se koi product match nahi hua.'
                            : _emptyMessage(state.statusFilter),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ProductCard(
                          key: ValueKey('${rows[index].sku}-$index'),
                          row: rows[index],
                          formatter: formatter,
                        ),
                        childCount: rows.length,
                      ),
                    ),
                  if (rows.isNotEmpty && state.total > 0)
                    SliverToBoxAdapter(
                      child: ScrollPaginationFooter(
                        isLoadingMore: false,
                        hasNextPage: state.hasNextPage,
                        from: state.visibleFrom,
                        to: state.visibleTo,
                        total: state.total,
                        page: state.page,
                        totalPages: state.totalPages,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.stock,
        onDashboardTap: () => context.go('/dashboard'),
        onHomeTap: () => context.go('/audit'),
        onOrdersTap: () => context.go('/orders'),
        onStockTap: () {},
      ),
    );
  }

  Widget _statsRow(
    MyProductsState state,
    NumberFormat formatter,
    MyProductsController notifier,
  ) {
    final filter = state.statusFilter;
    return ModuleStatsRow(
      stats: [
        ModuleStat(
          icon: Icons.inventory_2_rounded,
          label: 'Total SKU',
          value: formatter.format(state.totalSkuCount),
          background: AppColors.primary,
          labelColor: const Color(0xFFFFE4D2),
          isActive: filter == StockStatusFilter.all,
          onTap: () => notifier.setStatusFilter(StockStatusFilter.all),
        ),
        ModuleStat(
          icon: Icons.check_circle_outline_rounded,
          label: 'Matched',
          value: formatter.format(state.matchedCount),
          background: const Color(0xFF15803D),
          labelColor: const Color(0xFFBBF7D0),
          isActive: filter == StockStatusFilter.matched,
          onTap: () => notifier.setStatusFilter(StockStatusFilter.matched),
        ),
        ModuleStat(
          icon: Icons.trending_down_rounded,
          label: 'Short',
          value: formatter.format(state.shortCount),
          background: const Color(0xFFB91C1C),
          labelColor: const Color(0xFFFECACA),
          isActive: filter == StockStatusFilter.short,
          onTap: () => notifier.setStatusFilter(StockStatusFilter.short),
        ),
        ModuleStat(
          icon: Icons.trending_up_rounded,
          label: 'Excess',
          value: formatter.format(state.excessCount),
          background: const Color(0xFFB45309),
          labelColor: const Color(0xFFFED7AA),
          isActive: filter == StockStatusFilter.excess,
          onTap: () => notifier.setStatusFilter(StockStatusFilter.excess),
        ),
      ],
    );
  }

  String _emptyTitle(StockStatusFilter filter) {
    switch (filter) {
      case StockStatusFilter.matched:
        return 'Koi matched SKU nahi mila';
      case StockStatusFilter.short:
        return 'Koi short SKU nahi mila';
      case StockStatusFilter.excess:
        return 'Koi excess SKU nahi mila';
      case StockStatusFilter.all:
        return 'Koi audited SKU nahi mila';
    }
  }

  String _emptyMessage(StockStatusFilter filter) {
    switch (filter) {
      case StockStatusFilter.matched:
        return 'Is filter par koi matched stock audit nahi hai.';
      case StockStatusFilter.short:
        return 'Is filter par koi short stock audit nahi hai.';
      case StockStatusFilter.excess:
        return 'Is filter par koi excess stock audit nahi hai.';
      case StockStatusFilter.all:
        return 'Is location par abhi tak koi stock audit nahi hua hai.';
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({super.key, required this.row, required this.formatter});

  final ProductMismatchRow row;
  final NumberFormat formatter;

  Color get _statusColor {
    switch (row.status) {
      case ReconStatus.matched:
        return const Color(0xFF15803D);
      case ReconStatus.excess:
        return const Color(0xFFB45309);
      case ReconStatus.short:
        return const Color(0xFFB91C1C);
    }
  }

  String get _statusLabel {
    switch (row.status) {
      case ReconStatus.matched:
        return 'Matched';
      case ReconStatus.excess:
        return 'Excess';
      case ReconStatus.short:
        return 'Short';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    final comment = (row.comment ?? '').trim();
    final hasDamage = row.damageStock > 0;

    return ModuleCard(
      statusColor: statusColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.productName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: ModuleTokens.strongText,
                        ),
                      ),
                      if ((row.variantLabel ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          row.variantLabel!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: ModuleTokens.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ModuleStatusPill(label: _statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            _MetricStrip(
              cells: [
                _MetricCell(
                  label: 'System',
                  value: formatter.format(row.systemStock),
                ),
                _MetricCell(
                  label: 'Total Physical',
                  value: formatter.format(row.totalPhysicalStock),
                ),
                _MetricCell(
                  label: 'Physical',
                  value: formatter.format(row.physicalStock),
                ),
                _MetricCell(
                  label: 'Damage',
                  value: formatter.format(row.damageStock),
                  valueColor: hasDamage ? const Color(0xFFB91C1C) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DIFFERENCE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: statusColor.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatter.format(row.difference),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 12,
                    color: ModuleTokens.faintText,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      comment,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: ModuleTokens.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if ((row.storeName ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 12,
                    color: ModuleTokens.faintText,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      row.storeName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: ModuleTokens.faintText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
                    cells[i].label.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
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
                      fontSize: 12.5,
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
