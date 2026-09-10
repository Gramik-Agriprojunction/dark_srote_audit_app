import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/inventory_report_repository.dart';
import '../../data/models/inventory_summary_model.dart';

class InventoryReportState {
  const InventoryReportState({
    this.isLoading = false,
    this.error,
    this.model,
  });

  final bool isLoading;
  final String? error;
  final InventorySummaryModel? model;

  InventoryReportState copyWith({
    bool? isLoading,
    String? error,
    InventorySummaryModel? model,
    bool clearError = false,
  }) {
    return InventoryReportState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      model: model ?? this.model,
    );
  }
}

class InventoryReportController extends StateNotifier<InventoryReportState> {
  InventoryReportController(this._repo)
      : super(const InventoryReportState());

  final InventoryReportRepository _repo;

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      model: refresh ? state.model : null,
    );
    try {
      final model = await _repo.fetchInventorySummary(warehouseId: 2);
      state = InventoryReportState(model: model);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Report load nahi ho paya',
      );
    }
  }
}

final inventoryReportControllerProvider = StateNotifierProvider.autoDispose<
    InventoryReportController, InventoryReportState>((ref) {
  return InventoryReportController(
    ref.watch(inventoryReportRepositoryProvider),
  );
});
