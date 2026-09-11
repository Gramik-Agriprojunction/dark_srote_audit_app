import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_pagination.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/business_location_model.dart';
import '../../data/models/product_mismatch_model.dart';
import '../../data/models/stock_reconciliation_model.dart';
import '../../data/models/variance_model.dart';
import '../../data/stock_audit_repository.dart';
import '../utils/resolve_store_id.dart';

enum StockStatusFilter { all, matched, short, excess }

extension StockStatusFilterApi on StockStatusFilter {
  String get apiValue {
    switch (this) {
      case StockStatusFilter.all:
        return 'ALL';
      case StockStatusFilter.matched:
        return 'MATCHED';
      case StockStatusFilter.short:
        return 'SHORT';
      case StockStatusFilter.excess:
        return 'EXCESS';
    }
  }
}

class MyProductsState {
  const MyProductsState({
    this.locations = const [],
    this.rows = const [],
    this.summary = const StockReconciliationSummary(),
    this.meta = const PaginationMeta(
      page: 1,
      limit: kAppPageSize,
      total: 0,
      totalPages: 0,
    ),
    this.selectedStoreId,
    this.searchQuery = '',
    this.statusFilter = StockStatusFilter.all,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<BusinessLocationModel> locations;
  final List<ProductMismatchRow> rows;
  final StockReconciliationSummary summary;
  final PaginationMeta meta;
  final int? selectedStoreId;
  final String searchQuery;
  final StockStatusFilter statusFilter;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  int get totalSkuCount => summary.totalSku;
  int get matchedCount => summary.matched;
  int get shortCount => summary.short;
  int get excessCount => summary.excess;

  bool get hasNextPage => meta.page < meta.totalPages;

  MyProductsState copyWith({
    List<BusinessLocationModel>? locations,
    List<ProductMismatchRow>? rows,
    StockReconciliationSummary? summary,
    PaginationMeta? meta,
    int? selectedStoreId,
    bool clearSelectedStore = false,
    String? searchQuery,
    StockStatusFilter? statusFilter,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool clearRows = false,
  }) {
    return MyProductsState(
      locations: locations ?? this.locations,
      rows: clearRows ? const [] : (rows ?? this.rows),
      summary: summary ?? this.summary,
      meta: meta ?? this.meta,
      selectedStoreId: clearSelectedStore
          ? null
          : (selectedStoreId ?? this.selectedStoreId),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final myProductsControllerProvider =
    StateNotifierProvider<MyProductsController, MyProductsState>((ref) {
      return MyProductsController(ref.watch(stockAuditRepositoryProvider));
    });

class MyProductsController extends StateNotifier<MyProductsState> {
  MyProductsController(this._repository) : super(const MyProductsState());

  final StockAuditRepository _repository;
  Timer? _searchDebounce;

  Future<void> initialize({int? preferredStoreId}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearRows: true);
    try {
      final locations = await _repository.getBusinessLocations();
      final storeId = resolvePreferredStoreId(locations, preferredStoreId);
      state = state.copyWith(
        locations: locations,
        selectedStoreId: storeId,
        isLoading: false,
      );
      await loadReport();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> loadReport() => _fetch(page: 1);

  Future<void> setStoreFilter(int? storeId) async {
    state = state.copyWith(
      selectedStoreId: storeId,
      clearSelectedStore: storeId == null,
      clearRows: true,
    );
    await _fetch(page: 1);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, clearError: true, clearRows: true);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetch(page: 1);
    });
  }

  Future<void> setStatusFilter(StockStatusFilter filter) async {
    if (state.statusFilter == filter) return;
    state = state.copyWith(
      statusFilter: filter,
      clearRows: true,
      clearError: true,
    );
    await _fetch(page: 1);
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasNextPage ||
        state.selectedStoreId == null) {
      return;
    }
    await _fetch(page: state.meta.page + 1, loadMore: true);
  }

  Future<void> _fetch({required int page, bool loadMore = false}) async {
    final storeId = state.selectedStoreId;
    if (storeId == null) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        rows: const [],
        summary: const StockReconciliationSummary(),
        meta: const PaginationMeta(
          page: 1,
          limit: kAppPageSize,
          total: 0,
          totalPages: 0,
        ),
      );
      return;
    }

    if (loadMore) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true, clearRows: true);
    }

    try {
      final report = await _repository.getStockReconciliation(
        businessLocationId: storeId,
        status: state.statusFilter.apiValue,
        search: state.searchQuery,
        page: page,
        limit: kAppPageSize,
      );

      final merged = loadMore
          ? _mergeRows(state.rows, report.rows)
          : report.rows;

      state = state.copyWith(
        rows: merged,
        summary: report.summary,
        meta: report.meta,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.message,
        clearRows: !loadMore,
      );
    }
  }

  List<ProductMismatchRow> _mergeRows(
    List<ProductMismatchRow> existing,
    List<ProductMismatchRow> incoming,
  ) {
    final seen = <String>{};
    for (final row in existing) {
      seen.add('${row.sku}|${row.productName}|${row.auditUpdatedAt.millisecondsSinceEpoch}');
    }
    final merged = [...existing];
    for (final row in incoming) {
      final key =
          '${row.sku}|${row.productName}|${row.auditUpdatedAt.millisecondsSinceEpoch}';
      if (seen.add(key)) merged.add(row);
    }
    return merged;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
