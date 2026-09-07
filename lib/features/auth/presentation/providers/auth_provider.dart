import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_auth_bridge.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/role_helper.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.error,
  });

  final AuthStatus status;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.watch(authRepositoryProvider),
      ref.watch(sessionStorageProvider),
    );
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._storage)
    : super(const AuthState(status: AuthStatus.unknown)) {
    ApiAuthBridge.register(logout);
    _restoreSession();
  }

  final AuthRepository _repository;
  final SessionStorage _storage;
  Timer? _inactivityTimer;

  Future<void> _restoreSession() async {
    final token = await _storage.getAccessToken();
    final user = await _storage.getUser();
    if (token != null && token.isNotEmpty && user != null) {
      if (!RoleHelper.isDarkStoreRole(user.role?.name)) {
        await logout();
        return;
      }
      final lastActivity = await _storage.getLastActivity();
      if (lastActivity != null &&
          DateTime.now().difference(lastActivity) >
              AppConfig.inactivityTimeout) {
        await logout();
        return;
      }
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _startInactivityTimer();
      return;
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void touchActivity() {
    unawaited(_storage.touchActivity());
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(AppConfig.inactivityTimeout, () {
      logout();
    });
  }

  Future<String> sendOtp(String mobile) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final message = await _repository.sendOtp(mobile);
      state = state.copyWith(isLoading: false);
      return message;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> verifyOtp({required String mobile, required String otp}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.verifyOtp(mobile: mobile, otp: otp);
      if (!RoleHelper.isDarkStoreRole(result.user.role?.name)) {
        await _storage.clearSession();
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: 'Sirf Dark Store users is app se login kar sakte hain.',
        );
        return;
      }
      await _storage.saveSession(token: result.token, user: result.user);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      _startInactivityTimer();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    _inactivityTimer?.cancel();
    await _storage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
