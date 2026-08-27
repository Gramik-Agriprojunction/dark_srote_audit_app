class ProductMismatchRow {
  const ProductMismatchRow({
    required this.productName,
    required this.systemStock,
    required this.totalPhysicalStock,
    required this.physicalStock,
    required this.damageStock,
    required this.difference,
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
}
