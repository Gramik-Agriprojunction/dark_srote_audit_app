import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
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

class DcInboundOperation {
  const DcInboundOperation({
    required this.productId,
    required this.quantity,
  });

  final int productId;
  final int quantity;
}

class DcFetchQuery {
  const DcFetchQuery({
    this.type,
    this.status,
    this.direction,
  });

  final String? type;
  final String? status;
  final String? direction;

  /// Incoming / Received
  static const incoming = DcFetchQuery(type: 'in');

  /// Outgoing pending: status=ready&direction=outgoing
  static const outgoing = DcFetchQuery(
    status: 'ready',
    direction: 'outgoing',
  );

  /// Transferred: status=done&direction=outgoing
  static const transferred = DcFetchQuery(
    status: 'done',
    direction: 'outgoing',
  );

  String get key {
    if (status == 'done' && direction == 'outgoing') return 'transferred';
    if (status == 'ready' && direction == 'outgoing') return 'out';
    if (type == 'out') return 'out';
    return 'in';
  }

  Map<String, dynamic> toQuery() {
    return {
      if (type != null && type!.isNotEmpty) 'type': type,
      if (status != null && status!.isNotEmpty) 'status': status,
      if (direction != null && direction!.isNotEmpty) 'direction': direction,
    };
  }
}

class DcRepository {
  DcRepository(this._client, this._storage);

  final DarkStoreApiClient _client;
  final SessionStorage _storage;

  Future<void> _ensureCanWrite() async {
    final user = await _storage.getUser();
    if (RoleHelper.isViewOnlyRole(user?.role?.name)) {
      throw ApiException(RoleHelper.viewOnlyMessage);
    }
  }

  Future<DcTransferListModel> fetchTransfers({
    int? warehouseId,
    DcFetchQuery query = DcFetchQuery.incoming,
  }) async {
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
    final json = await _client.get(
      path,
      query: query.toQuery(),
    );
    return DcTransferListModel.fromJson(json);
  }

  Future<String> validateInboundProducts({
    required int transferId,
    required int inboundPickingId,
    required List<DcInboundOperation> operations,
  }) async {
    await _ensureCanWrite();
    final json = await _client.post(
      '/darkstore/inter-branch-transfers/$transferId/inbound/$inboundPickingId/validate',
      body: {
        'operations': operations
            .map(
              (row) => {
                'product_id': row.productId,
                'quantity': row.quantity,
              },
            )
            .toList(),
      },
    );
    return (json['message'] ?? 'Saved successfully').toString();
  }

  Future<String> validateOutboundProduct({
    required int transferId,
    required int outboundPickingId,
    required int productId,
    required int quantity,
  }) async {
    await _ensureCanWrite();
    final json = await _client.post(
      '/darkstore/inter-branch-transfers/$transferId/outbound/$outboundPickingId/validate',
      body: {
        'operations': [
          {'product_id': productId, 'quantity': quantity},
        ],
      },
    );
    return (json['message'] ?? 'Saved successfully').toString();
  }
}
