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
import '../data/models/dc_transfer_model.dart';
import 'providers/dc_provider.dart';

class DcDetailScreen extends ConsumerWidget {
  const DcDetailScreen({
    super.key,
    required this.transferId,
    this.showSaveActions = true,
  });

  final int transferId;
  final bool showSaveActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dcControllerProvider);
    final transfer = state.transferById(transferId);
    final formatter = NumberFormat.decimalPattern('en_IN');

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
              pageLabel: 'DC Detail',
              onBack: () => context.pop(),
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
              subtitle: transfer.from?.warehouse,
              onBack: () => context.pop(),
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
                    stats: [
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
                  if ((transfer.to?.warehouse ?? '').isNotEmpty)
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
                    ),
                  if (transfer.products.isEmpty)
                    const ModuleEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Koi product line nahi',
                      message: 'Is transfer me product detail available nahi hai.',
                    )
                  else
                    ...transfer.products.map(
                      (product) => _ProductCard(
                        transferId: transfer.transferId,
                        inboundPickingId: transfer.inboundPickingId,
                        product: product,
                        formatter: formatter,
                        showSaveActions: showSaveActions,
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
    required this.product,
    required this.formatter,
    required this.showSaveActions,
  });

  final int transferId;
  final int? inboundPickingId;
  final DcProductLineModel product;
  final NumberFormat formatter;
  final bool showSaveActions;

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
    final incoming = widget.product.incomingQty;
    _qtyController = TextEditingController(
      text: incoming > 0 ? incoming.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (widget.inboundPickingId == null || widget.inboundPickingId! <= 0) {
      return false;
    }
    final qty = int.tryParse(_qtyController.text.trim());
    return qty != null && qty >= 0 && !_saving;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null) return;
    final inboundPickingId = widget.inboundPickingId!;

    setState(() {
      _saving = true;
      _saved = false;
    });

    try {
      await ref.read(dcControllerProvider.notifier).validateInboundProduct(
            transferId: widget.transferId,
            inboundPickingId: inboundPickingId,
            productId: widget.product.productId,
            quantity: qty,
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      await ref.read(dcControllerProvider.notifier).refresh();
      if (!mounted) return;
      context.go('/dc?tab=received');
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
    return ModuleCard(
      statusColor: const Color(0xFF15803D),
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
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Incoming',
                      value: widget.formatter.format(widget.product.incomingQty),
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
                      value: widget.formatter.format(widget.product.receivedQty),
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
            if (widget.showSaveActions && widget.inboundPickingId == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Inbound picking id missing — save unavailable',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
            if (widget.showSaveActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ModuleTokens.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: !_saving,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          hintText: 'Qty daalo',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (_) {
                          if (_saved) setState(() => _saved = false);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 84,
                    child: LoadingButton(
                      label: _saved ? 'Saved' : 'Save',
                      compact: true,
                      secondary: true,
                      enabled: canSave,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: ModuleTokens.faintText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
