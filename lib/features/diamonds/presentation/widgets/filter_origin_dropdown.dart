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
    this.title = 'Origin Country',
    this.hint = 'Select origin country',
    this.infoText = "Filter by the diamond's mined origin country.",
    this.pickerTitle = 'Select Origin Country',
    this.options,
    this.flags,
    this.showFlags = true,
    super.key,
  });

  final String? selectedOrigin;
  final ValueChanged<String?> onSelected;
  final String title;
  final String hint;
  final String infoText;
  final String pickerTitle;

  /// Custom option list; defaults to the full diamond country list.
  final List<String>? options;

  /// Custom flag emoji map; defaults to the diamond country flags.
  final Map<String, String>? flags;
  final bool showFlags;

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.r16)),
      ),
      builder: (context) {
        return _CountryPickerModal(
          onSelected: (val) {
            onSelected(val);
            Navigator.pop(context);
          },
          title: pickerTitle,
          options: options ?? DiamondFilterState.countries,
          flags: flags ?? DiamondFilterState.countryFlags,
          showFlags: showFlags,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.warmBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: infoText,
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(color: Colors.white, fontSize: 13),
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
              color: AppColors.warmWhite,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (selectedOrigin != null && showFlags) ...[
                      Text(
                        (flags ?? DiamondFilterState.countryFlags)[
                                selectedOrigin!] ??
                            '',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      selectedOrigin ?? hint,
                      style: AppTypography.body.copyWith(
                        color: selectedOrigin == null
                            ? Colors.black38
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black54,
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
  const _CountryPickerModal({
    required this.onSelected,
    required this.title,
    required this.options,
    required this.flags,
    required this.showFlags,
  });

  final ValueChanged<String?> onSelected;
  final String title;
  final List<String> options;
  final Map<String, String> flags;
  final bool showFlags;

  @override
  State<_CountryPickerModal> createState() => _CountryPickerModalState();
}

class _CountryPickerModalState extends State<_CountryPickerModal> {
  late List<String> _filteredCountries;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filteredCountries = widget.options;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _filteredCountries = widget.options;
      } else {
        _filteredCountries = widget.options
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
                widget.title,
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
                final flag =
                    widget.showFlags ? (widget.flags[country] ?? '') : '';
                return ListTile(
                  leading: flag.isEmpty
                      ? null
                      : Text(
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
