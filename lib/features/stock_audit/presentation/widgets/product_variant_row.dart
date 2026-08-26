import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/audit_qty_helper.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../data/models/product_model.dart';
import '../providers/stock_audit_provider.dart';

class ProductVariantRow extends ConsumerStatefulWidget {
  const ProductVariantRow({
    super.key,
    required this.product,
    required this.variant,
    required this.onOpenDamage,
    required this.onOpenComment,
  });

  final ProductModel product;
  final ProductVariantModel variant;
  final VoidCallback onOpenDamage;
  final VoidCallback onOpenComment;

  @override
  ConsumerState<ProductVariantRow> createState() => _ProductVariantRowState();
}

class _ProductVariantRowState extends ConsumerState<ProductVariantRow> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant ProductVariantRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variant.auditUpdatedAt != widget.variant.auditUpdatedAt ||
        oldWidget.variant.auditQty != widget.variant.auditQty) {
      _syncController();
    }
  }

  void _syncController() {
    final state = ref.read(stockAuditControllerProvider);
    final draft = state.qtyDrafts[widget.variant.id];
    final hasDraft = state.qtyDrafts.containsKey(widget.variant.id);
    final displayQty = draft ?? AuditQtyHelper.todayAuditQty(widget.variant);
    _controller.text = AuditQtyHelper.formatInputValue(
      variant: widget.variant,
      qty: displayQty,
      hasDraft: hasDraft,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isRecent =>
      DateFormatter.isAuditUpdatedToday(widget.variant.auditUpdatedAt);

  bool get _canSave {
    final state = ref.watch(stockAuditControllerProvider);
    final draft = state.qtyDrafts[widget.variant.id];
    final hasDraft = state.qtyDrafts.containsKey(widget.variant.id);
    final isEmpty = state.emptyDraftVariantIds.contains(widget.variant.id);
    if (isEmpty) return false;
    return AuditQtyHelper.isQtyChanged(
      variant: widget.variant,
      draftQty: draft,
      hasDraft: hasDraft,
    );
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final state = ref.read(stockAuditControllerProvider);
    final draft = state.qtyDrafts[widget.variant.id];
    final qty = draft ?? AuditQtyHelper.todayAuditQty(widget.variant);

    final ok = await ref.read(stockAuditControllerProvider.notifier).saveSingleVariant(
          productId: widget.product.id,
          variantId: widget.variant.id,
          qty: qty,
        );

    if (mounted) {
      setState(() => _saving = false);
      if (ok) _syncController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pcsQty = AuditQtyHelper.displayPcsQty(widget.variant);
    final updatedLabel = DateFormatter.formatAuditUpdatedAt(widget.variant.auditUpdatedAt);
    final saveLabel = _isRecent ? 'Update' : 'Save';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _isRecent ? AppColors.auditRecentBg : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isRecent ? AppColors.auditRecentBorder : const Color(0xFFE6EFE6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumb(imageUrl: widget.product.image),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            widget.variant.variantName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5F4B),
                            ),
                          ),
                          Text(
                            '$pcsQty Pcs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: pcsQty > 0 ? AppColors.inStock : AppColors.outStock,
                            ),
                          ),
                        ],
                      ),
                      if (updatedLabel.isNotEmpty)
                        Text(
                          'Updated $updatedLabel',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 68,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD9E5D9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD9E5D9)),
                ),
              ),
              onChanged: (raw) {
                final notifier = ref.read(stockAuditControllerProvider.notifier);
                final trimmed = raw.trim();
                if (trimmed.isEmpty) {
                  notifier.setQtyDraft(widget.variant.id, null, emptyInput: true);
                  return;
                }
                final val = int.tryParse(trimmed);
                if (val == null || val < 0) {
                  _syncController();
                  return;
                }
                final baseline = AuditQtyHelper.todayAuditQty(widget.variant);
                final auditedToday =
                    DateFormatter.isAuditUpdatedToday(widget.variant.auditUpdatedAt);
                if (val == baseline && auditedToday) {
                  notifier.clearQtyDraft(widget.variant.id);
                } else {
                  notifier.setQtyDraft(widget.variant.id, val);
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          LoadingButton(
            label: saveLabel,
            compact: true,
            secondary: true,
            enabled: _canSave,
            isLoading: _saving,
            onPressed: _canSave ? _save : null,
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDBE6DB)),
              ),
              child: const Icon(Icons.more_vert, size: 18, color: Color(0xFF4B5F4B)),
            ),
            onSelected: (value) {
              if (value == 'damage') widget.onOpenDamage();
              if (value == 'comment') widget.onOpenComment();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'damage', child: Text('Update Damage Quantity')),
              PopupMenuItem(value: 'comment', child: Text('Comment')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDFEBDF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const _FallbackImage(),
            )
          : const _FallbackImage(),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Img',
        style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
      ),
    );
  }
}
