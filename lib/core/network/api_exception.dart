import 'api_auth_bridge.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => isUnauthorizedApiMessage(message, statusCode: statusCode);

  @override
  String toString() => message;
}

bool isUnauthorizedApiMessage(String message, {int? statusCode}) {
  // Only hard auth failures should force logout. Role/permission 403s
  // (e.g. SuperAdmin hitting a Darkstore-only profile) must not clear session.
  if (statusCode == 401) return true;
  if (statusCode == 403) {
    final normalized = message.trim().toLowerCase();
    return normalized.contains('invalid token') ||
        normalized.contains('token expired') ||
        normalized.contains('jwt expired') ||
        normalized.contains('not authenticated') ||
        normalized == 'unauthorized' ||
        normalized.contains('authentication required');
  }
  final normalized = message.trim().toLowerCase();
  return normalized.contains('invalid token') ||
      normalized.contains('token expired') ||
      normalized.contains('jwt expired') ||
      normalized.contains('not authenticated');
}

Never throwApiException(
  String message, {
  int? statusCode,
}) {
  final error = ApiException(message, statusCode: statusCode);
  if (error.isUnauthorized) {
    ApiAuthBridge.notifyUnauthorized();
  }
  throw error;
}
