import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_model.dart';
import '../../data/profile_repository.dart';

class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoggingOut = false,
    this.error,
  });

  final ProfileModel? profile;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoggingOut;
  final String? error;

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoggingOut,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repo) : super(const ProfileState());

  final ProfileRepository _repo;

  Future<void> load({bool refresh = false}) async {
    state = state.copyWith(
      isLoading: !refresh && state.profile == null,
      isRefreshing: refresh,
      clearError: true,
    );
    try {
      final profile = await _repo.fetchProfile();
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logoutRemote() async {
    state = state.copyWith(isLoggingOut: true);
    await _repo.logout();
    state = state.copyWith(isLoggingOut: false);
  }
}

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, ProfileState>((ref) {
  return ProfileController(ref.watch(profileRepositoryProvider));
});
