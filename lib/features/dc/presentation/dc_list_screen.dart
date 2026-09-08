import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/module_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/dc_transfer_model.dart';
import 'providers/dc_provider.dart';

class DcListScreen extends ConsumerStatefulWidget {
  const DcListScreen({super.key, this.initialTab = 'incoming'});

  /// `incoming` or `received` — from route query after save success.
  final String initialTab;

  @override
  ConsumerState<DcListScreen> createState() => _DcListScreenState();
}

class _DcListScreenState extends ConsumerState<DcListScreen> {
  bool _initialized = false;
  _DcListTab _activeTab = _DcListTab.incoming;

  bool _isIncomingTransfer(DcTransferModel transfer) =>
      transfer.ibtStatus.toLowerCase() == 'ready';

  bool _isReceivedTransfer(DcTransferModel transfer) =>
      transfer.ibtStatus.toLowerCase() == 'done';

  List<DcTransferModel> _visibleTransfers(List<DcTransferModel> transfers) {
    if (_activeTab == _DcListTab.received) {
      return transfers.where(_isReceivedTransfer).toList();
    }
    return transfers.where(_isIncomingTransfer).toList();
  }

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab == 'received'
        ? _DcListTab.received
        : _DcListTab.incoming;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_initialized) return;
    _initialized = true;
    ref.read(authControllerProvider.notifier).touchActivity();
    await ref.read(dcControllerProvider.notifier).initialize();
  }

  Future<void> _refresh() async {
    ref.read(authControllerProvider.notifier).touchActivity();
    await ref.read(dcControllerProvider.notifier).refresh();
  }

  Future<void> _switchTab(_DcListTab tab) async {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
    await _refresh();
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(dcControllerProvider);
    final userName = auth.user?.displayName ?? 'User';
    final formatter = NumberFormat.decimalPattern('en_IN');
    final summary = state.summary;
    final visibleTransfers = _visibleTransfers(state.transfers);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'DC Transfers',
            subtitle: 'Namaste, $userName',
            onLogout: _logout,
            bottom: state.warehouse?.code != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          state.warehouse!.code!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  if (summary != null)
                    SliverToBoxAdapter(
                      child: ModuleStatsRow(
                        stats: [
                          ModuleStat(
                            icon: Icons.call_received_rounded,
                            label: 'Incoming',
                            value: formatter.format(summary.incomingTransfers),
                            background: const Color(0xFF15803D),
                            labelColor: const Color(0xFFBBF7D0),
                          ),
                          ModuleStat(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Received',
                            value: formatter.format(summary.receivedTransfers),
                            background: AppColors.primary,
                            labelColor: const Color(0xFFFFE4D2),
                          ),
                        ],
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: ModuleChipsRow(
                      chips: [
                        ModuleChip(
                          label: 'Incoming',
                          icon: Icons.inbox_outlined,
                          tone: const Color(0xFF15803D),
                          isActive: _activeTab == _DcListTab.incoming,
                          onTap: () => _switchTab(_DcListTab.incoming),
                        ),
                        ModuleChip(
                          label: 'Received',
                          icon: Icons.check_circle_outline_rounded,
                          tone: AppColors.primary,
                          isActive: _activeTab == _DcListTab.received,
                          onTap: () => _switchTab(_DcListTab.received),
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
                  if (state.isLoading && state.transfers.isEmpty)
                    const SliverToBoxAdapter(
                      child: ModuleListLoadingBody(),
                    )
                  else if (state.transfers.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: Icons.local_shipping_outlined,
                        title: 'Koi DC transfer nahi mila',
                        message: 'Is darkstore par abhi koi inter-branch transfer nahi hai.',
                      ),
                    )
                  else if (visibleTransfers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: _activeTab == _DcListTab.received
                            ? Icons.check_circle_outline_rounded
                            : Icons.local_shipping_outlined,
                        title: _activeTab == _DcListTab.received
                            ? 'Koi received transfer nahi'
                            : 'Koi incoming transfer nahi',
                        message: _activeTab == _DcListTab.received
                            ? 'Abhi tak koi DC transfer receive nahi hui.'
                            : 'Is darkstore par abhi koi pending incoming transfer nahi hai.',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TransferCard(
                          transfer: visibleTransfers[index],
                          formatter: formatter,
                          showReceivedQty: _activeTab == _DcListTab.received,
                          onTap: () => context.push(
                            '/dc/${visibleTransfers[index].transferId}?tab=${_activeTab.name}',
                          ),
                        ),
                        childCount: visibleTransfers.length,
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
        currentTab: AppTab.dc,
        onDashboardTap: () => context.go('/dashboard'),
        onHomeTap: () => context.go('/audit'),
        onOrdersTap: () => context.go('/orders'),
        onStockTap: () => context.go('/my-products'),
      ),
    );
  }
}

enum _DcListTab { incoming, received }

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.transfer,
    required this.formatter,
    required this.showReceivedQty,
    required this.onTap,
  });

  final DcTransferModel transfer;
  final NumberFormat formatter;
  final bool showReceivedQty;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (transfer.state.toLowerCase()) {
      case 'executed':
      case 'done':
        return const Color(0xFF15803D);
      case 'approved':
        return const Color(0xFF1D4ED8);
      case 'draft':
        return const Color(0xFFB45309);
      case 'cancel':
      case 'cancelled':
        return const Color(0xFFB91C1C);
      default:
        return ModuleTokens.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      statusColor: _statusColor,
      onTap: onTap,
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
                        transfer.reference.isNotEmpty
                            ? transfer.reference
                            : 'Transfer #${transfer.transferId}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: ModuleTokens.strongText,
                        ),
                      ),
                      if ((transfer.from?.warehouse ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'From: ${transfer.from!.warehouse}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ModuleTokens.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ModuleStatusPill(
                  label: transfer.state.isNotEmpty ? transfer.state : '—',
                  color: _statusColor,
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
                      label: showReceivedQty ? 'Received' : 'Incoming',
                      value: formatter.format(
                        showReceivedQty
                            ? transfer.receivedQty
                            : transfer.incomingQty,
                      ),
                      color: showReceivedQty
                          ? AppColors.primary
                          : const Color(0xFF15803D),
                    ),
                  ),
                  if (!showReceivedQty) ...[
                    Container(
                      width: 1,
                      height: 26,
                      color: ModuleTokens.cardBorder,
                    ),
                    Expanded(
                      child: _QtyCell(
                        label: 'Remaining',
                        value: formatter.format(transfer.remainingQty),
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
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
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
