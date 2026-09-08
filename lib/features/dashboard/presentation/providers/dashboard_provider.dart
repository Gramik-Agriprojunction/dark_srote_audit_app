import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dashboard_repository.dart';
import '../../data/models/dashboard_model.dart';

class DashboardState {
  const DashboardState({
    this.data,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  final DashboardModel? data;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  DashboardState copyWith({
    DashboardModel? data,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._repo) : super(const DashboardState());

  final DashboardRepository _repo;

  Future<void> load({bool refresh = false, int attempt = 0}) async {
    state = state.copyWith(
      isLoading: !refresh && state.data == null,
      isRefreshing: refresh,
      clearError: true,
    );
    try {
      final data = await _repo.fetchDashboard();
      state = state.copyWith(
        data: data,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      final isConnection = message.toLowerCase().contains('connection');
      if (isConnection && attempt < 3) {
        await Future<void>.delayed(Duration(milliseconds: 800 * (attempt + 1)));
        return load(refresh: refresh || state.data != null, attempt: attempt + 1);
      }
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: message,
      );
    }
  }
}

final dashboardControllerProvider =
    StateNotifierProvider.autoDispose<DashboardController, DashboardState>(
  (ref) => DashboardController(ref.watch(dashboardRepositoryProvider)),
);
