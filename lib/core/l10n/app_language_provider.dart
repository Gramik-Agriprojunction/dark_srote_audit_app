import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../storage/session_storage.dart';
import 'app_language.dart';
import 'app_strings.dart';

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage>((ref) {
  return AppLanguageController(ref.watch(sessionStorageProvider));
});

final appStringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(appLanguageProvider));
});

/// Store line under page title in ModuleHeader (bold). No "Namaste," prefix.
final headerGreetingProvider = Provider<String>((ref) {
  final auth = ref.watch(authControllerProvider);
  return (auth.selectedStoreLabel ?? '').trim();
});

class AppLanguageController extends StateNotifier<AppLanguage> {
  AppLanguageController(this._storage)
      : super(AppLanguage.fromStorage(_storage.getLanguage()));

  final SessionStorage _storage;

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;
    await _storage.saveLanguage(language.storageValue);
  }
}
