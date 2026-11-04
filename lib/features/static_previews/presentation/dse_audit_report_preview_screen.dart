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
                  Row(
                    children: [
                      PreviewStatChip(
                        label: 'SKUs',
                        value: '${_summary.skus}',
                        color: PreviewTheme.blue,
                        soft: PreviewTheme.blueSoft,
                      ),
                      const SizedBox(width: 8),
                      PreviewStatChip(
                        label: 'Shortage',
                        value: '${_summary.shortage}',
                        color: PreviewTheme.red,
                        soft: PreviewTheme.redSoft,
                      ),
                      const SizedBox(width: 8),
                      PreviewStatChip(
                        label: 'Excess',
                        value: '${_summary.excess}',
                        color: PreviewTheme.green,
                        soft: PreviewTheme.greenSoft,
                      ),
                      const SizedBox(width: 8),
                      PreviewStatChip(
                        label: 'Matched',
                        value: '${_summary.matched}',
                        color: PreviewTheme.textSecondary,
                        soft: PreviewTheme.field,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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

class _AuditCard extends StatelessWidget {
  const _AuditCard({
    required this.row,
    required this.onTap,
  });

  final DseAuditReportRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMatched = row.diff == 0;
    final isExcess = row.diff > 0;
    final accent = isMatched
        ? PreviewTheme.blue
        : (isExcess ? PreviewTheme.green : PreviewTheme.red);
    final accentSoft = isMatched
        ? PreviewTheme.blueSoft
        : (isExcess ? PreviewTheme.greenSoft : PreviewTheme.redSoft);
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
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0x0F0F172A),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentSoft.withValues(alpha: 0.55),
                        PreviewTheme.surface,
                        PreviewTheme.surface,
                      ],
                      stops: const [0, 0.38, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accent,
                        accent.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: PreviewTheme.blue.withValues(alpha: 0.28),
                            ),
                          ),
                          child: ProductImageThumb(
                            imageUrl: row.image,
                            width: 54,
                            height: 54,
                            borderRadius: 12,
                            backgroundColor: PreviewTheme.blueSoft,
                            showBorder: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _pill(
                                    icon: Icons.calendar_month_rounded,
                                    label: row.date,
                                    fg: PreviewTheme.blue,
                                    bg: PreviewTheme.blueSoft,
                                  ),
                                  _pill(
                                    icon: isExcess
                                        ? Icons.trending_up_rounded
                                        : (isMatched
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.trending_down_rounded),
                                    label: statusLabel,
                                    fg: accent,
                                    bg: accentSoft,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                row.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.2,
                                  color: PreviewTheme.text,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: PreviewTheme.orangeSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'SKU: ${row.sku}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: PreviewTheme.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 64),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: accentSoft,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Text(
                                  diffText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    height: 1,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: PreviewTheme.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _metricTile(
                          icon: Icons.storage_rounded,
                          label: 'System Stock',
                          value: Text(
                            '${row.system}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              height: 1.05,
                              color: PreviewTheme.blue,
                            ),
                          ),
                          soft: PreviewTheme.blueSoft,
                          accent: PreviewTheme.blue,
                        ),
                        const SizedBox(width: 8),
                        _metricTile(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Sale / RTO',
                          value: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${row.sale}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: PreviewTheme.blue,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: PreviewTheme.textSecondary,
                                  ),
                                ),
                                TextSpan(
                                  text: '${row.rto}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: PreviewTheme.red,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          soft: const Color(0xFFE8EEF7),
                          accent: const Color(0xFF1E3A5F),
                        ),
                        const SizedBox(width: 8),
                        _metricTile(
                          icon: Icons.call_received_rounded,
                          label: 'Transfer (IN)',
                          value: Text(
                            '${row.transferIn}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              height: 1.05,
                              color: PreviewTheme.green,
                            ),
                          ),
                          soft: PreviewTheme.greenSoft,
                          accent: PreviewTheme.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _metricTile(
                          icon: Icons.call_made_rounded,
                          label: 'Transfer (OUT)',
                          value: Text(
                            '${row.transferOut}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              height: 1.05,
                              color: PreviewTheme.red,
                            ),
                          ),
                          soft: PreviewTheme.redSoft,
                          accent: PreviewTheme.red,
                        ),
                        const SizedBox(width: 8),
                        _metricTile(
                          icon: Icons.flag_outlined,
                          label: 'Expected Qty',
                          value: Text(
                            '${row.expected}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              height: 1.05,
                              color: PreviewTheme.text,
                            ),
                          ),
                          soft: const Color(0xFFE8EEF7),
                          accent: const Color(0xFF1E3A5F),
                        ),
                        const SizedBox(width: 8),
                        _metricTile(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'DSE Claim',
                          value: Text(
                            '${row.claim}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              height: 1.05,
                              color: PreviewTheme.green,
                            ),
                          ),
                          soft: PreviewTheme.greenSoft,
                          accent: PreviewTheme.green,
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
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required Color fg,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String label,
    required Widget value,
    required Color soft,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: PreviewTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            value,
          ],
        ),
      ),
    );
  }
}
