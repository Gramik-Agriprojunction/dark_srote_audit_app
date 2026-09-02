import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/module_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/transaction_model.dart';
import 'providers/transactions_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
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
        .read(transactionsControllerProvider.notifier)
        .initialize(preferredStoreId: preferredStoreId);
    final selectedId = ref.read(transactionsControllerProvider).selectedStoreId;
    if (selectedId != null) {
      await storage.saveSelectedStoreId(selectedId);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  Future<void> _pickDate(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Select date',
    );
    if (picked != null) {
      await ref.read(transactionsControllerProvider.notifier).setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(transactionsControllerProvider);
    final userName = auth.user?.displayName ?? 'User';
    final report = state.report;
    final selectedDate = state.selectedDate ?? DateTime.now();
    final dateLabel = DateFormat('d MMM yyyy').format(selectedDate);
    final formatter = NumberFormat.decimalPattern('en_IN');
    final products = report?.products ?? const <TransactionProductRow>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            icon: Icons.swap_horiz_rounded,
            title: 'Transactions',
            subtitle: 'Namaste, $userName',
            actions: [ModuleLogoutAction(onTap: _logout)],
            bottom: _DatePill(
              label: dateLabel,
              onTap: () => _pickDate(selectedDate),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref
                  .read(transactionsControllerProvider.notifier)
                  .loadReport(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: ModuleStatsRow(
                      stats: [
                        ModuleStat(
                          icon: Icons.local_shipping_outlined,
                          label: 'Pickup Orders',
                          value: formatter.format(
                            report?.summary.pickupOrders ?? 0,
                          ),
                          background: AppColors.primary,
                          labelColor: const Color(0xFFFFE4D2),
                        ),
                        ModuleStat(
                          icon: Icons.undo_rounded,
                          label: 'RTO Delivered',
                          value: formatter.format(
                            report?.summary.rtoDeliveredOrders ?? 0,
                          ),
                          background: const Color(0xFFB45309),
                          labelColor: const Color(0xFFFED7AA),
                        ),
                        ModuleStat(
                          icon: Icons.category_outlined,
                          label: 'SKU Moved',
                          value: formatter.format(products.length),
                          background: const Color(0xFF1D4ED8),
                          labelColor: const Color(0xFFBFDBFE),
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
                  if (state.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (state.selectedStoreId == null)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'Darkstore select karein',
                        message:
                            'Transactions dekhne ke liye pehle business location choose karein.',
                      ),
                    )
                  else if (products.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Koi transaction nahi mila',
                        message:
                            '$dateLabel par is location par koi pickup ya RTO delivered order nahi mila.',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TransactionProductCard(
                          row: products[index],
                          formatter: formatter,
                        ),
                        childCount: products.length,
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
        currentTab: AppTab.transactions,
        onHomeTap: () => context.go('/home'),
        onOrdersTap: () => context.go('/orders'),
        onStockTap: () => context.go('/my-products'),
        onTransactionsTap: () {},
        onDcTap: () => context.go('/dc'),
        onVarianceTap: () => context.go('/variance'),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Material(
          color: Colors.white.withValues(alpha: 0.2),
          shape: StadiumBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionProductCard extends StatelessWidget {
  const _TransactionProductCard({required this.row, required this.formatter});

  final TransactionProductRow row;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final hasRto = row.rtoDeliveredQty > 0;
    final statusColor = hasRto
        ? const Color(0xFFB45309)
        : const Color(0xFF1D4ED8);

    return ModuleCard(
      statusColor: statusColor,
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
                ModuleStatusPill(
                  label: hasRto ? 'RTO' : 'Pickup',
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ModuleTokens.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _QtyCell(
                      label: 'Pickup Qty',
                      value: formatter.format(row.pickupQty),
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 26,
                    color: ModuleTokens.cardBorder,
                  ),
                  Expanded(
                    child: _QtyCell(
                      label: 'RTO Qty',
                      value: formatter.format(row.rtoDeliveredQty),
                      color: const Color(0xFFB45309),
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
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: ModuleTokens.faintText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: color,
          ),
        ),
      ],
    );
  }
}
