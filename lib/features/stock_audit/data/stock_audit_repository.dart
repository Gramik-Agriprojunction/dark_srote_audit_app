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
import '../data/models/dse_attendance_model.dart';
import '../data/models/dse_audit_report_model.dart';
import '../data/models/product_stock_history_model.dart';
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

  Future<DseAttendanceReport> getDseAttendance({
    required int businessLocationId,
    required String month,
    int? employeeUserId,
  }) async {
    final json = await _client.get(
      '/dse-attendance',
      query: {
        'business_location_id': businessLocationId,
        'month': month,
        if (employeeUserId != null && employeeUserId > 0)
          'employee_user_id': employeeUserId,
      },
    );
    return DseAttendanceReport.fromJson(requireJsonMap(json['data']));
  }

  Future<DseAuditReport> getDseAuditReport({
    required int businessLocationId,
    required String month,
    String search = '',
    String status = 'all',
    int? categoryId,
    String? auditDate,
    int page = 1,
    int limit = 20,
  }) async {
    final json = await _client.get(
      '/dse-audit-report',
      query: {
        'business_location_id': businessLocationId,
        'month': month,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status.trim().isNotEmpty && status != 'all') 'status': status,
        if (categoryId != null && categoryId > 0) 'category_id': categoryId,
        if (auditDate != null && auditDate.trim().isNotEmpty)
          'audit_date': auditDate.trim(),
        'page': page,
        'limit': limit,
      },
    );
    return DseAuditReport.fromJson(requireJsonMap(json['data']));
  }

  Future<ProductStockHistoryReport> getProductStockHistory({
    required int businessLocationId,
    required int variantId,
    required String dateFrom,
    required String dateTo,
    int page = 1,
    int limit = 200,
  }) async {
    final json = await _client.get(
      '/product-stock-history',
      query: {
        'business_location_id': businessLocationId,
        'variant_id': variantId,
        'date_from': dateFrom,
        'date_to': dateTo,
        'page': page,
        'limit': limit,
      },
    );
    return ProductStockHistoryReport.fromJson(requireJsonMap(json['data']));
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
