import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/module_ui.dart';
import '../../stock_audit/data/models/business_location_model.dart';
import '../../stock_audit/data/stock_audit_repository.dart';
import '../../stock_audit/presentation/widgets/business_location_picker.dart';
import 'providers/auth_provider.dart';

/// SuperAdmin-only gate: warehouse choose ke bina dashboard nahi.
class SelectWarehouseScreen extends ConsumerStatefulWidget {
  const SelectWarehouseScreen({super.key});

  @override
  ConsumerState<SelectWarehouseScreen> createState() =>
      _SelectWarehouseScreenState();
}

class _SelectWarehouseScreenState extends ConsumerState<SelectWarehouseScreen> {
  List<BusinessLocationModel> _locations = const [];
  int? _selectedId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows =
          await ref.read(stockAuditRepositoryProvider).getBusinessLocations();
      if (!mounted) return;
      setState(() {
        _locations = rows;
        _selectedId = ref.read(authControllerProvider).selectedStoreId;
        if (_selectedId != null &&
            !_locations.any((l) => l.id == _selectedId)) {
          _selectedId = null;
        }
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Locations load nahi ho payi. Dubara try karein.';
      });
    }
  }

  Future<void> _continue() async {
    final id = _selectedId;
    if (id == null || id <= 0) {
      setState(() => _error = 'Pehle warehouse choose karein');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final selected = _locations.where((l) => l.id == id).firstOrNull;
    final label = (selected?.name ?? selected?.label ?? '').trim();
    await ref.read(authControllerProvider.notifier).setSelectedStoreId(
          id,
          label: label.isEmpty ? null : label,
        );
    if (!mounted) return;
    context.go('/dashboard');
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final name = (user?.name ?? user?.fullName ?? 'SuperAdmin').trim();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primary,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F5FA),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 16,
                right: 16,
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Select Warehouse',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _logout,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Namaste, $name',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dashboard dekhne se pehle warehouse choose karein.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        if (_error != null) ...[
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_locations.isEmpty)
                          const ModuleEmptyState(
                            icon: Icons.store_mall_directory_outlined,
                            title: 'No warehouse found',
                            message: 'Active business location nahi mili',
                          )
                        else
                          BusinessLocationPicker(
                            locations: _locations,
                            selectedId: _selectedId,
                            onChanged: (id) => setState(() {
                              _selectedId = id;
                              _error = null;
                            }),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saving || _locations.isEmpty
                                ? null
                                : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
