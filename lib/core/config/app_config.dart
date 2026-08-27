/// Backend base URL — override for local dev:
/// `flutter run --dart-define=API_BASE_URL=http://localhost:5000`
class AppConfig {
  AppConfig._();

  static const String liveBaseUrl = 'https://lens-api.gramik.in';
  static const String localBaseUrl = 'http://localhost:5000';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return liveBaseUrl;
  }

  /// Stock Audit Flutter app API (Dark Store only).
  static const String apiPrefix = '/mobile/stock-audit/api';

  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  static const Duration inactivityTimeout = Duration(hours: 1);
}
