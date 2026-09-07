import 'dart:convert';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/order_model.dart';
import '../presentation/utils/order_detail_helpers.dart';
import '../presentation/utils/order_status_helper.dart';

const _paperChars = 32;
const _storageAddressKey = 'thermal_printer_address';
const _storageNameKey = 'thermal_printer_name';

enum PrinterErrorCode {
  moduleMissing,
  permissionDenied,
  connectFailed,
  noPrinter,
  printFailed,
}

class PrinterException implements Exception {
  PrinterException(this.code, [this.detail]);

  final PrinterErrorCode code;
  final String? detail;

  String get userMessage {
    switch (code) {
      case PrinterErrorCode.moduleMissing:
        return 'Receipt printing is not available on this device.';
      case PrinterErrorCode.permissionDenied:
        return 'Bluetooth permission is required. Enable it in Settings and try again.';
      case PrinterErrorCode.connectFailed:
        return 'Could not connect to the printer. Check that it is on and paired in Settings.';
      case PrinterErrorCode.noPrinter:
        return 'Select a Bluetooth printer to print the receipt.';
      case PrinterErrorCode.printFailed:
        return detail?.trim().isNotEmpty == true
            ? detail!.trim()
            : 'Could not print the receipt. Make sure the printer is on and in range, then try again.';
    }
  }

  bool get shouldOpenPicker =>
      code == PrinterErrorCode.noPrinter ||
      code == PrinterErrorCode.connectFailed ||
      code == PrinterErrorCode.permissionDenied ||
      code == PrinterErrorCode.moduleMissing;
}

class SavedPrinter {
  const SavedPrinter({required this.address, required this.name});

  final String address;
  final String name;
}

class ThermalPrinterService {
  ThermalPrinterService._();

