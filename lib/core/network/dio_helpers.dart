import 'dart:io';

import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Transient network failures that should be retried silently.
bool isTransientDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    case DioExceptionType.unknown:
      return e.error is SocketException || e.error is HttpException;
    case DioExceptionType.badResponse:
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
      return false;
    default:
      // e.g. transformTimeout on newer Dio versions
      return e.type.name.toLowerCase().contains('timeout');
  }
}

/// Retries transient Dio failures with short backoff (mobile network flaps).
class RetryOnConnectionInterceptor extends Interceptor {
  RetryOnConnectionInterceptor(
    this._dio, {
    this.maxRetries = 2,
  });

  final Dio _dio;
  final int maxRetries;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;
    if (!isTransientDioError(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    final nextAttempt = attempt + 1;
    err.requestOptions.extra['retry_attempt'] = nextAttempt;
    await Future<void>.delayed(Duration(milliseconds: 350 * nextAttempt));

    try {
      final response = await _dio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return onError(e, handler);
    }
  }
}

ApiException mapDioException(DioException e) {
  if (e.type == DioExceptionType.cancel) {
    return ApiException('Request cancelled');
  }

  final data = e.response?.data;
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final message =
        (map['message'] ?? map['msg'] ?? 'Something went wrong').toString();
    return ApiException(message, statusCode: e.response?.statusCode);
  }

  if (isTransientDioError(e)) {
    return ApiException('Connection error. Please try again.');
  }

  return ApiException('Something went wrong. Please try again.');
}

Never throwMappedDioException(DioException e) {
  final mapped = mapDioException(e);
  if (mapped.isUnauthorized) {
    throwApiException(mapped.message, statusCode: mapped.statusCode);
  }
  throw mapped;
}
