import '../../../../core/utils/json_parse.dart';

class LmdAttendanceEmployee {
  const LmdAttendanceEmployee({
    required this.id,
    required this.label,
    this.name,
    this.empCode,
    this.district,
  });

  final int id;
  final String label;
  final String? name;
  final String? empCode;
  final String? district;

  factory LmdAttendanceEmployee.fromJson(Map<String, dynamic> json) {
    return LmdAttendanceEmployee(
      id: jsonInt(json['id']),
      label: (json['label'] ?? json['name'] ?? 'LMD').toString(),
      name: json['name']?.toString(),
      empCode: (json['empCode'] ?? json['emp_code'])?.toString(),
      district: json['district']?.toString(),
    );
  }
}

enum LmdAttendanceStatus { present, absent, weeklyOff }

LmdAttendanceStatus lmdStatusFromApi(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'present':
      return LmdAttendanceStatus.present;
    case 'weekly_off':
    case 'weeklyoff':
    case 'weekly-off':
      return LmdAttendanceStatus.weeklyOff;
    case 'absent':
    default:
      return LmdAttendanceStatus.absent;
  }
}

class LmdAttendanceDay {
  const LmdAttendanceDay({
    required this.date,
    required this.title,
    required this.status,
    this.firstActivity,
    this.lastActivity,
    this.workingHours,
    this.note,
    this.picked = 0,
    this.transit = 0,
    this.delivered = 0,
  });

  final String date;
  final String title;
  final LmdAttendanceStatus status;
  final String? firstActivity;
  final String? lastActivity;
  final String? workingHours;
  final String? note;
  final int picked;
  final int transit;
  final int delivered;

  factory LmdAttendanceDay.fromJson(Map<String, dynamic> json) {
    return LmdAttendanceDay(
      date: (json['date'] ?? '').toString(),
      title: (json['title'] ?? json['date'] ?? 'Day').toString(),
      status: lmdStatusFromApi(json['status']?.toString()),
      firstActivity:
          (json['firstActivity'] ?? json['first_activity'])?.toString(),
      lastActivity:
          (json['lastActivity'] ?? json['last_activity'])?.toString(),
      workingHours:
          (json['workingHours'] ?? json['working_hours'])?.toString(),
      note: json['note']?.toString(),
      picked: jsonInt(json['picked']),
      transit: jsonInt(json['transit']),
      delivered: jsonInt(json['delivered']),
    );
  }
}

class LmdAttendanceReport {
  const LmdAttendanceReport({
    required this.businessLocationId,
    required this.month,
    required this.selectedEmployeeId,
    required this.employees,
    required this.days,
  });

  final int businessLocationId;
  final String month;
  final int? selectedEmployeeId;
  final List<LmdAttendanceEmployee> employees;
  final List<LmdAttendanceDay> days;

  factory LmdAttendanceReport.fromJson(Map<String, dynamic> json) {
    final employeesRaw = json['employees'];
    final daysRaw = json['days'];
    return LmdAttendanceReport(
      businessLocationId: jsonInt(
        json['businessLocationId'] ?? json['business_location_id'],
      ),
      month: (json['month'] ?? '').toString(),
      selectedEmployeeId: () {
        final v = json['selectedEmployeeId'] ?? json['selected_employee_id'];
        if (v == null) return null;
        final n = jsonInt(v);
        return n > 0 ? n : null;
      }(),
      employees: employeesRaw is List
          ? employeesRaw
              .whereType<Map>()
              .map(
                (e) => LmdAttendanceEmployee.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      days: daysRaw is List
          ? daysRaw
              .whereType<Map>()
              .map(
                (e) =>
                    LmdAttendanceDay.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
    );
  }
}
