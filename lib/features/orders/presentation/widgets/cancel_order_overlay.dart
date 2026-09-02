import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';
import '../utils/order_status_helper.dart';

/// Full-screen cancel flow — matches Gramik Darkstore RN CancelOrderOverlay.
class CancelOrderOverlay extends StatefulWidget {
  const CancelOrderOverlay({
    super.key,
    required this.orderCode,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.itemsCount,
    required this.amount,
    required this.products,
    required this.reasons,
    required this.isLoading,
    required this.onClose,
    required this.onConfirm,
  });

  final String orderCode;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final int itemsCount;
  final double amount;
  final List<OrderProductLineModel> products;
  final List<CancelReasonModel> reasons;
  final bool isLoading;
  final VoidCallback onClose;
  final ValueChanged<String> onConfirm;

  @override
  State<CancelOrderOverlay> createState() => _CancelOrderOverlayState();
}

class _CancelOrderOverlayState extends State<CancelOrderOverlay> {
  int? _selectedId;
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: const Color(0xFF0F172A),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, top + 8, 14, 10),
                child: Row(
                  children: [
                    _CircleBtn(icon: Icons.chevron_left, onTap: widget.onClose),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0x24F25146),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x47F25146)),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFCA5A5),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _CircleBtn(icon: Icons.close, onTap: widget.onClose),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF25146),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cancel Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${widget.orderCode} · ${widget.customerName}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  children: [
                    _DarkCard(
                      title: 'ORDER',
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.orderCode,
                              style: const TextStyle(
                                color: Color(0xFFFDBA74),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            formatMoney(widget.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _DarkCard(
                      title: 'CUSTOMER',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customerName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          if (widget.customerPhone.isNotEmpty)
                            Text(
                              widget.customerPhone,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          if (widget.customerAddress.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.customerAddress,
                              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.products.isNotEmpty)
                      _DarkCard(
                        title: 'PRODUCTS (${widget.products.length})',
                        child: Column(
                          children: widget.products.take(4).map((p) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0x1AFFFFFF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: p.thumbnailImg != null && p.thumbnailImg!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: p.thumbnailImg!,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '×${p.quantity}',
                                    style: const TextStyle(color: Color(0xFFFDBA74), fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    _DarkCard(
                      title: 'SELECT REASON',
                      child: widget.isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            )
                          : Column(
                              children: widget.reasons.map((r) {
                                final selected = _selectedId == r.id;
                                return Material(
                                  color: selected
                                      ? const Color(0x24F25146)
                                      : Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(() {
                                      _selectedId = r.id;
                                      _selectedReason = r.reason;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.white.withValues(alpha: 0.06),
                                          ),
                                          left: selected
                                              ? const BorderSide(
                                                  color: Color(0xFFF25146),
                                                  width: 3,
                                                )
                                              : BorderSide.none,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_off,
                                            size: 18,
                                            color: selected
                                                ? const Color(0xFFF25146)
                                                : const Color(0x59FFFFFF),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              r.reason,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: selected
                                                    ? Colors.white
                                                    : const Color(0xFFCBD5E1),
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(14, 10, 14, bottom > 0 ? bottom : 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
                  color: Color(0xFF0F172A),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: widget.onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Keep Order', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _selectedReason == null
                              ? null
                              : () => widget.onConfirm(_selectedReason!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF25146),
                            disabledBackgroundColor: const Color(0x66F25146),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}
