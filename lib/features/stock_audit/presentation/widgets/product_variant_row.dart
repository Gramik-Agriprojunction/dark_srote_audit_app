import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/audit_qty_helper.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/product_model.dart';
import '../providers/stock_audit_provider.dart';

/// Audit product tile — matches dark mock (image, chips, stepper, orange Save).
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

  /// "Calcium (Sugar free) Animal Feed Supplements" → title + category line.
  (String, String?) _splitName(String raw) {
    final name = raw.trim();
    final close = name.indexOf(')');
    if (close > 0 && close < name.length - 1) {
      final title = name.substring(0, close + 1).trim();
      final sub = name.substring(close + 1).trim();
      if (sub.isNotEmpty) return (title, sub);
    }
    return (name, null);
  }

  @override
  Widget build(BuildContext context) {
    final pcsQty = AuditQtyHelper.displayPcsQty(widget.variant);
    final updatedLabel = DateFormatter.formatAuditUpdatedAt(
      widget.variant.auditUpdatedAt,
    );
    final saveLabel = _isRecent ? 'Update' : 'Save';
    final hasComment = (widget.variant.auditComment ?? '').trim().isNotEmpty;
    final (title, category) = _splitName(widget.product.name);
    final canSave = _canSave;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A36)),
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
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA1A1AA),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          label: widget.variant.variantName,
                          fg: Colors.white,
                          bg: const Color(0xFF2A2A36),
                        ),
                        _Pill(
                          label: '$pcsQty Pcs',
                          fg: Colors.white,
                          bg: pcsQty > 0
                              ? const Color(0xFF166534)
                              : const Color(0xFF7F1D1D),
                          icon: pcsQty > 0
                              ? Icons.check_circle_rounded
                              : Icons.remove_circle_outline_rounded,
                        ),
                        if (hasComment)
                          const _Pill(
                            label: 'Note',
                            fg: Color(0xFFFBBF24),
                            bg: Color(0xFF3D2E14),
                            icon: Icons.sticky_note_2_outlined,
                          ),
                      ],
                    ),
                    if (updatedLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Color(0xFF71717A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Updated $updatedLabel',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _RowMenuButton(
                onDamage: widget.onOpenDamage,
                onComment: widget.onOpenComment,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _qtyStepper()),
              const SizedBox(width: 10),
              _OrangeSaveButton(
                label: saveLabel,
                enabled: canSave,
                isLoading: _saving,
                onPressed: canSave ? _save : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyStepper() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A36)),
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
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                hintText: '0',
                hintStyle: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
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

class _OrangeSaveButton extends StatelessWidget {
  const _OrangeSaveButton({
    required this.label,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading && onPressed != null;
    final orange = AppColors.primary;
    final color = active ? orange : orange.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 88,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: color,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.fg,
    required this.bg,
    this.icon,
  });

  final String label;
  final Color fg;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 9 : 7, 4, 9, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 42,
        height: 44,
        child: Icon(icon, size: 20, color: AppColors.primary),
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
      color: const Color(0xFF1C1C24),
      offset: const Offset(0, 34),
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 22,
        color: Color(0xFFA1A1AA),
      ),
      onSelected: (value) {
        HapticFeedback.selectionClick();
        if (value == 'damage') onDamage();
        if (value == 'comment') onComment();
      },
      itemBuilder: (context) => [
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
              Text(
                'Update Damage Qty',
                style: TextStyle(color: Colors.white),
              ),
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
              Text('Comment', style: TextStyle(color: Colors.white)),
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
    return const ColoredBox(
      color: Color(0xFFF4F4F5),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 22,
          color: Color(0xFF71717A),
        ),
      ),
    );
  }
}
