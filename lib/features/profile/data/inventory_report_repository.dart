import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dark_store_api_client.dart';
import 'models/inventory_summary_model.dart';

final inventoryReportRepositoryProvider =
    Provider<InventoryReportRepository>((ref) {
  return InventoryReportRepository(ref.watch(darkStoreApiClientProvider));
});

class InventoryReportRepository {
  InventoryReportRepository(this._client);

  final DarkStoreApiClient _client;

  /// Proxies Odoo `warehouse/{id}/inventory_summary` via local backend.
  Future<InventorySummaryModel> fetchInventorySummary({
    int warehouseId = 2,
  }) async {
    final json = await _client.get(
      '/darkstore/warehouse/$warehouseId/inventory_summary',
    );
    return InventorySummaryModel.fromJson(json);
  }
}
