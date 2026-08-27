enum ReconStatus { matched, excess, short }

class ProductMismatchRow {
  const ProductMismatchRow({
    required this.productName,
    required this.systemStock,
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
  });

  final String productName;
  final String? variantLabel;
  final String? sku;
  final String? storeName;
  final int systemStock;
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
}
