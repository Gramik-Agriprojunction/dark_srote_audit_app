import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/module_ui.dart';

/// Hub to open static UI mocks (no API).
class StaticPreviewsHubScreen extends StatelessWidget {
  const StaticPreviewsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'UI Previews',
            subtitle: 'Static screens · mock data',
            onBack: () => context.pop(),
            showNotifications: false,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _PreviewTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'SKU Stock Ledger',
                  subtitle:
                      'Product tap → IN / Delivered / RTO history + running stock',
                  onTap: () => context.push('/preview/stock-ledger'),
                ),
                _PreviewTile(
                  icon: Icons.groups_rounded,
                  title: 'LMD Attendance',
                  subtitle:
                      'List → day card opens DSE attendance detail',
                  onTap: () => context.push('/preview/lmd-attendance'),
                ),
                _PreviewTile(
                  icon: Icons.fact_check_rounded,
                  title: 'DSE Audit Report',
                  subtitle:
                      'Dark store audit: system vs DSE claim vs difference',
                  onTap: () => context.push('/preview/dse-audit-report'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
