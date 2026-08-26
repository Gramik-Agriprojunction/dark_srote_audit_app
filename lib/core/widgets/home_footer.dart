import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key, required this.onHomeTap});

  final VoidCallback onHomeTap;

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Material(
              color: AppColors.footerActiveBg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onHomeTap,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 52,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(height: 2),
                      const Text(
                        'Home',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
