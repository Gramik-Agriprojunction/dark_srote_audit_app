import '../../../../core/utils/json_parse.dart';

class DseAuditReportCategory {
  const DseAuditReportCategory({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory DseAuditReportCategory.fromJson(Map<String, dynamic> json) {
    return DseAuditReportCategory(
      id: jsonInt(json['id']),
      name: (json['name'] ?? 'Category').toString(),
    );
  }
}

class DseAuditReportRow {
  const DseAuditReportRow({
    required this.id,
    required this.variantId,
    required this.date,
    required this.auditDate,
    required this.name,
    required this.sku,
    required this.system,
    required this.sale,
    required this.rto,
    required this.transferIn,
    required this.transferOut,
    required this.expected,
    required this.claim,
    required this.diff,
    required this.status,
    this.categoryId,
    this.categoryName,
  });

  final int id;
  final int variantId;
  final String date;
  final String auditDate;
  final String name;
  final String sku;
  final int system;
  final int sale;
  final int rto;
  final int transferIn;
  final int transferOut;
  final int expected;
  final int claim;
  final int diff;
  final String status;
  final int? categoryId;
  final String? categoryName;

  factory DseAuditReportRow.fromJson(Map<String, dynamic> json) {
    return DseAuditReportRow(
      id: jsonInt(json['id']),
      variantId: jsonInt(json['variantId'] ?? json['variant_id']),
      date: (json['date'] ?? '').toString(),
      auditDate: (json['auditDate'] ?? json['audit_date'] ?? '').toString(),
      name: (json['name'] ?? 'Product').toString(),
      sku: (json['sku'] ?? '').toString(),
      system: jsonInt(json['system']),
      sale: jsonInt(json['sale']),
      rto: jsonInt(json['rto']),
      transferIn: jsonInt(json['transferIn'] ?? json['transfer_in']),
      transferOut: jsonInt(json['transferOut'] ?? json['transfer_out']),
      expected: jsonInt(json['expected']),
      claim: jsonInt(json['claim']),
      diff: jsonInt(json['diff']),
      status: (json['status'] ?? 'matched').toString(),
      categoryId: json['categoryId'] != null || json['category_id'] != null
          ? jsonInt(json['categoryId'] ?? json['category_id'])
          : null,
      categoryName: (json['categoryName'] ?? json['category_name'])?.toString(),
    );
  }
}

class DseAuditReportSummary {
  const DseAuditReportSummary({
    required this.skus,
    required this.shortage,
    required this.excess,
    required this.matched,
  });

  final int skus;
  final int shortage;
  final int excess;
  final int matched;

  factory DseAuditReportSummary.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return DseAuditReportSummary(
      skus: jsonInt(map['skus']),
      shortage: jsonInt(map['shortage']),
      excess: jsonInt(map['excess']),
      matched: jsonInt(map['matched']),
    );
  }
}

class DseAuditReportMeta {
  const DseAuditReportMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory DseAuditReportMeta.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return DseAuditReportMeta(
      page: jsonInt(map['page'], fallback: 1),
      limit: jsonInt(map['limit'], fallback: 20),
      total: jsonInt(map['total']),
      totalPages: jsonInt(map['totalPages'] ?? map['total_pages']),
    );
  }
}

class DseAuditReport {
  const DseAuditReport({
    required this.businessLocationId,
    required this.month,
    required this.summary,
    required this.categories,
    required this.dates,
    required this.rows,
    required this.meta,
  });

  final int businessLocationId;
  final String month;
  final DseAuditReportSummary summary;
  final List<DseAuditReportCategory> categories;
  final List<String> dates;
  final List<DseAuditReportRow> rows;
  final DseAuditReportMeta meta;

  factory DseAuditReport.fromJson(Map<String, dynamic> json) {
    final categoriesRaw = json['categories'];
    final datesRaw = json['dates'];
    final rowsRaw = json['rows'];
    return DseAuditReport(
      businessLocationId: jsonInt(
        json['businessLocationId'] ?? json['business_location_id'],
      ),
      month: (json['month'] ?? '').toString(),
      summary: DseAuditReportSummary.fromJson(asJsonMap(json['summary'])),
      categories: categoriesRaw is List
          ? categoriesRaw
              .whereType<Map>()
              .map((e) => DseAuditReportCategory.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      dates: datesRaw is List
          ? datesRaw.map((e) => e.toString()).toList()
          : const [],
      rows: rowsRaw is List
          ? rowsRaw
              .whereType<Map>()
              .map(
                (e) => DseAuditReportRow.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
      meta: DseAuditReportMeta.fromJson(asJsonMap(json['meta'])),
    );
  }
}
