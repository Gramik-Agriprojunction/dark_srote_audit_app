import 'product_mismatch_model.dart';
import 'variance_model.dart';

class StockReconciliationSummary {
  const StockReconciliationSummary({
    this.totalSku = 0,
    this.matched = 0,
    this.short = 0,
    this.excess = 0,
  });

  final int totalSku;
  final int matched;
  final int short;
  final int excess;

  factory StockReconciliationSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StockReconciliationSummary();
    int pick(String camel, String snake) {
      final v = json[camel] ?? json[snake];
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    return StockReconciliationSummary(
      totalSku: pick('totalSku', 'total_sku'),
      matched: pick('matched', 'matched'),
      short: pick('short', 'short'),
      excess: pick('excess', 'excess'),
    );
  }
}

class StockReconciliationReportModel {
  const StockReconciliationReportModel({
    this.rows = const [],
    this.meta = const PaginationMeta(page: 1, limit: 20, total: 0, totalPages: 0),
    this.summary = const StockReconciliationSummary(),
  });

  final List<ProductMismatchRow> rows;
  final PaginationMeta meta;
  final StockReconciliationSummary summary;

  factory StockReconciliationReportModel.fromJson(Map<String, dynamic> json) {
    final rowsRaw = json['rows'];
    return StockReconciliationReportModel(
      rows: rowsRaw is List
          ? rowsRaw
                .whereType<Map<String, dynamic>>()
                .map(ProductMismatchRow.fromJson)
                .toList()
          : const [],
      meta: json['meta'] is Map<String, dynamic>
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : const PaginationMeta(page: 1, limit: 20, total: 0, totalPages: 0),
      summary: StockReconciliationSummary.fromJson(
        json['summary'] as Map<String, dynamic>?,
      ),
    );
  }
}
