import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/order_model.dart';
import '../../data/orders_repository.dart';

enum OrderFilterTab {
  all,
  pending,
  pickup,
  reschedule,
  cancelled,
  disputed,
  delivered,
  rto;

  static const tabs = [
    OrderFilterTab.all,
    OrderFilterTab.pending,
    OrderFilterTab.pickup,
    OrderFilterTab.reschedule,
    OrderFilterTab.cancelled,
    OrderFilterTab.disputed,
    OrderFilterTab.delivered,
    OrderFilterTab.rto,
  ];
}

extension OrderFilterTabX on OrderFilterTab {
  String get id {
    switch (this) {
      case OrderFilterTab.all:
        return 'all';
      case OrderFilterTab.pending:
        return 'pending';
      case OrderFilterTab.pickup:
        return 'pickup';
      case OrderFilterTab.reschedule:
        return 'reschedule';
      case OrderFilterTab.cancelled:
        return 'cancelled';
      case OrderFilterTab.disputed:
        return 'disputed';
      case OrderFilterTab.delivered:
        return 'delivered';
      case OrderFilterTab.rto:
        return 'rto';
    }
  }

  String get label {
    switch (this) {
      case OrderFilterTab.all:
        return 'All';
      case OrderFilterTab.pending:
        return 'Pending';
      case OrderFilterTab.pickup:
        return 'Picked Up';
      case OrderFilterTab.reschedule:
        return 'Rescheduled';
      case OrderFilterTab.cancelled:
        return 'Cancelled';
      case OrderFilterTab.disputed:
        return 'Disputed';
      case OrderFilterTab.delivered:
        return 'Delivered';
      case OrderFilterTab.rto:
        return 'RTO';
    }
  }
}

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.stats = const OrderListStatsModel(),
    this.pagination = const OrderPaginationModel(),
    this.activeTab = OrderFilterTab.all,
    this.search = '',
    this.expandedOrderIds = const {},
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<OrderListItemModel> orders;
  final OrderListStatsModel stats;
  final OrderPaginationModel pagination;
  final OrderFilterTab activeTab;
  final String search;
  final Set<int> expandedOrderIds;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? error;

  OrdersState copyWith({
    List<OrderListItemModel>? orders,
    OrderListStatsModel? stats,
    OrderPaginationModel? pagination,
    OrderFilterTab? activeTab,
    String? search,
    Set<int>? expandedOrderIds,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      stats: stats ?? this.stats,
      pagination: pagination ?? this.pagination,
      activeTab: activeTab ?? this.activeTab,
      search: search ?? this.search,
      expandedOrderIds: expandedOrderIds ?? this.expandedOrderIds,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final ordersControllerProvider =
    StateNotifierProvider<OrdersController, OrdersState>((ref) {
      return OrdersController(ref.watch(ordersRepositoryProvider));
    });

class OrdersController extends StateNotifier<OrdersState> {
  OrdersController(this._repository) : super(const OrdersState());

  final OrdersRepository _repository;
  Timer? _searchDebounce;

  Future<void> initialize() => _load(page: 1);

  Future<void> refresh() => _load(page: 1, isRefresh: true);

  void setSearch(String value) {
    state = state.copyWith(search: value, clearError: true);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _load(page: 1);
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    state = state.copyWith(search: '', clearError: true);
    _load(page: 1);
  }

  Future<void> setTab(OrderFilterTab tab) async {
    if (state.activeTab == tab) return;
    state = state.copyWith(
      activeTab: tab,
      orders: const [],
      isLoading: true,
      clearError: true,
      expandedOrderIds: const {},
    );
    await _load(page: 1);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasNextPage) return;
    await _load(page: state.pagination.currentPage + 1, loadMore: true);
  }

  void toggleExpanded(int orderId) {
    final next = Set<int>.from(state.expandedOrderIds);
    if (next.contains(orderId)) {
      next.remove(orderId);
    } else {
      next.add(orderId);
    }
    state = state.copyWith(expandedOrderIds: next);
  }

  Future<void> _load({
    required int page,
    bool loadMore = false,
    bool isRefresh = false,
  }) async {
    if (loadMore) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else if (isRefresh) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else if (page == 1 && state.orders.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final result = await _repository.fetchOrders(
        search: state.search,
        status: state.activeTab.id,
        page: page,
      );

      final merged = loadMore
          ? _mergeOrders(state.orders, result.orders)
          : result.orders;

      state = state.copyWith(
        orders: merged,
        stats: loadMore ? state.stats : result.stats,
        pagination: result.pagination,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: 'Connection error. Please try again.',
      );
    }
  }

  List<OrderListItemModel> _mergeOrders(
    List<OrderListItemModel> existing,
    List<OrderListItemModel> incoming,
  ) {
    final seen = existing.map((o) => o.id).toSet();
    return [
      ...existing,
      ...incoming.where((o) => !seen.contains(o.id)),
    ];
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
