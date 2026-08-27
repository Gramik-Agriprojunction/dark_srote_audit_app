import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/loading_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/stock_audit_provider.dart';
import 'widgets/business_location_picker.dart';
import 'widgets/comment_bottom_sheet.dart';
import 'widgets/product_variant_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_initialized) return;
    _initialized = true;
    ref.read(authControllerProvider.notifier).touchActivity();
    final storage = ref.read(sessionStorageProvider);
    final queryStoreId = int.tryParse(
      GoRouterState.of(context).uri.queryParameters['storeId'] ?? '',
    );
    if (queryStoreId != null) {
      await storage.saveSelectedStoreId(queryStoreId);
    }
    final preferredStoreId = queryStoreId ?? await storage.getSelectedStoreId();
    await ref
        .read(stockAuditControllerProvider.notifier)
        .loadLocations(preferredStoreId: preferredStoreId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onLocationChanged(int? locationId) async {
    ref.read(authControllerProvider.notifier).touchActivity();
    final storage = ref.read(sessionStorageProvider);
    await storage.saveSelectedStoreId(locationId);
    await ref
        .read(stockAuditControllerProvider.notifier)
        .selectLocation(locationId);
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  int _changedCount(StockAuditState state) {
    var count = 0;
    for (final product in state.products) {
      for (final variant in product.variants) {
        if (state.emptyDraftVariantIds.contains(variant.id)) continue;
        if (state.qtyDrafts.containsKey(variant.id)) count++;
      }
    }
    return count;
  }

  Future<void> _refresh() async {
    ref.read(authControllerProvider.notifier).touchActivity();
    final audit = ref.read(stockAuditControllerProvider);
    final storage = ref.read(sessionStorageProvider);
    final storeId =
        audit.selectedLocationId ?? await storage.getSelectedStoreId();
    await ref
        .read(stockAuditControllerProvider.notifier)
        .loadLocations(preferredStoreId: storeId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final audit = ref.watch(stockAuditControllerProvider);
    final userName = auth.user?.displayName ?? 'User';
    final changedCount = _changedCount(audit);
    final hasChanges = changedCount > 0;

    final variantCount = audit.filteredProducts.fold<int>(
      0,
      (sum, product) => sum + product.variants.length,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'StockShield',
            showBrandIcon: true,
            subtitle: 'Namaste, $userName',
            trailing: HeaderLogoutButton(onPressed: _logout),
            bottom: AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              radius: 18,
              shadow: AppColors.floatShadow,
              child: BusinessLocationPicker(
                locations: audit.locations,
                selectedId: audit.selectedLocationId,
                isLoading: audit.isLoadingLocations,
                onChanged: _onLocationChanged,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  if (audit.error != null) ...[
                    AlertBanner(message: audit.error!, isError: true),
                    const SizedBox(height: 14),
                  ],
                  if (audit.successMessage != null) ...[
                    AlertBanner(message: audit.successMessage!, isError: false),
                    const SizedBox(height: 14),
                  ],
                  if (!audit.showProducts)
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AppEmptyState(
                        icon: Icons.storefront_rounded,
                        title: audit.isLoadingLocations
                            ? 'Locations load ho rahi hain'
                            : 'Business location select karein',
                        message:
                            'Location choose karne ke baad store ke products yahan dikhenge.',
                      ),
                    )
                  else ...[
                    SectionHeading(
                      title: 'Store Products',
                      subtitle:
                          'Qty update karke save karein. 0 qty bhi allowed hai.',
                      trailing: audit.isLoadingProducts
                          ? null
                          : AppChip(
                              label: '$variantCount',
                              color: AppColors.primaryDark,
                              background: AppColors.primarySoft,
                            ),
                    ),
                    const SizedBox(height: 14),
                    AppSearchField(
                      hintText: 'Search product, variant or SKU',
                      onChanged: ref
                          .read(stockAuditControllerProvider.notifier)
                          .setSearchQuery,
                    ),
                    const SizedBox(height: 16),
                    if (audit.isLoadingProducts)
                      const Column(
                        children: [
                          ProductRowSkeleton(),
                          ProductRowSkeleton(),
                          ProductRowSkeleton(),
                        ],
                      )
                    else if (audit.filteredProducts.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const AppEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matching products',
                          message: 'Search clear karke dubara try karein.',
                        ),
                      )
                    else
                      ...audit.filteredProducts.expand((product) {
                        return product.variants.map(
                          (variant) => ProductVariantRow(
                            key: ValueKey(variant.id),
                            product: product,
                            variant: variant,
                            onOpenDamage: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .touchActivity();
                              context.push(
                                '/variant-audit?storeId=${audit.selectedLocationId}'
                                '&productId=${product.id}&variantId=${variant.id}',
                              );
                            },
                            onOpenComment: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .touchActivity();
                              showCommentSheet(
                                context: context,
                                ref: ref,
                                productId: product.id,
                                variantId: variant.id,
                                productName: product.name,
                                variantLabel: variant.variantName,
                                initialComment: variant.auditComment,
                              );
                            },
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            child: hasChanges
                ? StickyActionBar(
                    info: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Text(
                              '$changedCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'variant pending save',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    child: LoadingButton(
                      label: audit.isSaving ? 'Saving...' : 'Save Stocks',
                      icon: Icons.cloud_upload_outlined,
                      isLoading: audit.isSaving,
                      onPressed: () => ref
                          .read(stockAuditControllerProvider.notifier)
                          .saveAllChanged(),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          AppBottomNav(
            currentTab: AppTab.home,
            onHomeTap: () {
              ref.read(authControllerProvider.notifier).touchActivity();
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
              );
            },
            onStockTap: () => context.go('/my-products'),
            onTransactionsTap: () => context.go('/transactions'),
          ),
        ],
      ),
    );
  }
}
