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
    this.page = 1,
    this.limit = 10,
    this.report,
    this.isLoading = false,
    this.error,
  });

  final List<BusinessLocationModel> locations;
  final int? selectedStoreId;
  final VarianceTypeFilter typeFilter;
  final int page;
  final int limit;
  final VarianceReportModel? report;
  final bool isLoading;
  final String? error;

  List<VarianceRowModel> get rows => report?.rows ?? [];
  PaginationMeta get meta =>
      report?.meta ??
      const PaginationMeta(page: 1, limit: 10, total: 0, totalPages: 0);

  VarianceState copyWith({
    List<BusinessLocationModel>? locations,
    int? selectedStoreId,
    bool clearSelectedStore = false,
    VarianceTypeFilter? typeFilter,
    int? page,
    int? limit,
    VarianceReportModel? report,
    bool clearReport = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return VarianceState(
      locations: locations ?? this.locations,
      selectedStoreId: clearSelectedStore
          ? null
          : (selectedStoreId ?? this.selectedStoreId),
      typeFilter: typeFilter ?? this.typeFilter,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      report: clearReport ? null : (report ?? this.report),
      isLoading: isLoading ?? this.isLoading,
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
    state = state.copyWith(isLoading: true, clearError: true, clearReport: true);
    try {
      final locations = await _repository.getBusinessLocations();
      final storeId = resolvePreferredStoreId(locations, preferredStoreId);
      state = state.copyWith(
        locations: locations,
        selectedStoreId: storeId,
        page: 1,
        isLoading: false,
      );
      if (storeId != null) {
        await loadReport();
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> loadReport() async {
    final storeId = state.selectedStoreId;
    if (storeId == null) {
      state = state.copyWith(isLoading: false, clearReport: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final report = await _repository.getVariance(
        businessLocationId: storeId,
        type: state.typeFilter.apiValue,
        page: state.page,
        limit: state.limit,
      );
      state = state.copyWith(report: report, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        clearReport: true,
      );
    }
  }

  Future<void> setStoreFilter(int? storeId) async {
    state = state.copyWith(
      selectedStoreId: storeId,
      clearSelectedStore: storeId == null,
      page: 1,
    );
    await loadReport();
  }

  Future<void> setTypeFilter(VarianceTypeFilter filter) async {
    state = state.copyWith(typeFilter: filter, page: 1);
    await loadReport();
  }

  Future<void> setPage(int page) async {
    state = state.copyWith(page: page);
    await loadReport();
  }
}
