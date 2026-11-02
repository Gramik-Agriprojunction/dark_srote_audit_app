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
import '../../stock_audit/data/models/lmd_attendance_model.dart';
import '../../stock_audit/data/stock_audit_repository.dart';
import 'preview_theme.dart';

/// LMD Attendance — dynamic from `/lmd-attendance` (LMD Chase rules, app columns only).
class LmdAttendancePreviewScreen extends ConsumerStatefulWidget {
  const LmdAttendancePreviewScreen({super.key});

  @override
  ConsumerState<LmdAttendancePreviewScreen> createState() =>
      _LmdAttendancePreviewScreenState();
}

class _LmdAttendancePreviewScreenState
    extends ConsumerState<LmdAttendancePreviewScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int? _storeId;
  int? _employeeId;
  List<LmdAttendanceEmployee> _employees = const [];
  List<LmdAttendanceDay> _days = const [];
  bool _loading = true;
  String? _error;

  String get _monthLabel => DateFormat('MMM yyyy').format(_month);
  String get _monthApi => DateFormat('yyyy-MM').format(_month);

  String get _employeeLabel {
    if (_employees.isEmpty) return 'Select Employee';
    final match = _employees.where((e) => e.id == _employeeId);
    if (match.isNotEmpty) return match.first.label;
    return _employees.first.label;
  }

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
        _employees = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await ref.read(stockAuditRepositoryProvider).getLmdAttendance(
            businessLocationId: storeId,
            month: _monthApi,
            employeeUserId: _employeeId,
          );
      if (!mounted) return;
      setState(() {
        _employees = report.employees;
        _employeeId = report.selectedEmployeeId;
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

  Future<void> _pickEmployee() async {
    if (_employees.isEmpty) return;
    HapticFeedback.selectionClick();
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: PreviewTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PreviewTheme.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select Employee',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: PreviewTheme.text,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _employees.length,
                    itemBuilder: (_, i) {
                      final emp = _employees[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.person_outline_rounded,
                          color: PreviewTheme.orange,
                        ),
                        title: Text(
                          emp.label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: PreviewTheme.text,
                          ),
                        ),
                        trailing: emp.id == _employeeId
                            ? Icon(
                                Icons.check_rounded,
                                color: PreviewTheme.orange,
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, emp.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null || selected == _employeeId) return;
    setState(() => _employeeId = selected);
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appThemeModeProvider);
    final store = ref.watch(headerGreetingProvider);

    return Scaffold(
      backgroundColor: PreviewTheme.bg,
      body: Column(
        children: [
          ModuleHeader(
            pageLabel: 'LMD Attendance',
            subtitle: store.isEmpty ? 'Field Attendance System' : store,
            onBack: () => context.pop(),
            showNotifications: false,
            bottom: Column(
              children: [
                PreviewSelectField(
                  icon: Icons.person_outline_rounded,
                  label: _employeeLabel,
                  onHeader: true,
                  onTap: _employees.isEmpty ? null : _pickEmployee,
                ),
                const SizedBox(height: 8),
                PreviewSelectField(
                  icon: Icons.calendar_month_rounded,
                  label: _monthLabel,
                  onHeader: true,
                  onTap: _pickMonth,
                ),
              ],
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
                        _employees.isEmpty
                            ? 'Is dark store ke liye koi LMD partner nahi mila'
                            : 'Is month me koi attendance day nahi mila',
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
                      _LmdDayCard(day: _days[i]),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LmdDayCard extends StatelessWidget {
  const _LmdDayCard({required this.day});

  final LmdAttendanceDay day;

  (String, Color, Color) get _badge {
    switch (day.status) {
      case LmdAttendanceStatus.present:
        return ('Present', PreviewTheme.green, PreviewTheme.greenSoft);
      case LmdAttendanceStatus.weeklyOff:
        return ('Weekly Off', PreviewTheme.blue, PreviewTheme.blueSoft);
      case LmdAttendanceStatus.absent:
        return ('Absent', PreviewTheme.red, PreviewTheme.redSoft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final accent = badge.$2;
    final showTimes = day.firstActivity != null &&
        day.lastActivity != null &&
        day.workingHours != null;

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
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (showTimes)
                        Row(
                          children: [
                            _MetaChip(
                              Icons.login_rounded,
                              day.firstActivity!,
                            ),
                            const SizedBox(width: 6),
                            _MetaChip(
                              Icons.logout_rounded,
                              day.lastActivity!,
                            ),
                            const SizedBox(width: 6),
                            _MetaChip(
                              Icons.timer_outlined,
                              day.workingHours!,
                            ),
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
                            label: 'Picked Up',
                            value: '${day.picked}',
                            fg: PreviewTheme.green,
                            bg: PreviewTheme.greenSoft,
                          ),
                          const SizedBox(width: 6),
                          _MiniKpi(
                            label: 'In Transit',
                            value: '${day.transit}',
                            fg: PreviewTheme.blue,
                            bg: PreviewTheme.blueSoft,
                          ),
                          const SizedBox(width: 6),
                          _MiniKpi(
                            label: 'Delivered',
                            value: '${day.delivered}',
                            fg: PreviewTheme.orange,
                            bg: PreviewTheme.orangeSoft,
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

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.value);

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
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
