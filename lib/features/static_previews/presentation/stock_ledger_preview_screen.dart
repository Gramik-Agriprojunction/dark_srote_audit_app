import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_date_pickers.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/product_image_thumb.dart';
import 'preview_theme.dart';

/// SKU stock ledger — opened from Stock product card (static mock data).
class StockLedgerPreviewScreen extends ConsumerStatefulWidget {
  const StockLedgerPreviewScreen({
    super.key,
    this.productName = 'Musturd 1666',
    this.variantLabel = '500-GM',
    this.sku = 'MO-500',
    this.storeName = 'DS#31 - Unnao (Safipur) - Gramik',
    this.imageUrl,
  });

  final String productName;
  final String variantLabel;
  final String sku;
  final String storeName;
  final String? imageUrl;

  @override
  ConsumerState<StockLedgerPreviewScreen> createState() =>
      _StockLedgerPreviewScreenState();
}

class _StockLedgerPreviewScreenState
    extends ConsumerState<StockLedgerPreviewScreen> {
  static const _rows = <_LedgerRow>[
    _LedgerRow(
      '19-Sep-2026',
      '16:24',
      'Transit leg',
      'IBT/2026/00539',
      'LAVAKUSH YADAV BSO',
      _Bucket.transit,
      qty: null,
      running: 36,
    ),
    _LedgerRow(
      '19-Sep-2026',
      '16:24',
      'IN',
      'IBT/2026/00539',
      'Uttar Pradesh',
      _Bucket.inStock,
      qty: 36,
      running: 36,
    ),
    _LedgerRow(
      '20-Sep-2026',
      '11:05',
      'Cancelled',
      'AGRI9928579588401',
      'Phoolchandra',
      _Bucket.cancelled,
      qty: null,
      running: 36,
    ),
    _LedgerRow(
      '20-Sep-2026',
      '14:12',
      'Delivered',
      'AGRI9928579588408',
      'Ram Singh',
      _Bucket.delivered,
      qty: -1,
      running: 35,
    ),
    _LedgerRow(
      '21-Sep-2026',
      '09:40',
      'Delivered',
      'AGRI9928579588412',
      'Suresh Yadav',
      _Bucket.delivered,
      qty: -1,
      running: 34,
    ),
    _LedgerRow(
      '21-Sep-2026',
      '16:18',
      'Delivered',
      'AGRI9928579588420',
      'Anita Devi',
      _Bucket.delivered,
      qty: -1,
      running: 33,
    ),
    _LedgerRow(
      '22-Sep-2026',
      '10:22',
      'Delivered',
      'AGRI9928579588431',
      'Manoj Kumar',
      _Bucket.delivered,
      qty: -1,
      running: 32,
    ),
    _LedgerRow(
      '22-Sep-2026',
      '15:05',
      'Delivered',
      'AGRI9928579588444',
      'Geeta',
      _Bucket.delivered,
      qty: -14,
      running: 18,
    ),
    _LedgerRow(
      '23-Sep-2026',
      '12:30',
      'Delivered',
      'AGRI9928579588450',
      'Vikas',
      _Bucket.delivered,
      qty: -1,
      running: 17,
    ),
    _LedgerRow(
      '24-Sep-2026',
      '11:10',
      'RTO',
      'AGRI9928579588455',
      'Phoolchandra',
      _Bucket.rto,
      qty: 2,
      running: 19,
    ),
    _LedgerRow(
      '25-Sep-2026',
      '13:45',
      'Delivered',
      'AGRI9928579588460',
      'Ravi',
      _Bucket.delivered,
      qty: -2,
      running: 17,
    ),
    _LedgerRow(
      '26-Sep-2026',
      '10:05',
      'Delivered',
      'AGRI9928579588466',
      'Sunita',
      _Bucket.delivered,
      qty: -2,
      running: 15,
    ),
  ];

  DateTimeRange _range = DateTimeRange(
    start: DateTime(2026, 9, 19),
    end: DateTime(2026, 10, 23),
  );
  final _searchCtrl = TextEditingController();
  String _query = '';

  String get _rangeLabel {
    final fmt = DateFormat('d MMM yyyy');
    return '${fmt.format(_range.start)} - ${fmt.format(_range.end)}';
  }

  String get _skuLine => '${widget.variantLabel} | SKU: ${widget.sku}';

  List<_LedgerRow> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows
        .where(
          (r) =>
              r.orderNo.toLowerCase().contains(q) ||
              r.customer.toLowerCase().contains(q) ||
              r.bucket.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _pickRange() async {
    HapticFeedback.selectionClick();
    final picked = await AppDatePickers.pickDateRange(
      context,
      initialDateRange: _range,
    );
    if (!mounted || picked == null) return;
    setState(() => _range = picked);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeModeProvider);
    final rows = _filtered;

    return Scaffold(
      backgroundColor: PreviewTheme.bg,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: widget.productName,
            subtitle: _skuLine,
            onBack: () => context.pop(),
            showNotifications: false,
            actions: [
              ModuleHeaderAction(
                icon: Icons.more_vert_rounded,
                tooltip: 'More',
                onTap: () {},
              ),
            ],
            bottom: Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 14,
                  color: AppColors.isDark
                      ? AppColors.textMuted
                      : Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.isDark
                          ? AppColors.textMuted
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [
                _ProductSummaryCard(
                  productName: widget.productName,
                  skuLine: _skuLine,
                  storeName: widget.storeName,
                  imageUrl: widget.imageUrl,
                ),
                const SizedBox(height: 12),
                PreviewSelectField(
                  icon: Icons.calendar_month_rounded,
                  label: _rangeLabel,
                  onTap: _pickRange,
                ),
                const SizedBox(height: 10),
                _SearchFilterRow(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: PreviewTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PreviewTheme.border),
                    boxShadow: PreviewTheme.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      const _TableHeader(),
                      if (rows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            'No movements found',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PreviewTheme.textMuted,
                            ),
                          ),
                        )
                      else
                        for (var i = 0; i < rows.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: PreviewTheme.border,
                            ),
                          _TableRow(row: rows[i]),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({
    required this.productName,
    required this.skuLine,
    required this.storeName,
    this.imageUrl,
  });

  final String productName;
  final String skuLine;
  final String storeName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: PreviewTheme.cardShadow,
      ),
      child: Row(
        children: [
          ProductImageThumb(
            imageUrl: imageUrl,
            width: 56,
            height: 56,
            borderRadius: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PreviewTheme.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  skuLine,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: PreviewTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 13,
                      color: PreviewTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: PreviewTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: PreviewTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PreviewTheme.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: PreviewTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    cursorColor: PreviewTheme.orange,
                    style: TextStyle(
                      fontSize: 13,
                      color: PreviewTheme.text,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: 'Search Customer, Order No., Bucket...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: PreviewTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: PreviewTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: PreviewTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PreviewTheme.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_alt_rounded,
                size: 18,
                color: PreviewTheme.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'Filter',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PreviewTheme.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Bucket { transit, inStock, cancelled, delivered, rto }

class _LedgerRow {
  const _LedgerRow(
    this.date,
    this.time,
    this.bucket,
    this.orderNo,
    this.customer,
    this.style, {
    required this.qty,
    required this.running,
  });

  final String date;
  final String time;
  final String bucket;
  final String orderNo;
  final String customer;
  final _Bucket style;
  final int? qty;
  final int running;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
      color: PreviewTheme.field,
      child: Row(
        children: [
          SizedBox(width: 78, child: _h('Date (IST)')),
          SizedBox(width: 78, child: _h('Bucket')),
          Expanded(flex: 3, child: _h('Order No.')),
          Expanded(flex: 2, child: _h('Customer / Partner')),
          SizedBox(width: 40, child: _h('Qty', align: TextAlign.right)),
          SizedBox(width: 48, child: _h('Stock', align: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _h(String t, {TextAlign align = TextAlign.left}) => Text(
        t,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: PreviewTheme.textMuted,
        ),
      );
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.row});
  final _LedgerRow row;

  (Color bg, Color fg) get _pill {
    switch (row.style) {
      case _Bucket.transit:
        return (
          AppColors.isDark ? const Color(0xFF2A2F3A) : const Color(0xFFEEF1F5),
          AppColors.isDark ? const Color(0xFFB0B8C4) : const Color(0xFF5B6573),
        );
      case _Bucket.inStock:
        return (PreviewTheme.greenSoft, PreviewTheme.green);
      case _Bucket.cancelled:
        return (PreviewTheme.redSoft, PreviewTheme.red);
      case _Bucket.delivered:
        return (
          AppColors.isDark ? const Color(0xFF3A1A2A) : const Color(0xFFFCE7F3),
          AppColors.isDark ? const Color(0xFFE88A9A) : const Color(0xFFBE185D),
        );
      case _Bucket.rto:
        return (PreviewTheme.greenSoft, PreviewTheme.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pill = _pill;
    final qty = row.qty;
    final qtyColor = qty == null
        ? PreviewTheme.textMuted
        : qty >= 0
            ? PreviewTheme.green
            : PreviewTheme.red;
    final qtyText = qty == null
        ? '—'
        : qty > 0
            ? '+$qty'
            : '$qty';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.date,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: PreviewTheme.text,
                    height: 1.2,
                  ),
                ),
                Text(
                  row.time,
                  style: TextStyle(
                    fontSize: 10,
                    color: PreviewTheme.textMuted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 78,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: pill.$1,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  row.bucket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: pill.$2,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.orderNo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: PreviewTheme.text,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.customer,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: PreviewTheme.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              qtyText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: qtyColor,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${row.running}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: PreviewTheme.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
