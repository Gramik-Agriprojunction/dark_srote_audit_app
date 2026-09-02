import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dark_store_api_client.dart';
import 'models/dc_transfer_model.dart';

final dcRepositoryProvider = Provider<DcRepository>((ref) {
  return DcRepository(ref.watch(darkStoreApiClientProvider));
});

class DcRepository {
  DcRepository(this._client);

  final DarkStoreApiClient _client;

  Future<DcTransferListModel> fetchTransfers({int? warehouseId}) async {
    final path = warehouseId != null && warehouseId > 0
        ? '/darkstore/inter-branch-transfers/warehouse/$warehouseId'
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
