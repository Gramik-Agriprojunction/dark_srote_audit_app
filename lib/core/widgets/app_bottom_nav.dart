import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

enum AppTab { home, stock, transactions }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onHomeTap,
    required this.onStockTap,
    required this.onTransactionsTap,
  });

  final AppTab currentTab;
  final VoidCallback onHomeTap;
  final VoidCallback onStockTap;
  final VoidCallback onTransactionsTap;

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
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isActive: currentTab == AppTab.home,
                  onTap: onHomeTap,
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
                  label: 'Transaction',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  isActive: currentTab == AppTab.transactions,
                  onTap: onTransactionsTap,
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
    final color = isActive ? AppColors.primaryDark : AppColors.textMuted;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 32,
              width: isActive ? 56 : 40,
              decoration: BoxDecoration(
                color: isActive ? AppColors.footerActiveBg : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  isActive ? activeIcon : icon,
                  size: 21,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
