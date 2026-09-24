import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/audit_transaction_mismatch_helper.dart';

/// Returns mismatch reason text, or null if user cancelled.
Future<String?> showMismatchReasonDialog({
  required BuildContext context,
  required AppStrings strings,
  required String productName,
  required String variantLabel,
  required int baselineQty,
  required int inventoryChangeQty,
  required int expectedQty,
  required int enteredQty,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final controller = TextEditingController();
      String? errorText;

      return StatefulBuilder(
        builder: (context, setState) {
          final length = controller.text.trim().length;
          return AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              strings.mismatchReasonRequired,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$productName · $variantLabel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.mismatchSummary(
                      baselineQty: baselineQty,
                      inventoryChangeQty: inventoryChangeQty,
                      expectedQty: expectedQty,
                      enteredQty: enteredQty,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.mismatchReasonPrompt,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    minLines: 2,
                    maxLength: AuditTransactionMismatchHelper.reasonMaxLength,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => errorText = null),
                    decoration: InputDecoration(
                      hintText: strings.mismatchReasonHint,
                      counterText:
                          '$length / ${AuditTransactionMismatchHelper.reasonMinLength} min',
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final reason = controller.text.trim();
                  if (reason.isEmpty) {
                    setState(() => errorText = strings.reasonRequired);
                    return;
                  }
                  if (!AuditTransactionMismatchHelper.isValidReason(reason)) {
                    setState(() => errorText = strings.mismatchReasonMinLength);
                    return;
                  }
                  Navigator.of(dialogContext).pop(reason);
                },
                child: Text(strings.saveWithReason),
              ),
            ],
          );
        },
      );
    },
  );
}
