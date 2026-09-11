class InventorySummaryItem {
  const InventorySummaryItem({
    required this.productName,
    required this.receivedQty,
    required this.transferredOutQty,
    required this.customerDeliveredQty,
    required this.systemQuantityOnHand,
    required this.physicalStock,
    required this.raw,
    this.productId,
    this.crmProductId,
    this.crmVariantId,
    this.variantLabel,
    this.sku,
    this.image,
  });

  final int? productId;
  final int? crmProductId;
  final int? crmVariantId;
  final String productName;
  final String? variantLabel;
  final String? sku;
  final String? image;
  final double receivedQty;
  final double transferredOutQty;
  final double customerDeliveredQty;
  final double systemQuantityOnHand;
  final double physicalStock;
  final Map<String, dynamic> raw;

  factory InventorySummaryItem.fromJson(Map<String, dynamic> json) {
    String pickString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text != 'null') return text;
      }
      return '';
    }

    double pickQty(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is num) return value.toDouble();
        final parsed = double.tryParse(value.toString().trim());
        if (parsed != null) return parsed;
      }
      return 0;
    }

    int? pickInt(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is int) return value;
        if (value is num) return value.toInt();
        final parsed = int.tryParse(value.toString().trim());
        if (parsed != null) return parsed;
      }
      return null;
    }

    final productName = pickString([
      'product_name',
      'productName',
      'name',
      'display_name',
      'displayName',
      'title',
    ]);
    final variantLabel = pickString([
      'variant',
      'variant_label',
      'variantLabel',
      'variant_name',
      'variantName',
    ]);
    final sku = pickString([
      'sku',
      'default_code',
      'internal_reference',
      'product_code',
    ]);
    final imageRaw = pickString(['image', 'thumbnail', 'thumbnailImg']);

    return InventorySummaryItem(
      productId: pickInt(['product_id', 'productId', 'odoo_product_id']),
      crmProductId: pickInt(['crm_product_id', 'crmProductId']),
      crmVariantId: pickInt(['crm_variant_id', 'crmVariantId']),
      productName: productName.isNotEmpty ? productName : 'Product',
      variantLabel: variantLabel.isNotEmpty ? variantLabel : null,
      sku: sku.isNotEmpty ? sku : null,
      image: imageRaw.isNotEmpty ? imageRaw : null,
      receivedQty: pickQty(['received_qty', 'receivedQty']),
      transferredOutQty: pickQty([
        'transferred_out_qty',
        'transferredOutQty',
        'transfer_out_qty',
      ]),
      customerDeliveredQty: pickQty([
        'customer_delivered_qty',
        'customerDeliveredQty',
        'delivered_qty',
      ]),
      systemQuantityOnHand: pickQty([
        'system_quantity_on_hand',
        'systemQuantityOnHand',
        'qty_on_hand',
        'on_hand',
        'qty',
        'quantity',
      ]),
      physicalStock: pickQty(['physical_stock', 'physicalStock', 'audit_qty']),
      raw: json,
    );
  }
}

class InventorySummaryModel {
  const InventorySummaryModel({
    required this.items,
    this.warehouseLabel,
    this.warehouseId,
  });

  final List<InventorySummaryItem> items;
  final String? warehouseLabel;
  final int? warehouseId;

  factory InventorySummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final rows = _extractRows(data);
    String? warehouseLabel;
    int? warehouseId;

    if (data is Map) {
      final wh = data['warehouse'] ?? data['warehouse_name'] ?? data['name'];
      if (wh is Map) {
        warehouseLabel =
            (wh['name'] ?? wh['code'] ?? wh['id'])?.toString().trim();
        warehouseId = _asInt(wh['id'] ?? wh['warehouse_id']);
      } else if (wh != null) {
        warehouseLabel = wh.toString().trim();
      }
      warehouseId ??= _asInt(
        data['warehouse_id'] ?? data['warehouseId'] ?? data['id'],
      );
      final whName = data['warehouse_name']?.toString().trim();
      if ((warehouseLabel == null || warehouseLabel.isEmpty) &&
          whName != null &&
          whName.isNotEmpty) {
        warehouseLabel = whName;
      }
    }

    return InventorySummaryModel(
      items: rows
          .whereType<Map>()
          .map(
            (e) => InventorySummaryItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      warehouseLabel:
          (warehouseLabel != null && warehouseLabel.isNotEmpty)
              ? warehouseLabel
              : null,
      warehouseId: warehouseId,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}');
  }

  static List<dynamic> _extractRows(dynamic data) {
    if (data is List) return data;
    if (data is! Map) return const [];

    const keys = [
      'products',
      'items',
      'rows',
      'inventory',
      'lines',
      'stock',
      'summary',
      'records',
      'data',
    ];
    for (final key in keys) {
      final value = data[key];
      if (value is List) return value;
    }

    for (final value in data.values) {
      if (value is List && value.isNotEmpty && value.first is Map) {
        return value;
      }
    }
    return const [];
  }
}
