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
              child: _DcDetailBody(
                transfer: transfer,
                formatter: formatter,
                showSaveActions: showSaveActions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DcDetailBody extends ConsumerStatefulWidget {
  const _DcDetailBody({
    required this.transfer,
    required this.formatter,
    required this.showSaveActions,
  });

  final DcTransferModel transfer;
  final NumberFormat formatter;
  final bool showSaveActions;

  @override
  ConsumerState<_DcDetailBody> createState() => _DcDetailBodyState();
}

class _DcDetailBodyState extends ConsumerState<_DcDetailBody> {
  final Map<int, TextEditingController> _qtyByProduct = {};
  bool _saving = false;
  int? _savingProductId;
  int? _savedProductId;

  DcTransferModel get transfer => widget.transfer;

  @override
  void initState() {
    super.initState();
    _syncControllers(transfer.products);
  }

  @override
  void didUpdateWidget(covariant _DcDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transfer.transferId != transfer.transferId ||
        !_sameProductIds(oldWidget.transfer.products, transfer.products)) {
      _syncControllers(transfer.products);
    }
  }

  @override
  void dispose() {
    for (final controller in _qtyByProduct.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _sameProductIds(
    List<DcProductLineModel> a,
    List<DcProductLineModel> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].productId != b[i].productId) return false;
    }
    return true;
  }

  void _syncControllers(List<DcProductLineModel> products) {
    final nextIds = products.map((row) => row.productId).toSet();
    final staleIds =
        _qtyByProduct.keys.where((id) => !nextIds.contains(id)).toList();
    for (final id in staleIds) {
      _qtyByProduct.remove(id)?.dispose();
    }
    for (final product in products) {
      final incoming = product.incomingQty;
      final text = incoming > 0 ? incoming.toInt().toString() : '';
      final existing = _qtyByProduct[product.productId];
      if (existing == null) {
        _qtyByProduct[product.productId] = TextEditingController(text: text);
      }
    }
  }

  int? _qtyFor(DcProductLineModel product) {
    final raw = _qtyByProduct[product.productId]?.text.trim() ?? '';
    if (raw.isEmpty) {
      return product.incomingQty > 0 ? product.incomingQty.toInt() : null;
    }
    return int.tryParse(raw);
  }

  List<DcInboundOperation> _operations() {
    final operations = <DcInboundOperation>[];
    for (final product in transfer.products) {
      final qty = _qtyFor(product);
      if (qty == null || qty <= 0) continue;
      operations.add(
        DcInboundOperation(productId: product.productId, quantity: qty),
      );
    }
    return operations;
  }

  bool get _canSave {
    if (transfer.inboundPickingId == null || transfer.inboundPickingId! <= 0) {
      return false;
    }
    if (_saving || transfer.products.isEmpty) return false;
    return _operations().length == transfer.products.length;
  }

  Future<void> _save(int productId) async {
    if (!_canSave) return;
    final inboundPickingId = transfer.inboundPickingId!;
    final operations = _operations();
    if (operations.length != transfer.products.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Har product ki qty 0 se zyada honi chahiye.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _savingProductId = productId;
      _savedProductId = null;
    });

    try {
      await ref.read(dcControllerProvider.notifier).validateInboundProducts(
            transferId: transfer.transferId,
            inboundPickingId: inboundPickingId,
            operations: operations,
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savingProductId = null;
        _savedProductId = productId;
      });
      await ref.read(dcControllerProvider.notifier).refresh();
      if (!mounted) return;
      context.go('/dc?tab=received');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savingProductId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savingProductId = null;
      });
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
    return ListView(
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
              value: widget.formatter.format(transfer.incomingQty),
              background: const Color(0xFF15803D),
              labelColor: const Color(0xFFBBF7D0),
            ),
            ModuleStat(
              icon: Icons.check_circle_outline_rounded,
              label: 'Received Qty',
              value: widget.formatter.format(transfer.receivedQty),
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
              product: product,
              formatter: widget.formatter,
              showSaveActions: widget.showSaveActions,
              inboundPickingId: transfer.inboundPickingId,
              qtyController: _qtyByProduct[product.productId]!,
              saving: _saving && _savingProductId == product.productId,
              saved: _savedProductId == product.productId,
              canSave: _canSave,
              onChanged: () {
                if (_savedProductId != null) {
                  setState(() => _savedProductId = null);
                } else {
                  setState(() {});
                }
              },
              onSave: () => _save(product.productId),
            ),
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.formatter,
    required this.showSaveActions,
    required this.inboundPickingId,
    required this.qtyController,
    required this.saving,
    required this.saved,
    required this.canSave,
    required this.onChanged,
    required this.onSave,
  });

  final DcProductLineModel product;
  final NumberFormat formatter;
  final bool showSaveActions;
  final int? inboundPickingId;
  final TextEditingController qtyController;
  final bool saving;
  final bool saved;
  final bool canSave;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      statusColor: const Color(0xFF15803D),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
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
                      value: formatter.format(product.incomingQty),
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
                      value: formatter.format(product.receivedQty),
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'UOM: ${product.uom}',
              style: TextStyle(
                fontSize: 10.5,
                color: ModuleTokens.faintText,
              ),
            ),
            if (showSaveActions && inboundPickingId == null) ...[
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
            if (showSaveActions) ...[
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
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: !saving,
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
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 84,
                    child: LoadingButton(
                      label: saved ? 'Saved' : 'Save',
                      compact: true,
                      secondary: true,
                      enabled: canSave || saving,
                      isLoading: saving,
                      onPressed: canSave ? onSave : null,
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
