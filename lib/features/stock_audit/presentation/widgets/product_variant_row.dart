import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/audit_qty_helper.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/module_ui.dart';
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

  /// Shared by the text field and the +/- stepper so both behave identically.
  void _applyQty(int value) {
    final notifier = ref.read(stockAuditControllerProvider.notifier);
    final baseline = AuditQtyHelper.todayAuditQty(widget.variant);
    if (value == baseline && _isRecent) {
      notifier.clearQtyDraft(widget.variant.id);
    } else {
      notifier.setQtyDraft(widget.variant.id, value);
    }
  }

  void _step(int delta) {
    final current = int.tryParse(_controller.text.trim()) ?? 0;
    final next = current + delta;
    if (next < 0) return;
    HapticFeedback.selectionClick();
    _controller.text = '$next';
    _applyQty(next);
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final state = ref.read(stockAuditControllerProvider);
    final draft = state.qtyDrafts[widget.variant.id];
    final qty = draft ?? AuditQtyHelper.todayAuditQty(widget.variant);

    final ok = await ref
        .read(stockAuditControllerProvider.notifier)
        .saveSingleVariant(
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
    final updatedLabel = DateFormatter.formatAuditUpdatedAt(
      widget.variant.auditUpdatedAt,
    );
    final saveLabel = _isRecent ? 'Update' : 'Save';
    final hasComment = (widget.variant.auditComment ?? '').trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ModuleTokens.cardRadius),
        border: Border.all(
          color: _isRecent
              ? AppColors.auditRecentBorder
              : ModuleTokens.cardBorder,
          width: 1.2,
        ),
        boxShadow: ModuleTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductThumb(imageUrl: widget.product.image),
              const SizedBox(width: 12),
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
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AppChip(
                          label: widget.variant.variantName,
                          color: AppColors.textSecondary,
                          background: AppColors.fieldBg,
                        ),
                        AppChip(
                          label: '$pcsQty Pcs',
                          icon: pcsQty > 0
                              ? Icons.check_circle_rounded
                              : Icons.remove_circle_outline_rounded,
                          color: pcsQty > 0
                              ? AppColors.inStock
                              : AppColors.outStock,
                        ),
                        if (hasComment)
                          const AppChip(
                            label: 'Note',
                            icon: Icons.sticky_note_2_outlined,
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _RowMenuButton(
                onDamage: widget.onOpenDamage,
                onComment: widget.onOpenComment,
              ),
            ],
          ),
          if (updatedLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 58),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated $updatedLabel',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _qtyStepper()),
              const SizedBox(width: 10),
              SizedBox(
                width: 84,
                child: LoadingButton(
                  label: saveLabel,
                  compact: true,
                  secondary: true,
                  enabled: _canSave,
                  isLoading: _saving,
                  onPressed: _canSave ? _save : null,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyStepper() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: () => _step(-1)),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                hintText: '0',
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (raw) {
                final notifier = ref.read(
                  stockAuditControllerProvider.notifier,
                );
                final trimmed = raw.trim();
                if (trimmed.isEmpty) {
                  notifier.setQtyDraft(
                    widget.variant.id,
                    null,
                    emptyInput: true,
                  );
                  return;
                }
                final val = int.tryParse(trimmed);
                if (val == null || val < 0) {
                  _syncController();
                  return;
                }
                _applyQty(val);
              },
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => _step(1)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 40,
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}

class _RowMenuButton extends StatelessWidget {
  const _RowMenuButton({required this.onDamage, required this.onComment});

  final VoidCallback onDamage;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      splashRadius: 18,
      offset: const Offset(0, 34),
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.textMuted,
      ),
      onSelected: (value) {
        HapticFeedback.selectionClick();
        if (value == 'damage') onDamage();
        if (value == 'comment') onComment();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'damage',
          height: 46,
          child: Row(
            children: [
              Icon(
                Icons.report_gmailerrorred_rounded,
                size: 18,
                color: AppColors.warning,
              ),
              SizedBox(width: 10),
              Text('Update Damage Qty'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'comment',
          height: 46,
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Text('Comment'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (_, _) => const _FallbackImage(),
              errorWidget: (_, _, _) => const _FallbackImage(),
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
      child: Icon(
        Icons.inventory_2_outlined,
        size: 20,
        color: AppColors.textMuted,
      ),
    );
  }
}
