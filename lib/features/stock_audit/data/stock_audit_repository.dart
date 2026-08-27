import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/models/business_location_model.dart';
import '../data/models/product_model.dart';
import '../data/models/stock_audit_detail_model.dart';

final stockAuditRepositoryProvider = Provider<StockAuditRepository>((ref) {
  return StockAuditRepository(ref.watch(apiClientProvider));
});

class StockAuditRepository {
  StockAuditRepository(this._client);

  final ApiClient _client;

  Future<List<BusinessLocationModel>> getBusinessLocations() async {
    final json = await _client.get('/business-locations');
    final data = json['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(BusinessLocationModel.fromJson)
        .toList();
  }

  Future<List<ProductModel>> getLocationProducts(int businessLocationId) async {
    final json = await _client.get(
      '/business-locations/$businessLocationId/products',
    );
    final data = json['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<StockAuditDetailModel> getAuditDetail({
    required int businessLocationId,
    required int productId,
    required int variantId,
  }) async {
    final json = await _client.get(
      '/stock-audits/detail',
      query: {
        'business_location_id': businessLocationId,
        'product_id': productId,
        'variant_id': variantId,
      },
    );
    return StockAuditDetailModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<BulkSaveResultModel> saveBulk({
    required int businessLocationId,
    required List<Map<String, dynamic>> items,
  }) async {
    final json = await _client.post(
      '/stock-audits/bulk',
      body: {'businessLocationId': businessLocationId, 'items': items},
    );
    return BulkSaveResultModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> saveComment({
    required int businessLocationId,
    required int productId,
    required int variantId,
    required String comment,
  }) async {
    await _client.post(
      '/stock-audits/comment',
      body: {
        'businessLocationId': businessLocationId,
        'productId': productId,
        'variantId': variantId,
        'comment': comment,
      },
    );
  }

  Future<bool> saveDiscrepancy({
    required int businessLocationId,
    required int productId,
    required int variantId,
    required int damageQty,
    String? damageComment,
  }) async {
    final json = await _client.post(
      '/stock-audits/discrepancy',
      body: {
        'businessLocationId': businessLocationId,
        'productId': productId,
        'variantId': variantId,
        'damageQty': damageQty,
        'damageComment': damageComment,
      },
    );
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data['wasUpdated'] == true;
    }
    return false;
  }
}
