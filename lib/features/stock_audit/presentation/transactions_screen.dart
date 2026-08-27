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
import '../data/models/transaction_model.dart';
import 'providers/transactions_provider.dart';
import 'widgets/business_location_picker.dart';

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
        .read(transactionsControllerProvider.notifier)
        .setStoreFilter(storeId);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Transaction',
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
                  _DateFilterTile(
                    label: dateLabel,
                    onTap: () => _pickDate(selectedDate),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(transactionsControllerProvider.notifier).loadReport(),
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
                  _SummaryRow(
                    pickupOrders: report?.summary.pickupOrders ?? 0,
                    rtoDeliveredOrders: report?.summary.rtoDeliveredOrders ?? 0,
                    isLoading: state.isLoading,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeading(
                    title: 'Product Movement',
                    subtitle: 'Pickup & RTO delivered qty by SKU',
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
                            'Transactions dekhne ke liye pehle business location choose karein.',
                      ),
                    )
                  else if ((report?.products ?? []).isEmpty)
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Koi transaction nahi mila',
                        message:
                            '$dateLabel par is location par koi pickup ya RTO delivered order nahi mila.',
                      ),
                    )
                  else
                    ...report!.products.map(
                      (row) => _TransactionProductCard(
                        row: row,
                        formatter: formatter,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AppBottomNav(
            currentTab: AppTab.transactions,
            onHomeTap: () => context.go('/home'),
            onStockTap: () => context.go('/my-products'),
            onTransactionsTap: () {},
            onVarianceTap: () => context.go('/variance'),
          ),
        ],
      ),
    );
  }
}

class _DateFilterTile extends StatelessWidget {
  const _DateFilterTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.pickupOrders,
    required this.rtoDeliveredOrders,
    required this.isLoading,
  });

  final int pickupOrders;
  final int rtoDeliveredOrders;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Row(
        children: [
          Expanded(child: ProductRowSkeleton()),
          SizedBox(width: 10),
          Expanded(child: ProductRowSkeleton()),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Pickup Orders',
            value: '$pickupOrders',
            icon: Icons.local_shipping_outlined,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: 'RTO Delivered',
            value: '$rtoDeliveredOrders',
            icon: Icons.undo_rounded,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionProductCard extends StatelessWidget {
  const _TransactionProductCard({
    required this.row,
    required this.formatter,
  });

  final TransactionProductRow row;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.productName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            row.variantLabel,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _QtyCell(
                    label: 'Pickup Qty',
                    value: formatter.format(row.pickupQty),
                    color: AppColors.primaryDark,
                  ),
                ),
                Expanded(
                  child: _QtyCell(
                    label: 'RTO Qty',
                    value: formatter.format(row.rtoDeliveredQty),
                    color: AppColors.warning,
                  ),
                ),
                Expanded(
                  child: _QtyCell(
                    label: 'Total',
                    value: formatter.format(row.totalQty),
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
