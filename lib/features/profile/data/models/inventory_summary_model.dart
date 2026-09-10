class InventorySummaryItem {
  const InventorySummaryItem({
    required this.title,
    required this.subtitle,
    required this.qtyLabel,
    required this.raw,
  });

  final String title;
  final String subtitle;
  final String qtyLabel;
  final Map<String, dynamic> raw;

  factory InventorySummaryItem.fromJson(Map<String, dynamic> json) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text != 'null') return text;
      }
      return '';
    }

    final title = pick([
      'name',
      'product_name',
      'productName',
      'display_name',
      'displayName',
      'default_code',
      'sku',
      'product_sku',
      'title',
    ]);
    final sku = pick(['default_code', 'sku', 'product_sku', 'barcode']);
    final qty = pick([
      'qty',
      'quantity',
      'qty_available',
      'free_qty',
      'on_hand',
      'onHand',
      'stock',
      'available_qty',
      'availableQty',
      'incoming_qty',
      'received_qty',
    ]);

    final subtitleParts = <String>[];
    if (sku.isNotEmpty && sku != title) subtitleParts.add(sku);
    final uom = pick(['uom', 'uom_name', 'unit']);
    if (uom.isNotEmpty) subtitleParts.add(uom);

    return InventorySummaryItem(
      title: title.isNotEmpty ? title : 'Item',
      subtitle: subtitleParts.join(' · '),
      qtyLabel: qty.isNotEmpty ? qty : '—',
      raw: json,
    );
  }
}

class InventorySummaryModel {
  const InventorySummaryModel({
    required this.items,
    this.warehouseLabel,
  });

  final List<InventorySummaryItem> items;
  final String? warehouseLabel;

  factory InventorySummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final rows = _extractRows(data);
    String? warehouseLabel;
    if (data is Map) {
      final wh = data['warehouse'] ?? data['warehouse_name'] ?? data['name'];
      if (wh is Map) {
        warehouseLabel =
            (wh['name'] ?? wh['code'] ?? wh['id'])?.toString().trim();
      } else if (wh != null) {
        warehouseLabel = wh.toString().trim();
      }
    }

    return InventorySummaryModel(
      items: rows
          .whereType<Map>()
          .map((e) => InventorySummaryItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      warehouseLabel:
          (warehouseLabel != null && warehouseLabel.isNotEmpty)
              ? warehouseLabel
              : null,
    );
  }

  static List<dynamic> _extractRows(dynamic data) {
    if (data is List) return data;
    if (data is! Map) return const [];

    const keys = [
      'items',
      'products',
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

    // Fallback: first nested list of maps
    for (final value in data.values) {
      if (value is List &&
          value.isNotEmpty &&
          value.first is Map) {
        return value;
      }
    }
    return const [];
  }
}
