import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/theme_mode_provider.dart';
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
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).load();
    });
  }

  Future<void> _openLogoutSheet() async {
    final state = ref.read(profileControllerProvider);
    if (state.isLoggingOut) return;

    final s = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _LogoutConfirmDialog(strings: s),
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
    final s = ref.watch(appStringsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.headerBg,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _ProfileHeader(
              strings: s,
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
                        children: [
                          const SizedBox(height: 120),
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
                                style: TextStyle(
                                  color: AppColors.errorText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          _HeroCard(
                            strings: s,
                            name: name.isEmpty ? s.retailer : name,
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
                          _SectionLabel(s.appearance),
                          _ThemeModeCard(
                            strings: s,
                            mode: ref.watch(appThemeModeProvider),
                            onChanged: (mode) => ref
                                .read(appThemeModeProvider.notifier)
                                .setMode(mode),
                          ),
                          const SizedBox(height: 14),
                          _LanguageCard(
                            strings: s,
                            language: ref.watch(appLanguageProvider),
                            onChanged: (language) => ref
                                .read(appLanguageProvider.notifier)
                                .setLanguage(language),
                          ),
                          const SizedBox(height: 14),
                          _SectionLabel(s.menu),
                          _WhiteCard(
                            children: [
                              _InfoRow(
                                icon: Icons.dashboard_rounded,
                                iconBg: AppColors.softOrange,
                                iconColor: AppColors.primary,
                                label: s.dashboard,
                                value: '',
                                onTap: () => context.go('/dashboard'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.inventory_2_rounded,
                                iconBg: AppColors.softOrange,
                                iconColor: AppColors.primary,
                                label: s.stock,
                                value: '',
                                onTap: () => context.go('/my-products'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.receipt_long_rounded,
                                iconBg: AppColors.softBlue,
                                iconColor: const Color(0xFF2563EB),
                                label: s.orders,
                                value: '',
                                onTap: () => context.go('/orders'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.swap_horiz_rounded,
                                iconBg: AppColors.softPurple,
                                iconColor: const Color(0xFF7C3AED),
                                label: s.register,
                                value: '',
                                onTap: () => context.push('/transactions'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.fact_check_rounded,
                                iconBg: AppColors.softOrange,
                                iconColor: AppColors.primary,
                                label: s.audit,
                                value: '',
                                onTap: () => context.go('/audit'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.compare_arrows_rounded,
                                iconBg: AppColors.softGreen,
                                iconColor: AppColors.successText,
                                label: s.variance,
                                value: '',
                                onTap: () => context.push('/variance'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.call_received_rounded,
                                iconBg: AppColors.softBlue,
                                iconColor: const Color(0xFF0284C7),
                                label: s.incomingDelivery,
                                value: '',
                                onTap: () => context.push('/dc?tab=incoming'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.call_made_rounded,
                                iconBg: AppColors.softGreen,
                                iconColor: const Color(0xFF15803D),
                                label: s.outgoingDelivery,
                                value: '',
                                onTap: () => context.push('/dc?tab=outgoing'),
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                icon: Icons.assessment_outlined,
                                iconBg: AppColors.softPurple,
                                iconColor: const Color(0xFF7C3AED),
                                label: s.report,
                                value: '',
                                onTap: () => context.push('/report'),
                              ),
                              if (isSuperAdmin) ...[
                                const _RowDivider(),
                                _InfoRow(
                                  icon: Icons.store_mall_directory_rounded,
                                  iconBg: AppColors.softOrange,
                                  iconColor: AppColors.primary,
                                  label: s.changeWarehouse,
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
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed:
                        state.isLoggingOut ? null : _openLogoutSheet,
                    icon: state.isLoggingOut
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.cardBg,
                            ),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
                    label: Text(s.logout),
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
    required this.strings,
    required this.onBack,
    required this.onNotifications,
  });

  final AppStrings strings;
  final VoidCallback onBack;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerBg,
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
            tooltip: strings.back,
            onTap: onBack,
          ),
          Expanded(
            child: Text(
              strings.profile,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.isDark
                    ? AppColors.textPrimary
                    : Colors.white,
              ),
            ),
          ),
          ModuleHeaderAction(
            icon: Icons.notifications_none_rounded,
            tooltip: strings.notifications,
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.strings,
    required this.name,
    required this.phone,
    required this.retailerId,
    required this.address,
    required this.totalOrders,
    required this.delivered,
    required this.pending,
    required this.cancelled,
  });

  final AppStrings strings;
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
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
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
                              color: AppColors.fieldBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              retailerId,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
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
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
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
                            color: AppColors.textMuted,
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
                                color: AppColors.textSecondary,
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
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              _HeroStat(
                value: totalOrders,
                label: strings.total,
                color: AppColors.textPrimary,
              ),
              _vDiv(),
              _HeroStat(
                value: delivered,
                label: strings.delivered,
                color: AppColors.successText,
              ),
              _vDiv(),
              _HeroStat(
                value: pending,
                label: strings.pending,
                color: AppColors.warning,
              ),
              _vDiv(),
              _HeroStat(
                value: cancelled,
                label: strings.cancelled,
                color: AppColors.errorText,
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
        color: AppColors.border,
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
            label,
            style: TextStyle(
              fontSize: ModuleTokens.tileMetricLabelFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.strings,
    required this.mode,
    required this.onChanged,
  });

  final AppStrings strings;
  final AppThemeMode mode;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.theme,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ThemeChip(
                  label: strings.themeDefault,
                  icon: Icons.wb_sunny_outlined,
                  selected: mode == AppThemeMode.light,
                  onTap: () => onChanged(AppThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeChip(
                  label: strings.themeDark,
                  icon: Icons.dark_mode_outlined,
                  selected: mode == AppThemeMode.dark,
                  onTap: () => onChanged(AppThemeMode.dark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.strings,
    required this.language,
    required this.onChanged,
  });

  final AppStrings strings;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.language,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ThemeChip(
                  label: strings.languageEnglish,
                  icon: Icons.language_rounded,
                  selected: language == AppLanguage.en,
                  onTap: () => onChanged(AppLanguage.en),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeChip(
                  label: strings.languageHindi,
                  leadingText: 'अ',
                  selected: language == AppLanguage.hi,
                  onTap: () => onChanged(AppLanguage.hi),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leadingText,
  }) : assert(icon != null || leadingText != null);

  final String label;
  final IconData? icon;
  final String? leadingText;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppColors.primary : AppColors.textMuted;
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.fieldBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingText != null)
                Text(
                  leadingText!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: accent,
                  ),
                )
              else
                Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
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
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
      child: Divider(height: 1, color: AppColors.border),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      ],
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            SizedBox(height: 10),
            Text(
              strings.logoutQuestion,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              strings.logoutConfirm,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                        backgroundColor: AppColors.fieldBg,
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        strings.cancel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                      child: Text(
                        strings.logout,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
