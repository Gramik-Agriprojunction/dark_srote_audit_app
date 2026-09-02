import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/dc_repository.dart';
import '../../data/models/dc_transfer_model.dart';

class DcState {
  const DcState({
    this.warehouse,
    this.summary,
    this.transfers = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  final DcWarehouseModel? warehouse;
  final DcSummaryModel? summary;
  final List<DcTransferModel> transfers;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  DcTransferModel? transferById(int transferId) {
    for (final t in transfers) {
      if (t.transferId == transferId) return t;
    }
    return null;
  }

  DcState copyWith({
    DcWarehouseModel? warehouse,
    DcSummaryModel? summary,
    List<DcTransferModel>? transfers,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return DcState(
      warehouse: warehouse ?? this.warehouse,
      summary: summary ?? this.summary,
      transfers: transfers ?? this.transfers,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final dcControllerProvider = StateNotifierProvider<DcController, DcState>((ref) {
  return DcController(ref.watch(dcRepositoryProvider));
});

class DcController extends StateNotifier<DcState> {
  DcController(this._repository) : super(const DcState());

  final DcRepository _repository;

  Future<void> initialize() => _load(refresh: false);

  Future<void> refresh() => _load(refresh: true);

  Future<void> _load({required bool refresh}) async {
    state = state.copyWith(
      isLoading: !refresh && state.transfers.isEmpty,
      isRefreshing: refresh,
      clearError: true,
    );

    try {
      final result = await _repository.fetchTransfers();
      state = state.copyWith(
        warehouse: result.warehouse,
        summary: result.summary,
        transfers: result.transfers,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.message,
      );
    }
  }

  Future<String> validateInboundProduct({
    required int transferId,
    required int inboundPickingId,
    required int productId,
    required int quantity,
  }) {
    return _repository.validateInboundProduct(
      transferId: transferId,
      inboundPickingId: inboundPickingId,
      productId: productId,
      quantity: quantity,
    );
  }
}
