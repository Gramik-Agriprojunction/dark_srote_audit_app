import '../../../../core/utils/json_parse.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.variants,
    this.image,
  });

  final int id;
  final String name;
  final String? image;
  final List<ProductVariantModel> variants;

  ProductModel copyWith({List<ProductVariantModel>? variants}) {
    return ProductModel(
      id: id,
      name: name,
      image: image,
      variants: variants ?? this.variants,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final variantsRaw = json['variants'];
    return ProductModel(
      id: jsonInt(json['id']),
      name: (json['name'] ?? 'Unnamed product').toString(),
      image: json['image']?.toString(),
      variants: variantsRaw is List
          ? variantsRaw
                .whereType<Map<String, dynamic>>()
                .map(ProductVariantModel.fromJson)
                .toList()
          : const [],
    );
  }
}

class ProductVariantModel {
  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.sku,
    required this.label,
    required this.variantName,
    required this.auditQty,
    this.auditComment,
    this.auditUpdatedAt,
    this.damageQty = 0,
    this.damageComment,
    this.systemOnHandQty = 0,
    this.lastAuditSystemStock,
    this.backlog = 0,
    this.inventoryType = 'EQUAL',
    this.currentStock = 0,
    this.availableStock = 0,
  });

  final int id;
  final int productId;
  final String sku;
  final String label;
  final String variantName;
  final int auditQty;
  final String? auditComment;
  final DateTime? auditUpdatedAt;
  final int damageQty;
  final String? damageComment;
  final int systemOnHandQty;
  final int? lastAuditSystemStock;
  final int backlog;
  final String inventoryType;
  final int currentStock;
  final int availableStock;

  ProductVariantModel copyWith({
    int? auditQty,
    String? auditComment,
    DateTime? auditUpdatedAt,
    int? damageQty,
    String? damageComment,
    int? systemOnHandQty,
    int? lastAuditSystemStock,
  }) {
    return ProductVariantModel(
      id: id,
      productId: productId,
      sku: sku,
      label: label,
      variantName: variantName,
      auditQty: auditQty ?? this.auditQty,
      auditComment: auditComment ?? this.auditComment,
      auditUpdatedAt: auditUpdatedAt ?? this.auditUpdatedAt,
      damageQty: damageQty ?? this.damageQty,
      damageComment: damageComment ?? this.damageComment,
      systemOnHandQty: systemOnHandQty ?? this.systemOnHandQty,
      lastAuditSystemStock: lastAuditSystemStock ?? this.lastAuditSystemStock,
      currentStock: currentStock,
      availableStock: availableStock,
    );
  }

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final rawUpdated = json['auditUpdatedAt'];
    if (rawUpdated != null) {
      updatedAt = DateTime.tryParse(rawUpdated.toString());
    }

    return ProductVariantModel(
      id: jsonInt(json['id']),
      productId: jsonInt(json['productId']),
      sku: (json['sku'] ?? '').toString(),
      label: (json['label'] ?? json['variantName'] ?? json['sku'] ?? 'Variant')
          .toString(),
      variantName:
          (json['variantName'] ?? json['label'] ?? json['sku'] ?? 'Variant')
              .toString(),
      auditQty: json['auditQty'] is int
          ? json['auditQty'] as int
          : int.tryParse('${json['auditQty']}') ?? 0,
      auditComment: json['auditComment']?.toString(),
      auditUpdatedAt: updatedAt,
      damageQty: json['damageQty'] is int
          ? json['damageQty'] as int
          : int.tryParse('${json['damageQty']}') ?? 0,
      damageComment: json['damageComment']?.toString(),
      systemOnHandQty: json['systemOnHandQty'] is int
          ? json['systemOnHandQty'] as int
          : int.tryParse('${json['systemOnHandQty']}') ?? 0,
      lastAuditSystemStock: json['lastAuditSystemStock'] is int
          ? json['lastAuditSystemStock'] as int
          : int.tryParse('${json['lastAuditSystemStock']}'),
      backlog: json['backlog'] is int
          ? json['backlog'] as int
          : int.tryParse('${json['backlog']}') ?? 0,
      inventoryType: (json['inventoryType'] ?? json['type'] ?? 'EQUAL').toString(),
      currentStock: json['currentStock'] is int
          ? json['currentStock'] as int
          : int.tryParse('${json['currentStock']}') ?? 0,
      availableStock: json['availableStock'] is int
          ? json['availableStock'] as int
          : int.tryParse('${json['availableStock']}') ??
                (json['currentStock'] is int
                    ? json['currentStock'] as int
                    : int.tryParse('${json['currentStock']}') ?? 0),
    );
  }
}

class BulkSaveItemModel {
  const BulkSaveItemModel({
    required this.productId,
    required this.variantId,
    required this.qty,
    this.updatedAt,
  });

  final int productId;
  final int variantId;
  final int qty;
  final DateTime? updatedAt;

  factory BulkSaveItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final raw = json['updatedAt'];
    if (raw != null) updatedAt = DateTime.tryParse(raw.toString());

    return BulkSaveItemModel(
      productId: jsonInt(json['productId']),
      variantId: jsonInt(json['variantId']),
      qty: jsonInt(json['qty']),
      updatedAt: updatedAt,
    );
  }
}

class BulkSaveResultModel {
  const BulkSaveResultModel({
    required this.created,
    required this.updated,
    required this.items,
  });

  final int created;
  final int updated;
  final List<BulkSaveItemModel> items;

  factory BulkSaveResultModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return BulkSaveResultModel(
      created: json['created'] is int
          ? json['created'] as int
          : int.tryParse('${json['created']}') ?? 0,
      updated: json['updated'] is int
          ? json['updated'] as int
          : int.tryParse('${json['updated']}') ?? 0,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map<String, dynamic>>()
                .map(BulkSaveItemModel.fromJson)
                .toList()
          : const [],
    );
  }
}
