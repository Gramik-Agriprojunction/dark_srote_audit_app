import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dark_store_api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/role_helper.dart';
import 'models/dc_transfer_model.dart';

final dcRepositoryProvider = Provider<DcRepository>((ref) {
  return DcRepository(
    ref.watch(darkStoreApiClientProvider),
    ref.watch(sessionStorageProvider),
  );
});

class DcRepository {
  DcRepository(this._client, this._storage);

  final DarkStoreApiClient _client;
  final SessionStorage _storage;

  Future<DcTransferListModel> fetchTransfers({int? warehouseId}) async {
    var id = warehouseId;
    if (id == null || id <= 0) {
      final user = await _storage.getUser();
      final storeId = await _storage.getSelectedStoreId();
      if (RoleHelper.isSuperAdminRole(user?.role?.name) &&
          storeId != null &&
          storeId > 0) {
        id = storeId;
      }
    }
    final path = id != null && id > 0
        ? '/darkstore/inter-branch-transfers/warehouse/$id'
        : '/darkstore/inter-branch-transfers';
    final json = await _client.get(path);
    return DcTransferListModel.fromJson(json);
  }

  Future<String> validateInboundProduct({
    required int transferId,
    required int inboundPickingId,
    required int productId,
    required int quantity,
  }) async {
    final json = await _client.post(
      '/darkstore/inter-branch-transfers/$transferId/inbound/$inboundPickingId/validate',
      body: {
        'operations': [
          {'product_id': productId, 'quantity': quantity},
        ],
      },
    );
    return (json['message'] ?? 'Saved successfully').toString();
  }
}