  static Future<SavedPrinter?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_storageAddressKey)?.trim() ?? '';
    if (address.isEmpty) return null;
    final name = prefs.getString(_storageNameKey)?.trim();
    return SavedPrinter(address: address, name: name ?? address);
  }

  static Future<void> savePrinter({required String address, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageAddressKey, address);
    await prefs.setString(_storageNameKey, name);
  }

  static Future<bool> _ensurePermissions() async {
    try {
      return await PrintBluetoothThermal.isPermissionBluetoothGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BluetoothInfo>> scanPrinters() async {
    final granted = await _ensurePermissions();
    if (!granted) {
      throw PrinterException(PrinterErrorCode.permissionDenied);
    }

    try {
      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!enabled) {
        throw PrinterException(
          PrinterErrorCode.printFailed,
          'Turn on Bluetooth and try again.',
        );
      }
      final list = await PrintBluetoothThermal.pairedBluetooths;
      return list.where((d) => d.macAdress.trim().isNotEmpty).toList();
    } catch (e) {
      if (e is PrinterException) rethrow;
      throw PrinterException(PrinterErrorCode.moduleMissing);
    }
  }

  static Future<void> connectPrinter({
    required String address,
    String? name,
  }) async {
    final mac = address.trim();
    if (mac.isEmpty) {
      throw PrinterException(PrinterErrorCode.noPrinter);
    }

    final granted = await _ensurePermissions();
    if (!granted) {
      throw PrinterException(PrinterErrorCode.permissionDenied);
    }

    try {
      if (await PrintBluetoothThermal.connectionStatus) {
        await PrintBluetoothThermal.disconnect;
      }
      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (!ok) {
        throw PrinterException(PrinterErrorCode.connectFailed);
      }
      await savePrinter(address: mac, name: name?.trim() ?? mac);
    } catch (e) {
      if (e is PrinterException) rethrow;
      throw PrinterException(PrinterErrorCode.connectFailed);
    }
  }

  static Future<void> printOrderReceipt(
    OrderDetailModel order, {
    String? explicitAddress,
  }) async {
    final saved = await getSavedPrinter();
    final target = explicitAddress?.trim().isNotEmpty == true
        ? explicitAddress!.trim()
        : saved?.address;
    if (target == null || target.isEmpty) {
      throw PrinterException(PrinterErrorCode.noPrinter);
    }

    await connectPrinter(address: target, name: saved?.name);
    final receipt = _buildReceiptText(order);
    final bytes = <int>[
      ...utf8.encode(receipt),
      0x1D,
      0x56,
      0x00,
    ];

    try {
      final ok = await PrintBluetoothThermal.writeBytes(bytes);
      if (!ok) {
        throw PrinterException(PrinterErrorCode.printFailed);
      }
    } catch (e) {
      if (e is PrinterException) rethrow;
      throw PrinterException(PrinterErrorCode.printFailed);
    }
  }

  static String _buildReceiptText(OrderDetailModel order) {
    final code = order.code.isNotEmpty ? order.code : '${order.id}';
    final sh = order.shippingAddress;
    final cust = sh.displayName.isNotEmpty ? sh.displayName : '--';
    final phone = (sh.phone ?? '').trim();
    final deliveryAddr = sh.fullAddress;
    final prods = order.products;
    final sub = order.subtotal > 0
        ? order.subtotal
        : prods.fold<double>(
            0,
            (sum, p) => sum + (p.price ?? 0) * p.quantity,
          );
    final ship = order.shippingCost;
    final disc = order.discount;
    final tot = order.grandTotal > 0 ? order.grandTotal : sub + ship - disc;
    final itemCount = prods.fold<int>(0, (sum, p) => sum + p.quantity);

    final lines = <String>[
      ..._centerLines('Gramik (AGRIPROJUNCTION VENTURES PRIVATE LIMITED)'),
      _center('Receipt'),
      _dash(),
      _pairLine('Order No', code),
      _pairLine('Date', _fmtBillDate(order.createdAt)),
      _pairLine('Items', '$itemCount'),
      _dash(),
      _pairLine(
        'Customer',
        cust.length > 18 ? '${cust.substring(0, 15)}...' : cust,
      ),
    ];

    if (phone.isNotEmpty) {
      lines.add(_pairLine('Phone', maskPhone(phone)));
    }
    if (deliveryAddr.isNotEmpty) {
      lines.add('Address:');
      lines.addAll(_wrap(deliveryAddr));
    }

    lines
      ..add(_dash())
      ..add(_pairLine('Item', 'Amount'))
      ..add(_dash());

    for (final p in prods) {
      final name = p.name.trim().isNotEmpty ? p.name.trim() : 'Item';
      final qty = p.quantity;
      final unit = p.price ?? 0;
      final lineTotal = unit * qty;
      lines.addAll(_wrap(name));
      final qtyLine = qty > 1 ? '  $qty x ${_money(unit)}' : '  $qty pc';
      lines.add(_pairLine(qtyLine, _money(lineTotal)));

      if (p.isCombo) {
        for (final cp in p.comboProducts) {
          final cpName = cp.displayName.isNotEmpty ? cp.displayName : 'Item';
          final cpVar = cp.displayVariant;
          final unitQty = cp.quantity;
          final cpQty = unitQty * (qty == 0 ? 1 : qty);
          final cpPrice = cp.price;
          final cpLine = cpPrice == null ? null : cpPrice * unitQty * (qty == 0 ? 1 : qty);
          final label = cpVar.isNotEmpty ? '$cpName $cpVar' : cpName;
          lines.addAll(_wrap('  + $label${cpQty > 1 ? ' x$cpQty' : ''}'));
          if (cpLine != null) {
            final left = cpQty > 1 ? '    $cpQty x ${_money(cpPrice!)}' : '   ';
            lines.add(_pairLine(left, _money(cpLine)));
          }
        }
      }
    }

    lines.add(_dash());
    final showBreakup = disc > 0 || ship > 0;
    if (showBreakup) {
      lines.add(_pairLine('Subtotal', _money(sub)));
      if (disc > 0) lines.add(_pairLine('Discount', '-${_money(disc)}'));
      if (ship > 0) lines.add(_pairLine('Shipping', _money(ship)));
    }
    lines
      ..add(_pairLine('GRAND TOTAL', _money(tot)))
      ..add(_dash());

    return '${lines.where((l) => l.isNotEmpty).join('\n')}\n\n\n';
  }

  static String _money(num value) => 'Rs.${formatMoney(value).replaceFirst('₹', '')}';

  static String _fmtBillDate(String raw) {
    final formatted = formatOrderDate(raw);
    return formatted.isEmpty ? '--' : formatted;
  }

  static String _dash() => '-' * _paperChars;

  static String _center(String text) {
    final t = text.trim();
    if (t.isEmpty) return '';
    if (t.length >= _paperChars) return t.substring(0, _paperChars);
    final pad = ((_paperChars - t.length) / 2).floor();
    return '${' ' * pad}$t';
  }

  static List<String> _centerLines(String text) =>
      _wrap(text).map(_center).toList();

  static List<String> _wrap(String text, [int width = _paperChars]) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return [''];
    final lines = <String>[];
    var line = '';
    for (final w in words) {
      final next = line.isEmpty ? w : '$line $w';
      if (next.length <= width) {
        line = next;
      } else {
        if (line.isNotEmpty) lines.add(line);
        line = w.length > width ? w.substring(0, width) : w;
      }
    }
    if (line.isNotEmpty) lines.add(line);
    return lines;
  }

  static String _pairLine(String left, String right) {
    final l = left;
    final r = right;
    final space = _paperChars - l.length - r.length;
    if (space >= 1) return '$l${' ' * space}$r';
    final maxLeft = (_paperChars - r.length - 1).clamp(1, _paperChars);
    return '${l.substring(0, maxLeft)} $r';
  }
}
