import '../network/api_exception.dart';

int jsonInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse('$value') ?? fallback;
}

/// Non-null when order is linked to a demand (dark store).
int? jsonDemandId(dynamic value) {
  if (value == null) return null;
  final id = int.tryParse('$value');
  if (id == null || id <= 0) return null;
  return id;
}

Map<String, dynamic>? asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

Map<String, dynamic> requireJsonMap(
  dynamic value, {
  String message = 'Invalid response from server',
}) {
  final map = asJsonMap(value);
  if (map != null) return map;
  throw ApiException(message);
}
