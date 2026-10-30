import '../../../../core/utils/json_parse.dart';

class DseAttendanceEmployee {
  const DseAttendanceEmployee({
    required this.id,
    required this.label,
    this.name,
    this.empCode,
  });

  final int id;
  final String label;
  final String? name;
  final String? empCode;

  factory DseAttendanceEmployee.fromJson(Map<String, dynamic> json) {
    return DseAttendanceEmployee(
      id: jsonInt(json['id']),
      label: (json['label'] ?? json['name'] ?? 'Employee').toString(),
      name: json['name']?.toString(),
      empCode: (json['empCode'] ?? json['emp_code'])?.toString(),
    );
  }
}

enum DseAttendanceStatus { present, halfDay, absent, holiday, wop }

DseAttendanceStatus dseStatusFromApi(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'present':
      return DseAttendanceStatus.present;
    case 'half_day':
    case 'halfday':
    case 'half-day':
      return DseAttendanceStatus.halfDay;
    case 'holiday':
      return DseAttendanceStatus.holiday;
    case 'wop':
      return DseAttendanceStatus.wop;
    case 'absent':
    default:
      return DseAttendanceStatus.absent;
  }
}

class DseAttendanceDay {
  const DseAttendanceDay({
    required this.date,
    required this.title,
    required this.status,
    this.firstActivity,
    this.lastActivity,
    this.workingHours,
    this.note,
    required this.skuAudited,
    required this.skuPending,
    required this.matchPct,
    required this.shortQty,
    required this.excess,
    this.matched = 0,
    this.picked = 0,
    this.transit = 0,
    this.delivered = 0,
  });

  final String date;
  final String title;
  final DseAttendanceStatus status;
  final String? firstActivity;
  final String? lastActivity;
  final String? workingHours;
  final String? note;
  final int skuAudited;
  final int skuPending;
  final int matchPct;
  final int shortQty;
  final int excess;
  final int matched;
  final int picked;
  final int transit;
  final int delivered;

  factory DseAttendanceDay.fromJson(Map<String, dynamic> json) {
    return DseAttendanceDay(
      date: (json['date'] ?? '').toString(),
      title: (json['title'] ?? json['date'] ?? 'Day').toString(),
      status: dseStatusFromApi(json['status']?.toString()),
      firstActivity:
          (json['firstActivity'] ?? json['first_activity'])?.toString(),
      lastActivity:
          (json['lastActivity'] ?? json['last_activity'])?.toString(),
      workingHours:
          (json['workingHours'] ?? json['working_hours'])?.toString(),
      note: json['note']?.toString(),
      skuAudited: jsonInt(json['skuAudited'] ?? json['sku_audited']),
      skuPending: jsonInt(json['skuPending'] ?? json['sku_pending']),
      matchPct: jsonInt(json['matchPct'] ?? json['match_pct']),
      shortQty: jsonInt(json['short'] ?? json['shortQty'] ?? json['short_qty']),
      excess: jsonInt(json['excess']),
      matched: jsonInt(json['matched']),
      picked: jsonInt(json['picked']),
      transit: jsonInt(json['transit']),
      delivered: jsonInt(json['delivered']),
    );
  }
}

class DseAttendanceReport {
  const DseAttendanceReport({
    required this.businessLocationId,
    required this.month,
    required this.selectedEmployeeId,
    required this.employees,
    required this.days,
    this.totalSku = 0,
  });

  final int businessLocationId;
  final String month;
  final int selectedEmployeeId;
  final List<DseAttendanceEmployee> employees;
  final List<DseAttendanceDay> days;
  final int totalSku;

  factory DseAttendanceReport.fromJson(Map<String, dynamic> json) {
    final employeesRaw = json['employees'];
    final daysRaw = json['days'];
    return DseAttendanceReport(
      businessLocationId: jsonInt(
        json['businessLocationId'] ?? json['business_location_id'],
      ),
      month: (json['month'] ?? '').toString(),
      selectedEmployeeId: jsonInt(
        json['selectedEmployeeId'] ?? json['selected_employee_id'],
      ),
      employees: employeesRaw is List
          ? employeesRaw
              .whereType<Map<String, dynamic>>()
              .map(DseAttendanceEmployee.fromJson)
              .toList()
          : const [],
      days: daysRaw is List
          ? daysRaw
              .whereType<Map<String, dynamic>>()
              .map(DseAttendanceDay.fromJson)
              .toList()
          : const [],
      totalSku: jsonInt(json['totalSku'] ?? json['total_sku']),
    );
  }
}
