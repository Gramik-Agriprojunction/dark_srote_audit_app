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
  if (statusCode == 401 || statusCode == 403) return true;
  final normalized = message.trim().toLowerCase();
  return normalized.contains('invalid token') ||
      normalized.contains('token expired') ||
      normalized.contains('jwt expired') ||
      normalized.contains('unauthorized') ||
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
