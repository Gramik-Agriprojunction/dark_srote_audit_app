import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

import '../../data/models/order_model.dart';
import 'order_status_helper.dart';

Color get kDetailScreenBg => AppColors.background;
const kCustomerAccent = Color(0xFF3B82F6);
const kItemsAccent = Color(0xFFF59E0B);

Color statusTint(Color color, [double alpha = 0.12]) {
  return color.withValues(alpha: alpha);
}

Color statusLight(Color color) {
  final r = color.r * 255;
  final g = color.g * 255;
  final b = color.b * 255;
  int mix(double ch) => (ch + (255 - ch) * 0.32).round().clamp(0, 255);
  return Color.fromARGB(255, mix(r), mix(g), mix(b));
}

Color statusDark(Color color) {
  final r = color.r * 255;
  final g = color.g * 255;
  final b = color.b * 255;
  int darken(double ch) => (ch - 28).round().clamp(0, 255);
  return Color.fromARGB(255, darken(r), darken(g), darken(b));
}

String maskPhone(String? phone) {
  final s = (phone ?? '').trim();
  if (s.length >= 6) return '${s.substring(0, 2)}****${s.substring(s.length - 2)}';
  return s.isEmpty ? '--' : s;
}

String formatOrderDay(String? raw) {
  final r = (raw ?? '').trim();
  if (r.isEmpty) return '';
  final d = DateTime.tryParse(r.contains('T') ? r : '${r}T00:00:00');
  if (d == null) return r;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
}

String capitalizeWords(String? raw) {
  final t = (raw ?? '').replaceAll('_', ' ').trim();
  if (t.isEmpty) return '';
  return t
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

IconData statusIcon(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case 'PENDING':
      return Icons.schedule_rounded;
    case 'MANIFESTED':
      return Icons.layers_outlined;
    case 'DELIVERED':
      return Icons.check_circle_outline;
    case 'CANCELLED':
      return Icons.cancel_outlined;
    case 'RTO':
      return Icons.keyboard_return_rounded;
    case 'RESCHEDULE':
      return Icons.event_rounded;
    case 'PICKUP':
      return Icons.shopping_bag_outlined;
    case 'INTRANSIT':
      return Icons.pedal_bike_outlined;
    case 'DISPUTED':
      return Icons.error_outline_rounded;
    default:
      return Icons.circle_outlined;
  }
}

List<String> timelineSteps(OrderDetailModel order) {
  if (order.isCounterSale) {
    final cancelled = const {
      'CANCELLED',
      'RTO',
      'REJECTED',
      'PICKUPCANCELLED',
    }.contains(order.orderStatus.toUpperCase());
    return cancelled
        ? const ['Pending', 'Delivered', 'Cancelled']
        : const ['Pending', 'Delivered'];
  }
  return const ['Pending', 'Out', 'Delivered'];
}

int timelineStepIndex(OrderDetailModel order) {
  final k = order.orderStatus.toUpperCase();
  if (order.isCounterSale) {
    if (const {'CANCELLED', 'RTO', 'REJECTED', 'PICKUPCANCELLED'}.contains(k)) {
      return 2;
    }
    if (k == 'DELIVERED') return 1;
    return 0;
  }
  // Match Darkstore RN stepOf: MANIFESTED stays on Pending (0).
  if (k == 'DELIVERED' || k == 'RTO') return 2;
  if (const {'INTRANSIT', 'PICKUP'}.contains(k)) return 1;
  if (k == 'PICKUPCANCELLED') return 1;
  return 0;
}

int timelineFailedAt(OrderDetailModel order) {
  final k = order.orderStatus.toUpperCase();
  if (order.isCounterSale) {
    if (const {'CANCELLED', 'RTO', 'REJECTED', 'PICKUPCANCELLED'}.contains(k)) {
      return 2;
    }
    return -1;
  }
  if (k == 'RTO') return 2;
  if (k == 'PICKUPCANCELLED') return 1;
  if (const {'CANCELLED', 'REJECTED'}.contains(k)) return 0;
  return -1;
}

bool isCancelledStatus(String status) {
  return const {
    'CANCELLED',
    'RTO',
    'REJECTED',
    'PICKUPCANCELLED',
  }.contains(status.toUpperCase());
}

class OrderOtpEntry {
  const OrderOtpEntry({
    required this.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.compact = false,
  });

  final String key;
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool compact;
}

List<OrderOtpEntry> collectTopPickupOtps(OrderDetailModel order) {
  final list = <OrderOtpEntry>[];
  void add(String key, String label, String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return;
    list.add(
      OrderOtpEntry(
        key: key,
        label: label,
        value: v,
        color: const Color(0xFF7C3AED),
        icon: Icons.shopping_bag_outlined,
        compact: true,
      ),
    );
  }

  add('pickup_otp', 'Pickup OTP', order.pickupOtp);
  return list;
}

List<OrderOtpEntry> collectOrderOtps(OrderDetailModel order) {
  final list = <OrderOtpEntry>[];
  void add(String key, String label, String? value, Color color, IconData icon) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return;
    list.add(
      OrderOtpEntry(key: key, label: label, value: v, color: color, icon: icon),
    );
  }

  add('otp', 'Order OTP', order.otp, const Color(0xFFEC5800), Icons.key_outlined);
  add('deliver_otp', 'Delivery OTP', order.deliverOtp, const Color(0xFF2563EB), Icons.pedal_bike_outlined);
  add('return_otp', 'Return OTP', order.returnOtp, const Color(0xFFDC2626), Icons.keyboard_return_rounded);
  add('rto_return_otp', 'RTO Return OTP', order.rtoReturnOtp, const Color(0xFFDC2626), Icons.keyboard_return_rounded);

  final multi = order.multiplePickupOtp;
  if (multi is List) {
    for (var i = 0; i < multi.length; i++) {
      final v = '${multi[i]}'.trim();
      if (v.isEmpty) continue;
      list.add(
        OrderOtpEntry(
          key: 'multi_$i',
          label: 'Pickup OTP ${i + 1}',
          value: v,
          color: const Color(0xFF7C3AED),
          icon: Icons.layers_outlined,
        ),
      );
    }
  } else if (multi != null && '$multi'.trim().isNotEmpty) {
    add(
      'multiple_pickup_otp',
      'Multiple Pickup OTP',
      '$multi',
      const Color(0xFF7C3AED),
      Icons.layers_outlined,
    );
  }

  return list;
}

({Color bg, Color border, Color text}) markStatusStyle(String? markStatus) {
  if ((markStatus ?? '').toLowerCase() == 'disputed') {
    return (
      bg: const Color(0x24F87171),
      border: const Color(0x47F87171),
      text: const Color(0xFFDC2626),
    );
  }
  return (
    bg: AppColors.background,
    border: AppColors.border,
    text: AppColors.textSecondary,
  );
}

IconData stepIcon(String step) {
  switch (step) {
    case 'Pending':
      return Icons.hourglass_bottom_rounded;
    case 'Out':
      return Icons.pedal_bike_outlined;
    case 'Delivered':
      return Icons.done_all_rounded;
    case 'Cancelled':
      return Icons.close_rounded;
    default:
      return Icons.circle_outlined;
  }
}

OrderStatusInfo orderDetailStatus(OrderDetailModel order) =>
    mapOrderStatus(order.orderStatus);
