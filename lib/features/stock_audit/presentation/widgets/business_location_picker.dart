import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/business_location_model.dart';

class BusinessLocationPicker extends StatelessWidget {
  const BusinessLocationPicker({
    super.key,
    required this.locations,
    required this.selectedId,
    required this.onChanged,
    this.isLoading = false,
  });

  final List<BusinessLocationModel> locations;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool isLoading;

  BusinessLocationModel? get _selected =>
      locations.where((location) => location.id == selectedId).firstOrNull;

  BusinessLocationModel? get _effectiveSelected {
    if (_selected != null) return _selected;
    if (locations.length == 1) return locations.first;
    return null;
  }

  Future<void> _openSearchSheet(BuildContext context) async {
    if (locations.isEmpty) return;

    final picked = await showLocationPickerSheet(
      context: context,
      locations: locations,
      selectedId: selectedId,
    );

    if (picked != null) onChanged(picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _effectiveSelected;
    final parts = splitLocationLabel(selected?.label);
    final isSingleLocation = locations.length <= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Business Location', icon: Icons.place_outlined),
        const SizedBox(height: 10),
        if (isSingleLocation)
          BusinessLocationReadOnly(
            title: parts.title ?? selected?.label ?? '—',
            subtitle: parts.subtitle,
          )
        else
          AppSelectTile(
            value: parts.title,
            subtitle: parts.subtitle,
            placeholder: locations.isEmpty
                ? 'No location available'
                : 'Select location',
            isLoading: isLoading,
            enabled: locations.isNotEmpty,
            onTap: () => _openSearchSheet(context),
          ),
      ],
    );
  }
}

class BusinessLocationReadOnly extends StatelessWidget {
  const BusinessLocationReadOnly({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_rounded,
            size: 18,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if ((subtitle ?? '').isNotEmpty)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Location labels look like "DS#41 - Khaga - Gramik (FG-DS) — City, State".
/// Splitting them keeps the tile readable instead of truncating one long line.
({String? title, String? subtitle}) splitLocationLabel(String? label) {
  if (label == null || label.trim().isEmpty) {
    return (title: null, subtitle: null);
  }
  final index = label.indexOf('—');
  if (index < 0) return (title: label.trim(), subtitle: null);
  return (
    title: label.substring(0, index).trim(),
    subtitle: label.substring(index + 1).trim(),
  );
}

/// Result of the location sheet. [id] is null for the "all locations" option.
class LocationPickResult {
  const LocationPickResult(this.id);
  final int? id;
}

Future<LocationPickResult?> showLocationPickerSheet({
  required BuildContext context,
  required List<BusinessLocationModel> locations,
  required int? selectedId,
  bool includeAllOption = false,
}) {
  return showModalBottomSheet<LocationPickResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    builder: (context) => _LocationSearchSheet(
      locations: locations,
      selectedId: selectedId,
      includeAllOption: includeAllOption,
    ),
  );
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({
    required this.locations,
    required this.selectedId,
    required this.includeAllOption,
  });

  final List<BusinessLocationModel> locations;
  final int? selectedId;
  final bool includeAllOption;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  String _query = '';

  List<({int? id, String label})> get _options {
    final all = <({int? id, String label})>[
      if (widget.includeAllOption) (id: null, label: 'All Business Locations'),
      ...widget.locations.map((l) => (id: l.id, label: l.label)),
    ];
    final term = _query.trim().toLowerCase();
    if (term.isEmpty) return all;
    return all
        .where((item) => item.label.toLowerCase().contains(term))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;

    return AppSheet(
      title: 'Business Location',
      subtitle: 'Apna dark store select karein',
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: AppSearchField(
              hintText: 'Search location...',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: options.isEmpty
                ? const AppEmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'No location found',
                    message: 'Search term badal kar dubara try karein.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.id == widget.selectedId;
                      final parts = splitLocationLabel(option.label);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: isSelected
                              ? AppColors.primarySoft
                              : AppColors.fieldBg,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => Navigator.of(
                              context,
                            ).pop(LocationPickResult(option.id)),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    option.id == null
                                        ? Icons.apps_rounded
                                        : Icons.storefront_rounded,
                                    size: 18,
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          parts.title ?? option.label,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            height: 1.35,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if ((parts.subtitle ?? '').isNotEmpty)
                                          Text(
                                            parts.subtitle!,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              height: 1.35,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        size: 19,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
