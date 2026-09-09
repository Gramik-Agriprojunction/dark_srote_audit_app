import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
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
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
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

    final ok = await ref
        .read(stockAuditControllerProvider.notifier)
        .saveComment(
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
    return AppSheet(
      title: 'Add Comment',
      subtitle: '${widget.productName} — ${widget.variantLabel}',
      maxHeightFactor: 0.7,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 1000,
              autofocus: true,
              style: const TextStyle(fontSize: 14.5, height: 1.4),
              decoration: const InputDecoration(
                hintText: 'Enter comment for this variant',
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 15,
                    color: AppColors.errorText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: AppColors.errorText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: LoadingButton(
                    label: 'Cancel',
                    secondary: true,
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: LoadingButton(
                    label: 'Save Comment',
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
