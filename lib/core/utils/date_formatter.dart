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

  /// Odoo datetime like `2026-09-21 07:33:26` (treated as IST wall clock).
  static String formatOdooDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final normalized = raw.trim().contains('T')
        ? raw.trim()
        : raw.trim().replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return raw.trim();
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
  }
}
