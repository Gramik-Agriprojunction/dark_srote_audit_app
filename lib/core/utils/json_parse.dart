import '../network/api_exception.dart';

int jsonInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse('$value') ?? fallback;
}

Map<String, dynamic> requireJsonMap(
  dynamic value, {
  String message = 'Invalid response from server',
}) {
  if (value is Map<String, dynamic>) return value;
  throw ApiException(message);
}
