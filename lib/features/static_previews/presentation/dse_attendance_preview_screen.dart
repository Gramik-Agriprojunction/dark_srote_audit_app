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
import '../../stock_audit/data/models/dse_attendance_model.dart';
import '../../stock_audit/data/stock_audit_repository.dart';
import 'dse_attendance_detail_screen.dart';
import 'preview_theme.dart';
import 'widgets/dse_attendance_rules_panel.dart';

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

  Map<String, int> get _statusCounts {
    var present = 0;
    var half = 0;
    var holiday = 0;
    var wop = 0;
    for (final day in _days) {
      switch (day.status) {
        case DseAttendanceStatus.present:
          present++;
        case DseAttendanceStatus.halfDay:
          half++;
        case DseAttendanceStatus.holiday:
          holiday++;
        case DseAttendanceStatus.wop:
          wop++;
        case DseAttendanceStatus.absent:
          break;
      }
    }
    return {
      'present': present,
      'half': half,
      'holiday': holiday,
      'wop': wop,
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeModeProvider);
    final counts = _statusCounts;

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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 56),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load',
                      message: _error!,
                      accent: PreviewTheme.red,
                    )
                  else if (_days.isEmpty)
                    _EmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'No days yet',
                      message: 'Is month me koi attendance day nahi mila',
                      accent: PreviewTheme.textMuted,
                    )
                  else ...[
                    _StatusSummaryGrid(
                      present: counts['present']!,
                      half: counts['half']!,
                      holiday: counts['holiday']!,
                      wop: counts['wop']!,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Daily Attendance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: PreviewTheme.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _days.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _FadeIn(
                        delayMs: (40 * i).clamp(0, 280),
                        child: _DayCard(
                          day: DseAttendanceDetailDay.fromDse(_days[i]),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  const DseAttendanceRulesPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _StatusSummaryGrid extends StatelessWidget {
  const _StatusSummaryGrid({
    required this.present,
    required this.half,
    required this.holiday,
    required this.wop,
  });

  final int present;
  final int half;
  final int holiday;
  final int wop;

  Color get _wopFg =>
      AppColors.isDark ? const Color(0xFFB794F6) : const Color(0xFF7C3AED);
  Color get _wopBg =>
      AppColors.isDark ? const Color(0xFF2E2145) : const Color(0xFFF3E8FF);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.check_circle_rounded,
                label: 'Present',
                value: '$present',
                fg: PreviewTheme.green,
                bg: PreviewTheme.greenSoft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                icon: Icons.timelapse_rounded,
                label: 'Half Day Absent',
                value: '$half',
                fg: PreviewTheme.orange,
                bg: PreviewTheme.orangeSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.beach_access_rounded,
                label: 'Holiday',
                value: '$holiday',
                fg: PreviewTheme.blue,
                bg: PreviewTheme.blueSoft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                icon: Icons.work_outline_rounded,
                label: 'WOP',
                value: '$wop',
                fg: _wopFg,
                bg: _wopBg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.fg,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: fg.withValues(alpha: AppColors.isDark ? 0.14 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          ...PreviewTheme.cardShadow,
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: fg.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: PreviewTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.5,
                    color: fg,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PreviewTheme.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: PreviewTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final DseAttendanceDetailDay day;

  @override
  Widget build(BuildContext context) {
    final badge = day.badge;
    final accent = badge.$2;

    return Container(
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: badge.$3,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Text(
                                day.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                        ],
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
