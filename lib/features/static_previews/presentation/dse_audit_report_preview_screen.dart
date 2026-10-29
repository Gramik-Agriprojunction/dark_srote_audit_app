import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_date_pickers.dart';
import '../../../core/widgets/module_ui.dart';
import 'preview_theme.dart';

/// Static DSE Audit Report — orange ModuleHeader + working date picker.
class DseAuditReportPreviewScreen extends ConsumerStatefulWidget {
  const DseAuditReportPreviewScreen({super.key});

  @override
  ConsumerState<DseAuditReportPreviewScreen> createState() =>
      _DseAuditReportPreviewScreenState();
}

class _DseAuditReportPreviewScreenState
    extends ConsumerState<DseAuditReportPreviewScreen> {
  static const _rows = <_Row>[
    _Row('23 Oct 2026', 'Mustard Oil 1 Ltr', 'MST-001', 150, 20, 2, 10, 5, 133, 128, -5),
    _Row('23 Oct 2026', 'Sugar 1 Kg', 'SGR-001', 200, 35, 3, 20, 10, 170, 160, -10),
    _Row('23 Oct 2026', 'Basmati Rice 5 Kg', 'RCE-005', 75, 12, 1, 5, 8, 55, 58, 3),
    _Row('22 Oct 2026', 'Wheat Atta 10 Kg', 'WHT-010', 120, 25, 0, 15, 5, 103, 93, -10),
    _Row('22 Oct 2026', 'Toor Dal 1 Kg', 'TOOR-1', 80, 10, 2, 6, 4, 68, 66, -2),
    _Row('21 Oct 2026', 'Tea 250 Gm', 'TEA-250', 95, 18, 1, 8, 3, 76, 71, -5),
    _Row('21 Oct 2026', 'Masoor Dal 1 Kg', 'MAS-1', 60, 8, 0, 5, 2, 53, 55, 2),
    _Row('20 Oct 2026', 'Sunflower Oil 1 Ltr', 'SUN-001', 110, 22, 3, 12, 6, 91, 85, -6),
  ];

  DateTime _month = DateTime(2026, 10, 1);

  String get _monthLabel => DateFormat('MMM yyyy').format(_month);

  Future<void> _pickMonth() async {
    HapticFeedback.selectionClick();
    final picked = await AppDatePickers.pickDate(
      context,
      initialDate: _month,
      helpText: 'Select month',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (!mounted || picked == null) return;
    setState(() => _month = DateTime(picked.year, picked.month, 1));
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
                const PreviewSearchRow(
                  hint: 'Search product (name / SKU / code)...',
                  onHeader: true,
                ),
                const SizedBox(height: 8),
                const _Filters(onHeader: true),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              children: [
                Row(
                  children: [
                    PreviewStatChip(
                      label: 'SKUs',
                      value: '${_rows.length}',
                      color: PreviewTheme.blue,
                      soft: PreviewTheme.blueSoft,
                    ),
                    const SizedBox(width: 8),
                    PreviewStatChip(
                      label: 'Shortage',
                      value: '6',
                      color: PreviewTheme.red,
                      soft: PreviewTheme.redSoft,
                    ),
                    const SizedBox(width: 8),
                    PreviewStatChip(
                      label: 'Excess',
                      value: '2',
                      color: PreviewTheme.green,
                      soft: PreviewTheme.greenSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < _rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _AuditCard(row: _rows[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(
    this.date,
    this.name,
    this.sku,
    this.system,
    this.sale,
    this.rto,
    this.transferIn,
    this.transferOut,
    this.expected,
    this.claim,
    this.diff,
  );

  final String date;
  final String name;
  final String sku;
  final int system;
  final int sale;
  final int rto;
  final int transferIn;
  final int transferOut;
  final int expected;
  final int claim;
  final int diff;
}

class _Filters extends StatelessWidget {
  const _Filters({this.onHeader = false});
  final bool onHeader;

  @override
  Widget build(BuildContext context) {
    final onOrange = onHeader && !AppColors.isDark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All Category', onOrange),
          const SizedBox(width: 8),
          _chip('All Status', onOrange),
          const SizedBox(width: 8),
          _chip('All Date', onOrange),
          const SizedBox(width: 8),
          Container(
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
        ],
      ),
    );
  }

  Widget _chip(String label, bool onOrange) {
    return Container(
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
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.row});
  final _Row row;

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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: PreviewTheme.field,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _metric('System', '${row.system}', PreviewTheme.blue),
                          _metric('Sale/RTO', '${row.sale}/${row.rto}', PreviewTheme.text),
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
