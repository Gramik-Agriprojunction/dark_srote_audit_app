import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/audit_qty_helper.dart';
import '../../data/models/business_location_model.dart';
import '../../data/models/product_mismatch_model.dart';
import '../../data/stock_audit_repository.dart';
import '../utils/resolve_store_id.dart';

enum StockStatusFilter { all, matched, short, excess }

class MyProductsState {
  const MyProductsState({
    this.locations = const [],
    this.allRows = const [],
    this.selectedStoreId,
    this.searchQuery = '',
    this.statusFilter = StockStatusFilter.all,
    this.page = 1,
    this.limit = 10,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<BusinessLocationModel> locations;
  final List<ProductMismatchRow> allRows;
  final int? selectedStoreId;
  final String searchQuery;
  final StockStatusFilter statusFilter;
  final int page;
  final int limit;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  List<ProductMismatchRow> get searchFilteredRows {
    final term = searchQuery.trim().toLowerCase();
    if (term.isEmpty) return allRows;
    return allRows.where((row) {
      return row.productName.toLowerCase().contains(term) ||
          (row.sku ?? '').toLowerCase().contains(term) ||
          (row.storeName ?? '').toLowerCase().contains(term) ||
          (row.variantLabel ?? '').toLowerCase().contains(term) ||
          (row.comment ?? '').toLowerCase().contains(term);
    }).toList();
  }

  List<ProductMismatchRow> get filteredRows {
    final rows = searchFilteredRows;
    switch (statusFilter) {
      case StockStatusFilter.all:
        return rows;
      case StockStatusFilter.matched:
        return rows
            .where((row) => row.status == ReconStatus.matched)
            .toList();
      case StockStatusFilter.short:
        return rows.where((row) => row.status == ReconStatus.short).toList();
      case StockStatusFilter.excess:
        return rows.where((row) => row.status == ReconStatus.excess).toList();
    }
  }

  int get totalSkuCount => searchFilteredRows.length;
  int get matchedCount => searchFilteredRows
      .where((r) => r.status == ReconStatus.matched)
      .length;
  int get shortCount =>
      searchFilteredRows.where((r) => r.status == ReconStatus.short).length;
  int get excessCount =>
      searchFilteredRows.where((r) => r.status == ReconStatus.excess).length;

  int get total => filteredRows.length;

  int get totalPages => total > 0 ? (total / limit).ceil() : 0;

  bool get hasNextPage => page < totalPages;

  /// Infinite-scroll reveal: first `page * limit` filtered rows.
  List<ProductMismatchRow> get visibleRows {
    if (total == 0) return const [];
    final count = (page * limit).clamp(0, total);
    return filteredRows.take(count).toList();
  }

  int get visibleTo => visibleRows.length;
  int get visibleFrom => visibleRows.isEmpty ? 0 : 1;

  MyProductsState copyWith({
    List<BusinessLocationModel>? locations,
    List<ProductMismatchRow>? allRows,
    int? selectedStoreId,
    bool clearSelectedStore = false,
    String? searchQuery,
    StockStatusFilter? statusFilter,
    int? page,
    int? limit,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return MyProductsState(
      locations: locations ?? this.locations,
      allRows: allRows ?? this.allRows,
      selectedStoreId: clearSelectedStore
          ? null
          : (selectedStoreId ?? this.selectedStoreId),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      page: page ?? this.page,
      limit: limit ?? this.limit,
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

  /// Blocks rapid scroll-listener page jumps (one chunk per short window).
  bool _loadMoreLocked = false;

  Future<void> initialize({int? preferredStoreId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
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

  Future<void> loadReport() async {
    _loadMoreLocked = false;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
      page: 1,
    );
    try {
      final locations = state.locations;
      if (locations.isEmpty) {
        state = state.copyWith(isLoading: false, allRows: const []);
        return;
      }

      final targets = state.selectedStoreId == null
          ? locations
          : locations.where((location) => location.id == state.selectedStoreId);

      final rows = <ProductMismatchRow>[];

      for (final location in targets) {
        final products = await _repository.getLocationProducts(location.id);
        for (final product in products) {
          for (final variant in product.variants) {
            if (variant.auditUpdatedAt == null) continue;

            final totalPhysicalStock = variant.auditQty;
            final systemStock = variant.availableStock;
            final damageStock = variant.damageQty;
            final physicalStock = AuditQtyHelper.physicalStock(variant);
            // Lens v2PlotRunDiff: Total Physical − System Stock at Last Audit.
            // Damage is part of Total Physical, so leaked/damaged units do not
            // create a SHORT by themselves (matches Lens full report).
            final difference =
                AuditQtyHelper.reconciliationDifference(variant);
            final status = ProductMismatchRow.statusFromDifference(difference);

            rows.add(
              ProductMismatchRow(
                productName: product.name,
                variantLabel: variant.variantName,
                sku: variant.sku,
                storeName: location.label,
                systemStock: systemStock,
                totalPhysicalStock: totalPhysicalStock,
                physicalStock: physicalStock,
                damageStock: damageStock,
                comment: _normalizeComment(variant.damageComment),
                difference: difference,
                status: status,
                auditUpdatedAt: variant.auditUpdatedAt!,
              ),
            );
          }
        }
      }

      // Sort by audit updated date descending (most recent first) - same as CRM
      rows.sort((a, b) => b.auditUpdatedAt.compareTo(a.auditUpdatedAt));

      state = state.copyWith(
        allRows: rows,
        isLoading: false,
        isLoadingMore: false,
        page: 1,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.message,
        allRows: const [],
      );
    }
  }

  String? _normalizeComment(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> setStoreFilter(int? storeId) async {
    _loadMoreLocked = false;
    state = state.copyWith(
      selectedStoreId: storeId,
      clearSelectedStore: storeId == null,
      page: 1,
      isLoadingMore: false,
    );
    await loadReport();
  }

  void setSearch(String query) {
    _loadMoreLocked = false;
    state = state.copyWith(
      searchQuery: query,
      page: 1,
      isLoadingMore: false,
    );
  }

  void setStatusFilter(StockStatusFilter filter) {
    if (state.statusFilter == filter) return;
    _loadMoreLocked = false;
    state = state.copyWith(
      statusFilter: filter,
      page: 1,
      isLoadingMore: false,
    );
  }

  /// Loads the next chunk. Cooldown prevents scroll listener from jumping
  /// page 1 → last page in a single gesture.
  void loadMore() {
    if (state.isLoading ||
        state.isLoadingMore ||
        _loadMoreLocked ||
        !state.hasNextPage) {
      return;
    }
    _loadMoreLocked = true;
    state = state.copyWith(
      isLoadingMore: true,
      page: state.page + 1,
    );
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadMoreLocked = false;
      state = state.copyWith(isLoadingMore: false);
    });
  }
}
