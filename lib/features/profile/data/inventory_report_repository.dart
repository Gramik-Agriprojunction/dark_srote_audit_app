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

  /// Proxies Odoo `warehouse/{id}/inventory_summary` via CRM backend.
  /// [warehouseId] = logged-in / selected Dark Store warehouse id.
  Future<InventorySummaryModel> fetchInventorySummary({
    required int warehouseId,
  }) async {
    final json = await _client.get(
      '/darkstore/warehouse/$warehouseId/inventory_summary',
    );
    return InventorySummaryModel.fromJson(json);
  }
}
