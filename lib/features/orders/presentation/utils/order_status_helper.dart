import 'package:flutter/material.dart';

class OrderStatusInfo {
  const OrderStatusInfo({
    required this.label,
    required this.tone,
    required this.color,
  });

  final String label;
  final String tone;
  final Color color;
}

OrderStatusInfo mapOrderStatus(String? raw) {
  final s = (raw ?? '').toUpperCase();

  if (s == 'PENDING') {
    return const OrderStatusInfo(
      label: 'Pending',
      tone: 'warn',
      color: Color(0xFFD97706),
    );
  }
  if (s == 'DELIVERED') {
    return const OrderStatusInfo(
      label: 'Delivered',
      tone: 'ok',
      color: Color(0xFF059669),
    );
  }
  if (s == 'CANCELLED') {
    return const OrderStatusInfo(
      label: 'Cancelled',
      tone: 'cancelled',
      color: Color(0xFFE11D48),
    );
  }
  if (s == 'RTO') {
    return const OrderStatusInfo(
      label: 'RTO',
      tone: 'rto',
      color: Color(0xFFDC2626),
    );
  }
  if (s == 'RESCHEDULE') {
    return const OrderStatusInfo(
      label: 'Rescheduled',
      tone: 'reschedule',
      color: Color(0xFF0D9488),
    );
  }
  if (s == 'PICKUP') {
    return const OrderStatusInfo(
      label: 'Picked Up',
      tone: 'pickup',
      color: Color(0xFF7C3AED),
    );
  }
  if (s == 'DISPUTED') {
    return const OrderStatusInfo(
      label: 'Disputed',
      tone: 'disputed',
      color: Color(0xFFF87171),
    );
  }

  final label = s.isEmpty
      ? 'Pending'
      : s
          .split(' ')
          .map(
            (w) => w.isEmpty
                ? w
                : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
          )
          .join(' ');

  return OrderStatusInfo(label: label, tone: 'warn', color: const Color(0xFFD97706));
}

Color tabToneBg(String tabId) {
  switch (tabId) {
    case 'pending':
      return const Color(0xFFF59E0B);
    case 'pickup':
      return const Color(0xFF8B5CF6);
    case 'reschedule':
      return const Color(0xFF14B8A6);
    case 'cancelled':
      return const Color(0xFFF25146);
    case 'delivered':
      return const Color(0xFF059669);
    case 'rto':
      return const Color(0xFFEF4444);
    case 'disputed':
      return const Color(0xFFF87171);
    default:
      return const Color(0xFFEC5800);
  }
}

IconData tabIcon(String tabId) {
  switch (tabId) {
    case 'pending':
      return Icons.schedule_rounded;
    case 'pickup':
      return Icons.shopping_bag_outlined;
    case 'reschedule':
      return Icons.event_rounded;
    case 'cancelled':
      return Icons.cancel_outlined;
    case 'delivered':
      return Icons.check_circle_outline_rounded;
    case 'rto':
      return Icons.keyboard_return_rounded;
    case 'disputed':
      return Icons.error_outline_rounded;
    default:
      return Icons.apps_rounded;
  }
}

String formatOrderDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final parsed = DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
  if (parsed == null) return trimmed;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final ampm = parsed.hour >= 12 ? 'pm' : 'am';
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}, $h:$minute $ampm';
}

String formatMoney(num value) {
  final n = value.round();
  final s = n.abs().toString();
  if (s.length <= 3) return '₹${n < 0 ? '-' : ''}$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${n < 0 ? '-' : ''}${parts.join(',')},$last3';
}

String paymentLabel(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  if (s == 'cod' || s == 'cash_on_delivery') return 'COD';
  if (s == 'upi') return 'UPI';
  if (s.isEmpty) return 'COD';
  return s.toUpperCase();
}

String paymentStatusPill(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  if (s == 'paid' || s == 'success' || s == 'completed') return 'Paid';
  if (s.isEmpty) return 'Unpaid';
  return s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

bool isPaidStatus(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  return s == 'paid' || s == 'success' || s == 'completed';
}
