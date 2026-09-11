import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/product_image_thumb.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/inventory_summary_model.dart';
import 'providers/inventory_report_provider.dart';

class InventoryReportScreen extends ConsumerStatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  ConsumerState<InventoryReportScreen> createState() =>
      _InventoryReportScreenState();
}

class _InventoryReportScreenState extends ConsumerState<InventoryReportScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryReportControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _rawField(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  List<InventorySummaryItem> _filterItems(
    List<InventorySummaryItem> items,
    String query,
  ) {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return items;

    return items.where((item) {
      final haystack = [
        item.productName,
        item.variantLabel ?? '',
        item.sku ?? '',
        '${item.productId ?? ''}',
        '${item.crmProductId ?? ''}',
        '${item.crmVariantId ?? ''}',
        _rawField(item.raw, ['sku', 'default_code', 'internal_reference']),
        _rawField(item.raw, ['product_name', 'display_name', 'name']),
        _rawField(item.raw, ['variant', 'variant_label', 'variant_name']),
      ]
          .join(' ')
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s-]'), ' ');

      return terms.every((term) => haystack.contains(term));
    }).toList();
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) {
      return NumberFormat.decimalPattern('en_IN').format(value.round());
    }
    return NumberFormat('#,##0.##', 'en_IN').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryReportControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final allItems = state.model?.items ?? const <InventorySummaryItem>[];
    final searchQuery = _searchController.text;
    final items = _filterItems(allItems, searchQuery);
    final warehouse = (state.model?.warehouseLabel ??
            auth.selectedStoreLabel ??
            '')
        .trim();

    final receivedTotal =
        allItems.fold<double>(0, (s, e) => s + e.receivedQty);
    final transferredTotal =
        allItems.fold<double>(0, (s, e) => s + e.transferredOutQty);
    final deliveredTotal =
        allItems.fold<double>(0, (s, e) => s + e.customerDeliveredQty);
    final onHandTotal =
        allItems.fold<double>(0, (s, e) => s + e.systemQuantityOnHand);
    final physicalTotal =
        allItems.fold<double>(0, (s, e) => s + e.physicalStock);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.headerBg,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            ModuleHeader(
              pageLabel: 'Report',
              subtitle: warehouse.isNotEmpty
                  ? warehouse
                  : 'Warehouse inventory summary',
              onBack: () => context.pop(),
              searchController: _searchController,
              searchHint: 'Product ya SKU search karo...',
              searchValue: searchQuery,
              onSearchChanged: (_) => setState(() {}),
              onClearSearch: () {
                _searchController.clear();
                setState(() {});
              },
              actions: [
                ModuleHeaderAction(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onTap: () => ref
                      .read(inventoryReportControllerProvider.notifier)
                      .load(refresh: true),
                ),
              ],
              showNotifications: false,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref
                    .read(inventoryReportControllerProvider.notifier)
                    .load(refresh: true),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    if (allItems.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ModuleStatsRow(
                          itemWidth: 152,
                          stats: [
                            ModuleStat(
                              icon: Icons.move_to_inbox_outlined,
                              label: 'Received',
                              value: _fmt(receivedTotal),
                              background: AppColors.primary,
                              labelColor: const Color(0xFFFFE4D2),
                            ),
                            ModuleStat(
                              icon: Icons.outbox_outlined,
                              label: 'Transferred Out',
                              value: _fmt(transferredTotal),
                              background: const Color(0xFFB45309),
                              labelColor: const Color(0xFFFED7AA),
                            ),
                            ModuleStat(
                              icon: Icons.local_shipping_outlined,
                              label: 'Delivered',
                              value: _fmt(deliveredTotal),
                              background: const Color(0xFF1D4ED8),
                              labelColor: const Color(0xFFBFDBFE),
                            ),
                            ModuleStat(
                              icon: Icons.inventory_2_outlined,
                              label: 'On Hand',
                              value: _fmt(onHandTotal),
                              background: AppColors.inStock,
                              labelColor: const Color(0xFFBBF7D0),
                            ),
                            ModuleStat(
                              icon: Icons.fact_check_outlined,
                              label: 'Physical Stock',
                              value: _fmt(physicalTotal),
                              background: const Color(0xFF7C3AED),
                              labelColor: const Color(0xFFE9D5FF),
                            ),
                          ],
                        ),
                      ),
                    if (state.error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.errorBorder),
                            ),
                            child: Text(
                              state.error!,
                              style: TextStyle(
                                color: AppColors.errorText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (state.isLoading && state.model == null)
                      const SliverToBoxAdapter(
                        child: ModuleListLoadingBody(),
                      )
                    else if (state.error == null && allItems.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: ModuleEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Koi inventory row nahi mila',
                          message:
                              'Is warehouse par inventory summary empty hai.',
                        ),
                      )
                    else if (state.error == null &&
                        items.isEmpty &&
                        searchQuery.trim().isNotEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ModuleEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Koi matching product nahi mila',
                          message:
                              '"${searchQuery.trim()}" se koi product match nahi hua.',
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _InventoryProductCard(
                            item: items[index],
                            format: _fmt,
                          ),
                          childCount: items.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryProductCard extends StatelessWidget {
  const _InventoryProductCard({
    required this.item,
    required this.format,
  });

  final InventorySummaryItem item;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final variant = (item.variantLabel ?? '').trim();

    return ModuleCard(
      statusColor: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumb(imageUrl: item.image),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: ModuleTokens.strongText,
                        ),
                      ),
                      if (variant.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          variant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: ModuleTokens.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ModuleTokens.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _QtyCell(
                      label: 'Received',
                      value: format(item.receivedQty),
                      color: AppColors.primary,
                    ),
                  ),
                  _vDiv(),
                  Expanded(
                    child: _QtyCell(
                      label: 'Transfer Out',
                      value: format(item.transferredOutQty),
                      color: const Color(0xFFB45309),
                    ),
                  ),
                  _vDiv(),
                  Expanded(
                    child: _QtyCell(
                      label: 'Delivered',
                      value: format(item.customerDeliveredQty),
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  _vDiv(),
                  Expanded(
                    child: _QtyCell(
                      label: 'On Hand',
                      value: format(item.systemQuantityOnHand),
                      color: AppColors.inStock,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    size: 14,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PHYSICAL STOCK',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: ModuleTokens.strongText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    format(item.physicalStock),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7C3AED),
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

  Widget _vDiv() => Container(
        width: 1,
        height: 28,
        color: ModuleTokens.cardBorder,
      );
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ProductImageThumb(
      imageUrl: imageUrl,
      width: 48,
      height: 48,
      borderRadius: 12,
      iconSize: 22,
    );
  }
}

class _QtyCell extends StatelessWidget {
  const _QtyCell({
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
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
            color: ModuleTokens.faintText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: color,
          ),
        ),
      ],
    );
  }
}
