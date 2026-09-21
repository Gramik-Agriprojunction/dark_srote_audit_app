import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/dc_repository.dart';
import '../../data/models/dc_transfer_model.dart';

class DcState {
  const DcState({
    this.warehouse,
    this.summary,
    this.transfers = const [],
    this.queryKey = 'in',
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  final DcWarehouseModel? warehouse;
  final DcSummaryModel? summary;
  final List<DcTransferModel> transfers;
  final String queryKey;
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
    String? queryKey,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return DcState(
      warehouse: warehouse ?? this.warehouse,
      summary: summary ?? this.summary,
      transfers: transfers ?? this.transfers,
      queryKey: queryKey ?? this.queryKey,
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
  int _loadGeneration = 0;
  DcFetchQuery _query = DcFetchQuery.incoming;

  Future<void> initialize({DcFetchQuery query = DcFetchQuery.incoming}) async {
    await _load(refresh: false, query: query);
    await _prefetchOutboundPeerSummary(query.key);
  }

  Future<void> refresh({DcFetchQuery? query}) async {
    final activeQuery = query ?? _query;
    await _load(refresh: true, query: activeQuery);
    await _prefetchOutboundPeerSummary(activeQuery.key);
  }

  Future<void> loadWithQuery(DcFetchQuery query) async {
    await _load(refresh: true, query: query);
    await _prefetchOutboundPeerSummary(query.key);
  }

  /// Outgoing tile needs Transferred count (and vice versa) without switching list.
  Future<void> _prefetchOutboundPeerSummary(String primaryKey) async {
    if (primaryKey != 'out' && primaryKey != 'transferred') return;

    final summary = state.summary;
    if (primaryKey == 'out' && (summary?.transferredTransfers ?? 0) > 0) {
      return;
    }
    if (primaryKey == 'transferred' && (summary?.outgoingTransfers ?? 0) > 0) {
      return;
    }

    final peerQuery =
        primaryKey == 'out' ? DcFetchQuery.transferred : DcFetchQuery.outgoing;

    try {
      final result = await _repository.fetchTransfers(query: peerQuery);
      final merged = _mergeSummary(
        queryKey: peerQuery.key,
        next: result.summary,
        previous: state.summary ?? result.summary,
      );
      state = state.copyWith(summary: merged);
    } on ApiException {
      // Keep primary list/summary if peer count prefetch fails.
    }
  }

  DcSummaryModel _mergeSummary({
    required String queryKey,
    required DcSummaryModel next,
    DcSummaryModel? previous,
  }) {
    if (previous == null) return next;

    int pick(int nextValue, int previousValue) =>
        nextValue > 0 ? nextValue : previousValue;

    switch (queryKey) {
      case 'out':
        return DcSummaryModel(
          incomingTransfers: previous.incomingTransfers,
          receivedTransfers: previous.receivedTransfers,
          outgoingTransfers: next.outgoingTransfers,
          transferredTransfers: pick(
            next.transferredTransfers,
            previous.transferredTransfers,
          ),
          totalTransfers: next.totalTransfers,
        );
      case 'transferred':
        return DcSummaryModel(
          incomingTransfers: previous.incomingTransfers,
          receivedTransfers: previous.receivedTransfers,
          outgoingTransfers: pick(
            next.outgoingTransfers,
            previous.outgoingTransfers,
          ),
          transferredTransfers: next.transferredTransfers,
          totalTransfers: next.totalTransfers,
        );
      default:
        return DcSummaryModel(
          incomingTransfers: next.incomingTransfers,
          receivedTransfers: next.receivedTransfers,
          outgoingTransfers: pick(
            next.outgoingTransfers,
            previous.outgoingTransfers,
          ),
          transferredTransfers: pick(
            next.transferredTransfers,
            previous.transferredTransfers,
          ),
          totalTransfers: next.totalTransfers,
        );
    }
  }

  Future<void> _load({
    required bool refresh,
    required DcFetchQuery query,
  }) async {
    final generation = ++_loadGeneration;
    _query = query;
    state = state.copyWith(
      isLoading: !refresh && state.transfers.isEmpty,
      isRefreshing: refresh,
      queryKey: query.key,
      clearError: true,
    );

    try {
      final result = await _repository.fetchTransfers(query: query);
      if (generation != _loadGeneration) return;
      state = state.copyWith(
        warehouse: result.warehouse,
        summary: _mergeSummary(
          queryKey: query.key,
          next: result.summary,
          previous: state.summary,
        ),
        transfers: result.transfers,
        queryKey: query.key,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (generation != _loadGeneration) return;
      if (e.message == 'Request cancelled') return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.message,
      );
    }
  }

  Future<String> validateInboundProducts({
    required int transferId,
    required int inboundPickingId,
    required List<DcTransferOperation> operations,
  }) {
    return _repository.validateInboundProducts(
      transferId: transferId,
      inboundPickingId: inboundPickingId,
      operations: operations,
    );
  }

  Future<String> validateOutboundProducts({
    required int transferId,
    required int outboundPickingId,
    required List<DcTransferOperation> operations,
  }) {
    return _repository.validateOutboundProducts(
      transferId: transferId,
      outboundPickingId: outboundPickingId,
      operations: operations,
    );
  }
}
