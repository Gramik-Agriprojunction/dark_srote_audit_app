class ProductMismatchRow {
  const ProductMismatchRow({
    required this.productName,
    required this.systemStock,
    required this.physicalStock,
    required this.difference,
    this.variantLabel,
    this.storeName,
    this.sku,
  });

  final String productName;
  final String? variantLabel;
  final String? sku;
  final String? storeName;
  final int systemStock;
  final int physicalStock;
  final int difference;
}
