import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/module_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/dc_repository.dart';
import '../data/models/dc_transfer_model.dart';
import 'providers/dc_provider.dart';

class DcListScreen extends ConsumerStatefulWidget {
  const DcListScreen({super.key, this.initialTab = 'incoming'});

  /// `incoming`, `received`, `outgoing`, or `transferred`.
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

  DcFetchQuery get _query {
    switch (_activeTab) {
      case _DcListTab.outgoing:
        return DcFetchQuery.outgoing;
      case _DcListTab.transferred:
        return DcFetchQuery.transferred;
      case _DcListTab.incoming:
      case _DcListTab.received:
        return DcFetchQuery.incoming;
    }
  }

  List<DcTransferModel> _visibleTransfers(List<DcTransferModel> transfers) {
    switch (_activeTab) {
      case _DcListTab.received:
        return transfers.where(_isReceivedTransfer).toList();
      case _DcListTab.outgoing:
      case _DcListTab.transferred:
        return transfers;
      case _DcListTab.incoming:
        return transfers.where(_isIncomingTransfer).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialTab == 'received') {
      _activeTab = _DcListTab.received;
    } else if (widget.initialTab == 'outgoing') {
      _activeTab = _DcListTab.outgoing;
    } else if (widget.initialTab == 'transferred') {
      _activeTab = _DcListTab.transferred;
    } else {
      _activeTab = _DcListTab.incoming;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted || _initialized) return;
    _initialized = true;
    ref.read(authControllerProvider.notifier).touchActivity();
    await ref.read(dcControllerProvider.notifier).initialize(query: _query);
  }

  Future<void> _refresh() async {
    ref.read(authControllerProvider.notifier).touchActivity();
    await ref.read(dcControllerProvider.notifier).refresh(query: _query);
  }

