import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/module_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/dc_repository.dart';
import '../data/models/dc_transfer_model.dart';
import 'providers/dc_provider.dart';

class DcDetailScreen extends ConsumerWidget {
  const DcDetailScreen({
    super.key,
    required this.transferId,
    this.tab = 'incoming',
    this.showSaveActions = true,
  });

  final int transferId;
  final String tab;
  final bool showSaveActions;

  bool get _isOutgoingMode => tab == 'outgoing' || tab == 'transferred';
  bool get _isTransferredMode => tab == 'transferred';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dcControllerProvider);
    final transfer = state.transferById(transferId);
    final formatter = NumberFormat.decimalPattern('en_IN');
    final viewOnly = ref.watch(isViewOnlySessionProvider);
    final allowSaveActions = showSaveActions && !viewOnly;

    Future<void> logout() async {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }

    if (transfer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            ModuleHeader(
              pageLabel: _isOutgoingMode ? 'Outgoing Detail' : 'DC Detail',
              onBack: () => context.go('/dc?tab=$tab'),
              onLogout: logout,
            ),
            const Expanded(
              child: ModuleEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Transfer not found',
                message: 'List refresh karke dubara try karein.',
              ),
            ),
          ],
        ),
      );
    }

    final accent = _isOutgoingMode
        ? (tab == 'transferred'
            ? const Color(0xFF7C3AED)
            : const Color(0xFF1D4ED8))
        : const Color(0xFF15803D);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primary,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            ModuleHeader(
              pageLabel: transfer.reference.isNotEmpty
                  ? transfer.reference
                  : 'Transfer #${transfer.transferId}',
              subtitle: _isOutgoingMode
                  ? (transfer.to?.warehouse ?? transfer.from?.warehouse)
                  : transfer.from?.warehouse,
              onBack: () => context.go('/dc?tab=$tab'),
              onLogout: logout,
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
                children: [
                  ModuleStatsRow(
                    stats: _isTransferredMode
                        ? [
                            ModuleStat(
                              icon: Icons.call_made_rounded,
                              label: 'Outgoing Qty',
                              value: formatter.format(transfer.outgoingQty),
                              background: const Color(0xFF1D4ED8),
                              labelColor: const Color(0xFFBFDBFE),
                            ),
                            ModuleStat(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Transferred Qty',
                              value: formatter.format(transfer.transferredQty),
                              background: const Color(0xFF7C3AED),
                              labelColor: const Color(0xFFE9D5FF),
                            ),
                          ]
                        : _isOutgoingMode
                            ? [
                                ModuleStat(
                                  icon: Icons.call_made_rounded,
                                  label: 'Outgoing Qty',
                                  value: formatter.format(transfer.outgoingQty),
                                  background: accent,
                                  labelColor: const Color(0xFFBFDBFE),
                                ),
                                ModuleStat(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: 'Transferred Qty',
                                  value: formatter
                                      .format(transfer.transferredQty),
                                  background: AppColors.primary,
                                  labelColor: const Color(0xFFFFE4D2),
                                ),
                              ]
                            : [
                                ModuleStat(
                                  icon: Icons.call_received_rounded,
                                  label: 'Incoming Qty',
                                  value: formatter.format(transfer.incomingQty),
                                  background: const Color(0xFF15803D),
                                  labelColor: const Color(0xFFBBF7D0),
                                ),
                                ModuleStat(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: 'Received Qty',
                                  value: formatter.format(transfer.receivedQty),
                                  background: AppColors.primary,
                                  labelColor: const Color(0xFFFFE4D2),
                                ),
                              ],
                  ),
                  if (_isOutgoingMode &&
                      (transfer.to?.warehouse ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                      child: Text(
                        'To: ${transfer.to!.warehouse}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ModuleTokens.mutedText,
                        ),
                      ),
                    )
                  else if (!_isOutgoingMode &&
                      (transfer.from?.warehouse ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                      child: Text(
                        'From: ${transfer.from!.warehouse}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ModuleTokens.mutedText,
                        ),
                      ),
                    ),
                  if (transfer.products.isEmpty)
                    const ModuleEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Koi product line nahi',
                      message:
                          'Is transfer me product detail available nahi hai.',
                    )
                  else
                    ...transfer.products.map(
                      (product) => _ProductCard(
                        transferId: transfer.transferId,
                        inboundPickingId: transfer.inboundPickingId,
                        outboundPickingId: transfer.outboundPickingId,
                        product: product,
                        formatter: formatter,
                        showSaveActions: allowSaveActions,
                        isOutgoingMode: _isOutgoingMode,
                        isTransferredMode: _isTransferredMode,
                        accent: accent,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({
    required this.transferId,
    required this.inboundPickingId,
    required this.outboundPickingId,
    required this.product,
    required this.formatter,
    required this.showSaveActions,
    required this.isOutgoingMode,
    required this.isTransferredMode,
    required this.accent,
  });

  final int transferId;
  final int? inboundPickingId;
  final int? outboundPickingId;
  final DcProductLineModel product;
  final NumberFormat formatter;
  final bool showSaveActions;
  final bool isOutgoingMode;
  final bool isTransferredMode;
  final Color accent;

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  late final TextEditingController _qtyController;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final seedQty = widget.isOutgoingMode
        ? widget.product.outgoingQty
        : widget.product.incomingQty;
    _qtyController = TextEditingController(
      text: seedQty > 0 ? seedQty.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  int? get _activePickingId =>
      widget.isOutgoingMode ? widget.outboundPickingId : widget.inboundPickingId;

  bool get _canSave {
    if (!widget.showSaveActions) return false;
    final pickingId = _activePickingId;
    if (pickingId == null || pickingId <= 0) return false;
    final qty = int.tryParse(_qtyController.text.trim());
    return qty != null && qty >= 0 && !_saving;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null) return;
    final pickingId = _activePickingId!;

    setState(() {
      _saving = true;
      _saved = false;
    });

    try {
      if (widget.isOutgoingMode) {
        await ref.read(dcControllerProvider.notifier).validateOutboundProduct(
              transferId: widget.transferId,
              outboundPickingId: pickingId,
              productId: widget.product.productId,
              quantity: qty,
            );
      } else {
        await ref.read(dcControllerProvider.notifier).validateInboundProducts(
              transferId: widget.transferId,
              inboundPickingId: pickingId,
              operations: [
                DcInboundOperation(
                  productId: widget.product.productId,
                  quantity: qty,
                ),
              ],
            );
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      await ref.read(dcControllerProvider.notifier).refresh();
      if (!mounted) return;
      context.go(
        widget.isOutgoingMode ? '/dc?tab=transferred' : '/dc?tab=received',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error. Dubara try karein.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _canSave;
    final pickingMissing = widget.showSaveActions &&
        (_activePickingId == null || _activePickingId! <= 0);

    return ModuleCard(
      statusColor: widget.isOutgoingMode
          ? widget.accent
          : const Color(0xFF15803D),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.productName,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: ModuleTokens.strongText,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ModuleTokens.cardBorder),
              ),
              child: Row(
                children: widget.isTransferredMode
                    ? [
                        Expanded(
                          child: _Metric(
                            label: 'Outgoing',
                            value: widget.formatter
                                .format(widget.product.outgoingQty),
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 26,
                          color: ModuleTokens.cardBorder,
                        ),
                        Expanded(
                          child: _Metric(
                            label: 'Transferred Qty',
                            value: widget.formatter
                                .format(widget.product.transferredQty),
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ]
                    : widget.isOutgoingMode
                        ? [
                            Expanded(
                              child: _Metric(
                                label: 'Outgoing',
                                value: widget.formatter
                                    .format(widget.product.outgoingQty),
                                color: widget.accent,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 26,
                              color: ModuleTokens.cardBorder,
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Transferred Qty',
                                value: widget.formatter
                                    .format(widget.product.transferredQty),
                                color: AppColors.primary,
                              ),
                            ),
                          ]
                        : [
                            Expanded(
                              child: _Metric(
                                label: 'Incoming',
                                value: widget.formatter
                                    .format(widget.product.incomingQty),
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 26,
                              color: ModuleTokens.cardBorder,
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Received',
                                value: widget.formatter
                                    .format(widget.product.receivedQty),
                                color: AppColors.primary,
                              ),
                            ),
                          ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'UOM: ${widget.product.uom}',
              style: TextStyle(
                fontSize: 10.5,
                color: ModuleTokens.faintText,
              ),
            ),
            if (widget.showSaveActions) ...[
              if (pickingMissing) ...[
                const SizedBox(height: 8),
                Text(
                  widget.isOutgoingMode
                      ? 'Outbound picking id missing — save unavailable'
                      : 'Inbound picking id missing — save unavailable',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: widget.isOutgoingMode
                            ? 'Transferred qty'
                            : 'Received qty',
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 110,
                    child: LoadingButton(
                      label: _saved ? 'Saved' : 'Save',
                      isLoading: _saving,
                      onPressed: canSave ? _save : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: ModuleTokens.faintText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
