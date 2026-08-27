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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Stock',
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
                  _StatsRow(state: state),
                  const SizedBox(height: 20),
                  const SectionHeading(
                    title: 'Full SKU Reconciliation Report',
                    subtitle: 'CRM jaisa — latest audit first',
                  ),
                  const SizedBox(height: 14),
                  _SearchField(
                    onSearch: (query) {
                      ref
                          .read(myProductsControllerProvider.notifier)
                          .setSearch(query);
                    },
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
                      child: AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: state.searchQuery.isNotEmpty
                            ? 'Koi matching SKU nahi mila'
                            : 'Koi audited SKU nahi mila',
                        message: state.searchQuery.isNotEmpty
                            ? '"${state.searchQuery}" se koi product match nahi hua.'
                            : 'Is location par abhi tak koi stock audit nahi hua hai.',
                      ),
                    )
                  else ...[
                    ...rows.asMap().entries.map(
                      (entry) => _ProductCard(
                        key: ValueKey('${entry.value.sku}-${entry.key}'),
                        row: entry.value,
                        formatter: formatter,
                      ),
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
            currentTab: AppTab.stock,
            onHomeTap: () => context.go('/home'),
            onStockTap: () {},
            onTransactionsTap: () => context.go('/transactions'),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange(String value) {
    final hasText = value.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
    widget.onSearch(value);
  }

  void _clear() {
    _controller.clear();
    _handleChange('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.fieldBg,
        hintText: 'Search product, SKU or darkstore',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.cancel_rounded, size: 18),
                color: AppColors.textMuted,
                onPressed: _clear,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.4),
        ),
      ),
      onChanged: _handleChange,
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final MyProductsState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Total',
            value: '${state.total}',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Matched',
            value: '${state.matchedCount}',
            icon: Icons.check_circle_outline,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Short',
            value: '${state.shortCount}',
            icon: Icons.trending_down_rounded,
            color: AppColors.outStock,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Excess',
            value: '${state.excessCount}',
            icon: Icons.trending_up_rounded,
            color: AppColors.warning,
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({super.key, required this.row, required this.formatter});

  final ProductMismatchRow row;
  final NumberFormat formatter;

  Color _statusColor() {
    switch (row.status) {
      case ReconStatus.matched:
        return AppColors.primary;
      case ReconStatus.excess:
        return AppColors.warning;
      case ReconStatus.short:
        return AppColors.outStock;
    }
  }

  String _statusLabel() {
    switch (row.status) {
      case ReconStatus.matched:
        return 'Matched';
      case ReconStatus.excess:
        return 'Excess';
      case ReconStatus.short:
        return 'Short';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final comment = (row.comment ?? '').trim();
    final hasDamage = row.damageStock > 0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      radius: 16,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((row.variantLabel ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        row.variantLabel!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _DataRow(
                  cells: [
                    _DataCell(
                        label: 'System Stock',
                        value: formatter.format(row.systemStock)),
                    _DataCell(
                        label: 'Total Physical',
                        value: formatter.format(row.totalPhysicalStock)),
                    _DataCell(
                        label: 'Physical',
                        value: formatter.format(row.physicalStock)),
                  ],
                ),
                const SizedBox(height: 8),
                _DataRow(
                  cells: [
                    _DataCell(
                      label: 'Damage',
                      value: formatter.format(row.damageStock),
                      valueColor: hasDamage ? AppColors.outStock : null,
                    ),
                    _DataCell(
                      label: 'Comment',
                      value: comment.isEmpty ? '—' : comment,
                      valueColor:
                          comment.isEmpty ? AppColors.textMuted : null,
                      flex: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DIFFERENCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatter.format(row.difference),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if ((row.storeName ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 12,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    row.storeName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
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

class _DataRow extends StatelessWidget {
  const _DataRow({required this.cells});

  final List<_DataCell> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: cells
          .expand((cell) => [
                if (cells.indexOf(cell) > 0)
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: AppColors.border,
                  ),
                Expanded(flex: cell.flex, child: cell),
              ])
          .toList(),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.flex = 1,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: valueColor ?? AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
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
      radius: 14,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start–$end of $total',
              style: const TextStyle(
                fontSize: 11,
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${state.page} / $totalPages',
              style: const TextStyle(
                fontSize: 11,
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
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
