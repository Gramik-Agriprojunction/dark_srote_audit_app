import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../preview_theme.dart';

/// Compact status legend for DSE Attendance (list + detail).
class DseAttendanceRulesPanel extends StatelessWidget {
  const DseAttendanceRulesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = <({
      String status,
      String when,
      Color fg,
      Color bg,
      IconData icon,
    })>[
      (
        status: 'Present',
        when: 'Pending = 0, Match = 100%, Short = 0, Excess = 0',
        fg: PreviewTheme.green,
        bg: PreviewTheme.greenSoft,
        icon: Icons.check_circle_rounded,
      ),
      (
        status: 'Half Day',
        when: 'Pending = 0, aur Short ya Excess > 0',
        fg: PreviewTheme.orange,
        bg: PreviewTheme.orangeSoft,
        icon: Icons.timelapse_rounded,
      ),
      (
        status: 'Absent',
        when: 'Pending > 0, aur Short ya Excess > 0',
        fg: PreviewTheme.red,
        bg: PreviewTheme.redSoft,
        icon: Icons.cancel_rounded,
      ),
      (
        status: 'Holiday',
        when: 'Company holiday / weekly off',
        fg: PreviewTheme.blue,
        bg: PreviewTheme.blueSoft,
        icon: Icons.beach_access_rounded,
      ),
      (
        status: 'WOP',
        when: 'Work Off Pay — approved leave',
        fg: PreviewTheme.teal,
        bg: PreviewTheme.tealSoft,
        icon: Icons.payments_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: PreviewTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: PreviewTheme.border),
              ),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  PreviewTheme.orangeSoft.withValues(alpha: 0.55),
                  PreviewTheme.surface,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: PreviewTheme.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status kaise decide hota hai',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: PreviewTheme.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: i.isOdd
                    ? (AppColors.isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : PreviewTheme.field.withValues(alpha: 0.55))
                    : Colors.transparent,
                border: i == rows.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(color: PreviewTheme.border),
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 92,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: rows[i].bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: rows[i].fg.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(rows[i].icon, size: 14, color: rows[i].fg),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            rows[i].status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: rows[i].fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        rows[i].when,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: PreviewTheme.textSecondary,
                        ),
                      ),
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
