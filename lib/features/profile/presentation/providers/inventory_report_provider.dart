import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/inventory_report_repository.dart';
import '../../data/models/inventory_summary_model.dart';

class InventoryReportState {
  const InventoryReportState({
    this.isLoading = false,
    this.error,
    this.model,
    this.warehouseId,
  });

  final bool isLoading;
  final String? error;
  final InventorySummaryModel? model;
  final int? warehouseId;

  InventoryReportState copyWith({
    bool? isLoading,
    String? error,
    InventorySummaryModel? model,
    int? warehouseId,
    bool clearError = false,
    bool clearModel = false,
  }) {
    return InventoryReportState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      model: clearModel ? null : (model ?? this.model),
      warehouseId: warehouseId ?? this.warehouseId,
    );
  }
}

class InventoryReportController extends StateNotifier<InventoryReportState> {
  InventoryReportController(this._repo, this._storage, this._ref)
      : super(const InventoryReportState());

  final InventoryReportRepository _repo;
  final SessionStorage _storage;
  final Ref _ref;

  Future<int?> _resolveWarehouseId() async {
    final authId = _ref.read(authControllerProvider).selectedStoreId;
    if (authId != null && authId > 0) return authId;
    final stored = await _storage.getSelectedStoreId();
    if (stored != null && stored > 0) return stored;
    return null;
  }

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearModel: !refresh,
    );

    try {
      final warehouseId = await _resolveWarehouseId();
      if (warehouseId == null || warehouseId <= 0) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Warehouse select nahi mili. Pehle business location choose karein.',
        );
        return;
      }

      final model =
          await _repo.fetchInventorySummary(warehouseId: warehouseId);
      // Always prefer logged-in / selected store label — Odoo name can drift.
      final authLabel =
          (_ref.read(authControllerProvider).selectedStoreLabel ?? '').trim();
      final apiLabel = (model.warehouseLabel ?? '').trim();
      final label = authLabel.isNotEmpty
          ? authLabel
          : (apiLabel.isNotEmpty ? apiLabel : null);

      state = InventoryReportState(
        model: InventorySummaryModel(
          items: model.items,
          warehouseLabel: label,
          warehouseId: warehouseId,
        ),
        warehouseId: warehouseId,
      );
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
    ref.watch(sessionStorageProvider),
    ref,
  );
});
