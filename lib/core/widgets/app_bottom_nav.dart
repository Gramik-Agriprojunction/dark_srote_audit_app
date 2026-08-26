import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum AppTab { home, myProducts }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onHomeTap,
    required this.onMyProductsTap,
  });

  final AppTab currentTab;
  final VoidCallback onHomeTap;
  final VoidCallback onMyProductsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4EBE4))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F1F0F),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              label: 'Home',
              icon: Icons.home_rounded,
              isActive: currentTab == AppTab.home,
              onTap: onHomeTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NavItem(
              label: 'My Product',
              icon: Icons.inventory_2_outlined,
              isActive: currentTab == AppTab.myProducts,
              onTap: onMyProductsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.footerActiveBg : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
