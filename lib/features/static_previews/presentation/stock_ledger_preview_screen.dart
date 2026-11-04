import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
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
  double? _openingStock;
  double? _closingStock;
  double? _currentOnHand;

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
    final list = q.isEmpty
        ? List<ProductStockHistoryRow>.from(_rows)
        : _rows
            .where(
              (r) =>
                  r.orderNumber.toLowerCase().contains(q) ||
                  r.customer.toLowerCase().contains(q) ||
                  r.bucket.toLowerCase().contains(q),
            )
            .toList();
    // Newest first (18 Oct above 29 Sep).
    list.sort((a, b) {
      final at = a.dateIst?.millisecondsSinceEpoch ?? 0;
      final bt = b.dateIst?.millisecondsSinceEpoch ?? 0;
      return bt.compareTo(at);
    });
    return list;
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
        if (reset) {
          _openingStock = report.openingStock;
          _closingStock = report.closingStock;
          _currentOnHand = report.currentOnHand;
        }
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
            subtitle: () {
              final store = ref.watch(headerGreetingProvider);
              if (store.isNotEmpty) return store;
              return _skuLine;
            }(),
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
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                children: [
                  _ProductSummaryCard(
                    productName: widget.productName,
                    skuLine: _skuLine,
                    storeName: widget.storeName,
                    imageUrl: widget.imageUrl ?? _resolvedImageUrl,
                  ),
                  const SizedBox(height: 14),
                  _HeroFilterShell(
                    child: PreviewSelectField(
                      icon: Icons.calendar_month_rounded,
                      label: _rangeLabel,
                      onTap: _pickRange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _HeroFilterShell(
                    child: _SearchFilterRow(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transaction history',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: PreviewTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type · Change · Pehle → Stock',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: PreviewTheme.textMuted,
                    ),
                  ),
                  if (_openingStock != null ||
                      _closingStock != null ||
                      _currentOnHand != null) ...[
                    const SizedBox(height: 10),
                    _StockSummaryStrip(
                      opening: _openingStock,
                      closing: _closingStock,
                      now: _currentOnHand,
                    ),
                  ],
                  const SizedBox(height: 10),
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
                  else if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'No movements found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PreviewTheme.textMuted,
                        ),
                      ),
                    )
                  else ...[
                    for (final row in rows) ...[
                      _LedgerCard(
                        row: row,
                        displayDateFmt: _displayDateFmt,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_pagination.hasMore && _query.isEmpty)
                      TextButton(
                        onPressed:
                            _loadingMore ? null : () => _fetch(reset: false),
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
          ),
        ],
      ),
    );
  }
}

