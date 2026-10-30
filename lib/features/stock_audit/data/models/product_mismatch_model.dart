enum ReconStatus { matched, excess, short }

class ProductMismatchRow {
  const ProductMismatchRow({
    required this.productName,
    this.variantId,
    required this.systemStock,
    this.onHandQty = 0,
    required this.totalPhysicalStock,
    required this.physicalStock,
    required this.damageStock,
    required this.difference,
    required this.status,
    required this.auditUpdatedAt,
    this.comment,
    this.variantLabel,
    this.storeName,
    this.sku,
    this.image,
  });

  final String productName;
  final int? variantId;
  final String? variantLabel;
  final String? sku;
  final String? storeName;
  final String? image;
  final int systemStock;
  final int onHandQty;
  final int totalPhysicalStock;
  final int physicalStock;
  final int damageStock;
  final String? comment;
  final int difference;
  final ReconStatus status;
  final DateTime auditUpdatedAt;

  static ReconStatus statusFromDifference(int diff) {
    if (diff == 0) return ReconStatus.matched;
    if (diff > 0) return ReconStatus.excess;
    return ReconStatus.short;
  }

  factory ProductMismatchRow.fromJson(Map<String, dynamic> json) {
    final diff = _jsonInt(json['difference']);
    final auditRaw = json['auditUpdatedAt'] ?? json['audit_updated_at'];
    final imageRaw =
        json['image'] ?? json['thumbnail'] ?? json['productImage'] ?? json['product_image'];
    final imageStr = imageRaw?.toString().trim();
    return ProductMismatchRow(
      productName: (json['productName'] ?? json['product_name'] ?? 'Product')
          .toString(),
      variantId: _jsonIntOrNull(json['variantId'] ?? json['variant_id']),
      variantLabel: (json['variantLabel'] ?? json['variant_label'])?.toString(),
      sku: json['sku']?.toString(),
      storeName: (json['storeName'] ?? json['store_name'])?.toString(),
      image: (imageStr != null &&
              imageStr.isNotEmpty &&
              imageStr.toLowerCase() != 'null')
          ? imageStr
          : null,
      systemStock: _jsonInt(json['systemStock'] ?? json['system_stock']),
      onHandQty: _jsonInt(
        json['onHandQty'] ?? json['on_hand_qty'] ?? json['onHand'],
      ),
      totalPhysicalStock: _jsonInt(
        json['totalPhysicalStock'] ?? json['total_physical_stock'],
      ),
      physicalStock: _jsonInt(json['physicalStock'] ?? json['physical_stock']),
      damageStock: _jsonInt(json['damageStock'] ?? json['damage_stock']),
      comment: (json['comment'] ?? json['damageComment'] ?? json['damage_comment'])
          ?.toString(),
      difference: diff,
      status: statusFromDifference(diff),
      auditUpdatedAt: auditRaw != null
          ? DateTime.tryParse(auditRaw.toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

int _jsonInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

int? _jsonIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse('$value');
}
