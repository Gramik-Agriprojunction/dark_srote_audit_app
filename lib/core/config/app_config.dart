import 'dart:io';

/// Backend base URL — override with:
/// `flutter run --dart-define=API_BASE_URL=https://lens-api.gramik.in`
class AppConfig {
  AppConfig._();

  static const String liveBaseUrl = 'https://lens-api.gramik.in';
  static const String uatBaseUrl = 'https://uat-crm-backend.gramik.in';
  static const int localPort = 5000;

  /// Android emulators reach the host machine on 10.0.2.2, not localhost.
  static String get localBaseUrl {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:$localPort';
  }

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return liveBaseUrl;
  }

  /// Stock Audit Flutter app API (Dark Store only).
  static const String apiPrefix = '/mobile/stock-audit/api';

  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Gramik Darkstore app API (orders, profile, etc.)
  static const String darkStoreApiPrefix = '/api/v1';

  static String get darkStoreApiBaseUrl => '$baseUrl$darkStoreApiPrefix';

  /// Optional dev override — must match backend `MASTER_OTP` for 4-digit master login UX.
  /// `flutter run --dart-define=MASTER_OTP=5574`
  static const String masterOtp = String.fromEnvironment('MASTER_OTP');

  static const int otpLength = 5;

  /// Stock Audit testing — SMS OTP band; sirf master OTP se login.
  static const bool skipSmsOtp = true;

  static bool isMasterOtp(String otp) {
    final value = otp.trim();
    return masterOtp.isNotEmpty && value == masterOtp;
  }
}
