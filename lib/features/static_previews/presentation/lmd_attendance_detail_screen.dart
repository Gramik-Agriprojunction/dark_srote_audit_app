import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/module_ui.dart';
import 'preview_theme.dart';

/// Day detail — clean report layout (readable KPIs, clear sections).
class LmdAttendanceDetailScreen extends ConsumerWidget {
  const LmdAttendanceDetailScreen({
    super.key,
    required this.day,
    this.employee = 'EMP001 - Ravi Singh',
    this.monthLabel = 'Oct 2026',
  });

  final LmdAttendanceDetailDay day;
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
            subtitle: 'Dark Store Audit Attendance',
            onBack: () => context.pop(),
            showNotifications: false,
            bottom: Row(
              children: [
                Expanded(
                  child: PreviewSelectField(
                    icon: Icons.person_outline_rounded,
                    label: employee,
                    onHeader: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PreviewSelectField(
                    icon: Icons.calendar_month_rounded,
                    label: monthLabel,
                    onHeader: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // Status + date
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: PreviewTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: PreviewTheme.border),
                    boxShadow: PreviewTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Day summary',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: PreviewTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  day.title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: PreviewTheme.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: badge.$3,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge.$1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: badge.$2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (showTimes) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: PreviewTheme.field,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _TimeChip(
                                icon: Icons.login_rounded,
                                label: 'First',
                                value: day.first!,
                              ),
                              _TimeDivider(),
                              _TimeChip(
                                icon: Icons.logout_rounded,
                                label: 'Last',
                                value: day.last!,
                              ),
                              _TimeDivider(),
                              _TimeChip(
                                icon: Icons.schedule_rounded,
                                label: 'Hours',
                                value: day.hours!,
                              ),
                            ],
                          ),
                        ),
                      ] else if (day.note != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: badge.$3,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            day.note!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: badge.$2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Audit section
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
                            icon: Icons.inventory_2_outlined,
                          ),
                          const SizedBox(width: 10),
                          _MetricTile(
                            label: 'SKU Pending',
                            value: '${day.pending}',
                            color: PreviewTheme.orange,
                            soft: PreviewTheme.orangeSoft,
                            icon: Icons.pending_actions_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _MetricTile(
                            label: 'Match',
                            value: '${day.matchPct}%',
                            color: PreviewTheme.green,
                            soft: PreviewTheme.greenSoft,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                          const SizedBox(width: 10),
                          _MetricTile(
                            label: 'Short',
                            value: '${day.shortQty}',
                            color: PreviewTheme.rose,
                            soft: PreviewTheme.roseSoft,
                            icon: Icons.trending_down_rounded,
                          ),
                          const SizedBox(width: 10),
                          _MetricTile(
                            label: 'Excess',
                            value: '${day.excess}',
                            color: PreviewTheme.teal,
                            soft: PreviewTheme.tealSoft,
                            icon: Icons.trending_up_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Logistics
                _SectionCard(
                  title: 'Logistics',
                  child: Row(
                    children: [
                      _LogisticsTile(
                        label: 'Picked Up',
                        value: '${day.picked}',
                        color: PreviewTheme.green,
                        soft: PreviewTheme.greenSoft,
                        icon: Icons.inventory_2_rounded,
                      ),
                      const SizedBox(width: 10),
                      _LogisticsTile(
                        label: 'In Transit',
                        value: '${day.transit}',
                        color: PreviewTheme.blue,
                        soft: PreviewTheme.blueSoft,
                        icon: Icons.local_shipping_rounded,
                      ),
                      const SizedBox(width: 10),
                      _LogisticsTile(
                        label: 'Delivered',
                        value: '${day.delivered}',
                        color: PreviewTheme.orange,
                        soft: PreviewTheme.orangeSoft,
                        icon: Icons.assignment_turned_in_outlined,
                      ),
                    ],
                  ),
                ),

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

enum LmdDetailStatus { present, halfDay, absent, holiday, wop }

class LmdAttendanceDetailDay {
  const LmdAttendanceDetailDay({
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: PreviewTheme.text,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: PreviewTheme.orange),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: PreviewTheme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
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

class _TimeDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: PreviewTheme.border,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color soft;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogisticsTile extends StatelessWidget {
  const _LogisticsTile({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color soft;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: PreviewTheme.surface.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: color,
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
        'Pending 0 · Match 100% · Short 0 · Excess 0',
      ),
      (
        'Half Day',
        PreviewTheme.orange,
        PreviewTheme.orangeSoft,
        'Pending 0, but Short or Excess > 0',
      ),
      (
        'Absent',
        PreviewTheme.red,
        PreviewTheme.redSoft,
        'Pending > 0 with Short or Excess',
      ),
      (
        'Holiday',
        PreviewTheme.blue,
        PreviewTheme.blueSoft,
        'Company holiday / weekly off',
      ),
      (
        'WOP',
        AppColors.isDark ? const Color(0xFFB794F6) : const Color(0xFF7C3AED),
        AppColors.isDark ? const Color(0xFF2E2145) : const Color(0xFFF3E8FF),
        'Approved work-off permission',
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: PreviewTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: PreviewTheme.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Status rules',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: PreviewTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rules.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
              decoration: BoxDecoration(
                color: PreviewTheme.field,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: rules[i].$2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rules[i].$4,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: PreviewTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
