import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

enum AppTab { home, orders, stock, transactions, dc, variance }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onHomeTap,
    required this.onOrdersTap,
    required this.onStockTap,
    required this.onTransactionsTap,
    required this.onDcTap,
    required this.onVarianceTap,
  });

  final AppTab currentTab;
  final VoidCallback onHomeTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onStockTap;
  final VoidCallback onTransactionsTap;
  final VoidCallback onDcTap;
  final VoidCallback onVarianceTap;

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
                  label: 'Orders',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  isActive: currentTab == AppTab.orders,
                  onTap: onOrdersTap,
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
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isActive: currentTab == AppTab.home,
                  onTap: onHomeTap,
                  isCenter: true,
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Trans',
                  icon: Icons.swap_horiz_outlined,
                  activeIcon: Icons.swap_horiz_rounded,
                  isActive: currentTab == AppTab.transactions,
                  onTap: onTransactionsTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'DC',
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping_rounded,
                  isActive: currentTab == AppTab.dc,
                  onTap: onDcTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Variance',
                  icon: Icons.compare_arrows_outlined,
                  activeIcon: Icons.compare_arrows_rounded,
                  isActive: currentTab == AppTab.variance,
                  onTap: onVarianceTap,
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
    this.isCenter = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primaryDark : AppColors.textMuted;
    final iconSize = isCenter ? 24.0 : 22.0;
    final activeWidth = isCenter ? 52.0 : 48.0;

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
              height: isCenter ? 38 : 36,
              width: isActive ? activeWidth : (isCenter ? 36 : 34),
              decoration: BoxDecoration(
                color: isActive ? AppColors.footerActiveBg : Colors.transparent,
                borderRadius: BorderRadius.circular(isCenter ? 18 : 16),
              ),
              child: Center(
                child: Icon(
                  isActive ? activeIcon : icon,
                  size: iconSize,
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
                fontSize: 9.5,
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
