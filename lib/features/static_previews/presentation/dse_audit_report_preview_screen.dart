import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_date_pickers.dart';
import '../../../core/widgets/module_ui.dart';
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
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  String _status = 'all';
  int? _categoryId;
  String? _auditDate;

  List<DseAuditReportRow> _rows = const [];
  List<DseAuditReportCategory> _categories = const [];
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

  String get _categoryLabel {
    if (_categoryId == null) return 'All Category';
    final match = _categories.where((c) => c.id == _categoryId);
    if (match.isNotEmpty) return match.first.name;
    return 'All Category';
  }

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
      if (!mounted) return;
      setState(() => _storeId = storeId);
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
            categoryId: _categoryId,
            auditDate: _auditDate,
            page: nextPage,
            limit: 20,
          );
      if (!mounted) return;
      setState(() {
        _categories = report.categories;
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

  Future<void> _pickCategory() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<int?>(
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
                  'All Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: PreviewTheme.text,
                  ),
                ),
                trailing: _categoryId == null
                    ? Icon(Icons.check_rounded, color: PreviewTheme.orange)
                    : null,
                onTap: () => Navigator.pop(ctx, -1),
              ),
              for (final c in _categories)
                ListTile(
                  title: Text(
                    c.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PreviewTheme.text,
                    ),
                  ),
                  trailing: _categoryId == c.id
                      ? Icon(Icons.check_rounded, color: PreviewTheme.orange)
                      : null,
                  onTap: () => Navigator.pop(ctx, c.id),
                ),
            ],
          ),
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() => _categoryId = picked < 0 ? null : picked);
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
      _categoryId = null;
      _auditDate = null;
    });
    _fetch(reset: true);
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
            subtitle: 'Dark Store Audit Report',
            onBack: () => context.pop(),
            showNotifications: false,
            bottom: Column(
              children: [
                PreviewSelectField(
                  icon: Icons.calendar_month_rounded,
                  label: _monthLabel,
                  onHeader: true,
                  onTap: _pickMonth,
                ),
                const SizedBox(height: 8),
                _SearchRow(
                  controller: _searchCtrl,
                  hint: 'Search product (name / SKU / code)...',
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchCtrl.clear();
                    _fetch(reset: true);
                  },
                ),
                const SizedBox(height: 8),
                _Filters(
                  onHeader: true,
                  categoryLabel: _categoryLabel,
                  statusLabel: _statusLabel,
                  dateLabel: _dateLabel,
                  onCategory: _pickCategory,
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
                      _AuditCard(row: _rows[i]),
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

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final onOrange = !AppColors.isDark;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: onOrange
                  ? Colors.white.withValues(alpha: 0.18)
                  : PreviewTheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: onOrange
                    ? Colors.white.withValues(alpha: 0.28)
                    : PreviewTheme.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: onOrange
                      ? Colors.white.withValues(alpha: 0.85)
                      : PreviewTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onOrange ? Colors.white : PreviewTheme.text,
                    ),
                    cursorColor: onOrange ? Colors.white : PreviewTheme.orange,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: onOrange
                            ? Colors.white.withValues(alpha: 0.7)
                            : PreviewTheme.textMuted,
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
                        Icons.close_rounded,
                        size: 18,
                        color: onOrange
                            ? Colors.white.withValues(alpha: 0.85)
                            : PreviewTheme.textMuted,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: onOrange
                ? Colors.white.withValues(alpha: 0.18)
                : PreviewTheme.orangeSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onOrange
                  ? Colors.white.withValues(alpha: 0.35)
                  : PreviewTheme.orange.withValues(alpha: 0.55),
            ),
          ),
          child: Icon(
            Icons.filter_alt_rounded,
            size: 20,
            color: onOrange ? Colors.white : PreviewTheme.orange,
          ),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.categoryLabel,
    required this.statusLabel,
    required this.dateLabel,
    required this.onCategory,
    required this.onStatus,
    required this.onDate,
    required this.onReset,
    this.onHeader = false,
  });

  final bool onHeader;
  final String categoryLabel;
  final String statusLabel;
  final String dateLabel;
  final VoidCallback onCategory;
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
          _chip(categoryLabel, onOrange, onCategory),
          const SizedBox(width: 8),
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
  const _AuditCard({required this.row});
  final DseAuditReportRow row;

  @override
  Widget build(BuildContext context) {
    final diffPositive = row.diff >= 0;
    final accent = diffPositive ? PreviewTheme.green : PreviewTheme.red;
    final diffBg = diffPositive ? PreviewTheme.greenSoft : PreviewTheme.redSoft;
    final diffText = diffPositive ? '+${row.diff}' : '${row.diff}';

    return Container(
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: PreviewTheme.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: PreviewTheme.orangeSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: PreviewTheme.orange.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: PreviewTheme.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.date,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: PreviewTheme.textMuted,
                                ),
                              ),
                              Text(
                                row.name,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: PreviewTheme.text,
                                ),
                              ),
                              Text(
                                'SKU: ${row.sku}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: PreviewTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: diffBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            diffText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PreviewTheme.field,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _metric('System', '${row.system}', PreviewTheme.blue),
                          _metric(
                            'Sale/RTO',
                            '${row.sale}/${row.rto}',
                            PreviewTheme.text,
                          ),
                          _metric('IN', '${row.transferIn}', PreviewTheme.green),
                          _metric('OUT', '${row.transferOut}', PreviewTheme.red),
                          _metric('Expect', '${row.expected}', PreviewTheme.text),
                          _metric('Claim', '${row.claim}', PreviewTheme.green),
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
    );
  }

  Widget _metric(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: PreviewTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