  Future<void> _switchTab(_DcListTab tab) async {
    if (_activeTab == tab) return;
    final previousKey = _query.key;
    setState(() => _activeTab = tab);
    final nextQuery = _query;
    if (previousKey != nextQuery.key) {
      await ref.read(dcControllerProvider.notifier).loadWithQuery(nextQuery);
    } else {
      await _refresh();
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(dcControllerProvider);
    final formatter = NumberFormat.decimalPattern('en_IN');
    final summary = state.summary;
    final visibleTransfers = _visibleTransfers(state.transfers);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'DC Transfers',
            subtitle: auth.headerGreeting,
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
                        itemWidth: 118,
                        stats: [
                          ModuleStat(
                            icon: Icons.call_received_rounded,
                            label: 'Incoming',
                            value: formatter.format(summary.incomingTransfers),
                            background: const Color(0xFF15803D),
                            labelColor: const Color(0xFFBBF7D0),
                            isActive: _activeTab == _DcListTab.incoming,
                            onTap: () => _switchTab(_DcListTab.incoming),
                          ),
                          ModuleStat(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Received',
                            value: formatter.format(summary.receivedTransfers),
                            background: AppColors.primary,
                            labelColor: const Color(0xFFFFE4D2),
                            isActive: _activeTab == _DcListTab.received,
                            onTap: () => _switchTab(_DcListTab.received),
                          ),
                          ModuleStat(
                            icon: Icons.call_made_rounded,
                            label: 'Outgoing',
                            value: formatter.format(
                              _activeTab == _DcListTab.outgoing
                                  ? state.transfers.length
                                  : summary.outgoingTransfers,
                            ),
                            background: const Color(0xFF1D4ED8),
                            labelColor: const Color(0xFFBFDBFE),
                            isActive: _activeTab == _DcListTab.outgoing,
                            onTap: () => _switchTab(_DcListTab.outgoing),
                          ),
                          ModuleStat(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Transferred',
                            value: formatter.format(
                              _activeTab == _DcListTab.transferred
                                  ? state.transfers.length
                                  : summary.transferredTransfers,
                            ),
                            background: const Color(0xFF7C3AED),
                            labelColor: const Color(0xFFE9D5FF),
                            isActive: _activeTab == _DcListTab.transferred,
                            onTap: () => _switchTab(_DcListTab.transferred),
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
                        ModuleChip(
                          label: 'Outgoing',
                          icon: Icons.outbox_outlined,
                          tone: const Color(0xFF1D4ED8),
                          isActive: _activeTab == _DcListTab.outgoing,
                          onTap: () => _switchTab(_DcListTab.outgoing),
                        ),
                        ModuleChip(
                          label: 'Transferred',
                          icon: Icons.swap_horiz_rounded,
                          tone: const Color(0xFF7C3AED),
                          isActive: _activeTab == _DcListTab.transferred,
                          onTap: () => _switchTab(_DcListTab.transferred),
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
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: _emptyIcon,
                        title: _emptyTitle,
                        message: _emptyMessage,
                      ),
                    )
                  else if (visibleTransfers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: _emptyIcon,
                        title: _emptyTitle,
                        message: _emptyMessage,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final transfer = visibleTransfers[index];
                          return _TransferCard(
                            transfer: transfer,
                            formatter: formatter,
                            mode: _activeTab,
                            onTap: () {
                              if (transfer.transferId <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Transfer id missing — detail open nahi ho sakta.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              context.push(
                                '/dc/${transfer.transferId}?tab=${_activeTab.name}',
                              );
                            },
                          );
                        },
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

  IconData get _emptyIcon {
    switch (_activeTab) {
      case _DcListTab.received:
        return Icons.check_circle_outline_rounded;
      case _DcListTab.outgoing:
        return Icons.call_made_rounded;
      case _DcListTab.transferred:
        return Icons.swap_horiz_rounded;
      case _DcListTab.incoming:
        return Icons.local_shipping_outlined;
    }
  }

  String get _emptyTitle {
    switch (_activeTab) {
      case _DcListTab.received:
        return 'Koi received transfer nahi';
      case _DcListTab.outgoing:
        return 'Koi outgoing transfer nahi';
      case _DcListTab.transferred:
        return 'Koi transferred transfer nahi';
      case _DcListTab.incoming:
        return 'Koi incoming transfer nahi';
    }
  }

  String get _emptyMessage {
    switch (_activeTab) {
      case _DcListTab.received:
        return 'Abhi tak koi DC transfer receive nahi hui.';
      case _DcListTab.outgoing:
        return 'Is darkstore se abhi koi pending outgoing transfer nahi hai.';
      case _DcListTab.transferred:
        return 'Is darkstore se abhi koi completed outgoing transfer nahi hai.';
      case _DcListTab.incoming:
        return 'Is darkstore par abhi koi pending incoming transfer nahi hai.';
    }
  }
}

enum _DcListTab { incoming, received, outgoing, transferred }

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.transfer,
    required this.formatter,
    required this.mode,
    required this.onTap,
  });

  final DcTransferModel transfer;
  final NumberFormat formatter;
  final _DcListTab mode;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (mode) {
      case _DcListTab.outgoing:
        return const Color(0xFF1D4ED8);
      case _DcListTab.transferred:
        return const Color(0xFF7C3AED);
      case _DcListTab.received:
      case _DcListTab.incoming:
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
  }

  String get _statusLabel {
    switch (mode) {
      case _DcListTab.outgoing:
        return 'Outgoing';
      case _DcListTab.transferred:
        return 'Transferred';
      case _DcListTab.received:
      case _DcListTab.incoming:
        switch (transfer.state.toLowerCase()) {
          case 'executed':
          case 'done':
            return 'Received';
          default:
            return transfer.state.isNotEmpty ? transfer.state : '—';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showReceivedQty = mode == _DcListTab.received;
    final showOutgoingQty = mode == _DcListTab.outgoing;
    final showTransferredQty = mode == _DcListTab.transferred;

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
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: ModuleTokens.strongText,
                        ),
                      ),
                      if ((showOutgoingQty || showTransferredQty) &&
                          (transfer.to?.warehouse ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'To: ${transfer.to!.warehouse}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: ModuleTokens.mutedText,
                          ),
                        ),
                      ] else if ((transfer.from?.warehouse ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'From: ${transfer.from!.warehouse}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: ModuleTokens.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ModuleStatusPill(
                  label: _statusLabel,
                  color: _statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ModuleTokens.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _QtyCell(
                      label: showTransferredQty
                          ? 'Transferred Qty'
                          : showOutgoingQty
                              ? 'Outgoing'
                              : showReceivedQty
                                  ? 'Received'
                                  : 'Incoming',
                      value: formatter.format(
                        showTransferredQty
                            ? transfer.transferredQty
                            : showOutgoingQty
                                ? transfer.outgoingQty
                                : showReceivedQty
                                    ? transfer.receivedQty
                                    : transfer.incomingQty,
                      ),
                      color: _statusColor,
                    ),
                  ),
                  if (!showReceivedQty &&
                      !showOutgoingQty &&
                      !showTransferredQty) ...[
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
          style: TextStyle(
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
