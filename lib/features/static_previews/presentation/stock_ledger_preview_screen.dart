import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_date_pickers.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/product_image_thumb.dart';
import '../../stock_audit/data/models/product_stock_history_model.dart';
import '../../stock_audit/data/stock_audit_repository.dart';
import 'preview_theme.dart';

/// SKU stock ledger — Odoo product-stock-history via CRM backend.
class StockLedgerPreviewScreen extends ConsumerStatefulWidget {
  const StockLedgerPreviewScreen({
    super.key,
    this.productName = 'Product',
    this.variantLabel = '—',
    this.sku = '—',
    this.storeName = 'Dark Store',
    this.imageUrl,
    this.variantId,
    this.businessLocationId,
  });

  final String productName;
  final String variantLabel;
  final String sku;
  final String storeName;
  final String? imageUrl;
  final int? variantId;
  final int? businessLocationId;

  @override
  ConsumerState<StockLedgerPreviewScreen> createState() =>
      _StockLedgerPreviewScreenState();
}

class _StockLedgerPreviewScreenState
    extends ConsumerState<StockLedgerPreviewScreen> {
  static final _apiDateFmt = DateFormat('yyyy-MM-dd');
  static final _displayDateFmt = DateFormat('d-MMM-yyyy');
  static final _timeFmt = DateFormat('HH:mm');

  late DateTimeRange _range;
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<ProductStockHistoryRow> _rows = [];
  ProductStockHistoryPagination _pagination =
      const ProductStockHistoryPagination(
    page: 1,
    limit: 200,
    total: 0,
    hasMore: false,
  );

  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    final end = DateTime.now();
    _range = DateTimeRange(
      start: end.subtract(const Duration(days: 34)),
      end: end,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch(reset: true));
  }

  String get _rangeLabel {
    final fmt = DateFormat('d MMM yyyy');
    return '${fmt.format(_range.start)} - ${fmt.format(_range.end)}';
  }

  String get _skuLine => '${widget.variantLabel} | SKU: ${widget.sku}';

  bool get _canFetch =>
      widget.variantId != null &&
      widget.variantId! > 0 &&
      widget.businessLocationId != null &&
      widget.businessLocationId! > 0;

  List<ProductStockHistoryRow> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows
        .where(
          (r) =>
              r.orderNumber.toLowerCase().contains(q) ||
              r.customer.toLowerCase().contains(q) ||
              r.bucket.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _fetch({required bool reset}) async {
    if (!_canFetch) {
      setState(() {
        _error = 'Product variant ya store select nahi hai.';
        _rows = [];
      });
      return;
    }

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    final page = reset ? 1 : _pagination.page + 1;

    try {
      final repo = ref.read(stockAuditRepositoryProvider);
      final report = await repo.getProductStockHistory(
        businessLocationId: widget.businessLocationId!,
        variantId: widget.variantId!,
        dateFrom: _apiDateFmt.format(_range.start),
        dateTo: _apiDateFmt.format(_range.end),
        page: page,
        limit: 200,
      );

      if (!mounted) return;
      setState(() {
        _pagination = report.pagination;
        _rows = reset ? report.rows : [..._rows, ...report.rows];
        final img = report.productImage?.trim();
        if (img != null && img.isNotEmpty) {
          _resolvedImageUrl = img;
        }
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.message;
        if (reset) _rows = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.toString();
        if (reset) _rows = [];
      });
    }
  }

  Future<void> _pickRange() async {
    HapticFeedback.selectionClick();
    final picked = await AppDatePickers.pickDateRange(
      context,
      initialDateRange: _range,
    );
    if (!mounted || picked == null) return;
    setState(() => _range = picked);
    await _fetch(reset: true);
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
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: _loading ? () {} : () => _fetch(reset: true),
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
            child: RefreshIndicator(
              color: PreviewTheme.orange,
              onRefresh: () => _fetch(reset: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  _ProductSummaryCard(
                    productName: widget.productName,
                    skuLine: _skuLine,
                    storeName: widget.storeName,
                    imageUrl: widget.imageUrl ?? _resolvedImageUrl,
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
                  if (_loading && _rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null && _rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PreviewTheme.red,
                        ),
                      ),
                    )
                  else
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
                              _TableRow(
                                row: rows[i],
                                displayDateFmt: _displayDateFmt,
                                timeFmt: _timeFmt,
                              ),
                            ],
                          if (_pagination.hasMore && _query.isEmpty) ...[
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: PreviewTheme.border,
                            ),
                            TextButton(
                              onPressed: _loadingMore
                                  ? null
                                  : () => _fetch(reset: false),
                              child: _loadingMore
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Load more'),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
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
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: onClear,
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: PreviewTheme.textMuted,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _BucketStyle { transit, inStock, cancelled, delivered, rto, other }

_BucketStyle _bucketStyleFor(String bucket) {
  final b = bucket.toLowerCase();
  if (b.contains('transit')) return _BucketStyle.transit;
  if (b == 'in') return _BucketStyle.inStock;
  if (b.contains('cancel')) return _BucketStyle.cancelled;
  if (b.contains('deliver')) return _BucketStyle.delivered;
  if (b.contains('rto')) return _BucketStyle.rto;
  return _BucketStyle.other;
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
  const _TableRow({
    required this.row,
    required this.displayDateFmt,
    required this.timeFmt,
  });

  final ProductStockHistoryRow row;
  final DateFormat displayDateFmt;
  final DateFormat timeFmt;

  (Color bg, Color fg) get _pill {
    switch (_bucketStyleFor(row.bucket)) {
      case _BucketStyle.transit:
        return (
          AppColors.isDark ? const Color(0xFF2A2F3A) : const Color(0xFFEEF1F5),
          AppColors.isDark ? const Color(0xFFB0B8C4) : const Color(0xFF5B6573),
        );
      case _BucketStyle.inStock:
        return (PreviewTheme.greenSoft, PreviewTheme.green);
      case _BucketStyle.cancelled:
        return (PreviewTheme.redSoft, PreviewTheme.red);
      case _BucketStyle.delivered:
        return (
          AppColors.isDark ? const Color(0xFF3A1A2A) : const Color(0xFFFCE7F3),
          AppColors.isDark ? const Color(0xFFE88A9A) : const Color(0xFFBE185D),
        );
      case _BucketStyle.rto:
        return (PreviewTheme.greenSoft, PreviewTheme.green);
      case _BucketStyle.other:
        return (PreviewTheme.field, PreviewTheme.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pill = _pill;
    final qty = row.displayQty;
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

    final dt = row.dateIst?.toLocal();
    final dateStr =
        dt != null ? displayDateFmt.format(dt) : '—';
    final timeStr = dt != null ? timeFmt.format(dt) : '';

    final running = row.runningStock;
    final runningText =
        running == null ? '—' : running.round().toString();

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
                  dateStr,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: PreviewTheme.text,
                    height: 1.2,
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
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
              row.orderNumber,
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
              runningText,
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
