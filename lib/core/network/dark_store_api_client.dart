import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/session_storage.dart';
import 'api_exception.dart';

final darkStoreApiClientProvider = Provider<DarkStoreApiClient>((ref) {
  return DarkStoreApiClient(ref.watch(sessionStorageProvider));
});

/// Client for `/api/v1/*` endpoints (orders, darkstore profile, etc.).
class DarkStoreApiClient {
  DarkStoreApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.darkStoreApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-localization': 'en',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  late final Dio _dio;
  final SessionStorage _storage;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(path, data: body);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? json) {
    if (json == null) {
      throw ApiException('Empty response from server');
    }
    if (json['status'] == false || json['success'] == false) {
      throw ApiException(
        (json['message'] ?? json['msg'] ?? 'Something went wrong').toString(),
      );
    }
    return json;
  }

  ApiException _mapError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = (data['message'] ?? data['msg'] ?? 'Something went wrong')
          .toString();
      return ApiException(message, statusCode: e.response?.statusCode);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException('Connection error. Please try again.');
    }
    return ApiException('Something went wrong. Please try again.');
  }
}
