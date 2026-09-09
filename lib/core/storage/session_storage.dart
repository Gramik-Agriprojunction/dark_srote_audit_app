import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/user_model.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  throw UnimplementedError('SessionStorage must be overridden in main.dart');
});

class SessionStorage {
  SessionStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _tokenKey = 'gramik_access_token';
  static const _userKey = 'gramik_user';
  static const _storeIdKey = 'gramik_mobile_store_id';
  static const _storeLabelKey = 'gramik_mobile_store_label';
  static const _lastActivityKey = 'gramik_last_activity_ms';
  static const _themeModeKey = 'app_theme_mode';

  Future<String?> getAccessToken() async => _prefs.getString(_tokenKey);

  Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    await touchActivity();
  }

  Future<UserModel?> getUser() async {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    await _prefs.remove(_storeIdKey);
    await _prefs.remove(_storeLabelKey);
    await _prefs.remove(_lastActivityKey);
  }

  Future<int?> getSelectedStoreId() async {
    final value = _prefs.getString(_storeIdKey);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<String?> getSelectedStoreLabel() async {
    final value = _prefs.getString(_storeLabelKey);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> saveSelectedStoreId(int? storeId, {String? label}) async {
    if (storeId == null) {
      await _prefs.remove(_storeIdKey);
      await _prefs.remove(_storeLabelKey);
      return;
    }
    await _prefs.setString(_storeIdKey, storeId.toString());
    final trimmed = label?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await _prefs.setString(_storeLabelKey, trimmed);
    }
  }

  Future<void> touchActivity() async {
    await _prefs.setInt(
      _lastActivityKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<DateTime?> getLastActivity() async {
    final ms = _prefs.getInt(_lastActivityKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  String? getThemeMode() => _prefs.getString(_themeModeKey);

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }
}
