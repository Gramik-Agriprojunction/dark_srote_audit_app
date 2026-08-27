import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/business_location_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/stock_audit_repository.dart';

class TransactionsState {
  const TransactionsState({
    this.locations = const [],
    this.selectedStoreId,
    this.selectedDate,
    this.report,
    this.isLoading = false,
    this.error,
  });

  final List<BusinessLocationModel> locations;
  final int? selectedStoreId;
  final DateTime? selectedDate;
  final TransactionReportModel? report;
  final bool isLoading;
  final String? error;

  TransactionsState copyWith({
    List<BusinessLocationModel>? locations,
    int? selectedStoreId,
    bool clearSelectedStore = false,
    DateTime? selectedDate,
    TransactionReportModel? report,
    bool clearReport = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TransactionsState(
      locations: locations ?? this.locations,
      selectedStoreId: clearSelectedStore
          ? null
          : (selectedStoreId ?? this.selectedStoreId),
      selectedDate: selectedDate ?? this.selectedDate,
      report: clearReport ? null : (report ?? this.report),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final transactionsControllerProvider =
    StateNotifierProvider<TransactionsController, TransactionsState>((ref) {
      return TransactionsController(ref.watch(stockAuditRepositoryProvider));
    });

class TransactionsController extends StateNotifier<TransactionsState> {
  TransactionsController(this._repository) : super(const TransactionsState());

  final StockAuditRepository _repository;

  Future<void> initialize({int? preferredStoreId}) async {
    final today = DateTime.now();
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedDate: DateTime(today.year, today.month, today.day),
      clearReport: true,
    );
    try {
      final locations = await _repository.getBusinessLocations();
      final storeId = preferredStoreId ??
          (locations.length == 1 ? locations.first.id : null);
      state = state.copyWith(
        locations: locations,
        selectedStoreId: storeId,
        isLoading: false,
      );
      if (storeId != null) {
        await loadReport();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> loadReport() async {
    final storeId = state.selectedStoreId;
    final date = state.selectedDate;
    if (storeId == null || date == null) {
      state = state.copyWith(isLoading: false, clearReport: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final report = await _repository.getTransactions(
        businessLocationId: storeId,
        date: _formatDate(date),
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
    );
    await loadReport();
  }

  Future<void> setDate(DateTime date) async {
    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
    );
    await loadReport();
  }
}
