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
import '../data/models/business_location_model.dart';
import '../data/models/product_mismatch_model.dart';
import 'providers/my_products_provider.dart';
import 'widgets/business_location_picker.dart';

class MyProductsScreen extends ConsumerStatefulWidget {
  const MyProductsScreen({super.key});

  @override
  ConsumerState<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends ConsumerState<MyProductsScreen> {
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
        .read(myProductsControllerProvider.notifier)
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
    await ref
        .read(myProductsControllerProvider.notifier)
        .setStoreFilter(storeId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(myProductsControllerProvider);
    final userName = auth.user?.displayName ?? 'User';
    final rows = state.pagedRows;
    final formatter = NumberFormat.decimalPattern('en_IN');

    final missing = state.filteredRows.where((r) => r.difference > 0).length;
    final extra = state.filteredRows.where((r) => r.difference < 0).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'My Product',
            showBrandIcon: true,
            subtitle: 'Namaste, $userName',
            trailing: HeaderLogoutButton(onPressed: _logout),
            bottom: AppCard(
              padding: const EdgeInsets.all(14),
              radius: 18,
              shadow: AppColors.floatShadow,
              child: _ReportLocationFilter(
                locations: state.locations,
                selectedId: state.selectedStoreId,
                onChanged: _onStoreChanged,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(myProductsControllerProvider.notifier).loadReport(),
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
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Mismatch',
                          value: '${state.total}',
                          icon: Icons.difference_outlined,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Short',
                          value: '$missing',
                          icon: Icons.trending_down_rounded,
                          color: AppColors.outStock,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Extra',
                          value: '$extra',
                          icon: Icons.trending_up_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionHeading(
                    title: 'Inventory Plot Run',
                    subtitle: 'Sirf wahi SKU jinme difference ≠ 0 hai',
                  ),
                  const SizedBox(height: 14),
                  AppSearchField(
                    hintText: 'Search product, SKU or darkstore',
                    onChanged: ref
                        .read(myProductsControllerProvider.notifier)
                        .setSearch,
                  ),
                  const SizedBox(height: 16),
                  if (state.isLoading)
                    const Column(
                      children: [
                        ProductRowSkeleton(),
                        ProductRowSkeleton(),
                        ProductRowSkeleton(),
                      ],
                    )
                  else if (rows.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const AppEmptyState(
                        icon: Icons.verified_outlined,
                        title: 'Koi mismatch nahi mila',
                        message:
                            'Is location ke saare audited SKU system stock se match kar rahe hain.',
                      ),
                    )
                  else ...[
                    ...rows.map(
                      (row) => _MismatchCard(row: row, formatter: formatter),
                    ),
                    if (state.total > 0) ...[
                      const SizedBox(height: 4),
                      _PaginationBar(state: state),
                    ],
                  ],
                ],
              ),
            ),
          ),
          AppBottomNav(
            currentTab: AppTab.myProducts,
            onHomeTap: () => context.go('/home'),
            onMyProductsTap: () {},
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportLocationFilter extends StatelessWidget {
  const _ReportLocationFilter({
    required this.locations,
    required this.selectedId,
    required this.onChanged,
  });

  final List<BusinessLocationModel> locations;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedId == null
        ? 'All Business Locations'
        : locations
                  .where((l) => l.id == selectedId)
                  .map((l) => l.label)
                  .firstOrNull ??
              'Select location';
    final parts = selectedId == null
        ? (title: selectedLabel, subtitle: null)
        : splitLocationLabel(selectedLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Business Location', icon: Icons.place_outlined),
        const SizedBox(height: 10),
        AppSelectTile(
          value: parts.title,
          subtitle: parts.subtitle,
          icon: selectedId == null
              ? Icons.apps_rounded
              : Icons.storefront_rounded,
          onTap: () async {
            final result = await showLocationPickerSheet(
              context: context,
              locations: locations,
              selectedId: selectedId,
              includeAllOption: true,
            );
            if (result != null) onChanged(result.id);
          },
        ),
      ],
    );
  }
}

class _MismatchCard extends StatelessWidget {
  const _MismatchCard({required this.row, required this.formatter});

  final ProductMismatchRow row;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final isShort = row.difference > 0;
    final diffColor = isShort ? AppColors.outStock : AppColors.warning;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      radius: 18,
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
                        letterSpacing: -0.2,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((row.variantLabel ?? '').isNotEmpty ||
                        (row.sku ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if ((row.variantLabel ?? '').isNotEmpty)
                            AppChip(
                              label: row.variantLabel!,
                              color: AppColors.textSecondary,
                              background: AppColors.fieldBg,
                            ),
                          if ((row.sku ?? '').isNotEmpty)
                            AppChip(
                              label: row.sku!,
                              color: AppColors.textMuted,
                              background: AppColors.fieldBg,
                              bold: false,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppChip(
                label:
                    '${row.difference > 0 ? '-' : '+'}${formatter.format(row.difference.abs())}',
                icon: isShort
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: diffColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCell(
                    label: 'System',
                    value: formatter.format(row.systemStock),
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _MetricCell(
                    label: 'Physical',
                    value: formatter.format(row.physicalStock),
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _MetricCell(
                    label: 'Difference',
                    value: formatter.format(row.difference),
                    valueColor: diffColor,
                  ),
                ),
              ],
            ),
          ),
          if ((row.storeName ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    row.storeName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: AppColors.border);
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PaginationBar extends ConsumerWidget {
  const _PaginationBar({required this.state});

  final MyProductsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(myProductsControllerProvider.notifier);
    final total = state.total;
    final start = total == 0 ? 0 : ((state.page - 1) * state.limit) + 1;
    final end = (state.page * state.limit).clamp(0, total);
    final totalPages = state.totalPages == 0 ? 1 : state.totalPages;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      radius: 18,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start–$end of $total',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _PageButton(
            icon: Icons.chevron_left_rounded,
            onTap: state.page > 1
                ? () => notifier.setPage(state.page - 1)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${state.page} / $totalPages',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            onTap: state.page < state.totalPages
                ? () => notifier.setPage(state.page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: enabled ? AppColors.primarySoft : AppColors.fieldBg,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.primaryDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
