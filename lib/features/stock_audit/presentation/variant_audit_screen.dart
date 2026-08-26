import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_bottom_nav.dart';
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
      final detail = await ref.read(stockAuditRepositoryProvider).getAuditDetail(
            businessLocationId: widget.storeId,
            productId: widget.productId,
            variantId: widget.variantId,
          );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _damageQtyController.text = detail.damageQty > 0 ? '${detail.damageQty}' : '';
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
      final wasUpdated =
          await ref.read(stockAuditRepositoryProvider).saveDiscrepancy(
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
          AppHeader(
            centerTitle: true,
            title: 'Stock Audit Detail',
            subtitle: detail?.variantSku ?? (_loading ? 'Loading...' : 'Variant audit'),
            leading: HeaderBackButton(
              onPressed: () => context.go('/home?storeId=${widget.storeId}'),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (detail != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                detail.variantLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5F4B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'System stock: ${detail.currentStock} Pcs · Audit: ${detail.auditQty} Pcs',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last updated: ${DateFormatter.formatAuditDetailUpdatedAt(detail.auditUpdatedAt)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAMAGE QTY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _damageQtyController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(hintText: '0'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'COMMENT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _damageCommentController,
                          maxLines: 2,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            hintText: 'Damage stock comment (optional)',
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  LoadingButton(
                    label: 'Submit',
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ],
            ),
          ),
          AppBottomNav(
            currentTab: AppTab.home,
            onHomeTap: () => context.go('/home?storeId=${widget.storeId}'),
            onMyProductsTap: () => context.go('/my-products'),
          ),
        ],
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDFEBDF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
          : const Center(
              child: Text('Img', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            ),
    );
  }
}
