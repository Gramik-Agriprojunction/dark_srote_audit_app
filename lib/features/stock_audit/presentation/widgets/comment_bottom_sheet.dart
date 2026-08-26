import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/loading_button.dart';
import '../providers/stock_audit_provider.dart';

Future<void> showCommentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required int productId,
  required int variantId,
  required String productName,
  required String variantLabel,
  String? initialComment,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _CommentSheet(
        productId: productId,
        variantId: variantId,
        productName: productName,
        variantLabel: variantLabel,
        initialComment: initialComment,
      );
    },
  );
}

class _CommentSheet extends ConsumerStatefulWidget {
  const _CommentSheet({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantLabel,
    this.initialComment,
  });

  final int productId;
  final int variantId;
  final String productName;
  final String variantLabel;
  final String? initialComment;

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  late final TextEditingController _controller;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialComment ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _controller.text.trim();
    if (comment.isEmpty) {
      setState(() => _error = 'Comment likh kar submit karein.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final ok = await ref.read(stockAuditControllerProvider.notifier).saveComment(
          productId: widget.productId,
          variantId: widget.variantId,
          comment: comment,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      final error = ref.read(stockAuditControllerProvider).error;
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.productName} — ${widget.variantLabel}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Enter comment for this variant',
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.errorText, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LoadingButton(
                    label: 'Submit',
                    compact: true,
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
