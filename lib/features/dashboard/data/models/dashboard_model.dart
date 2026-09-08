class DashboardModel {
  const DashboardModel({
    required this.header,
    required this.mismatchAlert,
    required this.auditProgress,
    required this.summary,
    required this.recentOrders,
  });

  final DashboardHeader header;
  final DashboardMismatchAlert mismatchAlert;
  final DashboardAuditProgress auditProgress;
  final DashboardSummary summary;
  final List<DashboardRecentOrder> recentOrders;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final headerJson = json['header'];
    final mismatchJson = json['mismatchAlert'];
    final auditJson = json['auditProgress'];
    final summaryJson = json['summary'];
    final recentRaw = json['recentOrders'];

    return DashboardModel(
      header: headerJson is Map<String, dynamic>
          ? DashboardHeader.fromJson(headerJson)
          : const DashboardHeader(
              userName: 'Darkstore',
              storeName: 'Gramik Darkstore',
              storeCode: '',
              greeting: 'Namaste',
            ),
      mismatchAlert: mismatchJson is Map<String, dynamic>
          ? DashboardMismatchAlert.fromJson(mismatchJson)
          : const DashboardMismatchAlert(count: 0, items: []),
      auditProgress: auditJson is Map<String, dynamic>
          ? DashboardAuditProgress.fromJson(auditJson)
          : const DashboardAuditProgress(
              auditedToday: 0,
              totalSkus: 0,
              percent: 0,
            ),
      summary: summaryJson is Map<String, dynamic>
          ? DashboardSummary.fromJson(summaryJson)
          : const DashboardSummary(
              ordersTotal: 0,
              ordersPending: 0,
              stockTotalSkus: 0,
              stockMismatch: 0,
              dcIncoming: 0,
              dcReceived: 0,
              varianceBacklog: 0,
              variancePendingReview: 0,
            ),
      recentOrders: recentRaw is List
          ? recentRaw
              .whereType<Map<String, dynamic>>()
              .map(DashboardRecentOrder.fromJson)
              .toList()
          : const [],
    );
  }
}

class DashboardHeader {
  const DashboardHeader({
    required this.userName,
    required this.storeName,
    required this.storeCode,
    required this.greeting,
    this.businessLocationId,
  });

  final String userName;
  final String storeName;
  final String storeCode;
  final String greeting;
  final int? businessLocationId;

  factory DashboardHeader.fromJson(Map<String, dynamic> json) {
    return DashboardHeader(
      userName: (json['userName'] ?? '').toString(),
      storeName: (json['storeName'] ?? 'Gramik Darkstore').toString(),
      storeCode: (json['storeCode'] ?? '').toString(),
      greeting: (json['greeting'] ?? 'Namaste').toString(),
      businessLocationId: json['businessLocationId'] is int
          ? json['businessLocationId'] as int
          : int.tryParse('${json['businessLocationId']}'),
    );
  }
}

class DashboardMismatchAlert {
  const DashboardMismatchAlert({
    required this.count,
    required this.items,
  });

  final int count;
  final List<DashboardMismatchItem> items;

  factory DashboardMismatchAlert.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return DashboardMismatchAlert(
      count: _asInt(json['count']),
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(DashboardMismatchItem.fromJson)
              .toList()
          : const [],
    );
  }
}

class DashboardMismatchItem {
  const DashboardMismatchItem({
    required this.productName,
    required this.systemStock,
    required this.physicalStock,
    required this.difference,
    required this.status,
    this.variantLabel,
    this.sku,
    this.image,
  });

  final String productName;
  final String? variantLabel;
  final String? sku;
  final String? image;
  final int systemStock;
  final int physicalStock;
  final int difference;
  final String status;

  String get displayName {
    final v = (variantLabel ?? '').trim();
    if (v.isEmpty) return productName;
    return '$productName ($v)';
  }

  factory DashboardMismatchItem.fromJson(Map<String, dynamic> json) {
    return DashboardMismatchItem(
      productName: (json['productName'] ?? 'Product').toString(),
      variantLabel: json['variantLabel']?.toString(),
      sku: json['sku']?.toString(),
      image: (json['image'] ?? json['thumbnailImg'] ?? json['thumbnail_img'])
          ?.toString(),
      systemStock: _asInt(json['systemStock']),
      physicalStock: _asInt(json['physicalStock']),
      difference: _asInt(json['difference']),
      status: (json['status'] ?? 'SHORT').toString().toUpperCase(),
    );
  }
}

class DashboardAuditProgress {
  const DashboardAuditProgress({
    required this.auditedToday,
    required this.totalSkus,
    required this.percent,
  });

  final int auditedToday;
  final int totalSkus;
  final int percent;

  factory DashboardAuditProgress.fromJson(Map<String, dynamic> json) {
    return DashboardAuditProgress(
      auditedToday: _asInt(json['auditedToday']),
      totalSkus: _asInt(json['totalSkus']),
      percent: _asInt(json['percent']),
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.ordersTotal,
    required this.ordersPending,
    required this.stockTotalSkus,
    required this.stockMismatch,
    required this.dcIncoming,
    required this.dcReceived,
    required this.varianceBacklog,
    required this.variancePendingReview,
  });

  final int ordersTotal;
  final int ordersPending;
  final int stockTotalSkus;
  final int stockMismatch;
  final int dcIncoming;
  final int dcReceived;
  final int varianceBacklog;
  final int variancePendingReview;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final orders = json['orders'];
    final stock = json['stock'];
    final dc = json['dcTransfers'];
    final variance = json['variance'];

    Map<String, dynamic> asMap(dynamic v) =>
        v is Map<String, dynamic> ? v : <String, dynamic>{};

    final o = asMap(orders);
    final s = asMap(stock);
    final d = asMap(dc);
    final v = asMap(variance);

    return DashboardSummary(
      ordersTotal: _asInt(o['total']),
      ordersPending: _asInt(o['pending']),
      stockTotalSkus: _asInt(s['totalSkus']),
      stockMismatch: _asInt(s['mismatch']),
      dcIncoming: _asInt(d['incoming']),
      dcReceived: _asInt(d['received']),
      varianceBacklog: _asInt(v['backlog']),
      variancePendingReview: _asInt(v['pendingReview']),
    );
  }
}

class DashboardRecentOrder {
  const DashboardRecentOrder({
    required this.id,
    required this.code,
    required this.customerName,
    required this.customerCity,
    required this.grandTotal,
    required this.paymentType,
    required this.paymentStatus,
    required this.orderStatus,
    this.createdAt,
    this.firstProductImage,
  });

  final int id;
  final String code;
  final String customerName;
  final String customerCity;
  final num grandTotal;
  final String paymentType;
  final String paymentStatus;
  final String orderStatus;
  final String? createdAt;
  final String? firstProductImage;

  factory DashboardRecentOrder.fromJson(Map<String, dynamic> json) {
    return DashboardRecentOrder(
      id: _asInt(json['id']),
      code: (json['code'] ?? '').toString(),
      customerName: (json['customerName'] ?? 'Customer').toString(),
      customerCity: (json['customerCity'] ?? '').toString(),
      grandTotal: json['grandTotal'] is num
          ? json['grandTotal'] as num
          : num.tryParse('${json['grandTotal']}') ?? 0,
      paymentType: (json['paymentType'] ?? 'COD').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'UNPAID').toString(),
      orderStatus: (json['orderStatus'] ?? 'PENDING').toString(),
      createdAt: json['createdAt']?.toString(),
      firstProductImage: json['firstProductImage']?.toString(),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse('$v') ?? 0;
}
