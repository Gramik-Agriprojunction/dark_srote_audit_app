class TransactionSummary {
  const TransactionSummary({
    required this.pickupOrders,
    required this.rtoDeliveredOrders,
  });

  final int pickupOrders;
  final int rtoDeliveredOrders;

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      pickupOrders: json['pickupOrders'] is int
          ? json['pickupOrders'] as int
          : int.tryParse('${json['pickupOrders']}') ?? 0,
      rtoDeliveredOrders: json['rtoDeliveredOrders'] is int
          ? json['rtoDeliveredOrders'] as int
          : int.tryParse('${json['rtoDeliveredOrders']}') ?? 0,
    );
  }
}

class TransactionProductRow {
  const TransactionProductRow({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantLabel,
    required this.sku,
    required this.pickupQty,
    required this.rtoDeliveredQty,
    required this.totalQty,
  });

  final int productId;
  final String productName;
  final int variantId;
  final String variantLabel;
  final String sku;
  final int pickupQty;
  final int rtoDeliveredQty;
  final int totalQty;

  factory TransactionProductRow.fromJson(Map<String, dynamic> json) {
    return TransactionProductRow(
      productId: json['productId'] is int
          ? json['productId'] as int
          : int.tryParse('${json['productId']}') ?? 0,
      productName: (json['productName'] ?? 'Product').toString(),
      variantId: json['variantId'] is int
          ? json['variantId'] as int
          : int.tryParse('${json['variantId']}') ?? 0,
      variantLabel: (json['variantLabel'] ?? json['sku'] ?? 'Variant')
          .toString(),
      sku: (json['sku'] ?? '').toString(),
      pickupQty: json['pickupQty'] is int
          ? json['pickupQty'] as int
          : int.tryParse('${json['pickupQty']}') ?? 0,
      rtoDeliveredQty: json['rtoDeliveredQty'] is int
          ? json['rtoDeliveredQty'] as int
          : int.tryParse('${json['rtoDeliveredQty']}') ?? 0,
      totalQty: json['totalQty'] is int
          ? json['totalQty'] as int
          : int.tryParse('${json['totalQty']}') ?? 0,
    );
  }
}

class TransactionReportModel {
  const TransactionReportModel({
    required this.date,
    required this.summary,
    required this.products,
  });

  final String date;
  final TransactionSummary summary;
  final List<TransactionProductRow> products;

  factory TransactionReportModel.fromJson(Map<String, dynamic> json) {
    final summaryRaw = json['summary'];
    final productsRaw = json['products'];
    return TransactionReportModel(
      date: (json['date'] ?? '').toString(),
      summary: summaryRaw is Map<String, dynamic>
          ? TransactionSummary.fromJson(summaryRaw)
          : const TransactionSummary(pickupOrders: 0, rtoDeliveredOrders: 0),
      products: productsRaw is List
          ? productsRaw
                .whereType<Map<String, dynamic>>()
                .map(TransactionProductRow.fromJson)
                .toList()
          : const [],
    );
  }
}
