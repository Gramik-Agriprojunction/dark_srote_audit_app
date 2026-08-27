import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/business_location_model.dart';
import '../../data/models/product_mismatch_model.dart';
import '../../data/stock_audit_repository.dart';
import '../utils/resolve_store_id.dart';

class MyProductsState {
  const MyProductsState({
    this.locations = const [],
    this.allRows = const [],
    this.selectedStoreId,
    this.searchQuery = '',
    this.page = 1,
    this.limit = 10,
    this.isLoading = false,
    this.error,
  });

  final List<BusinessLocationModel> locations;
  final List<ProductMismatchRow> allRows;
  final int? selectedStoreId;
  final String searchQuery;
  final int page;
  final int limit;
  final bool isLoading;
  final String? error;

  List<ProductMismatchRow> get filteredRows {
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

  int get total => filteredRows.length;
  int get matchedCount =>
      filteredRows.where((r) => r.status == ReconStatus.matched).length;
  int get shortCount =>
      filteredRows.where((r) => r.status == ReconStatus.short).length;
  int get excessCount =>
      filteredRows.where((r) => r.status == ReconStatus.excess).length;

  int get totalPages => total > 0 ? (total / limit).ceil() : 0;

  List<ProductMismatchRow> get pagedRows {
    if (total == 0) return const [];
    final safePage = page.clamp(1, totalPages == 0 ? 1 : totalPages);
    final start = (safePage - 1) * limit;
    return filteredRows.skip(start).take(limit).toList();
  }

  MyProductsState copyWith({
    List<BusinessLocationModel>? locations,
    List<ProductMismatchRow>? allRows,
    int? selectedStoreId,
    bool clearSelectedStore = false,
    String? searchQuery,
    int? page,
    int? limit,
    bool? isLoading,
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
      page: page ?? this.page,
      limit: limit ?? this.limit,
      isLoading: isLoading ?? this.isLoading,
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
    state = state.copyWith(isLoading: true, clearError: true, page: 1);
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
            // CRM "Total Available Stock" — current on-hand with backlog
            final systemStock = variant.availableStock;
            final damageStock = variant.damageQty;
            final physicalStock = (totalPhysicalStock - damageStock).clamp(
              0,
              totalPhysicalStock,
            );
            // CRM diff = physicalStock - lastAuditSystemStock (not current available)
            final lastAuditBase = variant.lastAuditSystemStock ??
                variant.systemOnHandQty;
            final difference = physicalStock - lastAuditBase;
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

      state = state.copyWith(allRows: rows, isLoading: false, page: 1);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
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
    state = state.copyWith(
      selectedStoreId: storeId,
      clearSelectedStore: storeId == null,
      page: 1,
    );
    await loadReport();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, page: 1);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void setLimit(int limit) {
    state = state.copyWith(limit: limit, page: 1);
  }
}
