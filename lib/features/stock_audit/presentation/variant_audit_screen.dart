import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/loading_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/stock_audit_detail_model.dart';
import '../data/stock_audit_repository.dart';

class VariantAuditScreen extends ConsumerStatefulWidget {
  const VariantAuditScreen({
    super.key,
    required this.storeId,
    required this.productId,
    required this.variantId,
  });

  final int storeId;
  final int productId;
  final int variantId;

  @override
  ConsumerState<VariantAuditScreen> createState() => _VariantAuditScreenState();
}

class _VariantAuditScreenState extends ConsumerState<VariantAuditScreen> {
  StockAuditDetailModel? _detail;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _success;

  final _damageQtyController = TextEditingController();
  final _damageCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _damageQtyController.dispose();
    _damageCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await ref
          .read(stockAuditRepositoryProvider)
          .getAuditDetail(
            businessLocationId: widget.storeId,
            productId: widget.productId,
            variantId: widget.variantId,
          );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _damageQtyController.text = detail.damageQty > 0
            ? '${detail.damageQty}'
            : '';
        _damageCommentController.text = detail.damageComment ?? '';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _stepDamage(int delta) {
    final current = int.tryParse(_damageQtyController.text.trim()) ?? 0;
    final next = current + delta;
    if (next < 0) return;
    HapticFeedback.selectionClick();
    setState(() => _damageQtyController.text = '$next');
  }

  Future<void> _submit() async {
    final detail = _detail;
    if (detail == null) return;

    ref.read(authControllerProvider.notifier).touchActivity();

    final damageQty = int.tryParse(_damageQtyController.text.trim()) ?? 0;
    if (damageQty > detail.auditQty) {
      setState(() {
        _error = detail.auditQty > 0
            ? 'Damage qty cannot exceed audit quantity (${detail.auditQty} pcs)'
            : 'Please update audit quantity before adding damage';
        _success = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });

    try {
      final wasUpdated = await ref
          .read(stockAuditRepositoryProvider)
          .saveDiscrepancy(
            businessLocationId: widget.storeId,
            productId: widget.productId,
            variantId: widget.variantId,
            damageQty: damageQty,
            damageComment: _damageCommentController.text.trim().isEmpty
                ? null
                : _damageCommentController.text.trim(),
          );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _success = wasUpdated ? 'Successfully updated.' : 'Successfully saved.';
      });

      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) context.go('/home?storeId=${widget.storeId}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            icon: Icons.fact_check_rounded,
            title: 'Audit Detail',
            subtitle:
                detail?.variantSku ??
                (_loading ? 'Loading...' : 'Variant audit'),
            onBack: () => context.go('/home?storeId=${widget.storeId}'),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                if (_error != null) ...[
                  AlertBanner(message: _error!, isError: true),
                  const SizedBox(height: 14),
                ],
                if (_success != null) ...[
                  AlertBanner(message: _success!, isError: false),
                  const SizedBox(height: 14),
                ],
                if (_loading)
                  const AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeleton(height: 62, radius: 16),
                        SizedBox(height: 16),
                        AppSkeleton(height: 14, width: 160),
                        SizedBox(height: 10),
                        AppSkeleton(height: 14, width: 110),
                      ],
                    ),
                  )
                else if (detail != null) ...[
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailImage(imageUrl: detail.image),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.productName,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  AppChip(
                                    label: detail.variantLabel,
                                    color: AppColors.textSecondary,
                                    background: AppColors.fieldBg,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fieldBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCell(
                                  label: 'System Stock',
                                  value: '${detail.currentStock}',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppColors.border,
                              ),
                              Expanded(
                                child: _StatCell(
                                  label: 'Audit Qty',
                                  value: '${detail.auditQty}',
                                  valueColor: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                DateFormatter.formatAuditDetailUpdatedAt(
                                  detail.auditUpdatedAt,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading(
                          title: 'Damage Quantity',
                          subtitle:
                              'Audit qty me se kitna stock damaged hai wo enter karein.',
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _CircleStep(
                              icon: Icons.remove_rounded,
                              onTap: () => _stepDamage(-1),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _damageQtyController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintStyle: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            _CircleStep(
                              icon: Icons.add_rounded,
                              onTap: () => _stepDamage(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const FieldLabel(
                          'Comment',
                          icon: Icons.chat_bubble_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _damageCommentController,
                          maxLines: 3,
                          maxLength: 1000,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                          decoration: const InputDecoration(
                            hintText: 'Damage stock comment (optional)',
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!_loading && detail != null)
            StickyActionBar(
              child: LoadingButton(
                label: _submitting ? 'Submitting...' : 'Submit',
                icon: Icons.check_rounded,
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleStep extends StatelessWidget {
  const _CircleStep({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 22, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value Pcs',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              errorWidget: (_, _, _) => const _Fallback(),
            )
          : const _Fallback(),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 24,
        color: AppColors.textMuted,
      ),
    );
  }
}
