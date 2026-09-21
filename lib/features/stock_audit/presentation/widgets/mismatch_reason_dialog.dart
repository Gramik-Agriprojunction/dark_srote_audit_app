import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Returns mismatch reason text, or null if user cancelled.
Future<String?> showMismatchReasonDialog({
  required BuildContext context,
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
          return AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Mismatch reason chahiye',
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
                    'Total physical: $baselineQty\n'
                    'Inventory change qty: $inventoryChangeQty\n'
                    'Expected update: $expectedQty\n'
                    'Aapne enter kiya: $enteredQty',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Transaction ke hisaab se difference zyada hai. Reason likhiye:',
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
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Mismatch reason...',
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
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final reason = controller.text.trim();
                  if (reason.isEmpty) {
                    setState(() => errorText = 'Reason dena zaroori hai.');
                    return;
                  }
                  Navigator.of(dialogContext).pop(reason);
                },
                child: const Text('Save with reason'),
              ),
            ],
          );
        },
      );
    },
  );
}
