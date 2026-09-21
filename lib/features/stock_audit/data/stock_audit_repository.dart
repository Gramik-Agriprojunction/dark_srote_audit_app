import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/json_parse.dart';
import '../../../core/utils/role_helper.dart';
import '../data/models/business_location_model.dart';
import '../data/models/product_model.dart';
import '../data/models/stock_audit_detail_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/stock_reconciliation_model.dart';
import '../data/models/variance_model.dart';
import '../../../core/constants/app_pagination.dart';

final stockAuditRepositoryProvider = Provider<StockAuditRepository>((ref) {
  return StockAuditRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStorageProvider),
  );
});

class StockAuditRepository {
  StockAuditRepository(this._client, this._storage);

  final ApiClient _client;
  final SessionStorage _storage;

  Future<void> _ensureCanWrite() async {
    final user = await _storage.getUser();
    if (RoleHelper.isViewOnlyRole(user?.role?.name)) {
      throw ApiException(RoleHelper.viewOnlyMessage);
    }
  }

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
    return StockAuditDetailModel.fromJson(requireJsonMap(json['data']));
  }

  Future<BulkSaveResultModel> saveBulk({
    required int businessLocationId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _ensureCanWrite();
    final json = await _client.post(
      '/stock-audits/bulk',
      body: {'businessLocationId': businessLocationId, 'items': items},
    );
    return BulkSaveResultModel.fromJson(requireJsonMap(json['data']));
  }

  Future<void> saveComment({
    required int businessLocationId,
    required int productId,
    required int variantId,
    required String comment,
  }) async {
    await _ensureCanWrite();
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
    await _ensureCanWrite();
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

  Future<TransactionReportModel> getTransactions({
    required int businessLocationId,
    String? date,
  }) async {
    final json = await _client.get(
      '/transactions',
      query: {
        'business_location_id': businessLocationId,
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
    return TransactionReportModel.fromJson(requireJsonMap(json['data']));
  }

  Future<StockReconciliationReportModel> getStockReconciliation({
    required int businessLocationId,
    String status = 'ALL',
    String search = '',
    int page = 1,
    int limit = kAppPageSize,
  }) async {
    final json = await _client.get(
      '/stock-reconciliation',
      query: {
        'business_location_id': businessLocationId,
        'status': status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'limit': limit,
      },
    );
    return StockReconciliationReportModel.fromJson(requireJsonMap(json['data']));
  }

  Future<VarianceReportModel> getVariance({
    required int businessLocationId,
    String type = 'ALL',
    int page = 1,
    int limit = kAppPageSize,
  }) async {
    final json = await _client.get(
      '/variance',
      query: {
        'business_location_id': businessLocationId,
        'type': type,
        'page': page,
        'limit': limit,
      },
    );
    return VarianceReportModel.fromJson(requireJsonMap(json['data']));
  }
}
