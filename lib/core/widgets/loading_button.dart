import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// Adds the subtle press-in scale that native buttons have.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 16,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.compact = false,
    this.secondary = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final bool compact;
  final bool secondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading && onPressed != null;
    final radius = compact ? 12.0 : 16.0;
    final height = compact ? 36.0 : 54.0;

    if (secondary) {
      return PressScale(
        borderRadius: radius,
        onTap: active ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
          decoration: BoxDecoration(
            color: active ? AppColors.primarySoft : AppColors.fieldBg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: active ? AppColors.primarySoftBorder : AppColors.border,
            ),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primaryDark,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AppColors.primaryDark
                          : AppColors.textMuted,
                    ),
                  ),
          ),
        ),
      );
    }

    return PressScale(
      borderRadius: radius,
      onTap: active ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryMid, AppColors.primaryDark],
                )
              : null,
          color: active ? null : AppColors.border,
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x452E8B57),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(label, style: _labelStyle(active, compact)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: compact ? 16 : 19,
                        color: active ? Colors.white : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: _labelStyle(active, compact)),
                  ],
                ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(bool active, bool compact) => TextStyle(
    fontSize: compact ? 13 : 15.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: active ? Colors.white : AppColors.textMuted,
  );
}
