enum VarianceType { minus, plus, equal }

VarianceType varianceTypeFromString(String value) {
  switch (value.toUpperCase()) {
    case 'MINUS':
      return VarianceType.minus;
    case 'PLUS':
      return VarianceType.plus;
    default:
      return VarianceType.equal;
  }
}

class VarianceRowModel {
  const VarianceRowModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantLabel,
    required this.sku,
    required this.storeName,
    required this.backlog,
    required this.type,
    this.backlogUpdatedAt,
  });

  final int id;
  final int productId;
  final String productName;
  final int variantId;
  final String variantLabel;
  final String sku;
  final String storeName;
  final int backlog;
  final VarianceType type;
  final DateTime? backlogUpdatedAt;

  factory VarianceRowModel.fromJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final raw = json['backlogUpdatedAt'];
    if (raw != null) updatedAt = DateTime.tryParse(raw.toString());

    return VarianceRowModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
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
      storeName: (json['storeName'] ?? '').toString(),
      backlog: json['backlog'] is int
          ? json['backlog'] as int
          : int.tryParse('${json['backlog']}') ?? 0,
      type: varianceTypeFromString((json['type'] ?? 'EQUAL').toString()),
      backlogUpdatedAt: updatedAt,
    );
  }
}

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] is int
          ? json['page'] as int
          : int.tryParse('${json['page']}') ?? 1,
      limit: json['limit'] is int
          ? json['limit'] as int
          : int.tryParse('${json['limit']}') ?? 20,
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse('${json['total']}') ?? 0,
      totalPages: json['totalPages'] is int
          ? json['totalPages'] as int
          : int.tryParse('${json['totalPages']}') ?? 0,
    );
  }
}

class VarianceReportModel {
  const VarianceReportModel({
    required this.rows,
    required this.meta,
  });

  final List<VarianceRowModel> rows;
  final PaginationMeta meta;

  factory VarianceReportModel.fromJson(Map<String, dynamic> json) {
    final rowsRaw = json['rows'];
    final metaRaw = json['meta'];
    return VarianceReportModel(
      rows: rowsRaw is List
          ? rowsRaw
                .whereType<Map<String, dynamic>>()
                .map(VarianceRowModel.fromJson)
                .toList()
          : const [],
      meta: metaRaw is Map<String, dynamic>
          ? PaginationMeta.fromJson(metaRaw)
          : const PaginationMeta(page: 1, limit: 20, total: 0, totalPages: 0),
    );
  }
}
