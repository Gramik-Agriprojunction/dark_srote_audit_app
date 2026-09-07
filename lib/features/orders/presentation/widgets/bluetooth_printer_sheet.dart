import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../../core/constants/app_colors.dart';
import '../../services/thermal_printer_service.dart';

class BluetoothPrinterSheet extends StatefulWidget {
  const BluetoothPrinterSheet({
    super.key,
    required this.onSelect,
  });

  final Future<void> Function(BluetoothInfo device) onSelect;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(BluetoothInfo device) onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BluetoothPrinterSheet(onSelect: onSelect),
    );
  }

  @override
  State<BluetoothPrinterSheet> createState() => _BluetoothPrinterSheetState();
}

class _BluetoothPrinterSheetState extends State<BluetoothPrinterSheet> {
  List<BluetoothInfo> _devices = [];
  SavedPrinter? _saved;
  bool _scanning = false;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _saved = await ThermalPrinterService.getSavedPrinter();
    if (!mounted) return;
    await _scan();
  }

  Future<void> _scan() async {
    if (_processing) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final devices = await ThermalPrinterService.scanPrinters();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _scanning = false;
        if (devices.isEmpty) {
          _error =
              'No paired Bluetooth printers found. Pair your printer in phone Settings first.';
        }
      });
    } on PrinterException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _devices = [];
        _error = e.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _devices = [];
        _error = 'Could not scan for printers.';
      });
    }
  }

  Future<void> _select(BluetoothInfo device) async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      await widget.onSelect(device);
      if (mounted) Navigator.of(context).pop();
    } on PrinterException catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = e.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'Could not connect to printer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bluetooth Printer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                onPressed: _processing ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Text(
            'Select a paired thermal printer. Pair the printer in Android Bluetooth settings if it does not appear.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
          ),
          if (_saved != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Saved: ${_saved!.name}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A3412),
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.35),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: _processing
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 10),
                        Text(
                          'Connecting and printing…',
                          style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  )
                : _scanning
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 10),
                            Text(
                              'Searching printers…',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : _devices.isEmpty
                        ? const Center(
                            child: Text(
                              'No printers found.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _devices.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _devices[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.print_outlined,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  item.name.trim().isEmpty ? 'Printer' : item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  item.macAdress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                ),
                                onTap: () => _select(item),
                              );
                            },
                          ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: (_scanning || _processing) ? null : _scan,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Scan again', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
