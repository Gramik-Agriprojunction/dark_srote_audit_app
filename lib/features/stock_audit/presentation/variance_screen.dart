import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/variance_model.dart';
import 'providers/variance_provider.dart';
import 'widgets/business_location_picker.dart';

class VarianceScreen extends ConsumerStatefulWidget {
  const VarianceScreen({super.key});

  @override
  ConsumerState<VarianceScreen> createState() => _VarianceScreenState();
}

class _VarianceScreenState extends ConsumerState<VarianceScreen> {
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
    final preferredStoreId = await storage.getSelectedStoreId();
    await ref
        .read(varianceControllerProvider.notifier)
        .initialize(preferredStoreId: preferredStoreId);
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  Future<void> _onStoreChanged(int? storeId) async {
    ref.read(authControllerProvider.notifier).touchActivity();
    final storage = ref.read(sessionStorageProvider);
    await storage.saveSelectedStoreId(storeId);
    await ref.read(varianceControllerProvider.notifier).setStoreFilter(storeId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(varianceControllerProvider);
    final userName = auth.user?.displayName ?? 'User';
    final formatter = NumberFormat.decimalPattern('en_IN');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Variance',
            showBrandIcon: true,
            subtitle: 'Namaste, $userName',
            trailing: HeaderLogoutButton(onPressed: _logout),
            bottom: AppCard(
              padding: const EdgeInsets.all(14),
              radius: 18,
              shadow: AppColors.floatShadow,
              child: Column(
                children: [
                  BusinessLocationPicker(
                    locations: state.locations,
                    selectedId: state.selectedStoreId,
                    onChanged: _onStoreChanged,
                  ),
                  const SizedBox(height: 12),
                  _TypeFilterRow(
                    selected: state.typeFilter,
                    onChanged: (filter) => ref
                        .read(varianceControllerProvider.notifier)
                        .setTypeFilter(filter),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(varianceControllerProvider.notifier).loadReport(),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  if (state.error != null) ...[
                    AlertBanner(message: state.error!, isError: true),
                    const SizedBox(height: 14),
                  ],
                  const SectionHeading(
                    title: 'Backlog',
                    subtitle: 'Minus red, plus green — CRM jaisa',
                  ),
                  const SizedBox(height: 14),
                  if (state.isLoading)
                    const Column(
                      children: [
                        ProductRowSkeleton(),
                        ProductRowSkeleton(),
                        ProductRowSkeleton(),
                      ],
                    )
                  else if (state.selectedStoreId == null)
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const AppEmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'Darkstore select karein',
                        message:
                            'Variance dekhne ke liye pehle business location choose karein.',
                      ),
                    )
                  else if (state.rows.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const AppEmptyState(
                        icon: Icons.compare_arrows_rounded,
                        title: 'Koi backlog nahi mila',
                        message:
                            'Is location par abhi koi minus/plus backlog nahi hai.',
                      ),
                    )
                  else ...[
                    ...state.rows.map(
                      (row) => _VarianceRowCard(row: row, formatter: formatter),
                    ),
                    if (state.meta.total > 0) ...[
                      const SizedBox(height: 4),
                      _PaginationBar(
                        meta: state.meta,
                        onPageChanged: (page) => ref
                            .read(varianceControllerProvider.notifier)
                            .setPage(page),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          AppBottomNav(
            currentTab: AppTab.variance,
            onHomeTap: () => context.go('/home'),
            onStockTap: () => context.go('/my-products'),
            onTransactionsTap: () => context.go('/transactions'),
            onVarianceTap: () {},
          ),
        ],
      ),
    );
  }
}

class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({
    required this.selected,
    required this.onChanged,
  });

  final VarianceTypeFilter selected;
  final ValueChanged<VarianceTypeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            label: 'All Backlog',
            isSelected: selected == VarianceTypeFilter.all,
            onTap: () => onChanged(VarianceTypeFilter.all),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'Minus',
            isSelected: selected == VarianceTypeFilter.minus,
            selectedColor: AppColors.outStock.withValues(alpha: 0.15),
            onTap: () => onChanged(VarianceTypeFilter.minus),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'Plus',
            isSelected: selected == VarianceTypeFilter.plus,
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            onTap: () => onChanged(VarianceTypeFilter.plus),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (selectedColor ?? AppColors.footerActiveBg)
              : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryMid : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _VarianceRowCard extends StatelessWidget {
  const _VarianceRowCard({
    required this.row,
    required this.formatter,
  });

  final VarianceRowModel row;
  final NumberFormat formatter;

  Color _bgColor() {
    switch (row.type) {
      case VarianceType.minus:
        return const Color(0xFFFFECE8);
      case VarianceType.plus:
        return const Color(0xFFE8F8EE);
      case VarianceType.equal:
        return AppColors.fieldBg;
    }
  }

  Color _accentColor() {
    switch (row.type) {
      case VarianceType.minus:
        return AppColors.outStock;
      case VarianceType.plus:
        return AppColors.primary;
      case VarianceType.equal:
        return AppColors.textMuted;
    }
  }

  String _backlogLabel() {
    final prefix = row.type == VarianceType.minus ? '-' : '+';
    if (row.type == VarianceType.equal) {
      return formatter.format(row.backlog);
    }
    return '$prefix${formatter.format(row.backlog)}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                row.variantLabel,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _backlogLabel(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            row.storeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.meta,
    required this.onPageChanged,
  });

  final PaginationMeta meta;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = meta.total == 0 ? 0 : ((meta.page - 1) * meta.limit) + 1;
    final end = (meta.page * meta.limit).clamp(0, meta.total);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start–$end of ${meta.total}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: meta.page > 1 ? () => onPageChanged(meta.page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            '${meta.page}/${meta.totalPages == 0 ? 1 : meta.totalPages}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: meta.page < meta.totalPages
                ? () => onPageChanged(meta.page + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
