import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dark_store_api_client.dart';
import 'models/order_model.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(darkStoreApiClientProvider));
});

class OrdersRepository {
  OrdersRepository(this._client);

  final DarkStoreApiClient _client;

  Future<OrderListResultModel> fetchOrders({
    String? search,
    String? status,
    int page = 1,
    int limit = 30,
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

    final json = await _client.get('/order/dark-store-order-list', query: query);
    return OrderListResultModel.fromJson(json);
  }

  Future<OrderDetailModel> fetchOrderDetail(int orderId) async {
    final json = await _client.get('/order/dark-store-order-details/$orderId');
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

  Future<String> markReadyToPick(int orderId) async {
    final json = await _client.post(
      '/order/ready-to-pick',
      body: {'order_id': orderId},
    );
    return (json['message'] ?? json['msg'] ?? 'Order marked ready to pick')
        .toString();
  }

  Future<String> cancelOrder({
    required int orderId,
    required String reason,
  }) async {
    final json = await _client.put(
      '/order/dark-store-order-update-status',
      body: {
        'order_id': orderId,
        'status': 'cancel',
        'reason': reason,
      },
    );
    return (json['message'] ?? json['msg'] ?? 'Order cancelled').toString();
  }
}
