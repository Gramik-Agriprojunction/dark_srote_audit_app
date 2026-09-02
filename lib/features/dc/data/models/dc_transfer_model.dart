class DcWarehouseModel {
  const DcWarehouseModel({
    required this.id,
    this.name,
    this.code,
  });

  final int id;
  final String? name;
  final String? code;

  factory DcWarehouseModel.fromJson(Map<String, dynamic> json) {
    return DcWarehouseModel(
      id: _int(json['id']),
      name: json['name']?.toString(),
      code: json['code']?.toString(),
    );
  }
}

class DcSummaryModel {
  const DcSummaryModel({
    required this.incomingTransfers,
    required this.receivedTransfers,
    required this.outgoingTransfers,
    required this.totalTransfers,
  });

  final int incomingTransfers;
  final int receivedTransfers;
  final int outgoingTransfers;
  final int totalTransfers;

  factory DcSummaryModel.fromJson(Map<String, dynamic> json) {
    return DcSummaryModel(
      incomingTransfers: _int(json['incomingTransfers'] ?? json['incoming_transfers']),
      receivedTransfers: _int(json['receivedTransfers'] ?? json['received_transfers']),
      outgoingTransfers: _int(json['outgoingTransfers'] ?? json['outgoing_transfers']),
      totalTransfers: _int(json['totalTransfers'] ?? json['total_transfers']),
    );
  }
}

class DcLocationRefModel {
  const DcLocationRefModel({
    this.warehouseId,
    this.warehouse,
    this.locationId,
    this.location,
  });

  final int? warehouseId;
  final String? warehouse;
  final int? locationId;
  final String? location;

  factory DcLocationRefModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DcLocationRefModel();
    return DcLocationRefModel(
      warehouseId: _intOrNull(json['warehouse_id']),
      warehouse: json['warehouse']?.toString(),
      locationId: _intOrNull(json['location_id']),
      location: json['location']?.toString(),
    );
  }
}

class DcProductLineModel {
  const DcProductLineModel({
    required this.productId,
    required this.productName,
    required this.requestedQty,
    required this.actualQty,
    required this.incomingQty,
    required this.receivedQty,
    required this.remainingQty,
    required this.outgoingQty,
    required this.uom,
  });

  final int productId;
  final String productName;
  final num requestedQty;
  final num actualQty;
  final num incomingQty;
  final num receivedQty;
  final num remainingQty;
  final num outgoingQty;
  final String uom;

  num get totalQty => incomingQty;

  factory DcProductLineModel.fromJson(Map<String, dynamic> json) {
    return DcProductLineModel(
      productId: _int(json['productId'] ?? json['product_id']),
      productName: (json['productName'] ?? json['product'] ?? 'Product').toString(),
      requestedQty: _num(json['requestedQty'] ?? json['requested_quantity']),
      actualQty: _num(json['actualQty'] ?? json['actual_quantity']),
      incomingQty: _num(
        json['incomingQty'] ??
            json['incoming_qty'] ??
            json['demand_quantity'] ??
            json['demandQuantity'],
      ),
      receivedQty: _num(
        json['receivedQty'] ??
            json['received_qty'] ??
            json['received_quantity'] ??
            json['receivedQuantity'],
      ),
      remainingQty: _num(
        json['remainingQty'] ??
            json['remaining_qty'] ??
            json['remaining_quantity'] ??
            json['remainingQuantity'],
      ),
      outgoingQty: _num(json['outgoingQty'] ?? json['outgoing_qty']),
      uom: (json['uom'] ?? 'Units').toString(),
    );
  }
}

class DcTransferModel {
  const DcTransferModel({
    required this.transferId,
    required this.reference,
    required this.state,
    required this.ibtStatus,
    required this.direction,
    required this.incomingQty,
    required this.receivedQty,
    required this.remainingQty,
    required this.outgoingQty,
    required this.totalQty,
    required this.productCount,
    required this.products,
    this.inboundPickingId,
    this.type,
    this.from,
    this.to,
  });

  final int transferId;
  final String reference;
  final String state;
  final String ibtStatus;
  final String direction;
  final num incomingQty;
  final num receivedQty;
  final num remainingQty;
  final num outgoingQty;
  final num totalQty;
  final int productCount;
  final List<DcProductLineModel> products;
  final int? inboundPickingId;
  final String? type;
  final DcLocationRefModel? from;
  final DcLocationRefModel? to;

  factory DcTransferModel.fromJson(Map<String, dynamic> json) {
    final productsRaw = json['products'];
    return DcTransferModel(
      transferId: _int(json['transferId'] ?? json['transfer_id']),
      reference: (json['reference'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      ibtStatus: (json['ibtStatus'] ?? json['ibt_status'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
      incomingQty: _num(json['incomingQty'] ?? json['incoming_qty']),
      receivedQty: _num(json['receivedQty'] ?? json['received_qty']),
      remainingQty: _num(json['remainingQty'] ?? json['remaining_qty']),
      outgoingQty: _num(json['outgoingQty'] ?? json['outgoing_qty']),
      totalQty: _num(json['totalQty'] ?? json['total_qty'] ?? json['incomingQty']),
      productCount: _int(json['productCount'] ?? json['product_count']),
      inboundPickingId: _intOrNull(
        json['inboundPickingId'] ?? json['inbound_picking_id'],
      ),
      type: json['type']?.toString(),
      from: DcLocationRefModel.fromJson(json['from'] as Map<String, dynamic>?),
      to: DcLocationRefModel.fromJson(json['to'] as Map<String, dynamic>?),
      products: productsRaw is List
          ? productsRaw
              .whereType<Map<String, dynamic>>()
              .map(DcProductLineModel.fromJson)
              .toList()
          : const [],
    );
  }
}

class DcTransferListModel {
  const DcTransferListModel({
    required this.warehouse,
    required this.summary,
    required this.transfers,
  });

  final DcWarehouseModel warehouse;
  final DcSummaryModel summary;
  final List<DcTransferModel> transfers;

  factory DcTransferListModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final transfersRaw = data['transfers'] ?? data['incoming'];
    return DcTransferListModel(
      warehouse: DcWarehouseModel.fromJson(
        (data['warehouse'] as Map<String, dynamic>?) ?? const {},
      ),
      summary: DcSummaryModel.fromJson(
        (data['summary'] as Map<String, dynamic>?) ?? const {},
      ),
      transfers: transfersRaw is List
          ? transfersRaw
              .whereType<Map<String, dynamic>>()
              .map(DcTransferModel.fromJson)
              .toList()
          : const [],
    );
  }
}

int _int(dynamic v) {
  if (v is int) return v;
  return int.tryParse('$v') ?? 0;
}

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  final n = int.tryParse('$v');
  return n;
}

num _num(dynamic v) {
  if (v is num) return v;
  return num.tryParse('$v') ?? 0;
}
