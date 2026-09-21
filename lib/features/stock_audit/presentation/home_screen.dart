import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/module_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/stock_audit_provider.dart';
import 'widgets/comment_bottom_sheet.dart';
import 'widgets/product_variant_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted || _initialized) return;
    _initialized = true;
    ref.read(authControllerProvider.notifier).touchActivity();
    final storage = ref.read(sessionStorageProvider);
    final queryStoreId = int.tryParse(
      GoRouterState.of(context).uri.queryParameters['storeId'] ?? '',
    );
    if (queryStoreId != null) {
      await storage.saveSelectedStoreId(queryStoreId);
    }
    if (!mounted) return;
    final preferredStoreId = queryStoreId ?? await storage.getSelectedStoreId();
    if (!mounted) return;
    await ref
        .read(stockAuditControllerProvider.notifier)
        .loadLocations(preferredStoreId: preferredStoreId);
    if (!mounted) return;
    final selectedId =
        ref.read(stockAuditControllerProvider).selectedLocationId;
    if (selectedId != null) {
      final loc = ref
          .read(stockAuditControllerProvider)
          .locations
          .where((l) => l.id == selectedId)
          .firstOrNull;
      final label = (loc?.name ?? loc?.label ?? '').trim();
      await ref.read(authControllerProvider.notifier).setSelectedStoreId(
            selectedId,
            label: label.isEmpty ? null : label,
          );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
    final s = ref.watch(appStringsProvider);
    final viewOnly = ref.watch(isViewOnlySessionProvider);
    final audit = ref.watch(stockAuditControllerProvider);
    final changedCount = _changedCount(audit);
    final hasChanges = !viewOnly && changedCount > 0;
    final notifier = ref.read(stockAuditControllerProvider.notifier);
    final selectedLoc = audit.locations
        .where((l) => l.id == audit.selectedLocationId)
        .firstOrNull;
    final storeSubtitle = (selectedLoc?.name ??
            selectedLoc?.label ??
            auth.selectedStoreLabel ??
            '')
        .trim();

    if (_searchController.text != audit.searchQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: audit.searchQuery,
        selection: TextSelection.collapsed(offset: audit.searchQuery.length),
      );
    }

    ref.listen<StockAuditState>(stockAuditControllerProvider, (previous, next) {
      final message = next.successMessage;
      if (message == null || message == previous?.successMessage) return;
      if (!context.mounted) return;
      AppSnackBar.showSuccess(context, message);
      ref.read(stockAuditControllerProvider.notifier).clearSuccessMessage();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: ref.watch(headerGreetingProvider),
            subtitle: storeSubtitle.isEmpty ? null : storeSubtitle,
            onLogout: _logout,
            searchController: audit.showProducts ? _searchController : null,
            searchHint: s.searchProductSku,
            searchValue: audit.searchQuery,
            onSearchChanged: audit.showProducts ? notifier.setSearchQuery : null,
            onClearSearch: () => notifier.setSearchQuery(''),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  if (audit.showProducts)
                    SliverToBoxAdapter(
                      child: _statsRow(audit, notifier, s),
                    ),
                  if (audit.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: AlertBanner(
                          message: audit.error!,
                          isError: true,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (!audit.showProducts)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: Icons.storefront_outlined,
                        title: audit.isLoadingLocations
                            ? s.loadingLocations
                            : s.selectBusinessLocation,
                        message: s.auditSelectLocationHint,
                      ),
                    )
                  else if (audit.isLoadingProducts)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          for (var i = 0; i < 5; i++) const ProductRowSkeleton(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    )
                  else if (audit.filteredProducts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: Icons.search_off_rounded,
                        title: audit.searchQuery.isNotEmpty
                            ? s.noMatchingProducts
                            : _emptyTitle(audit.auditStatusFilter, s),
                        message: audit.searchQuery.isNotEmpty
                            ? s.searchClearAndRetry
                            : _emptyMessage(audit.auditStatusFilter, s),
                      ),
                    )
                  else
                    SliverList.list(
                      children: audit.filteredProducts.expand((product) {
                        return product.variants.map(
                          (variant) => ProductVariantRow(
                            key: ValueKey(variant.id),
                            product: product,
                            variant: variant,
                            readOnly: viewOnly,
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
                      }).toList(),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.variantsPendingSave(changedCount),
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
                      label: audit.isSaving ? s.saving : s.saveStocks,
                      icon: Icons.cloud_upload_outlined,
                      isLoading: audit.isSaving,
                      onPressed: () => notifier.saveAllChanged(context),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(
    StockAuditState audit,
    StockAuditController notifier,
    AppStrings s,
  ) {
    final filter = audit.auditStatusFilter;
    final total = audit.totalVariantCount;
    final audited = audit.auditedVariantCount;
    final pending = audit.pendingVariantCount;
    final auditedPct = total > 0 ? audited / total : 0.0;
    final pendingPct = total > 0 ? pending / total : 0.0;

    return ModuleStatsRow(
      stats: [
        ModuleStat(
          icon: Icons.inventory_2_rounded,
          label: s.totalSku,
          value: '$total',
          background: AppColors.primary,
          labelColor: AppColors.textMuted,
          progress: 1,
          isActive: filter == AuditStatusFilter.all,
          onTap: () => notifier.setAuditStatusFilter(AuditStatusFilter.all),
        ),
        ModuleStat(
          icon: Icons.task_alt_rounded,
          label: s.audited,
          value: '$audited',
          background: AppColors.successText,
          labelColor: AppColors.textMuted,
          progress: auditedPct,
          isActive: filter == AuditStatusFilter.audited,
          onTap: () => notifier.setAuditStatusFilter(AuditStatusFilter.audited),
        ),
        ModuleStat(
          icon: Icons.pending_actions_rounded,
          label: s.pending,
          value: '$pending',
          background: AppColors.warning,
          labelColor: AppColors.textMuted,
          progress: pendingPct,
          isActive: filter == AuditStatusFilter.pending,
          onTap: () => notifier.setAuditStatusFilter(AuditStatusFilter.pending),
        ),
      ],
    );
  }

  String _emptyTitle(AuditStatusFilter filter, AppStrings s) {
    switch (filter) {
      case AuditStatusFilter.audited:
        return s.auditEmptyAuditedTitle;
      case AuditStatusFilter.pending:
        return s.auditEmptyPendingTitle;
      case AuditStatusFilter.all:
        return s.noProductsFound;
    }
  }

  String _emptyMessage(AuditStatusFilter filter, AppStrings s) {
    switch (filter) {
      case AuditStatusFilter.audited:
        return s.auditEmptyAuditedMessage;
      case AuditStatusFilter.pending:
        return s.auditEmptyPendingMessage;
      case AuditStatusFilter.all:
        return s.auditEmptyAllMessage;
    }
  }
}
