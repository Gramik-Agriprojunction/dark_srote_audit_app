import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_date_pickers.dart';
import '../../../core/widgets/module_ui.dart';
import 'lmd_attendance_detail_screen.dart';
import 'preview_theme.dart';

/// Static DSE Attendance list — matches design mock (day cards + rules).
class LmdAttendancePreviewScreen extends ConsumerStatefulWidget {
  const LmdAttendancePreviewScreen({super.key});

  @override
  ConsumerState<LmdAttendancePreviewScreen> createState() =>
      _LmdAttendancePreviewScreenState();
}

class _LmdAttendancePreviewScreenState
    extends ConsumerState<LmdAttendancePreviewScreen> {
  static const _employees = <String>[
    'EMP001 - Ravi Singh',
    'EMP002 - Amit Kumar',
    'EMP003 - Suresh Yadav',
    'EMP004 - Priya Sharma',
  ];

  static const _days = <LmdAttendanceDetailDay>[
    LmdAttendanceDetailDay(
      title: 'Thursday, 8 Oct 2026',
      status: LmdDetailStatus.present,
      first: '10:20 AM',
      last: '6:15 PM',
      hours: '7h 55m',
      audited: 112,
      pending: 0,
      matchPct: 100,
      shortQty: 0,
      excess: 0,
      picked: 28,
      transit: 12,
      delivered: 6,
    ),
    LmdAttendanceDetailDay(
      title: 'Wednesday, 7 Oct 2026',
      status: LmdDetailStatus.halfDay,
      first: '10:20 AM',
      last: '7:25 PM',
      hours: '9h 5m',
      audited: 98,
      pending: 0,
      matchPct: 96,
      shortQty: 3,
      excess: 1,
      picked: 22,
      transit: 9,
      delivered: 7,
    ),
    LmdAttendanceDetailDay(
      title: 'Tuesday, 6 Oct 2026',
      status: LmdDetailStatus.absent,
      first: '9:25 AM',
      last: '6:30 PM',
      hours: '9h 5m',
      audited: 56,
      pending: 12,
      matchPct: 85,
      shortQty: 8,
      excess: 4,
      picked: 14,
      transit: 6,
      delivered: 3,
    ),
    LmdAttendanceDetailDay(
      title: 'Monday, 5 Oct 2026',
      status: LmdDetailStatus.absent,
      note: 'No entries logged',
      audited: 0,
      pending: 0,
      matchPct: 0,
      shortQty: 0,
      excess: 0,
    ),
    LmdAttendanceDetailDay(
      title: 'Sunday, 4 Oct 2026',
      status: LmdDetailStatus.holiday,
      note: 'Full day Holiday',
      audited: 0,
      pending: 0,
      matchPct: 0,
      shortQty: 0,
      excess: 0,
    ),
    LmdAttendanceDetailDay(
      title: 'Saturday, 3 Oct 2026',
      status: LmdDetailStatus.wop,
      note: 'Work Off Permission (WOP)',
      audited: 0,
      pending: 0,
      matchPct: 0,
      shortQty: 0,
      excess: 0,
    ),
  ];

  String _employee = _employees.first;
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

  Future<void> _pickEmployee() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<String>(
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
              for (final e in _employees)
                ListTile(
                  leading: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    e,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: e == _employee
                      ? Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, e),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() => _employee = picked);
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
            onLogout: () async {},
            showNotifications: true,
            bottom: Row(
              children: [
                Expanded(
                  child: PreviewSelectField(
                    icon: Icons.person_outline_rounded,
                    label: _employee,
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              children: [
                for (var i = 0; i < _days.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _DayCard(
                    day: _days[i],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // Day card → same orange DSE list-style detail (not red).
                      context.push('/preview/lmd-attendance/detail', extra: {
                        'employee': _employee,
                        'month': _monthLabel,
                        'day': _days[i],
                      });
                    },
                  ),
                ],
                const SizedBox(height: 14),
                const _RulesCard(),
              ],
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
                    _meta(
                      Icons.login_rounded,
                      'First Activity',
                      day.first!,
                    ),
                    _meta(
                      Icons.logout_rounded,
                      'Last Activity',
                      day.last!,
                    ),
                    _meta(
                      Icons.timer_outlined,
                      'Working Hours',
                      day.hours!,
                    ),
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
