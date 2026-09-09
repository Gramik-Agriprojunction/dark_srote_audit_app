import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../storage/session_storage.dart';

final appThemeModeProvider =
    StateNotifierProvider<AppThemeModeController, AppThemeMode>((ref) {
  return AppThemeModeController(ref.watch(sessionStorageProvider));
});

class AppThemeModeController extends StateNotifier<AppThemeMode> {
  AppThemeModeController(this._storage)
      : super(AppThemeMode.fromStorage(_storage.getThemeMode())) {
    AppColors.apply(state);
  }

  final SessionStorage _storage;

  Future<void> setMode(AppThemeMode mode) async {
    if (state == mode) return;
    AppColors.apply(mode);
    state = mode;
    await _storage.saveThemeMode(mode.storageValue);
  }
}
