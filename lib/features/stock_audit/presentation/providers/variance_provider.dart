import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/business_location_model.dart';
import '../../data/models/variance_model.dart';
import '../../data/stock_audit_repository.dart';
import '../utils/resolve_store_id.dart';

enum VarianceTypeFilter { all, minus, plus }

extension VarianceTypeFilterApi on VarianceTypeFilter {
  String get apiValue {
    switch (this) {
      case VarianceTypeFilter.all:
        return 'ALL';
      case VarianceTypeFilter.minus:
        return 'MINUS';
      case VarianceTypeFilter.plus:
        return 'PLUS';
    }
  }
}

class VarianceState {
  const VarianceState({
    this.locations = const [],
    this.selectedStoreId,
    this.typeFilter = VarianceTypeFilter.all,
    this.rows = const [],
    this.meta = const PaginationMeta(page: 1, limit: 10, total: 0, totalPages: 0),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<BusinessLocationModel> locations;
  final int? selectedStoreId;
  final VarianceTypeFilter typeFilter;
  final List<VarianceRowModel> rows;
  final PaginationMeta meta;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasNextPage => meta.page < meta.totalPages;

  VarianceState copyWith({
    List<BusinessLocationModel>? locations,
    int? selectedStoreId,
    bool clearSelectedStore = false,
    VarianceTypeFilter? typeFilter,
    List<VarianceRowModel>? rows,
    PaginationMeta? meta,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool clearRows = false,
  }) {
    return VarianceState(
      locations: locations ?? this.locations,
      selectedStoreId: clearSelectedStore
          ? null
          : (selectedStoreId ?? this.selectedStoreId),
      typeFilter: typeFilter ?? this.typeFilter,
      rows: clearRows ? const [] : (rows ?? this.rows),
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final varianceControllerProvider =
    StateNotifierProvider<VarianceController, VarianceState>((ref) {
      return VarianceController(ref.watch(stockAuditRepositoryProvider));
    });

class VarianceController extends StateNotifier<VarianceState> {
  VarianceController(this._repository) : super(const VarianceState());

  final StockAuditRepository _repository;

  Future<void> initialize({int? preferredStoreId}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearRows: true,
    );
    try {
      final locations = await _repository.getBusinessLocations();
      final storeId = resolvePreferredStoreId(locations, preferredStoreId);
      state = state.copyWith(
        locations: locations,
        selectedStoreId: storeId,
        isLoading: false,
      );
      if (storeId != null) {
        await _fetch(page: 1);
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> loadReport() => _fetch(page: 1);

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasNextPage) return;
    await _fetch(page: state.meta.page + 1, loadMore: true);
  }

  Future<void> _fetch({required int page, bool loadMore = false}) async {
    final storeId = state.selectedStoreId;
    if (storeId == null) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        clearRows: true,
      );
      return;
    }

    if (loadMore) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true, clearRows: true);
    }

    try {
      final report = await _repository.getVariance(
        businessLocationId: storeId,
        type: state.typeFilter.apiValue,
        page: page,
        limit: state.meta.limit,
      );

      final merged = loadMore
          ? _mergeRows(state.rows, report.rows)
          : report.rows;

      state = state.copyWith(
        rows: merged,
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

  List<VarianceRowModel> _mergeRows(
    List<VarianceRowModel> existing,
    List<VarianceRowModel> incoming,
  ) {
    final seen = existing.map((r) => r.id).toSet();
    return [
      ...existing,
      ...incoming.where((r) => !seen.contains(r.id)),
    ];
  }

  Future<void> setStoreFilter(int? storeId) async {
    state = state.copyWith(
      selectedStoreId: storeId,
      clearSelectedStore: storeId == null,
      clearRows: true,
    );
    await _fetch(page: 1);
  }

  Future<void> setTypeFilter(VarianceTypeFilter filter) async {
    if (state.typeFilter == filter) return;
    state = state.copyWith(typeFilter: filter, clearRows: true);
    await _fetch(page: 1);
  }
}
