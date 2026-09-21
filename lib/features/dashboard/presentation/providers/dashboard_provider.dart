import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
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
  int _loadGeneration = 0;

  Future<void> load({bool refresh = false}) async {
    final generation = ++_loadGeneration;
    state = state.copyWith(
      isLoading: !refresh && state.data == null,
      isRefreshing: refresh,
      clearError: true,
    );
    try {
      final data = await _repo.fetchDashboard();
      if (generation != _loadGeneration) return;
      state = state.copyWith(
        data: data,
        isLoading: false,
        isRefreshing: false,
      );
    } on ApiException catch (e) {
      if (generation != _loadGeneration) return;
      if (e.message == 'Request cancelled') return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.message,
      );
    } catch (e) {
      if (generation != _loadGeneration) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

/// Kept alive across bottom-nav switches so Home is not re-fetched (and
/// flaky) every time the user leaves and returns to the tab.
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>(
  (ref) => DashboardController(ref.watch(dashboardRepositoryProvider)),
);
