import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_header.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/business_location_model.dart';
import '../data/models/product_mismatch_model.dart';
import 'providers/my_products_provider.dart';

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
    await ref.read(myProductsControllerProvider.notifier).initialize(
          preferredStoreId: preferredStoreId,
        );
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  Future<void> _onStoreChanged(int? storeId) async {
    ref.read(authControllerProvider.notifier).touchActivity();
    final storage = ref.read(sessionStorageProvider);
    await storage.saveSelectedStoreId(storeId);
    await ref.read(myProductsControllerProvider.notifier).setStoreFilter(storeId);
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
            title: 'Stock Audit',
            showBrandIcon: true,
            subtitle: 'Namaste, $userName',
            trailing: HeaderLogoutButton(onPressed: _logout),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(myProductsControllerProvider.notifier).loadReport(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
                children: [
                  if (state.error != null) ...[
                    AlertBanner(message: state.error!, isError: true),
                    const SizedBox(height: 14),
                  ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full Inventory Plot Run Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Only SKUs with a mismatch (difference ≠ 0)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: _ReportLocationFilter(
                            locations: state.locations,
                            selectedId: state.selectedStoreId,
                            onChanged: _onStoreChanged,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search product, SKU or darkstore',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: ref.read(myProductsControllerProvider.notifier).setSearch,
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        if (state.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        else if (rows.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(
                              child: Text(
                                'No mismatch found.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ...rows.map((row) => _MismatchRow(row: row, formatter: formatter)),
                        if (!state.isLoading && state.total > 0) ...[
                          const Divider(height: 1, color: AppColors.border),
                          _PaginationBar(state: state),
                        ],
                      ],
                    ),
                  ),
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

class _StoreFilterResult {
  const _StoreFilterResult(this.storeId);
  final int? storeId;
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
        : locations.where((l) => l.id == selectedId).firstOrNull?.label ?? 'Select location';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BUSINESS LOCATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () async {
              final result = await showModalBottomSheet<_StoreFilterResult>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _AllLocationsSheet(
                  locations: locations,
                  selectedId: selectedId,
                ),
              );
              if (result != null) onChanged(result.storeId);
            },
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                selectedLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AllLocationsSheet extends StatefulWidget {
  const _AllLocationsSheet({
    required this.locations,
    required this.selectedId,
  });

  final List<BusinessLocationModel> locations;
  final int? selectedId;

  @override
  State<_AllLocationsSheet> createState() => _AllLocationsSheetState();
}

class _AllLocationsSheetState extends State<_AllLocationsSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<({int? id, String label})> get _options {
    final all = <({int? id, String label})>[
      (id: null, label: 'All Business Locations'),
      ...widget.locations.map((l) => (id: l.id, label: l.label)),
    ];
    final term = _query.trim().toLowerCase();
    if (term.isEmpty) return all;
    return all.where((item) => item.label.toLowerCase().contains(term)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Search business location...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Color(0xFFEEF3EE),
                ),
                itemBuilder: (context, index) {
                  final item = _options[index];
                  final isSelected = item.id == widget.selectedId;
                  return Material(
                    color: isSelected ? AppColors.footerActiveBg : Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(
                        context,
                        _StoreFilterResult(item.id),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _MismatchRow extends StatelessWidget {
  const _MismatchRow({required this.row, required this.formatter});

  final ProductMismatchRow row;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final diffColor = row.difference < 0
        ? AppColors.outStock
        : row.difference > 0
            ? AppColors.inStock
            : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEF3EE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.productName,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if ((row.variantLabel ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                row.variantLabel!,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCell(
                  label: 'System Stock',
                  value: formatter.format(row.systemStock),
                ),
              ),
              Expanded(
                child: _MetricCell(
                  label: 'Total Physical Stock',
                  value: formatter.format(row.physicalStock),
                ),
              ),
              Expanded(
                child: _MetricCell(
                  label: 'Difference',
                  value: formatter.format(row.difference),
                  valueColor: diffColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start–$end of $total',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
          IconButton(
            onPressed: state.page > 1 ? () => notifier.setPage(state.page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('${state.page}/${state.totalPages == 0 ? 1 : state.totalPages}'),
          IconButton(
            onPressed: state.page < state.totalPages ? () => notifier.setPage(state.page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
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
