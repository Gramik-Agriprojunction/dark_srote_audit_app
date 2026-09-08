import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/role_helper.dart';
import '../../../core/widgets/module_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/profile_model.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).load();
    });
  }

  Future<void> _openLogoutSheet() async {
    final state = ref.read(profileControllerProvider);
    if (state.isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => const _LogoutConfirmDialog(),
    );
    if (!mounted || confirmed != true) return;

    await ref.read(profileControllerProvider.notifier).logoutRemote();
    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final p = state.profile ?? const ProfileModel();
    final bottom = MediaQuery.paddingOf(context).bottom;
    final name = (p.name ?? '').trim();
    final phone = (p.phone ?? '').trim();
    final retailerId = (p.retailerId ?? '').trim();
    final address = p.displayAddress;
    final isSuperAdmin = RoleHelper.isSuperAdminRole(
      ref.watch(authControllerProvider).user?.role?.name,
    );
    final selectedStore =
        (ref.watch(authControllerProvider).selectedStoreLabel ?? '').trim();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primary,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F5FA),
        body: Column(
          children: [
            _ProfileHeader(
              onBack: () => context.pop(),
              onNotifications: () {},
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    ref.read(profileControllerProvider.notifier).load(refresh: true),
                child: state.isLoading && state.profile == null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
                        children: [
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                              child: Text(
                                state.error!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          _HeroCard(
                            name: name.isEmpty ? 'Retailer' : name,
                            phone: phone.isEmpty ? '--' : phone,
                            retailerId: retailerId,
                            address: selectedStore.isNotEmpty
                                ? selectedStore
                                : address,
                            totalOrders: p.totalOrders,
                            delivered: p.delivered,
                            pending: p.pending,
                            cancelled: p.cancelled,
                          ),
                          const SizedBox(height: 14),
                          const _SectionLabel('Menu'),
                          _WhiteCard(
                            children: [
                              _InfoRow(
                                icon: Icons.dashboard_rounded,
                                iconBg: const Color(0xFFFFF5F0),
                                iconColor: AppColors.primary,
                                label: 'Dashboard',
                                value: '',
                                onTap: () => context.go('/dashboard'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.inventory_2_rounded,
                                iconBg: const Color(0xFFFFF5F0),
                                iconColor: AppColors.primary,
                                label: 'Stock',
                                value: '',
                                onTap: () => context.go('/my-products'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.receipt_long_rounded,
                                iconBg: const Color(0xFFEFF6FF),
                                iconColor: Color(0xFF2563EB),
                                label: 'Orders',
                                value: '',
                                onTap: () => context.go('/orders'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.swap_horiz_rounded,
                                iconBg: const Color(0xFFF5F3FF),
                                iconColor: Color(0xFF7C3AED),
                                label: 'Transaction',
                                value: '',
                                onTap: () => context.go('/transactions'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.fact_check_rounded,
                                iconBg: const Color(0xFFFFF7ED),
                                iconColor: Color(0xFFEA580C),
                                label: 'Audit',
                                value: '',
                                onTap: () => context.go('/audit'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.compare_arrows_rounded,
                                iconBg: const Color(0xFFECFDF5),
                                iconColor: Color(0xFF059669),
                                label: 'Variance',
                                value: '',
                                onTap: () => context.go('/variance'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.local_shipping_rounded,
                                iconBg: const Color(0xFFEFF6FF),
                                iconColor: Color(0xFF0284C7),
                                label: 'DC',
                                value: '',
                                onTap: () => context.go('/dc'),
                              ),
                              if (isSuperAdmin) ...[
                                const _RowDivider(),
                                _InfoRow(
                                  icon: Icons.store_mall_directory_rounded,
                                  iconBg: const Color(0xFFFFF7ED),
                                  iconColor: Color(0xFFEA580C),
                                  label: 'Change Warehouse',
                                  value: '',
                                  onTap: () async {
                                    await ref
                                        .read(authControllerProvider.notifier)
                                        .clearSelectedStore();
                                    if (context.mounted) {
                                      context.go('/select-warehouse');
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            if (!state.isLoading || state.profile != null)
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: EdgeInsets.fromLTRB(
                  10,
                  10,
                  10,
                  bottom > 0 ? bottom : 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F5FA),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E6EC)),
                  ),
                ),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed:
                        state.isLoggingOut ? null : _openLogoutSheet,
                    icon: state.isLoggingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onBack,
    required this.onNotifications,
  });

  final VoidCallback onBack;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        14,
        MediaQuery.paddingOf(context).top + 8,
        14,
        12,
      ),
      child: Row(
        children: [
          ModuleHeaderAction(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Back',
            onTap: onBack,
          ),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          ModuleHeaderAction(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.phone,
    required this.retailerId,
    required this.address,
    required this.totalOrders,
    required this.delivered,
    required this.pending,
    required this.cancelled,
  });

  final String name;
  final String phone;
  final String retailerId;
  final String address;
  final int totalOrders;
  final int delivered;
  final int pending;
  final int cancelled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF5F00).withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      name.isEmpty ? 'R' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (retailerId.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  retailerId,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.call,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.35,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Row(
                children: [
                  _HeroStat(value: totalOrders, label: 'Total', color: Colors.white),
                  _vDiv(),
                  _HeroStat(
                    value: delivered,
                    label: 'Delivered',
                    color: const Color(0xFF4ADE80),
                  ),
                  _vDiv(),
                  _HeroStat(
                    value: pending,
                    label: 'Pending',
                    color: const Color(0xFFFBBF24),
                  ),
                  _vDiv(),
                  _HeroStat(
                    value: cancelled,
                    label: 'Cancelled',
                    color: const Color(0xFFF87171),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDiv() => Container(
        width: 1,
        height: 22,
        color: Colors.white.withValues(alpha: 0.08),
      );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({this.thin = false});

  final bool thin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: thin ? 8 : 10),
      child: Divider(
        height: 1,
        color: thin ? const Color(0xFFF4F6FA) : const Color(0xFFEEF1F5),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
        ],
      ],
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Logout?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kya aap logout karna chahte ho?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        foregroundColor: const Color(0xFF666666),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
