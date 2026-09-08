import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/module_ui.dart';
import '../../../core/widgets/scroll_pagination_footer.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/variance_model.dart';
import 'providers/variance_provider.dart';

class VarianceScreen extends ConsumerStatefulWidget {
  const VarianceScreen({super.key});

  @override
  ConsumerState<VarianceScreen> createState() => _VarianceScreenState();
}

class _VarianceScreenState extends ConsumerState<VarianceScreen> {
  final _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 220) {
      ref.read(varianceControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_initialized) return;
    _initialized = true;
    ref.read(authControllerProvider.notifier).touchActivity();
    final storage = ref.read(sessionStorageProvider);
    final preferredStoreId = await storage.getSelectedStoreId();
    await ref
        .read(varianceControllerProvider.notifier)
        .initialize(preferredStoreId: preferredStoreId);
    final selectedId = ref.read(varianceControllerProvider).selectedStoreId;
    if (selectedId != null) {
      await storage.saveSelectedStoreId(selectedId);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(varianceControllerProvider);
    final formatter = NumberFormat.decimalPattern('en_IN');
    final notifier = ref.read(varianceControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'Variance',
            subtitle: auth.headerGreeting,
            onLogout: _logout,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => notifier.loadReport(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: ModuleStatsRow(
                      stats: [
                        ModuleStat(
                          icon: Icons.compare_arrows_rounded,
                          label: 'Total Backlog',
                          value: formatter.format(state.meta.total),
                          background: AppColors.primary,
                          labelColor: const Color(0xFFFFE4D2),
                        ),
                        ModuleStat(
                          icon: Icons.visibility_outlined,
                          label: 'Showing',
                          value: formatter.format(state.rows.length),
                          background: const Color(0xFF1D4ED8),
                          labelColor: const Color(0xFFBFDBFE),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ModuleChipsRow(
                      chips: [
                        ModuleChip(
                          label: 'All Backlog',
                          icon: Icons.list_alt_rounded,
                          tone: AppColors.primary,
                          isActive: state.typeFilter == VarianceTypeFilter.all,
                          onTap: () =>
                              notifier.setTypeFilter(VarianceTypeFilter.all),
                        ),
                        ModuleChip(
                          label: 'Minus',
                          icon: Icons.trending_down_rounded,
                          tone: const Color(0xFFB91C1C),
                          isActive: state.typeFilter == VarianceTypeFilter.minus,
                          onTap: () =>
                              notifier.setTypeFilter(VarianceTypeFilter.minus),
                        ),
                        ModuleChip(
                          label: 'Plus',
                          icon: Icons.trending_up_rounded,
                          tone: const Color(0xFF15803D),
                          isActive: state.typeFilter == VarianceTypeFilter.plus,
                          onTap: () =>
                              notifier.setTypeFilter(VarianceTypeFilter.plus),
                        ),
                      ],
                    ),
                  ),
                  if (state.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                        child: AlertBanner(
                          message: state.error!,
                          isError: true,
                        ),
                      ),
                    ),
                  if (state.isLoading && state.rows.isEmpty)
                    const SliverToBoxAdapter(
                      child: ModuleListLoadingBody(showStats: false),
                    )
                  else if (state.selectedStoreId == null)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'Darkstore select karein',
                        message:
                            'Variance dekhne ke liye pehle business location choose karein.',
                      ),
                    )
                  else if (state.rows.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: Icons.compare_arrows_rounded,
                        title: 'Koi backlog nahi mila',
                        message:
                            'Is location par abhi koi minus/plus backlog nahi hai.',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _VarianceRowCard(
                          row: state.rows[index],
                          formatter: formatter,
                        ),
                        childCount: state.rows.length,
                      ),
                    ),
                  if (state.rows.isNotEmpty && state.meta.total > 0)
                    SliverToBoxAdapter(
                      child: ScrollPaginationFooter(
                        isLoadingMore: state.isLoadingMore,
                        hasNextPage: state.hasNextPage,
                        from: state.rows.isEmpty ? 0 : 1,
                        to: state.rows.length,
                        total: state.meta.total,
                        page: state.meta.page,
                        totalPages: state.meta.totalPages,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.variance,
        onDashboardTap: () => context.go('/dashboard'),
        onHomeTap: () => context.go('/audit'),
        onOrdersTap: () => context.go('/orders'),
        onStockTap: () => context.go('/my-products'),
      ),
    );
  }
}

class _VarianceRowCard extends StatelessWidget {
  const _VarianceRowCard({required this.row, required this.formatter});

  final VarianceRowModel row;
  final NumberFormat formatter;

  Color get _accent {
    switch (row.type) {
      case VarianceType.minus:
        return const Color(0xFFB91C1C);
      case VarianceType.plus:
        return const Color(0xFF15803D);
      case VarianceType.equal:
        return ModuleTokens.faintText;
    }
  }

  String get _backlogLabel {
    if (row.type == VarianceType.equal) return formatter.format(row.backlog);
    final prefix = row.type == VarianceType.minus ? '-' : '+';
    return '$prefix${formatter.format(row.backlog)}';
  }

  String get _typeLabel {
    switch (row.type) {
      case VarianceType.minus:
        return 'Minus';
      case VarianceType.plus:
        return 'Plus';
      case VarianceType.equal:
        return 'Equal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return ModuleCard(
      statusColor: accent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.productName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: ModuleTokens.strongText,
                        ),
                      ),
                      if (row.variantLabel.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          row.variantLabel,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: ModuleTokens.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ModuleStatusPill(label: _typeLabel, color: accent),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'BACKLOG',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: accent.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _backlogLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            if (row.storeName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 12,
                    color: ModuleTokens.faintText,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      row.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: ModuleTokens.faintText,
                      ),
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
