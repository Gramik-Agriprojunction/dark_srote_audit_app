import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.compact = false,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final bool compact;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading && onPressed != null;

    if (secondary) {
      return SizedBox(
        width: compact ? 56 : null,
        height: compact ? 32 : 52,
        child: OutlinedButton(
          onPressed: active ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            backgroundColor: AppColors.btnSecondaryBg,
            side: const BorderSide(color: AppColors.btnSecondaryBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 9 : 14)),
            textStyle: TextStyle(
              fontSize: compact ? 12 : 15,
              fontWeight: FontWeight.w700,
            ),
            padding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: isLoading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryDark.withValues(alpha: active ? 1 : 0.5),
                  ),
                )
              : Text(label),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: compact ? 32 : 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 9 : 14),
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryMid, AppColors.primaryDark],
                )
              : null,
          color: active ? null : AppColors.primaryMid.withValues(alpha: 0.65),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x4D1A7A52),
                    blurRadius: 22,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: active ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 9 : 14)),
            textStyle: TextStyle(
              fontSize: compact ? 12 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(label),
                  ],
                )
              : Text(label),
        ),
      ),
    );
  }
}
