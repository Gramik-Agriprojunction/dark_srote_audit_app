import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/order_model.dart';
import 'providers/orders_provider.dart';
import 'utils/order_status_helper.dart';
import 'widgets/order_card.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_initialized) return;
    _initialized = true;
    ref.read(authControllerProvider.notifier).touchActivity();
    await ref.read(ordersControllerProvider.notifier).initialize();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 220) {
      ref.read(ordersControllerProvider.notifier).loadMore();
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

  Future<void> _refresh() async {
    ref.read(authControllerProvider.notifier).touchActivity();
    await ref.read(ordersControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersControllerProvider);
    final top = MediaQuery.paddingOf(context).top;

    if (_searchController.text != state.search) {
      _searchController.value = _searchController.value.copyWith(
        text: state.search,
        selection: TextSelection.collapsed(offset: state.search.length),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primary,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _OrdersHeader(
              topPadding: top,
              searchController: _searchController,
              search: state.search,
              notificationCount: state.stats.notificationCount,
              onSearchChanged: (v) =>
                  ref.read(ordersControllerProvider.notifier).setSearch(v),
              onClearSearch: () =>
                  ref.read(ordersControllerProvider.notifier).clearSearch(),
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
                    SliverToBoxAdapter(child: _StatsRow(stats: state.stats)),
                    SliverToBoxAdapter(
                      child: _FilterTabs(
                        activeTab: state.activeTab,
                        onTabSelected: (tab) => ref
                            .read(ordersControllerProvider.notifier)
                            .setTab(tab),
                      ),
                    ),
                    if (state.error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: AlertBanner(message: state.error!, isError: true),
                        ),
                      ),
                    if (state.isLoading && state.orders.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (state.orders.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyOrders(isRefreshing: state.isRefreshing),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= state.orders.length) return null;
                            final order = state.orders[index];
                            return OrderCard(
                              order: order,
                              expanded: state.expandedOrderIds.contains(order.id),
                              onToggleExpand: () => ref
                                  .read(ordersControllerProvider.notifier)
                                  .toggleExpanded(order.id),
                              onOpenDetail: () async {
                                await context.push('/orders/${order.id}');
                                if (!context.mounted) return;
                                await ref
                                    .read(ordersControllerProvider.notifier)
                                    .refresh();
                              },
                            );
                          },
                          childCount: state.orders.length,
                        ),
                      ),
                    if (state.orders.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _PaginationFooter(
                          isLoadingMore: state.isLoadingMore,
                          hasNextPage: state.pagination.hasNextPage,
                          from: state.pagination.from,
                          to: state.pagination.to,
                          total: state.pagination.total,
                          page: state.pagination.currentPage,
                          totalPages: state.pagination.totalPages,
                          onLoadMore: () => ref
                              .read(ordersControllerProvider.notifier)
                              .loadMore(),
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
          currentTab: AppTab.orders,
          onHomeTap: () => context.go('/home'),
          onOrdersTap: () {},
          onStockTap: () => context.go('/my-products'),
          onTransactionsTap: () => context.go('/transactions'),
          onVarianceTap: () => context.go('/variance'),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.topPadding,
    required this.searchController,
    required this.search,
    required this.notificationCount,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final double topPadding;
  final TextEditingController searchController;
  final String search;
  final int notificationCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _HeaderIconButton(
                icon: Icons.person_outline_rounded,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _HeaderIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          notificationCount > 99 ? '99+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Order search karo...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (search.isNotEmpty)
                  GestureDetector(
                    onTap: onClearSearch,
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

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
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final OrderListStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatCardData(
        icon: Icons.receipt_long_rounded,
        label: 'Total Orders',
        value: '${stats.totalOrders}',
        background: AppColors.primary,
        labelColor: const Color(0xFFFFE4D2),
      ),
      _StatCardData(
        icon: Icons.schedule_rounded,
        label: 'Pending',
        value: '${stats.pending}',
        background: const Color(0xFFB45309),
        labelColor: const Color(0xFFFED7AA),
      ),
      _StatCardData(
        icon: Icons.payments_outlined,
        label: 'Total Value',
        value: formatMoney(stats.totalValue),
        background: const Color(0xFF1D4ED8),
        labelColor: const Color(0xFFBFDBFE),
      ),
    ];

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _StatCard(data: items[index]),
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.background,
    required this.labelColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color background;
  final Color labelColor;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: data.labelColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.activeTab,
    required this.onTabSelected,
  });

  final OrderFilterTab activeTab;
  final ValueChanged<OrderFilterTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Row(
        children: OrderFilterTab.tabs.map((tab) {
          final active = activeTab == tab;
          final tone = tabToneBg(tab.id);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: active ? tone : Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: active ? tone : const Color(0xFFD1D9E6),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTabSelected(tab);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabIcon(tab.id),
                        size: 13,
                        color: active ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          color: active ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.isRefreshing});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    if (isRefreshing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF94A3B8)),
            SizedBox(height: 10),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try another filter or pull to refresh',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.isLoadingMore,
    required this.hasNextPage,
    required this.from,
    required this.to,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.onLoadMore,
  });

  final bool isLoadingMore;
  final bool hasNextPage;
  final int from;
  final int to;
  final int total;
  final int page;
  final int totalPages;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      child: Column(
        children: [
          if (isLoadingMore)
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            )
          else if (hasNextPage)
            OutlinedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.expand_more_rounded, size: 16),
              label: const Text('Load more'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xFFD1D9E6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '$from-$to of $total · Page $page of $totalPages',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
