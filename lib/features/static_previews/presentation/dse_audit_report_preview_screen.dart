import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_date_pickers.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/product_image_thumb.dart';
import '../../stock_audit/data/models/dse_audit_report_model.dart';
import '../../stock_audit/data/stock_audit_repository.dart';
import 'preview_theme.dart';

/// DSE Audit Report — System / Sale·RTO / IN / OUT / Expect / Claim from V2 inventory register.
class DseAuditReportPreviewScreen extends ConsumerStatefulWidget {
  const DseAuditReportPreviewScreen({super.key});

  @override
  ConsumerState<DseAuditReportPreviewScreen> createState() =>
      _DseAuditReportPreviewScreenState();
}

class _DseAuditReportPreviewScreenState
    extends ConsumerState<DseAuditReportPreviewScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int? _storeId;
  String _storeName = 'Dark Store';
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  String _status = 'all';
  String? _auditDate;

  List<DseAuditReportRow> _rows = const [];
  List<String> _dates = const [];
  DseAuditReportSummary _summary = const DseAuditReportSummary(
    skus: 0,
    shortage: 0,
    excess: 0,
    matched: 0,
  );
  DseAuditReportMeta _meta = const DseAuditReportMeta(
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 0,
  );

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  String get _monthLabel => DateFormat('MMM yyyy').format(_month);
  String get _monthApi => DateFormat('yyyy-MM').format(_month);

  String get _statusLabel {
    switch (_status) {
      case 'shortage':
        return 'Shortage';
      case 'excess':
        return 'Excess';
      case 'matched':
        return 'Matched';
      default:
        return 'All Status';
    }
  }

  String get _dateLabel {
    if (_auditDate == null || _auditDate!.isEmpty) return 'All Date';
    try {
      final d = DateTime.parse(_auditDate!);
      return DateFormat('d MMM').format(d);
    } catch (_) {
      return _auditDate!;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final storage = ref.read(sessionStorageProvider);
    final preferred = await storage.getSelectedStoreId();
    final repo = ref.read(stockAuditRepositoryProvider);
    try {
      final locations = await repo.getBusinessLocations();
      int? storeId = preferred;
      if (storeId == null || !locations.any((l) => l.id == storeId)) {
        storeId = locations.length == 1 ? locations.first.id : preferred;
      }
      if (storeId == null && locations.isNotEmpty) {
        storeId = locations.first.id;
      }
      final storeMatch = locations.where((l) => l.id == storeId);
      final storeName = storeMatch.isNotEmpty
          ? (storeMatch.first.label.trim().isNotEmpty
              ? storeMatch.first.label
              : (storeMatch.first.name ?? 'Dark Store'))
          : 'Dark Store';
      if (!mounted) return;
      setState(() {
        _storeId = storeId;
        _storeName = storeName;
      });
      await _fetch(reset: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    final storeId = _storeId;
    if (storeId == null || storeId <= 0) {
      setState(() {
        _loading = false;
        _error = 'Store select nahi hai. Pehle Stock tab se store choose karo.';
        _rows = [];
      });
      return;
    }

    final nextPage = reset ? 1 : _meta.page + 1;
    if (!reset && (_loadingMore || nextPage > (_meta.totalPages == 0 ? 1 : _meta.totalPages))) {
      return;
    }

    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final report = await ref.read(stockAuditRepositoryProvider).getDseAuditReport(
            businessLocationId: storeId,
            month: _monthApi,
            search: _searchCtrl.text,
            status: _status,
            auditDate: _auditDate,
            page: nextPage,
            limit: 20,
          );
      if (!mounted) return;
      setState(() {
        _dates = report.dates;
        _summary = report.summary;
        _meta = report.meta;
        _rows = reset ? report.rows : [..._rows, ...report.rows];
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

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetch(reset: true);
    });
  }

  Future<void> _pickMonth() async {
    HapticFeedback.selectionClick();
    final picked = await AppDatePickers.pickDate(
      context,
      initialDate: _month,
      helpText: 'Select month',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _month = DateTime(picked.year, picked.month, 1);
      _auditDate = null;
    });
    await _fetch(reset: true);
  }

  Future<void> _pickStatus() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        const options = <(String, String)>[
          ('all', 'All Status'),
          ('shortage', 'Shortage'),
          ('excess', 'Excess'),
          ('matched', 'Matched'),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final o in options)
                ListTile(
                  title: Text(
                    o.$2,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PreviewTheme.text,
                    ),
                  ),
                  trailing: _status == o.$1
                      ? Icon(Icons.check_rounded, color: PreviewTheme.orange)
                      : null,
                  onTap: () => Navigator.pop(ctx, o.$1),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _status = picked);
    await _fetch(reset: true);
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  'All Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: PreviewTheme.text,
                  ),
                ),
                trailing: _auditDate == null
                    ? Icon(Icons.check_rounded, color: PreviewTheme.orange)
                    : null,
                onTap: () => Navigator.pop(ctx, ''),
              ),
              for (final d in _dates)
                ListTile(
                  title: Text(
                    _formatDay(d),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PreviewTheme.text,
                    ),
                  ),
                  trailing: _auditDate == d
                      ? Icon(Icons.check_rounded, color: PreviewTheme.orange)
                      : null,
                  onTap: () => Navigator.pop(ctx, d),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _auditDate = picked.isEmpty ? null : picked);
    await _fetch(reset: true);
  }

  String _formatDay(String key) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(key));
    } catch (_) {
      return key;
    }
  }

  void _resetFilters() {
    HapticFeedback.selectionClick();
    _searchCtrl.clear();
    setState(() {
      _status = 'all';
      _auditDate = null;
    });
    _fetch(reset: true);
  }

  void _openStockLedger(DseAuditReportRow row) {
    final storeId = _storeId;
    if (storeId == null || storeId <= 0 || row.variantId <= 0) return;
    HapticFeedback.selectionClick();
    final sku = row.sku.trim().isNotEmpty ? row.sku.trim() : '—';
    context.push(
      '/preview/stock-ledger',
      extra: {
        'productName': row.name,
        'variantLabel': sku,
        'sku': sku,
        'storeName': _storeName,
        'imageUrl': row.image,
        'variantId': row.variantId,
        'businessLocationId': storeId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'DSE Audit Report',
            subtitle: () {
              final store = ref.watch(headerGreetingProvider);
              return store.isEmpty ? null : store;
            }(),
            onBack: () => context.pop(),
            showNotifications: false,
            searchController: _searchCtrl,
            searchHint: 'Search product (name / SKU / code)...',
            searchValue: _searchCtrl.text,
            onSearchChanged: (value) {
              setState(() {});
              _onSearchChanged(value);
            },
            onClearSearch: () {
              _searchCtrl.clear();
              setState(() {});
              _fetch(reset: true);
            },
            bottom: Column(
              children: [
                PreviewSelectField(
                  icon: Icons.calendar_month_rounded,
                  label: _monthLabel,
                  onHeader: true,
                  onTap: _pickMonth,
                ),
                const SizedBox(height: 8),
                _Filters(
                  onHeader: true,
                  statusLabel: _statusLabel,
                  dateLabel: _dateLabel,
                  onStatus: _pickStatus,
                  onDate: _pickDate,
                  onReset: _resetFilters,
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
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                children: [
                  _SummaryStrip(summary: _summary),
                  const SizedBox(height: 14),
                  if (!_loading || _rows.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(
                            'Audit list',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: PreviewTheme.text,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_meta.total} SKUs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PreviewTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_loading && _rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null && _rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PreviewTheme.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => _fetch(reset: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Is month me koi audit nahi mila',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PreviewTheme.textMuted,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    for (var i = 0; i < _rows.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _AuditCard(
                        row: _rows[i],
                        onTap: () => _openStockLedger(_rows[i]),
                      ),
                    ],
                    if (_meta.page < _meta.totalPages) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _loadingMore ? null : () => _fetch(),
                          child: _loadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Load more'),
                        ),
                      ),
                    ],
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

class _Filters extends StatelessWidget {
  const _Filters({
    required this.statusLabel,
    required this.dateLabel,
    required this.onStatus,
    required this.onDate,
    required this.onReset,
    this.onHeader = false,
  });

  final bool onHeader;
  final String statusLabel;
  final String dateLabel;
  final VoidCallback onStatus;
  final VoidCallback onDate;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final onOrange = onHeader && !AppColors.isDark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(statusLabel, onOrange, onStatus),
          const SizedBox(width: 8),
          _chip(dateLabel, onOrange, onDate),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onReset,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: onOrange
                      ? Colors.white.withValues(alpha: 0.22)
                      : PreviewTheme.blueSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: onOrange ? Colors.white : PreviewTheme.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: onOrange ? Colors.white : PreviewTheme.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool onOrange, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: onOrange
                ? Colors.white.withValues(alpha: 0.18)
                : PreviewTheme.field,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: onOrange
                  ? Colors.white.withValues(alpha: 0.28)
                  : PreviewTheme.border,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: onOrange ? Colors.white : PreviewTheme.textSecondary,
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: onOrange
                    ? Colors.white.withValues(alpha: 0.85)
                    : PreviewTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final DseAuditReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: PreviewTheme.cardShadow,
      ),
      child: Row(
        children: [
          _SummaryTile(
            label: 'SKUs',
            value: '${summary.skus}',
            color: PreviewTheme.blue,
            soft: PreviewTheme.blueSoft,
          ),
          const SizedBox(width: 8),
          _SummaryTile(
            label: 'Shortage',
            value: '${summary.shortage}',
            color: PreviewTheme.red,
            soft: PreviewTheme.redSoft,
          ),
          const SizedBox(width: 8),
          _SummaryTile(
            label: 'Excess',
            value: '${summary.excess}',
            color: PreviewTheme.orange,
            soft: PreviewTheme.orangeSoft,
          ),
          const SizedBox(width: 8),
          _SummaryTile(
            label: 'Matched',
            value: '${summary.matched}',
            color: PreviewTheme.green,
            soft: PreviewTheme.greenSoft,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
  });

  final String label;
  final String value;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _displaySku(String? raw) {
  var value = (raw ?? '').trim();
  if (value.isEmpty) return '—';
  value = value.replaceFirst(RegExp(r'^sku\s*[:\-]?\s*', caseSensitive: false), '');
  return value.trim().isEmpty ? '—' : value.trim();
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({
    required this.row,
    required this.onTap,
  });

  final DseAuditReportRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skuLabel = _displaySku(row.sku);
    final isMatched = row.diff == 0;
    final isExcess = row.diff > 0;
    final accent = isMatched
        ? PreviewTheme.green
        : (isExcess ? PreviewTheme.orange : PreviewTheme.red);
    final soft = isMatched
        ? PreviewTheme.greenSoft
        : (isExcess ? PreviewTheme.orangeSoft : PreviewTheme.redSoft);
    final statusLabel = isMatched
        ? 'Matched'
        : (isExcess ? 'Excess' : 'Shortage');
    final diffText = isExcess
        ? '+${row.diff}'
        : (isMatched ? '0' : '${row.diff}');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: PreviewTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PreviewTheme.cardEdge, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: AppColors.isDark ? 0.18 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
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
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, accent.withValues(alpha: 0.45)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: ProductImageThumb(
                                imageUrl: row.image,
                                width: 56,
                                height: 56,
                                borderRadius: 14,
                                backgroundColor: PreviewTheme.field,
                                showBorder: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      letterSpacing: -0.25,
                                      color: PreviewTheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: PreviewTheme.orangeSoft,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            skuLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: PreviewTheme.orange,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        row.date,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: PreviewTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: soft,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMatched
                                        ? Icons.check_circle_rounded
                                        : (isExcess
                                            ? Icons.trending_up_rounded
                                            : Icons.trending_down_rounded),
                                    size: 13,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QtyPanel(
                                label: 'Expected',
                                value: '${row.expected}',
                                icon: Icons.flag_outlined,
                                color: PreviewTheme.blue,
                                soft: PreviewTheme.blueSoft,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QtyPanel(
                                label: 'DSE Claim',
                                value: '${row.claim}',
                                icon: Icons.verified_outlined,
                                color: PreviewTheme.green,
                                soft: PreviewTheme.greenSoft,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 64,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: soft,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Diff',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: accent.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    diffText,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                      height: 1,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: PreviewTheme.field,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: PreviewTheme.cardEdge),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _FlowMetric(
                                  label: 'System',
                                  value: '${row.system}',
                                ),
                              ),
                              _FlowDivider(),
                              Expanded(
                                child: _FlowMetric(
                                  label: 'Sale/RTO',
                                  value: '${row.sale}/${row.rto}',
                                ),
                              ),
                              _FlowDivider(),
                              Expanded(
                                child: _FlowMetric(
                                  label: 'IN',
                                  value: '${row.transferIn}',
                                  valueColor: PreviewTheme.green,
                                ),
                              ),
                              _FlowDivider(),
                              Expanded(
                                child: _FlowMetric(
                                  label: 'OUT',
                                  value: '${row.transferOut}',
                                  valueColor: PreviewTheme.red,
                                ),
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
      ),
    );
  }
}

class _QtyPanel extends StatelessWidget {
  const _QtyPanel({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.soft,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
              color: PreviewTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowMetric extends StatelessWidget {
  const _FlowMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: PreviewTheme.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
              height: 1,
              color: valueColor ?? PreviewTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: PreviewTheme.border,
    );
  }
}
