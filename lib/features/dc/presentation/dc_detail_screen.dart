import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
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
    final s = ref.watch(appStringsProvider);
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
              pageLabel: _isOutgoingMode
                  ? s.outgoingDeliveryDetail
                  : s.incomingDeliveryDetail,
              onBack: () => context.go('/dc?tab=$tab'),
              onLogout: logout,
            ),
            Expanded(
              child: ModuleEmptyState(
                icon: Icons.search_off_rounded,
                title: s.transferNotFound,
                message: s.refreshListAndRetry,
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
                  : s.transferNumber(transfer.transferId),
              subtitle: _isOutgoingMode
                  ? (transfer.to?.warehouse ?? transfer.from?.warehouse)
                  : transfer.from?.warehouse,
              onBack: () => context.go('/dc?tab=$tab'),
              onLogout: logout,
            ),
            Expanded(
              child: _DcDetailBody(
                transfer: transfer,
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
    );
  }
}

class _DcDetailBody extends ConsumerStatefulWidget {
  const _DcDetailBody({
    required this.transfer,
    required this.formatter,
    required this.showSaveActions,
    required this.isOutgoingMode,
    required this.isTransferredMode,
    required this.accent,
  });

  final DcTransferModel transfer;
  final NumberFormat formatter;
  final bool showSaveActions;
  final bool isOutgoingMode;
  final bool isTransferredMode;
  final Color accent;

  @override
  ConsumerState<_DcDetailBody> createState() => _DcDetailBodyState();
}

class _DcDetailBodyState extends ConsumerState<_DcDetailBody> {
  final Map<int, TextEditingController> _qtyByProduct = {};
  bool _saving = false;
  bool _saved = false;

  DcTransferModel get transfer => widget.transfer;

