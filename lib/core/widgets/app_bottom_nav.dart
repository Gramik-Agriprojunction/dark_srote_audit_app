import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

enum AppTab { dashboard, audit, orders, stock, transactions, dc, variance }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onDashboardTap,
    required this.onHomeTap,
    required this.onOrdersTap,
    required this.onStockTap,
  });

  final AppTab currentTab;
  final VoidCallback onDashboardTap;
  final VoidCallback onHomeTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onStockTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x14101B12),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  label: 'Home',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  isActive: currentTab == AppTab.dashboard,
                  onTap: onDashboardTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Stock',
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  isActive: currentTab == AppTab.stock,
                  onTap: onStockTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Orders',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  isActive: currentTab == AppTab.orders,
                  onTap: onOrdersTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Audit',
                  icon: Icons.fact_check_outlined,
                  activeIcon: Icons.fact_check_rounded,
                  isActive: currentTab == AppTab.audit,
                  onTap: onHomeTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : const Color(0xFF94A3B8);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
