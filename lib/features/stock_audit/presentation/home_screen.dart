import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_bottom_nav.dart';
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
    await ref.read(stockAuditControllerProvider.notifier).selectLocation(locationId);
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  bool _hasBulkChanges(StockAuditState state) {
    for (final product in state.products) {
      for (final variant in product.variants) {
        if (state.emptyDraftVariantIds.contains(variant.id)) continue;
        if (state.qtyDrafts.containsKey(variant.id)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final audit = ref.watch(stockAuditControllerProvider);
    final userName = auth.user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Stock Audit',
            showBrandIcon: true,
            subtitle: 'Namaste, $userName',
            trailing: HeaderLogoutButton(onPressed: _logout),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.read(authControllerProvider.notifier).touchActivity();
                final storage = ref.read(sessionStorageProvider);
                final storeId = audit.selectedLocationId ?? await storage.getSelectedStoreId();
                await ref
                    .read(stockAuditControllerProvider.notifier)
                    .loadLocations(preferredStoreId: storeId);
              },
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
                children: [
                  if (audit.error != null) ...[
                    AlertBanner(message: audit.error!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  if (audit.successMessage != null) ...[
                    AlertBanner(message: audit.successMessage!, isError: false),
                    const SizedBox(height: 16),
                  ],
                  BusinessLocationPicker(
                    locations: audit.locations,
                    selectedId: audit.selectedLocationId,
                    isLoading: audit.isLoadingLocations,
                    onChanged: _onLocationChanged,
                  ),
                  if (audit.showProducts) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Store Products',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Select qty for required variants and submit. You can update qty to 0.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search product / variant / SKU',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: ref.read(stockAuditControllerProvider.notifier).setSearchQuery,
                          ),
                          const SizedBox(height: 12),
                          if (audit.isLoadingProducts)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          else if (audit.filteredProducts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No matching products found.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            )
                          else
                            ...audit.filteredProducts.expand((product) {
                              return product.variants.map(
                                (variant) => ProductVariantRow(
                                  product: product,
                                  variant: variant,
                                  onOpenDamage: () {
                                    ref.read(authControllerProvider.notifier).touchActivity();
                                    context.push(
                                      '/variant-audit?storeId=${audit.selectedLocationId}'
                                      '&productId=${product.id}&variantId=${variant.id}',
                                    );
                                  },
                                  onOpenComment: () {
                                    ref.read(authControllerProvider.notifier).touchActivity();
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
                          const SizedBox(height: 12),
                          LoadingButton(
                            label: audit.isSaving ? 'Saving...' : 'Save Stocks',
                            isLoading: audit.isSaving,
                            enabled: audit.selectedLocationId != null && _hasBulkChanges(audit),
                            onPressed: audit.selectedLocationId != null && _hasBulkChanges(audit)
                                ? () => ref
                                    .read(stockAuditControllerProvider.notifier)
                                    .saveAllChanged()
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
            onMyProductsTap: () => context.go('/my-products'),
          ),
        ],
      ),
    );
  }
}