  bool get _canEditQty =>
      widget.showSaveActions && !widget.isTransferredMode;

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
      final seed = widget.isOutgoingMode
          ? product.outgoingQty
          : product.incomingQty;
      final text = seed > 0 ? seed.toInt().toString() : '';
      if (!_qtyByProduct.containsKey(product.productId)) {
        _qtyByProduct[product.productId] = TextEditingController(text: text);
      }
    }
  }

  int? _qtyFor(DcProductLineModel product) {
    final raw = _qtyByProduct[product.productId]?.text.trim() ?? '';
    if (raw.isEmpty) {
      final seed =
          widget.isOutgoingMode ? product.outgoingQty : product.incomingQty;
      return seed > 0 ? seed.toInt() : null;
    }
    return int.tryParse(raw);
  }

  List<DcTransferOperation> _operations() {
    final operations = <DcTransferOperation>[];
    for (final product in transfer.products) {
      final qty = _qtyFor(product);
      if (qty == null || qty < 0) continue;
      operations.add(
        DcTransferOperation(productId: product.productId, quantity: qty),
      );
    }
    return operations;
  }

  int? get _activePickingId => widget.isOutgoingMode
      ? transfer.outboundPickingId
      : transfer.inboundPickingId;

  bool get _canSave {
    if (!_canEditQty) return false;
    final pickingId = _activePickingId;
    if (pickingId == null || pickingId <= 0) return false;
    if (_saving || transfer.products.isEmpty) return false;
    return _operations().length == transfer.products.length;
  }

  Future<void> _saveAll() async {
    final s = ref.read(appStringsProvider);
    if (!_canSave) {
      if (_operations().length != transfer.products.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.allProductsQtyRequired),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
      return;
    }

    final pickingId = _activePickingId!;
    final operations = _operations();

    setState(() {
      _saving = true;
      _saved = false;
    });

    try {
      if (widget.isOutgoingMode) {
        await ref.read(dcControllerProvider.notifier).validateOutboundProducts(
              transferId: transfer.transferId,
              outboundPickingId: pickingId,
              operations: operations,
            );
      } else {
        await ref.read(dcControllerProvider.notifier).validateInboundProducts(
              transferId: transfer.transferId,
              inboundPickingId: pickingId,
              operations: operations,
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
        SnackBar(
          content: Text(s.connectionError),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final pickingMissing =
        _canEditQty && (_activePickingId == null || _activePickingId! <= 0);

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
      children: [
        ModuleStatsRow(
          stats: widget.isTransferredMode
              ? [
                  ModuleStat(
                    icon: Icons.call_made_rounded,
                    label: s.outgoingQty,
                    value: widget.formatter.format(transfer.outgoingQty),
                    background: const Color(0xFF1D4ED8),
                    labelColor: const Color(0xFFBFDBFE),
                  ),
                  ModuleStat(
                    icon: Icons.check_circle_outline_rounded,
                    label: s.transferredQty,
                    value: widget.formatter.format(transfer.transferredQty),
                    background: const Color(0xFF7C3AED),
                    labelColor: const Color(0xFFE9D5FF),
                  ),
                ]
              : widget.isOutgoingMode
                  ? [
                      ModuleStat(
                        icon: Icons.call_made_rounded,
                        label: s.outgoingQty,
                        value: widget.formatter.format(transfer.outgoingQty),
                        background: widget.accent,
                        labelColor: const Color(0xFFBFDBFE),
                      ),
                      ModuleStat(
                        icon: Icons.check_circle_outline_rounded,
                        label: s.transferredQty,
                        value: widget.formatter.format(transfer.transferredQty),
                        background: AppColors.primary,
                        labelColor: const Color(0xFFFFE4D2),
                      ),
                    ]
                  : [
                      ModuleStat(
                        icon: Icons.call_received_rounded,
                        label: s.incomingQty,
                        value: widget.formatter.format(transfer.incomingQty),
                        background: const Color(0xFF15803D),
                        labelColor: const Color(0xFFBBF7D0),
                      ),
                      ModuleStat(
                        icon: Icons.check_circle_outline_rounded,
                        label: s.receivedQty,
                        value: widget.formatter.format(transfer.receivedQty),
                        background: AppColors.primary,
                        labelColor: const Color(0xFFFFE4D2),
                      ),
                    ],
        ),
        if (widget.isOutgoingMode &&
            (transfer.to?.warehouse ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
            child: Text(
              s.toWarehouse(transfer.to!.warehouse ?? ''),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ModuleTokens.mutedText,
              ),
            ),
          )
        else if (!widget.isOutgoingMode &&
            (transfer.from?.warehouse ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
            child: Text(
              s.fromWarehouse(transfer.from!.warehouse ?? ''),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ModuleTokens.mutedText,
              ),
            ),
          ),
        if (transfer.products.isEmpty)
          ModuleEmptyState(
            icon: Icons.inventory_2_outlined,
            title: s.noProductLines,
            message: s.noProductDetail,
          )
        else ...[
          ...transfer.products.map((product) {
            return _ProductCard(
              product: product,
              formatter: widget.formatter,
              showQtyField: _canEditQty,
              isOutgoingMode: widget.isOutgoingMode,
              isTransferredMode: widget.isTransferredMode,
              accent: widget.accent,
              qtyController: _qtyByProduct[product.productId]!,
              onChanged: () {
                if (_saved) {
                  setState(() => _saved = false);
                } else {
                  setState(() {});
                }
              },
            );
          }),
          if (_canEditQty) ...[
            if (pickingMissing) ...[
              const SizedBox(height: 8),
              Text(
                widget.isOutgoingMode
                    ? s.outboundPickingMissing
                    : s.inboundPickingMissing,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ],
            const SizedBox(height: 16),
            LoadingButton(
              label: _saved ? s.saved : s.save,
              isLoading: _saving,
              onPressed: _canSave ? _saveAll : null,
            ),
          ],
        ],
      ],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({
    required this.product,
    required this.formatter,
    required this.showQtyField,
    required this.isOutgoingMode,
    required this.isTransferredMode,
    required this.accent,
    required this.qtyController,
    required this.onChanged,
  });

  final DcProductLineModel product;
  final NumberFormat formatter;
  final bool showQtyField;
  final bool isOutgoingMode;
  final bool isTransferredMode;
  final Color accent;
  final TextEditingController qtyController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return ModuleCard(
      statusColor: isOutgoingMode ? accent : const Color(0xFF15803D),
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
                children: isTransferredMode
                    ? [
                        Expanded(
                          child: _Metric(
                            label: s.outgoing,
                            value: formatter.format(product.outgoingQty),
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
                            label: s.transferredQty,
                            value: formatter.format(product.transferredQty),
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ]
                    : isOutgoingMode
                        ? [
                            Expanded(
                              child: _Metric(
                                label: s.outgoing,
                                value: formatter.format(product.outgoingQty),
                                color: accent,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 26,
                              color: ModuleTokens.cardBorder,
                            ),
                            Expanded(
                              child: _Metric(
                                label: s.transferredQty,
                                value:
                                    formatter.format(product.transferredQty),
                                color: AppColors.primary,
                              ),
                            ),
                          ]
                        : [
                            Expanded(
                              child: _Metric(
                                label: s.incoming,
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
                                label: s.received,
                                value: formatter.format(product.receivedQty),
                                color: AppColors.primary,
                              ),
                            ),
                          ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${s.uom}: ${product.uom}',
              style: TextStyle(
                fontSize: 10.5,
                color: ModuleTokens.faintText,
              ),
            ),
            if (showQtyField) ...[
              const SizedBox(height: 10),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: isOutgoingMode
                      ? s.transferredQtyLabel
                      : s.receivedQtyLabel,
                  isDense: true,
                ),
                onChanged: (_) => onChanged(),
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
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: ModuleTokens.tileMetricLabelFontSize,
            fontWeight: FontWeight.w700,
            height: 1.15,
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
