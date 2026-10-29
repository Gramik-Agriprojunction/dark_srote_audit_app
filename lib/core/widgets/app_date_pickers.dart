import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// Shared date / date-range pickers — dialog style (not fullscreen page).
class AppDatePickers {
  AppDatePickers._();

  static SystemUiOverlayStyle get _dialogStatusBar => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            AppColors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            AppColors.isDark ? Brightness.dark : Brightness.light,
      );

  static Widget _dialogWrap(BuildContext context, Widget? child) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _dialogStatusBar,
      child: child ?? const SizedBox.shrink(),
    );
  }

  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2024),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      helpText: helpText,
      initialDatePickerMode: initialDatePickerMode,
      builder: _dialogWrap,
    );
  }

  /// Opens as a centered dialog (same feel as [pickDate]), not a full page.
  static Future<DateTimeRange?> pickDateRange(
    BuildContext context, {
    required DateTimeRange initialDateRange,
    DateTime? firstDate,
    DateTime? lastDate,
    String helpText = 'Select date range',
    String saveText = 'Apply',
  }) {
    final first = firstDate ?? DateTime(2024);
    final last = lastDate ?? DateTime.now().add(const Duration(days: 365));
    final screen = MediaQuery.sizeOf(context);
    final maxH = screen.height * 0.78;

    return showDialog<DateTimeRange>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _dialogStatusBar,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Material(
              color: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: maxH.clamp(420.0, 640.0),
                ),
                // Force Material to use the compact dialog calendar layout
                // instead of the mobile fullscreen page layout.
                child: MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(
                    size: Size(400, maxH.clamp(420.0, 640.0)),
                  ),
                  child: DateRangePickerDialog(
                    firstDate: first,
                    lastDate: last,
                    currentDate: DateTime.now(),
                    initialDateRange: initialDateRange,
                    helpText: helpText,
                    cancelText: 'Cancel',
                    confirmText: saveText,
                    saveText: saveText,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
