import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.selectedStoreId,
    this.selectedStoreLabel,
    this.isLoading = false,
    this.error,
  });

  final AuthStatus status;
  final UserModel? user;
  final int? selectedStoreId;
  final String? selectedStoreLabel;
  final bool isLoading;
  final String? error;

  bool get needsWarehouseSelection =>
      status == AuthStatus.authenticated &&
      RoleHelper.isSuperAdminRole(user?.role?.name) &&
      (selectedStoreId == null || selectedStoreId! <= 0);

  /// Darkstore-style greeting: warehouse name for SuperAdmin, else user name.
  String get headerGreeting {
    final store = (selectedStoreLabel ?? '').trim();
    if (RoleHelper.isSuperAdminRole(user?.role?.name) && store.isNotEmpty) {
      return 'Namaste, $store';
    }
    final name = (user?.displayName ?? 'User').trim();
    return 'Namaste, ${name.isEmpty ? 'User' : name}';
  }

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    int? selectedStoreId,
    String? selectedStoreLabel,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSelectedStoreId = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      selectedStoreId: clearSelectedStoreId
          ? null
          : (selectedStoreId ?? this.selectedStoreId),
      selectedStoreLabel: clearSelectedStoreId
          ? null
          : (selectedStoreLabel ?? this.selectedStoreLabel),
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

  Future<void> _restoreSession() async {
    final token = await _storage.getAccessToken();
    final user = await _storage.getUser();
    if (token != null && token.isNotEmpty && user != null) {
      if (!RoleHelper.isStockAuditAllowedRole(user.role?.name)) {
        await logout();
        return;
      }
      final storeId = await _storage.getSelectedStoreId();
      final storeLabel = await _storage.getSelectedStoreLabel();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        selectedStoreId: storeId,
        selectedStoreLabel: storeLabel,
      );
      return;
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Kept for call sites; StockAudit does not auto-logout on inactivity.
  void touchActivity() {}

  Future<({String message, bool otpSent})> sendOtp(String mobile) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.sendOtp(mobile);
      state = state.copyWith(isLoading: false);
      return result;
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
      if (!RoleHelper.isStockAuditAllowedRole(result.user.role?.name)) {
        await _storage.clearSession();
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error:
              'Sirf Dark Store ya SuperAdmin is app se login kar sakte hain.',
        );
        return;
      }
      await _storage.saveSession(token: result.token, user: result.user);
      // SuperAdmin must pick warehouse; clear any stale store from prior session.
      if (RoleHelper.isSuperAdminRole(result.user.role?.name)) {
        await _storage.saveSelectedStoreId(null);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.user,
          selectedStoreId: null,
          selectedStoreLabel: null,
        );
      } else {
        final storeId = await _storage.getSelectedStoreId();
        final storeLabel = await _storage.getSelectedStoreLabel();
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.user,
          selectedStoreId: storeId,
          selectedStoreLabel: storeLabel,
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> setSelectedStoreId(int storeId, {String? label}) async {
    await _storage.saveSelectedStoreId(storeId, label: label);
    final resolvedLabel =
        (label ?? await _storage.getSelectedStoreLabel())?.trim();
    state = state.copyWith(
      selectedStoreId: storeId,
      selectedStoreLabel:
          (resolvedLabel != null && resolvedLabel.isNotEmpty)
              ? resolvedLabel
              : state.selectedStoreLabel,
    );
  }

  Future<void> clearSelectedStore() async {
    await _storage.saveSelectedStoreId(null);
    state = state.copyWith(clearSelectedStoreId: true);
  }

  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
