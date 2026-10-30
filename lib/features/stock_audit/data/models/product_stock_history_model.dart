import '../../../../core/utils/json_parse.dart';

class ProductStockHistoryPagination {
  const ProductStockHistoryPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  factory ProductStockHistoryPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProductStockHistoryPagination(
        page: 1,
        limit: 200,
        total: 0,
        hasMore: false,
      );
    }
    return ProductStockHistoryPagination(
      page: jsonInt(json['page'], fallback: 1),
      limit: jsonInt(json['limit'], fallback: 200),
      total: jsonInt(json['total']),
      hasMore: json['has_more'] == true || json['hasMore'] == true,
    );
  }
}

class ProductStockHistoryRow {
  const ProductStockHistoryRow({
    required this.dateIst,
    required this.bucket,
    required this.orderNumber,
    required this.customer,
    required this.quantity,
    required this.transitQuantity,
    this.runningStock,
    required this.affectsStock,
  });

  final DateTime? dateIst;
  final String bucket;
  final String orderNumber;
  final String customer;
  final double quantity;
  final double transitQuantity;
  final double? runningStock;
  final bool affectsStock;

  int? get displayQty {
    final bucketLower = bucket.toLowerCase();
    if (bucketLower.contains('transit')) {
      if (transitQuantity == 0) return null;
      return transitQuantity.round();
    }
    if (!affectsStock && quantity == 0) return null;
    if (quantity == 0) return null;
    return quantity.round();
  }

  factory ProductStockHistoryRow.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date_ist'] ?? json['dateIst'] ?? json['date'];
    return ProductStockHistoryRow(
      dateIst: dateRaw != null ? DateTime.tryParse(dateRaw.toString()) : null,
      bucket: (json['bucket'] ?? '').toString(),
      orderNumber: (json['order_number'] ?? json['orderNumber'] ?? '')
          .toString(),
      customer: (json['customer'] ?? '').toString(),
      quantity: _jsonDouble(json['quantity']),
      transitQuantity: _jsonDouble(
        json['transit_quantity'] ?? json['transitQuantity'],
      ),
      runningStock: _jsonDoubleOrNull(
        json['running_stock'] ?? json['runningStock'],
      ),
      affectsStock: json['affects_stock'] == true || json['affectsStock'] == true,
    );
  }
}

class ProductStockHistoryReport {
  const ProductStockHistoryReport({
    required this.rows,
    required this.pagination,
    this.openingStock,
    this.closingStock,
    this.currentOnHand,
    this.productImage,
  });

  final List<ProductStockHistoryRow> rows;
  final ProductStockHistoryPagination pagination;
  final double? openingStock;
  final double? closingStock;
  final double? currentOnHand;
  final String? productImage;

  factory ProductStockHistoryReport.fromJson(Map<String, dynamic> json) {
    final rowsRaw = json['rows'];
    final rows = rowsRaw is List
        ? rowsRaw
            .whereType<Map<String, dynamic>>()
            .map(ProductStockHistoryRow.fromJson)
            .toList()
        : <ProductStockHistoryRow>[];

    return ProductStockHistoryReport(
      rows: rows,
      pagination: ProductStockHistoryPagination.fromJson(
        json['pagination'] is Map<String, dynamic>
            ? json['pagination'] as Map<String, dynamic>
            : null,
      ),
      openingStock: _jsonDoubleOrNull(
        json['opening_stock'] ?? json['openingStock'],
      ),
      closingStock: _jsonDoubleOrNull(
        json['closing_stock'] ?? json['closingStock'],
      ),
      currentOnHand: _jsonDoubleOrNull(
        json['current_on_hand'] ?? json['currentOnHand'],
      ),
      productImage: (json['productImage'] ??
              json['product_image'] ??
              json['image'])
          ?.toString(),
    );
  }
}

double _jsonDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

double? _jsonDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final parsed = double.tryParse('$value');
  return parsed;
}
