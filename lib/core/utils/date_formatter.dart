import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String istDateKey(DateTime date) {
    final ist = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('yyyy-MM-dd').format(ist);
  }

  static bool isAuditUpdatedToday(DateTime? updatedAt) {
    if (updatedAt == null) return false;
    return istDateKey(updatedAt.toUtc()) == istDateKey(DateTime.now());
  }

  static String formatAuditUpdatedAt(DateTime? iso) {
    if (iso == null) return '';
    final ist = iso.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd MMM, hh:mm a').format(ist);
  }

  static String formatAuditDetailUpdatedAt(DateTime? iso) {
    if (iso == null) return '—';
    final ist = iso.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd MMM, yyyy, hh:mm a').format(ist);
  }
}
