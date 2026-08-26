import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorBg : AppColors.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? AppColors.errorBorder : AppColors.successBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isError ? '⚠' : '✓',
            style: TextStyle(
              color: isError ? AppColors.errorText : AppColors.successText,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? AppColors.errorText : AppColors.successText,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
