import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/module_ui.dart';
import '../../stock_audit/data/models/dse_attendance_model.dart';
import 'preview_theme.dart';
import 'widgets/dse_attendance_rules_panel.dart';

/// Day detail — same typography / cards as DSE Attendance list.
class DseAttendanceDetailScreen extends ConsumerWidget {
  const DseAttendanceDetailScreen({
    super.key,
    required this.day,
    this.employee = 'EMP001 - Ravi Singh',
    this.monthLabel = 'Oct 2026',
  });

  final DseAttendanceDetailDay day;
  final String employee;
  final String monthLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeModeProvider);
    final badge = day.badge;
    final showTimes =
        day.first != null && day.last != null && day.hours != null;

    return Scaffold(
      backgroundColor: PreviewTheme.bg,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'DSE Attendance',
            subtitle: () {
              final store = ref.watch(headerGreetingProvider);
              return store.isEmpty ? null : store;
            }(),
            onBack: () => context.pop(),
            showNotifications: false,
            bottom: PreviewSelectField(
              icon: Icons.calendar_month_rounded,
              label: monthLabel,
              onHeader: true,
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              children: [
                _HeroDayCard(
                  day: day,
                  badge: badge,
                  showTimes: showTimes,
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Audit performance',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _MetricTile(
                            label: 'SKU Audited',
                            value: '${day.audited}',
                            color: PreviewTheme.blue,
                            soft: PreviewTheme.blueSoft,
                          ),
                          const SizedBox(width: 8),
                          _MetricTile(
                            label: 'SKU Pending',
                            value: '${day.pending}',
                            color: PreviewTheme.orange,
                            soft: PreviewTheme.orangeSoft,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _MetricTile(
                            label: 'Match',
                            value: '${day.matchPct}%',
                            color: PreviewTheme.green,
                            soft: PreviewTheme.greenSoft,
                          ),
                          const SizedBox(width: 8),
                          _MetricTile(
                            label: 'Short',
                            value: '${day.shortQty}',
                            color: PreviewTheme.rose,
                            soft: PreviewTheme.roseSoft,
                          ),
                          const SizedBox(width: 8),
                          _MetricTile(
                            label: 'Excess',
                            value: '${day.excess}',
                            color: PreviewTheme.teal,
                            soft: PreviewTheme.tealSoft,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Logistics',
                  child: Row(
                    children: [
                      _MetricTile(
                        label: 'Picked Up',
                        value: '${day.picked}',
                        color: PreviewTheme.green,
                        soft: PreviewTheme.greenSoft,
                      ),
                      const SizedBox(width: 8),
                      _MetricTile(
                        label: 'In Transit',
                        value: '${day.transit}',
                        color: PreviewTheme.blue,
                        soft: PreviewTheme.blueSoft,
                      ),
                      const SizedBox(width: 8),
                      _MetricTile(
                        label: 'Delivered',
                        value: '${day.delivered}',
                        color: PreviewTheme.orange,
                        soft: PreviewTheme.orangeSoft,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const DseAttendanceRulesPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum LmdDetailStatus { present, halfDay, absent, holiday, wop }

class DseAttendanceDetailDay {
  const DseAttendanceDetailDay({
    required this.title,
    required this.status,
    this.first,
    this.last,
    this.hours,
    this.note,
    required this.audited,
    required this.pending,
    required this.matchPct,
    required this.shortQty,
    required this.excess,
    this.picked = 0,
    this.transit = 0,
    this.delivered = 0,
  });

  final String title;
  final LmdDetailStatus status;
  final String? first;
  final String? last;
  final String? hours;
  final String? note;
  final int audited;
  final int pending;
  final int matchPct;
  final int shortQty;
  final int excess;
  final int picked;
  final int transit;
  final int delivered;

  factory DseAttendanceDetailDay.fromDse(DseAttendanceDay day) {
    LmdDetailStatus status;
    switch (day.status) {
      case DseAttendanceStatus.present:
        status = LmdDetailStatus.present;
      case DseAttendanceStatus.halfDay:
        status = LmdDetailStatus.halfDay;
      case DseAttendanceStatus.holiday:
        status = LmdDetailStatus.holiday;
      case DseAttendanceStatus.wop:
        status = LmdDetailStatus.wop;
      case DseAttendanceStatus.absent:
        status = LmdDetailStatus.absent;
    }
    return DseAttendanceDetailDay(
      title: day.title,
      status: status,
      first: day.firstActivity,
      last: day.lastActivity,
      hours: day.workingHours,
      note: day.note,
      audited: day.skuAudited,
      pending: day.skuPending,
      matchPct: day.matchPct,
      shortQty: day.shortQty,
      excess: day.excess,
      picked: day.picked,
      transit: day.transit,
      delivered: day.delivered,
    );
  }

  (String, Color, Color) get badge {
    switch (status) {
      case LmdDetailStatus.present:
        return ('Present', PreviewTheme.green, PreviewTheme.greenSoft);
      case LmdDetailStatus.halfDay:
        return ('Half Day', PreviewTheme.orange, PreviewTheme.orangeSoft);
      case LmdDetailStatus.absent:
        return ('Absent', PreviewTheme.red, PreviewTheme.redSoft);
      case LmdDetailStatus.holiday:
        return ('Holiday', PreviewTheme.blue, PreviewTheme.blueSoft);
      case LmdDetailStatus.wop:
        return (
          'WOP',
          AppColors.isDark ? const Color(0xFFB794F6) : const Color(0xFF7C3AED),
          AppColors.isDark ? const Color(0xFF2E2145) : const Color(0xFFF3E8FF),
        );
    }
  }
}

class _HeroDayCard extends StatelessWidget {
  const _HeroDayCard({
    required this.day,
    required this.badge,
    required this.showTimes,
  });

  final DseAttendanceDetailDay day;
  final (String, Color, Color) badge;
  final bool showTimes;

  @override
  Widget build(BuildContext context) {
    final accent = badge.$2;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PreviewTheme.surface,
            Color.lerp(PreviewTheme.surface, badge.$3, 0.55) ??
                PreviewTheme.surface,
          ],
        ),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: AppColors.isDark ? 0.16 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          ...PreviewTheme.cardShadow,
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              day.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
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
                              border: Border.all(
                                color: accent.withValues(alpha: 0.18),
                              ),
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (showTimes)
                        Row(
                          children: [
                            _TimeChip(Icons.login_rounded, day.first!),
                            const SizedBox(width: 6),
                            _TimeChip(Icons.logout_rounded, day.last!),
                            const SizedBox(width: 6),
                            _TimeChip(Icons.timer_outlined, day.hours!),
                          ],
                        )
                      else if (day.note != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: badge.$3,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Text(
                            day.note!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: badge.$2,
                            ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: PreviewTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: PreviewTheme.text,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip(this.icon, this.value);

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: PreviewTheme.field,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PreviewTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: PreviewTheme.textMuted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: PreviewTheme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