class _HeroFilterShell extends StatelessWidget {
  const _HeroFilterShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PreviewTheme.orange.withValues(
              alpha: AppColors.isDark ? 0.14 : 0.08,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          ...PreviewTheme.cardShadow,
        ],
      ),
      child: child,
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PreviewTheme.surface,
            Color.lerp(PreviewTheme.surface, PreviewTheme.orangeSoft, 0.55) ??
                PreviewTheme.surface,
          ],
        ),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: [
          BoxShadow(
            color: PreviewTheme.orange.withValues(
              alpha: AppColors.isDark ? 0.22 : 0.12,
            ),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          ...PreviewTheme.cardShadow,
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      PreviewTheme.orange,
                      PreviewTheme.orange.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: PreviewTheme.orange.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ProductImageThumb(
                          imageUrl: imageUrl,
                          width: 64,
                          height: 64,
                          borderRadius: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: PreviewTheme.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: PreviewTheme.orangeSoft,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: PreviewTheme.orange.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Text(
                                skuLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: PreviewTheme.orange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                      fontWeight: FontWeight.w500,
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
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PreviewTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: PreviewTheme.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: PreviewTheme.orange,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
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
                  fontWeight: FontWeight.w500,
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
    );
  }
}

enum _BucketStyle {
  transit,
  inStock,
  cancelled,
  delivered,
  rto,
  pending,
  ofd,
  other,
}

_BucketStyle _bucketStyleFor(String bucket) {
  final b = bucket.toLowerCase().trim();
  if (b.contains('cancel')) return _BucketStyle.cancelled;
  if (b.contains('deliver')) return _BucketStyle.delivered;
  if (b.contains('rto')) return _BucketStyle.rto;
  if (b.contains('transit') || b.contains('picked')) return _BucketStyle.transit;
  if (b.contains('ofd') || b.contains('out for')) return _BucketStyle.ofd;
  if (b.contains('pending') || b.contains('confirm') || b.contains('placed')) {
    return _BucketStyle.pending;
  }
  if (b == 'in' || b.contains('incoming') || b.contains('received')) {
    return _BucketStyle.inStock;
  }
  return _BucketStyle.other;
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({
    required this.row,
    required this.displayDateFmt,
  });

  final ProductStockHistoryRow row;
  final DateFormat displayDateFmt;

  (Color bg, Color fg, IconData icon) get _pill {
    final amberBg =
        AppColors.isDark ? const Color(0xFF3A2E14) : const Color(0xFFFEF3C7);
    final amberFg =
        AppColors.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final purpleBg =
        AppColors.isDark ? const Color(0xFF2A1F40) : const Color(0xFFF3E8FF);
    final purpleFg =
        AppColors.isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED);

    switch (_bucketStyleFor(row.bucket)) {
      case _BucketStyle.delivered:
        return (PreviewTheme.greenSoft, PreviewTheme.green, Icons.check_rounded);
      case _BucketStyle.cancelled:
        return (PreviewTheme.redSoft, PreviewTheme.red, Icons.close_rounded);
      case _BucketStyle.rto:
        return (amberBg, amberFg, Icons.undo_rounded);
      case _BucketStyle.transit:
        return (PreviewTheme.blueSoft, PreviewTheme.blue, Icons.local_shipping_outlined);
      case _BucketStyle.ofd:
        return (purpleBg, purpleFg, Icons.delivery_dining_rounded);
      case _BucketStyle.pending:
        return (amberBg, amberFg, Icons.schedule_rounded);
      case _BucketStyle.inStock:
        return (PreviewTheme.tealSoft, PreviewTheme.teal, Icons.south_west_rounded);
      case _BucketStyle.other:
        return (
          PreviewTheme.field,
          PreviewTheme.textSecondary,
          Icons.label_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pill = _pill;
    final qty = row.displayQty;
    final isOut = qty != null && qty < 0;
    final isIn = qty != null && qty > 0;
    final qtyColor = qty == null
        ? PreviewTheme.textMuted
        : isIn
            ? PreviewTheme.green
            : PreviewTheme.red;
    final qtyText = qty == null
        ? '—'
        : qty > 0
            ? '+$qty'
            : '$qty';

    final dt = row.dateIst?.toLocal();
    final dateStr = dt != null ? displayDateFmt.format(dt) : '—';
    final running = row.runningStock;
    final afterText = running == null ? '—' : running.round().toString();
    final beforeText = (running != null && qty != null)
        ? '${running.round() - qty}'
        : '—';
    final orderNo =
        row.orderNumber.trim().isEmpty ? '—' : row.orderNumber.trim();
    final customer =
        row.customer.trim().isEmpty ? '—' : row.customer.trim();

    final accent = pill.$2;
    final edge = Color.lerp(
          PreviewTheme.cardEdge,
          accent,
          AppColors.isDark ? 0.35 : 0.28,
        ) ??
        PreviewTheme.cardEdge;

    return Container(
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: edge, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: AppColors.isDark ? 0.16 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          ...PreviewTheme.cardShadow,
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent, accent.withValues(alpha: 0.55)],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: pill.$1,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(pill.$3, size: 18, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.bucket,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: PreviewTheme.text,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  orderNo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: PreviewTheme.textSecondary,
                                  ),
                                ),
                              ),
                              if (orderNo != '—') ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: orderNo),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order code copied'),
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.content_copy_rounded,
                                      size: 14,
                                      color: PreviewTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (customer != '—') ...[
                            const SizedBox(height: 2),
                            Text(
                              customer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: PreviewTheme.textMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '$dateStr  ·  Pehle $beforeText  →  $afterText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: PreviewTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      qtyText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                        color: qtyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockSummaryStrip extends StatelessWidget {
  const _StockSummaryStrip({
    required this.opening,
    required this.closing,
    required this.now,
  });

  final double? opening;
  final double? closing;
  final double? now;

  String _fmt(double? v) => v == null ? '—' : v.round().toString();

  @override
  Widget build(BuildContext context) {
    final nowVal = now ?? closing;
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Opening',
            value: _fmt(opening),
            icon: Icons.history_rounded,
            accent: PreviewTheme.blue,
            soft: PreviewTheme.blueSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: 'Now',
            value: _fmt(nowVal),
            icon: Icons.inventory_2_rounded,
            accent: PreviewTheme.orange,
            soft: PreviewTheme.orangeSoft,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.soft,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PreviewTheme.cardEdge, width: 1.2),
        boxShadow: [
          ...PreviewTheme.cardShadow,
          BoxShadow(
            color: accent.withValues(alpha: AppColors.isDark ? 0.14 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1,
                    color: PreviewTheme.text,
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
