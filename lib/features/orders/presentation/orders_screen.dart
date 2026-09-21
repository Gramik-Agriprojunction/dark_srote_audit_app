import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/scroll_pagination_footer.dart';
import '../../auth/presentation/providers/auth_provider.dart';
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
    if (!mounted || _initialized) return;
    _initialized = true;
    ref.read(authControllerProvider.notifier).touchActivity();
    await ref.read(ordersControllerProvider.notifier).initialize();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
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

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final state = ref.watch(ordersControllerProvider);
    final notifier = ref.read(ordersControllerProvider.notifier);

    if (_searchController.text != state.search) {
      _searchController.value = _searchController.value.copyWith(
        text: state.search,
        selection: TextSelection.collapsed(offset: state.search.length),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: s.orders,
            subtitle: ref.watch(headerGreetingProvider),
            onLogout: _logout,
            notificationCount: state.stats.notificationCount,
            searchController: _searchController,
            searchHint: s.orderSearchHint,
            searchValue: state.search,
            onSearchChanged: notifier.setSearch,
            onClearSearch: notifier.clearSearch,
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
                    child: ModuleStatsRow(
                      stats: [
                        ModuleStat(
                          icon: Icons.receipt_long_rounded,
                          label: s.totalOrders,
                          value: '${state.stats.totalOrders}',
                          background: AppColors.primary,
                          labelColor: const Color(0xFFFFE4D2),
                        ),
                        ModuleStat(
                          icon: Icons.schedule_rounded,
                          label: s.pending,
                          value: '${state.stats.pending}',
                          background: const Color(0xFFB45309),
                          labelColor: const Color(0xFFFED7AA),
                        ),
                        ModuleStat(
                          icon: Icons.payments_outlined,
                          label: s.totalValue,
                          value: formatMoney(state.stats.totalValue),
                          background: const Color(0xFF1D4ED8),
                          labelColor: const Color(0xFFBFDBFE),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ModuleChipsRow(
                      chips: OrderFilterTab.tabs.map((tab) {
                        return ModuleChip(
                          label: _tabLabel(tab, s),
                          icon: tabIcon(tab.id),
                          tone: tabToneBg(tab.id),
                          isActive: state.activeTab == tab,
                          onTap: () => notifier.setTab(tab),
                        );
                      }).toList(),
                    ),
                  ),
                  if (state.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: AlertBanner(
                          message: state.error!,
                          isError: true,
                        ),
                      ),
                    ),
                  if ((state.isLoading || state.isRefreshing) &&
                      state.orders.isEmpty)
                    const SliverToBoxAdapter(
                      child: ModuleListLoadingBody(showStats: false),
                    )
                  else if (state.orders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: s.noOrdersFound,
                        message: s.tryAnotherFilter,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = state.orders[index];
                          return OrderCard(
                            order: order,
                            expanded: state.expandedOrderIds.contains(order.id),
                            onToggleExpand: () =>
                                notifier.toggleExpanded(order.id),
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
}

String _tabLabel(OrderFilterTab tab, AppStrings s) {
  switch (tab) {
    case OrderFilterTab.all:
      return s.filterAll;
    case OrderFilterTab.pending:
      return s.pending;
    case OrderFilterTab.pickup:
      return s.filterPickup;
    case OrderFilterTab.reschedule:
      return s.filterReschedule;
    case OrderFilterTab.cancelled:
      return s.cancelled;
    case OrderFilterTab.disputed:
      return s.filterDisputed;
    case OrderFilterTab.delivered:
      return s.delivered;
    case OrderFilterTab.rto:
      return s.filterRto;
  }
}
