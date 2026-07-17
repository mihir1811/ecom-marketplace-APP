import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/diamond_filter_state.dart';

class FilterOriginDropdown extends StatelessWidget {
  const FilterOriginDropdown({
    required this.selectedOrigin,
    required this.onSelected,
    required this.isDark,
    super.key,
  });

  final String? selectedOrigin;
  final ValueChanged<String?> onSelected;
  final bool isDark;

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.charcoalDark : AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.r16)),
      ),
      builder: (context) {
        return _CountryPickerModal(
          onSelected: (val) {
            onSelected(val);
            Navigator.pop(context);
          },
          isDark: isDark,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Origin Country',
              style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: "Filter by the diamond's mined origin country.",
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(color: Colors.white, fontSize: 11),
              child: const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.bronze,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        GestureDetector(
          onTap: () => _showCountryPicker(context),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppSpacing.r8),
              color: isDark ? AppColors.slateSurface : AppColors.warmWhite,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (selectedOrigin != null) ...[
                      Text(
                        DiamondFilterState.countryFlags[selectedOrigin!] ?? '',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      selectedOrigin ?? 'Select origin country',
                      style: AppTypography.body.copyWith(
                        color: selectedOrigin == null
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryPickerModal extends StatefulWidget {
  const _CountryPickerModal({required this.onSelected, required this.isDark});

  final ValueChanged<String?> onSelected;
  final bool isDark;

  @override
  State<_CountryPickerModal> createState() => _CountryPickerModalState();
}

class _CountryPickerModalState extends State<_CountryPickerModal> {
  late List<String> _filteredCountries;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filteredCountries = DiamondFilterState.countries;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _filteredCountries = DiamondFilterState.countries;
      } else {
        _filteredCountries = DiamondFilterState.countries
            .where((c) => c.toLowerCase().contains(q.toLowerCase()))
            .toList();
      }
    });
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () => _filter(q));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Origin Country',
                style: AppTypography.headline.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search countries...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final flag = DiamondFilterState.countryFlags[country] ?? '';
                return ListTile(
                  leading: Text(
                    flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(country),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                  onTap: () => widget.onSelected(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
