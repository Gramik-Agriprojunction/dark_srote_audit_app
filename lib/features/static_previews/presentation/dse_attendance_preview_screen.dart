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
    var absent = 0;
    var other = 0;
    for (final raw in _days) {
      final label = DseAttendanceDetailDay.fromDse(raw).badge.$1.toLowerCase();
      if (label.contains('present')) {
        present++;
      } else if (label.contains('half')) {
        half++;
      } else if (label.contains('absent')) {
        absent++;
      } else {
        other++;
      }
    }
    return {
      'present': present,
      'half': half,
      'absent': absent,
      'other': other,
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
                    _MonthPulse(
                      monthLabel: _monthLabel,
                      present: counts['present']!,
                      half: counts['half']!,
                      absent: counts['absent']!,
                      other: counts['other']!,
                      total: _days.length,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          'Daily log',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: PreviewTheme.text,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_days.length} days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PreviewTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _days.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
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

class _MonthPulse extends StatelessWidget {
  const _MonthPulse({
    required this.monthLabel,
    required this.present,
    required this.half,
    required this.absent,
    required this.other,
    required this.total,
  });

  final String monthLabel;
  final int present;
  final int half;
  final int absent;
  final int other;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.isDark
              ? [
                  Color.lerp(PreviewTheme.surface, PreviewTheme.orange, 0.12)!,
                  PreviewTheme.surface,
                ]
              : [
                  Color.lerp(Colors.white, PreviewTheme.orange, 0.08)!,
                  PreviewTheme.surface,
                ],
        ),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: PreviewTheme.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PreviewTheme.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PreviewTheme.orange.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: PreviewTheme.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: PreviewTheme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total logged days this month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PreviewTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PulseStat(
                label: 'Present',
                value: '$present',
                color: PreviewTheme.green,
                soft: PreviewTheme.greenSoft,
              ),
              const SizedBox(width: 8),
              _PulseStat(
                label: 'Half',
                value: '$half',
                color: PreviewTheme.orange,
                soft: PreviewTheme.orangeSoft,
              ),
              const SizedBox(width: 8),
              _PulseStat(
                label: 'Absent',
                value: '$absent',
                color: PreviewTheme.red,
                soft: PreviewTheme.redSoft,
              ),
              if (other > 0) ...[
                const SizedBox(width: 8),
                _PulseStat(
                  label: 'Other',
                  value: '$other',
                  color: PreviewTheme.blue,
                  soft: PreviewTheme.blueSoft,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseStat extends StatelessWidget {
  const _PulseStat({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
  });

  final String label;
  final String value;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -0.5,
                color: color,
              ),
            ),
          ],
        ),
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
    final showTimes =
        day.first != null && day.last != null && day.hours != null;
    final accent = badge.$2;
    final dateParts = _splitTitle(day.title);

    return Container(
      decoration: BoxDecoration(
        color: PreviewTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PreviewTheme.border),
        boxShadow: PreviewTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: AppColors.isDark ? 0.28 : 0.16),
                      accent.withValues(alpha: AppColors.isDark ? 0.10 : 0.06),
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dateParts.$1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateParts.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -0.6,
                        color: PreviewTheme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateParts.$3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: PreviewTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, color: PreviewTheme.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              day.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: PreviewTheme.text,
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
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: badge.$2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (showTimes)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: PreviewTheme.field,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: PreviewTheme.border),
                          ),
                          child: Row(
                            children: [
                              _TimeBit(
                                icon: Icons.login_rounded,
                                value: day.first!,
                              ),
                              _TimeDivider(),
                              _TimeBit(
                                icon: Icons.logout_rounded,
                                value: day.last!,
                              ),
                              _TimeDivider(),
                              _TimeBit(
                                icon: Icons.timer_outlined,
                                value: day.hours!,
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: badge.$3,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            day.note ?? '',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: badge.$2,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetricPill(
                            label: 'Audited',
                            value: '${day.audited}',
                            color: PreviewTheme.blue,
                            soft: PreviewTheme.blueSoft,
                          ),
                          _MetricPill(
                            label: 'Pending',
                            value: '${day.pending}',
                            color: PreviewTheme.orange,
                            soft: PreviewTheme.orangeSoft,
                          ),
                          _MetricPill(
                            label: 'Match',
                            value: '${day.matchPct}%',
                            color: PreviewTheme.green,
                            soft: PreviewTheme.greenSoft,
                          ),
                          _MetricPill(
                            label: 'Short',
                            value: '${day.shortQty}',
                            color: PreviewTheme.rose,
                            soft: PreviewTheme.roseSoft,
                          ),
                          _MetricPill(
                            label: 'Excess',
                            value: '${day.excess}',
                            color: PreviewTheme.teal,
                            soft: PreviewTheme.tealSoft,
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

  /// "Sunday, 1 Nov 2026" → (Sun, 1, Nov)
  (String, String, String) _splitTitle(String title) {
    try {
      final cleaned = title.replaceAll(',', '');
      final parts = cleaned.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final weekday = parts[0].length >= 3
            ? parts[0].substring(0, 3).toUpperCase()
            : parts[0].toUpperCase();
        final dayNum = parts[1];
        final month = parts[2].length >= 3
            ? parts[2].substring(0, 3)
            : parts[2];
        return (weekday, dayNum, month);
      }
    } catch (_) {}
    return ('DAY', '—', '');
  }
}

class _TimeBit extends StatelessWidget {
  const _TimeBit({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: PreviewTheme.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: PreviewTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: PreviewTheme.border,
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
  });

  final String label;
  final String value;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
