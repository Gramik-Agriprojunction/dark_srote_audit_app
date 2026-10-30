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
import '../../stock_audit/data/models/dse_attendance_model.dart';
import '../../stock_audit/data/stock_audit_repository.dart';
import 'lmd_attendance_detail_screen.dart';
import 'preview_theme.dart';

/// DSE Attendance — daily audit attendance from `/dse-attendance`.
class LmdAttendancePreviewScreen extends ConsumerStatefulWidget {
  const LmdAttendancePreviewScreen({super.key});

  @override
  ConsumerState<LmdAttendancePreviewScreen> createState() =>
      _LmdAttendancePreviewScreenState();
}

class _LmdAttendancePreviewScreenState
    extends ConsumerState<LmdAttendancePreviewScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int? _storeId;
  int? _employeeId;
  List<DseAttendanceEmployee> _employees = const [];
  List<DseAttendanceDay> _days = const [];
  bool _loading = true;
  String? _error;

  String get _monthLabel => DateFormat('MMM yyyy').format(_month);
  String get _monthApi => DateFormat('yyyy-MM').format(_month);

  String get _employeeLabel {
    if (_employees.isEmpty) return 'Employee';
    final match = _employees.where((e) => e.id == _employeeId);
    if (match.isNotEmpty) return match.first.label;
    return _employees.first.label;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
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
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  Future<void> _fetch() async {
    final storeId = _storeId;
    if (storeId == null || storeId <= 0) {
      setState(() {
        _loading = false;
        _error = 'Store select nahi hai. Pehle Stock tab se store choose karo.';
        _days = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await ref.read(stockAuditRepositoryProvider).getDseAttendance(
            businessLocationId: storeId,
            month: _monthApi,
            employeeUserId: _employeeId,
          );
      if (!mounted) return;
      setState(() {
        _employees = report.employees;
        _employeeId = report.selectedEmployeeId;
        _days = report.days;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        _days = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _days = [];
      });
    }
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
    setState(() => _month = DateTime(picked.year, picked.month, 1));
    await _fetch();
  }

  Future<void> _pickEmployee() async {
    if (_employees.isEmpty) return;
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select employee',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in _employees)
                      ListTile(
                        leading: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          e.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: e.id == _employeeId
                            ? Icon(Icons.check_rounded, color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.pop(ctx, e.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() => _employeeId = picked);
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeModeProvider);

    return Scaffold(
      backgroundColor: PreviewTheme.bg,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'DSE Attendance',
            subtitle: 'Dark Store Audit Attendance',
            onBack: () => context.pop(),
            showNotifications: true,
            bottom: Row(
              children: [
                Expanded(
                  child: PreviewSelectField(
                    icon: Icons.person_outline_rounded,
                    label: _employeeLabel,
                    onHeader: true,
                    onTap: _pickEmployee,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PreviewSelectField(
                    icon: Icons.calendar_month_rounded,
                    label: _monthLabel,
                    onHeader: true,
                    onTap: _pickMonth,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: PreviewTheme.orange,
              onRefresh: _fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
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
                  else if (_days.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'Is month me koi attendance day nahi mila',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PreviewTheme.textMuted,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < _days.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _DayCard(
                        day: LmdAttendanceDetailDay.fromDse(_days[i]),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push('/preview/lmd-attendance/detail', extra: {
                            'employee': _employeeLabel,
                            'month': _monthLabel,
                            'day': LmdAttendanceDetailDay.fromDse(_days[i]),
                          });
                        },
                      ),
                    ],
                  const SizedBox(height: 14),
                  const _RulesCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, this.onTap});

  final LmdAttendanceDetailDay day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = day.badge;
    final showTimes =
        day.first != null && day.last != null && day.hours != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: PreviewTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PreviewTheme.border),
            boxShadow: PreviewTheme.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      day.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: PreviewTheme.text,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badge.$3,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge.$1,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: badge.$2,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: PreviewTheme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (showTimes)
                Row(
                  children: [
                    _meta(Icons.login_rounded, 'First Activity', day.first!),
                    _meta(Icons.logout_rounded, 'Last Activity', day.last!),
                    _meta(Icons.timer_outlined, 'Working Hours', day.hours!),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: badge.$3,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    day.note ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: badge.$2,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniKpi(
                    icon: Icons.inventory_2_outlined,
                    label: 'SKU Audited',
                    value: '${day.audited}',
                    fg: PreviewTheme.blue,
                    bg: PreviewTheme.blueSoft,
                  ),
                  const SizedBox(width: 6),
                  _MiniKpi(
                    icon: Icons.pending_actions_outlined,
                    label: 'SKU Pending',
                    value: '${day.pending}',
                    fg: PreviewTheme.orange,
                    bg: PreviewTheme.orangeSoft,
                  ),
                  const SizedBox(width: 6),
                  _MiniKpi(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Match',
                    value: '${day.matchPct}%',
                    fg: PreviewTheme.green,
                    bg: PreviewTheme.greenSoft,
                  ),
                  const SizedBox(width: 6),
                  _MiniKpi(
                    icon: Icons.trending_down_rounded,
                    label: 'Short',
                    value: '${day.shortQty}',
                    fg: PreviewTheme.rose,
                    bg: PreviewTheme.roseSoft,
                  ),
                  const SizedBox(width: 6),
                  _MiniKpi(
                    icon: Icons.trending_up_rounded,
                    label: 'Excess',
                    value: '${day.excess}',
                    fg: PreviewTheme.teal,
                    bg: PreviewTheme.tealSoft,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: PreviewTheme.textMuted),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: PreviewTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: PreviewTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.fg,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: fg.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: fg,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    final rules = <(String, Color, Color, String)>[
      (
        'Present',
        PreviewTheme.green,
        PreviewTheme.greenSoft,
        'SKU Pending = 0, Match = 100%, Short = 0, Excess = 0',
      ),
      (
        'Half Day',
        PreviewTheme.orange,
        PreviewTheme.orangeSoft,
        'SKU Pending = 0, Short > 0 or Excess > 0',
      ),
      (
        'Absent',
        PreviewTheme.red,
        PreviewTheme.redSoft,
        'SKU Pending > 0 and (Short > 0 or Excess > 0)',
      ),
      (
        'Holiday',
        PreviewTheme.blue,
        PreviewTheme.blueSoft,
        'Company defined holiday / weekly off day',
      ),
      (
        'WOP',
        AppColors.isDark ? const Color(0xFFB794F6) : const Color(0xFF7C3AED),
        AppColors.isDark ? const Color(0xFF2E2145) : const Color(0xFFF3E8FF),
        'Work Off Permission (Approved leave)',
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? const Color(0xFF2A2438)
            : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.isDark
              ? const Color(0xFF3D3554)
              : const Color(0xFFE9E5FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.isDark
                    ? const Color(0xFFB794F6)
                    : const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 8),
              Text(
                'Attendance Status Rules',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.isDark
                      ? const Color(0xFFE9D5FF)
                      : const Color(0xFF5B21B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rules.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 78,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rules[i].$3,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        rules[i].$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: rules[i].$2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      rules[i].$4,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.isDark
                            ? const Color(0xFFD8B4FE)
                            : const Color(0xFF4C1D95),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
