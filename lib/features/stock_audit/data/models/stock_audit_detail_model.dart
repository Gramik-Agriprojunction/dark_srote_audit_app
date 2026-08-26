class StockAuditDetailModel {
  const StockAuditDetailModel({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantLabel,
    required this.variantSku,
    required this.currentStock,
    required this.auditQty,
    required this.damageQty,
    this.image,
    this.auditUpdatedAt,
    this.damageComment,
  });

  final int productId;
  final int variantId;
  final String productName;
  final String variantLabel;
  final String variantSku;
  final String? image;
  final int currentStock;
  final int auditQty;
  final int damageQty;
  final String? damageComment;
  final DateTime? auditUpdatedAt;

  factory StockAuditDetailModel.fromJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final raw = json['auditUpdatedAt'];
    if (raw != null) updatedAt = DateTime.tryParse(raw.toString());

    return StockAuditDetailModel(
      productId: json['productId'] is int
          ? json['productId'] as int
          : int.parse('${json['productId']}'),
      variantId: json['variantId'] is int
          ? json['variantId'] as int
          : int.parse('${json['variantId']}'),
      productName: (json['productName'] ?? 'Product').toString(),
      variantLabel: (json['variantLabel'] ?? json['variantSku'] ?? 'Variant').toString(),
      variantSku: (json['variantSku'] ?? '').toString(),
      image: json['image']?.toString(),
      currentStock: json['currentStock'] is int
          ? json['currentStock'] as int
          : int.tryParse('${json['currentStock']}') ?? 0,
      auditQty: json['auditQty'] is int
          ? json['auditQty'] as int
          : int.tryParse('${json['auditQty']}') ?? 0,
      damageQty: json['damageQty'] is int
          ? json['damageQty'] as int
          : int.tryParse('${json['damageQty']}') ?? 0,
      damageComment: json['damageComment']?.toString(),
      auditUpdatedAt: updatedAt,
    );
  }
}
