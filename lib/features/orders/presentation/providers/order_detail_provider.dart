import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/order_model.dart';
import '../../data/orders_repository.dart';

class OrderDetailState {
  const OrderDetailState({
    this.order,
    this.cancelReasons = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isActionLoading = false,
    this.error,
    this.successMessage,
  });

  final OrderDetailModel? order;
  final List<CancelReasonModel> cancelReasons;
  final bool isLoading;
  final bool isRefreshing;
  final bool isActionLoading;
  final String? error;
  final String? successMessage;

  OrderDetailState copyWith({
    OrderDetailModel? order,
    List<CancelReasonModel>? cancelReasons,
    bool? isLoading,
    bool? isRefreshing,
    bool? isActionLoading,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return OrderDetailState(
      order: order ?? this.order,
      cancelReasons: cancelReasons ?? this.cancelReasons,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      error: clearMessages ? null : (error ?? this.error),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

final orderDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailController, OrderDetailState, int>((ref, orderId) {
      return OrderDetailController(ref.watch(ordersRepositoryProvider), orderId);
    });

class OrderDetailController extends StateNotifier<OrderDetailState> {
  OrderDetailController(this._repository, this._orderId)
    : super(const OrderDetailState());

  final OrdersRepository _repository;
  final int _orderId;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true, clearMessages: true);
    } else {
      state = state.copyWith(isLoading: true, clearMessages: true);
    }

    try {
      final order = await _repository.fetchOrderDetail(_orderId);
      state = state.copyWith(
        order: order,
        isLoading: false,
        isRefreshing: false,
        clearMessages: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Connection error. Please try again.',
      );
    }
  }

  Future<void> loadCancelReasons() async {
    if (state.cancelReasons.isNotEmpty) return;
    try {
      final reasons = await _repository.fetchCancelReasons();
      state = state.copyWith(cancelReasons: reasons);
    } catch (_) {
      // Non-blocking — user can still type if list fails.
    }
  }

  Future<bool> markReadyToPick() async {
    state = state.copyWith(isActionLoading: true, clearMessages: true);
    try {
      final message = await _repository.markReadyToPick(_orderId);
      await load(refresh: true);
      state = state.copyWith(
        isActionLoading: false,
        successMessage: message,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        error: 'Connection error. Please try again.',
      );
      return false;
    }
  }

  Future<bool> cancelOrder(String reason) async {
    state = state.copyWith(isActionLoading: true, clearMessages: true);
    try {
      final message = await _repository.cancelOrder(
        orderId: _orderId,
        reason: reason,
      );
      await load(refresh: true);
      state = state.copyWith(
        isActionLoading: false,
        successMessage: message,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        error: 'Connection error. Please try again.',
      );
      return false;
    }
  }
}
