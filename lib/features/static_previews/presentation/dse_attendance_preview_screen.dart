import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_date_pickers.dart';
import '../../../core/widgets/module_ui.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../stock_audit/data/models/dse_attendance_model.dart';
import '../../stock_audit/data/stock_audit_repository.dart';
import 'dse_attendance_detail_screen.dart';
import 'preview_theme.dart';

/// DSE Attendance — logged-in darkstore list from `/dse-attendance` API.
class DseAttendancePreviewScreen extends ConsumerStatefulWidget {
  const DseAttendancePreviewScreen({super.key});

  @override
  ConsumerState<DseAttendancePreviewScreen> createState() =>
      _DseAttendancePreviewScreenState();
}

class _DseAttendancePreviewScreenState
    extends ConsumerState<DseAttendancePreviewScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int? _storeId;
  List<DseAttendanceDay> _days = const [];
  bool _loading = true;
  String? _error;

  String get _monthLabel => DateFormat('MMM yyyy').format(_month);
  String get _monthApi => DateFormat('yyyy-MM').format(_month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final storage = ref.read(sessionStorageProvider);
    final preferred = await storage.getSelectedStoreId();
    final repo = ref.read(stockAuditRepositoryProvider);
    try {
      final locations = await repo.getBusinessLocations();
      int? storeId = preferred;
      if (storeId == null || !locations.any((l) => l.id == storeId)) {
        storeId = locations.length == 1 ? locations.first.id : preferred;
      }
      if (storeId == null && locations.isNotEmpty) {
        storeId = locations.first.id;
      }
      if (!mounted) return;
      setState(() => _storeId = storeId);
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  Future<void> _fetch() async {
    final storeId = _storeId;
    if (storeId == null || storeId <= 0) {
      setState(() {
        _loading = false;
        _error = 'Store select nahi hai. Pehle Stock tab se store choose karo.';
        _days = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // No employee dropdown — API uses logged-in viewer for this darkstore.
      final report = await ref.read(stockAuditRepositoryProvider).getDseAttendance(
            businessLocationId: storeId,
            month: _monthApi,
          );
      if (!mounted) return;
      setState(() {
        _days = report.days;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        _days = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _days = [];
      });
    }
  }

  Future<void> _pickMonth() async {
    HapticFeedback.selectionClick();
    final picked = await AppDatePickers.pickDate(
      context,
      initialDate: _month,
      helpText: 'Select month',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (!mounted || picked == null) return;
    setState(() => _month = DateTime(picked.year, picked.month, 1));
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeModeProvider);

    return Scaffold(
      backgroundColor: PreviewTheme.bg,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'DSE Attendance',
            subtitle: () {
              final store = ref.watch(headerGreetingProvider);
              return store.isEmpty ? null : store;
            }(),
            onBack: () => context.pop(),
            showNotifications: false,
            bottom: PreviewSelectField(
              icon: Icons.calendar_month_rounded,
              label: _monthLabel,
              onHeader: true,
              onTap: _pickMonth,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: PreviewTheme.orange,
              onRefresh: _fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PreviewTheme.red,
                        ),
                      ),
                    )
                  else if (_days.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'Is month me koi attendance day nahi mila',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PreviewTheme.textMuted,
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'Daily attendance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: PreviewTheme.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < _days.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _DayCard(
                        day: DseAttendanceDetailDay.fromDse(_days[i]),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final userName =
                              (ref.read(authControllerProvider).user?.name ??
                                      '')
                                  .trim();
                          context.push(
                            '/preview/dse-attendance/detail',
                            extra: {
                              'employee':
                                  userName.isEmpty ? 'DSE' : userName,
                              'month': _monthLabel,
                              'day': DseAttendanceDetailDay.fromDse(_days[i]),
                            },
                          );
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  const _RulesCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, this.onTap});

  final DseAttendanceDetailDay day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = day.badge;
    final showTimes =
        day.first != null && day.last != null && day.hours != null;
    final accent = badge.$2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PreviewTheme.surface,
                Color.lerp(PreviewTheme.surface, badge.$3, 0.55) ??
                    PreviewTheme.surface,
              ],
            ),
            border: Border.all(color: PreviewTheme.border),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: AppColors.isDark ? 0.16 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              ...PreviewTheme.cardShadow,
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  day.title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: PreviewTheme.text,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: badge.$3,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  badge.$1,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: badge.$2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: PreviewTheme.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (showTimes)
                            Row(
                              children: [
                                _metaChip(Icons.login_rounded, day.first!),
                                const SizedBox(width: 6),
                                _metaChip(Icons.logout_rounded, day.last!),
                                const SizedBox(width: 6),
                                _metaChip(Icons.timer_outlined, day.hours!),
                              ],
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: badge.$3,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Text(
                                day.note ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: badge.$2,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _MiniKpi(
                                label: 'SKU Audited',
                                value: '${day.audited}',
                                fg: PreviewTheme.blue,
                                bg: PreviewTheme.blueSoft,
                              ),
                              const SizedBox(width: 6),
                              _MiniKpi(
                                label: 'SKU Pending',
                                value: '${day.pending}',
                                fg: PreviewTheme.orange,
                                bg: PreviewTheme.orangeSoft,
                              ),
                              const SizedBox(width: 6),
                              _MiniKpi(
                                label: 'Match',
                                value: '${day.matchPct}%',
                                fg: PreviewTheme.green,
                                bg: PreviewTheme.greenSoft,
                              ),
                              const SizedBox(width: 6),
                              _MiniKpi(
                                label: 'Short',
                                value: '${day.shortQty}',
                                fg: PreviewTheme.rose,
                                bg: PreviewTheme.roseSoft,
                              ),
                              const SizedBox(width: 6),
                              _MiniKpi(
                                label: 'Excess',
                                value: '${day.excess}',
                                fg: PreviewTheme.teal,
                                bg: PreviewTheme.tealSoft,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: PreviewTheme.field,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PreviewTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: PreviewTheme.textMuted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: PreviewTheme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.label,
    required this.value,
    required this.fg,
    required this.bg,
  });

  final String label;
  final String value;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 9, 4, 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: fg.withValues(alpha: 0.9),
                ),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    height: 1.1,
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

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    final rules = <(String, Color, Color, String)>[
      (
        'Present',
        PreviewTheme.green,
        PreviewTheme.greenSoft,
        'SKU Pending = 0, Match = 100%, Short = 0, Excess = 0',
      ),
      (
        'Half Day',
        PreviewTheme.orange,
        PreviewTheme.orangeSoft,
        'SKU Pending = 0, Short > 0 or Excess > 0',
      ),
      (
        'Absent',
        PreviewTheme.red,
        PreviewTheme.redSoft,
        'SKU Pending > 0 and (Short > 0 or Excess > 0)',
      ),
      (
        'Holiday',
        PreviewTheme.blue,
        PreviewTheme.blueSoft,
        'Company defined holiday / weekly off day',
      ),
      (
        'WOP',
        AppColors.isDark ? const Color(0xFFB794F6) : const Color(0xFF7C3AED),
        AppColors.isDark ? const Color(0xFF2E2145) : const Color(0xFFF3E8FF),
        'Work Off Permission (Approved leave)',
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.isDark
              ? const [Color(0xFF2A2438), Color(0xFF1C1828)]
              : const [Color(0xFFF8F5FF), Color(0xFFF3E8FF)],
        ),
        border: Border.all(
          color: AppColors.isDark
              ? const Color(0xFF3D3554)
              : const Color(0xFFE9E5FF),
        ),
        boxShadow: PreviewTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.isDark
                      ? const Color(0xFF3D3554)
                      : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.isDark
                      ? const Color(0xFFB794F6)
                      : const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Attendance Status Rules',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.isDark
                      ? const Color(0xFFE9D5FF)
                      : const Color(0xFF5B21B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rules.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              decoration: BoxDecoration(
                color: PreviewTheme.surface.withValues(
                  alpha: AppColors.isDark ? 0.45 : 0.72,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PreviewTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rules[i].$3,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      rules[i].$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rules[i].$2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rules[i].$4,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: PreviewTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
