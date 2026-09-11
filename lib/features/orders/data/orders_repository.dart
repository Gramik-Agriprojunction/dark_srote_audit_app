import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dark_store_api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/role_helper.dart';
import '../../../core/constants/app_pagination.dart';
import 'models/order_model.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(
    ref.watch(darkStoreApiClientProvider),
    ref.watch(sessionStorageProvider),
  );
});

class OrdersRepository {
  OrdersRepository(this._client, this._storage);

  final DarkStoreApiClient _client;
  final SessionStorage _storage;

  Future<OrderListResultModel> fetchOrders({
    String? search,
    String? status,
    int page = 1,
    int limit = kAppPageSize,
    String source = 'gramik',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      'source': source,
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status.toUpperCase();
    }

    final user = await _storage.getUser();
    final storeId = await _storage.getSelectedStoreId();
    if (RoleHelper.isSuperAdminRole(user?.role?.name) &&
        storeId != null &&
        storeId > 0) {
      query['businessLocationId'] = storeId;
    }

    final json = await _client.get('/order/dark-store-order-list', query: query);
    return OrderListResultModel.fromJson(json);
  }

  Future<OrderDetailModel> fetchOrderDetail(int orderId) async {
    final query = <String, dynamic>{};
    final user = await _storage.getUser();
    final storeId = await _storage.getSelectedStoreId();
    if (RoleHelper.isSuperAdminRole(user?.role?.name) &&
        storeId != null &&
        storeId > 0) {
      query['businessLocationId'] = storeId;
    }

    final json = await _client.get(
      '/order/dark-store-order-details/$orderId',
      query: query.isEmpty ? null : query,
    );
    final data = json['data'] as Map<String, dynamic>?;
    final orderJson = data?['order'] as Map<String, dynamic>?;
    if (orderJson == null) {
      throw Exception('Order detail not found');
    }
    return OrderDetailModel.fromJson(orderJson);
  }

  Future<List<CancelReasonModel>> fetchCancelReasons() async {
    final json = await _client.get('/order/cancel-reasons');
    final raw = json['data'];
    if (raw is! List) return const [];
    return raw
        .asMap()
        .entries
        .map((e) => CancelReasonModel.fromJson(e.value, e.key))
        .where((r) => r.reason.trim().isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _superAdminStoreBody() async {
    final body = <String, dynamic>{};
    final user = await _storage.getUser();
    final storeId = await _storage.getSelectedStoreId();
    if (RoleHelper.isSuperAdminRole(user?.role?.name) &&
        storeId != null &&
        storeId > 0) {
      body['businessLocationId'] = storeId;
    }
    return body;
  }

  Future<String> markReadyToPick(int orderId) async {
    final body = await _superAdminStoreBody();
    body['order_id'] = orderId;
    final json = await _client.post(
      '/order/ready-to-pick',
      body: body,
    );
    return (json['message'] ?? json['msg'] ?? 'Order marked ready to pick')
        .toString();
  }

  Future<String> cancelOrder({
    required int orderId,
    required String reason,
  }) async {
    final body = await _superAdminStoreBody();
    body.addAll({
      'order_id': orderId,
      'status': 'cancel',
      'reason': reason,
    });
    final json = await _client.put(
      '/order/dark-store-order-update-status',
      body: body,
    );
    return (json['message'] ?? json['msg'] ?? 'Order cancelled').toString();
  }
}
