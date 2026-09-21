import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/l10n/app_strings.dart';
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
  late final _DcListFlow _flow;
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

  List<_DcListTab> get _flowTabs {
    switch (_flow) {
      case _DcListFlow.incoming:
        return const [_DcListTab.incoming, _DcListTab.received];
      case _DcListFlow.outgoing:
        return const [_DcListTab.outgoing, _DcListTab.transferred];
    }
  }

  _DcListFlow _flowFromInitialTab(String tab) {
    switch (tab) {
      case 'outgoing':
      case 'transferred':
        return _DcListFlow.outgoing;
      default:
        return _DcListFlow.incoming;
    }
  }

  _DcListTab _tabFromName(String tab) {
    switch (tab) {
      case 'received':
        return _DcListTab.received;
      case 'outgoing':
        return _DcListTab.outgoing;
      case 'transferred':
        return _DcListTab.transferred;
      default:
        return _DcListTab.incoming;
    }
  }

  @override
  void initState() {
    super.initState();
    _flow = _flowFromInitialTab(widget.initialTab);
    final requestedTab = _tabFromName(widget.initialTab);
    _activeTab = _flowTabs.contains(requestedTab)
        ? requestedTab
        : _flowTabs.first;
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

  String _pageLabel(AppStrings s) => _flow == _DcListFlow.incoming
      ? s.incomingDelivery
      : s.outgoingDelivery;

  List<ModuleStat> _buildStats({
    required AppStrings s,
    required NumberFormat formatter,
    required DcSummaryModel? summary,
  }) {
    if (summary == null) return const [];

    ModuleStat statForTab(_DcListTab tab) {
      switch (tab) {
        case _DcListTab.incoming:
          return ModuleStat(
            icon: Icons.call_received_rounded,
            label: s.incoming,
            value: formatter.format(summary.incomingTransfers),
            background: const Color(0xFF15803D),
            labelColor: const Color(0xFFBBF7D0),
            isActive: _activeTab == _DcListTab.incoming,
            onTap: () => _switchTab(_DcListTab.incoming),
          );
        case _DcListTab.received:
          return ModuleStat(
            icon: Icons.check_circle_outline_rounded,
            label: s.received,
            value: formatter.format(summary.receivedTransfers),
            background: AppColors.primary,
            labelColor: const Color(0xFFFFE4D2),
            isActive: _activeTab == _DcListTab.received,
            onTap: () => _switchTab(_DcListTab.received),
          );
        case _DcListTab.outgoing:
          return ModuleStat(
            icon: Icons.call_made_rounded,
            label: s.outgoing,
            value: formatter.format(summary.outgoingTransfers),
            background: const Color(0xFF1D4ED8),
            labelColor: const Color(0xFFBFDBFE),
            isActive: _activeTab == _DcListTab.outgoing,
            onTap: () => _switchTab(_DcListTab.outgoing),
          );
        case _DcListTab.transferred:
          return ModuleStat(
            icon: Icons.swap_horiz_rounded,
            label: s.transferred,
            value: formatter.format(summary.transferredTransfers),
            background: const Color(0xFF7C3AED),
            labelColor: const Color(0xFFE9D5FF),
            isActive: _activeTab == _DcListTab.transferred,
            onTap: () => _switchTab(_DcListTab.transferred),
          );
      }
    }

    return _flowTabs.map(statForTab).toList();
  }

  List<ModuleChip> _buildChips(AppStrings s) {
    ModuleChip chipForTab(_DcListTab tab) {
      switch (tab) {
        case _DcListTab.incoming:
          return ModuleChip(
            label: s.incoming,
            icon: Icons.inbox_outlined,
            tone: const Color(0xFF15803D),
            isActive: _activeTab == _DcListTab.incoming,
            onTap: () => _switchTab(_DcListTab.incoming),
          );
        case _DcListTab.received:
          return ModuleChip(
            label: s.received,
            icon: Icons.check_circle_outline_rounded,
            tone: AppColors.primary,
            isActive: _activeTab == _DcListTab.received,
            onTap: () => _switchTab(_DcListTab.received),
          );
        case _DcListTab.outgoing:
          return ModuleChip(
            label: s.outgoing,
            icon: Icons.outbox_outlined,
            tone: const Color(0xFF1D4ED8),
            isActive: _activeTab == _DcListTab.outgoing,
            onTap: () => _switchTab(_DcListTab.outgoing),
          );
        case _DcListTab.transferred:
          return ModuleChip(
            label: s.transferred,
            icon: Icons.swap_horiz_rounded,
            tone: const Color(0xFF7C3AED),
            isActive: _activeTab == _DcListTab.transferred,
            onTap: () => _switchTab(_DcListTab.transferred),
          );
      }
    }

    return _flowTabs.map(chipForTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final state = ref.watch(dcControllerProvider);
    final formatter = NumberFormat.decimalPattern('en_IN');
    final summary = state.summary;
    final visibleTransfers = _visibleTransfers(state.transfers);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: _pageLabel(s),
            subtitle: ref.watch(headerGreetingProvider),
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
                        stats: _buildStats(
                          s: s,
                          formatter: formatter,
                          summary: summary,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: ModuleChipsRow(chips: _buildChips(s)),
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
                        title: _emptyTitle(s),
                        message: _emptyMessage(s),
                      ),
                    )
                  else if (visibleTransfers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ModuleEmptyState(
                        icon: _emptyIcon,
                        title: _emptyTitle(s),
                        message: _emptyMessage(s),
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
                            strings: s,
                            onTap: () {
                              if (transfer.transferId <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(s.transferIdMissing),
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

  String _emptyTitle(AppStrings s) {
    switch (_activeTab) {
      case _DcListTab.received:
        return s.dcEmptyReceivedTitle;
      case _DcListTab.outgoing:
        return s.dcEmptyOutgoingTitle;
      case _DcListTab.transferred:
        return s.dcEmptyTransferredTitle;
      case _DcListTab.incoming:
        return s.dcEmptyIncomingTitle;
    }
  }

  String _emptyMessage(AppStrings s) {
    switch (_activeTab) {
      case _DcListTab.received:
        return s.dcEmptyReceivedMessage;
      case _DcListTab.outgoing:
        return s.dcEmptyOutgoingMessage;
      case _DcListTab.transferred:
        return s.dcEmptyTransferredMessage;
      case _DcListTab.incoming:
        return s.dcEmptyIncomingMessage;
    }
  }
}

enum _DcListFlow { incoming, outgoing }

enum _DcListTab { incoming, received, outgoing, transferred }

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.transfer,
    required this.formatter,
    required this.mode,
    required this.strings,
    required this.onTap,
  });

  final DcTransferModel transfer;
  final NumberFormat formatter;
  final _DcListTab mode;
  final AppStrings strings;
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
        return strings.outgoing;
      case _DcListTab.transferred:
        return strings.transferred;
      case _DcListTab.received:
      case _DcListTab.incoming:
        switch (transfer.state.toLowerCase()) {
          case 'executed':
          case 'done':
            return strings.received;
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
                            : strings.transferNumber(transfer.transferId),
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
                          strings.toWarehouse(transfer.to!.warehouse ?? ''),
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
                          strings.fromWarehouse(transfer.from!.warehouse ?? ''),
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
                          ? strings.transferredQty
                          : showOutgoingQty
                              ? strings.outgoing
                              : showReceivedQty
                                  ? strings.received
                                  : strings.incoming,
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
                        label: strings.remaining,
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
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: ModuleTokens.tileMetricLabelFontSize,
            fontWeight: FontWeight.w700,
            height: 1.15,
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
