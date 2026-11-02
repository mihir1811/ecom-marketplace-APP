import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'filter_advanced_range_input.dart';
import 'filter_proportion_diagram.dart';
import 'filter_scrollable_chips.dart';
import 'filter_section_divider.dart';

/// A single min/max advanced proportion field.
class CatalogAdvancedRangeSpec {
  const CatalogAdvancedRangeSpec({
    required this.title,
    required this.currentMin,
    required this.currentMax,
    required this.onMinChanged,
    required this.onMaxChanged,
    required this.infoText,
    this.infoDiagram,
    this.unit = '',
    this.minLimit = 0.0,
    this.maxLimit = 100.0,
  });

  final String title;
  final double currentMin;
  final double currentMax;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;
  final String infoText;
  final FilterProportionDiagramKind? infoDiagram;
  final String unit;
  final double minLimit;
  final double maxLimit;
}

/// A chip-group section inside expandable advanced filters.
class CatalogAdvancedChipSpec {
  const CatalogAdvancedChipSpec({
    required this.title,
    required this.options,
    required this.selectedItems,
    required this.onToggle,
    required this.infoText,
    this.infoDiagram,
  });

  final String title;
  final List<String> options;
  final List<String> selectedItems;
  final ValueChanged<String> onToggle;
  final String infoText;
  final FilterProportionDiagramKind? infoDiagram;
}

/// Expandable advanced filter panel shared by catalog search screens.
class CatalogExpandableAdvancedFilters extends StatefulWidget {
  const CatalogExpandableAdvancedFilters({
    required this.ranges,
    this.chipSections = const [],
    this.expandAdvanced = false,
    super.key,
  });

  final List<CatalogAdvancedRangeSpec> ranges;
  final List<CatalogAdvancedChipSpec> chipSections;
  final bool expandAdvanced;

  @override
  State<CatalogExpandableAdvancedFilters> createState() =>
      _CatalogExpandableAdvancedFiltersState();
}

class _CatalogExpandableAdvancedFiltersState
    extends State<CatalogExpandableAdvancedFilters> {
  late bool _isExpanded = widget.expandAdvanced;

  @override
  void didUpdateWidget(covariant CatalogExpandableAdvancedFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandAdvanced && !oldWidget.expandAdvanced) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isExpanded)
            _ToggleBar(
              label: context.tr(CatalogL10n.viewAdvancedFilters),
              icon: Icons.keyboard_arrow_down,
              fontSize: 15,
              onTap: () => setState(() => _isExpanded = true),
            ),
          if (_isExpanded) ...[
            for (var i = 0; i < widget.ranges.length; i++) ...[
              if (i > 0) const FilterSectionDivider(),
              FilterAdvancedRangeInput(
                title: widget.ranges[i].title,
                currentMin: widget.ranges[i].currentMin,
                currentMax: widget.ranges[i].currentMax,
                minLimit: widget.ranges[i].minLimit,
                maxLimit: widget.ranges[i].maxLimit,
                unit: widget.ranges[i].unit,
                infoText: widget.ranges[i].infoText,
                infoDiagram: widget.ranges[i].infoDiagram,
                onMinChanged: widget.ranges[i].onMinChanged,
                onMaxChanged: widget.ranges[i].onMaxChanged,
              ),
            ],
            for (final chips in widget.chipSections) ...[
              const FilterSectionDivider(),
              FilterScrollableChips(
                title: chips.title,
                options: chips.options,
                selectedItems: chips.selectedItems,
                onToggle: chips.onToggle,
                infoText: chips.infoText,
                infoDiagram: chips.infoDiagram,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ToggleBar extends StatelessWidget {
  const _ToggleBar({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.fontSize,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bg(context),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.bronze,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
            const SizedBox(width: 5),
            Icon(icon, color: AppColors.bronze, size: fontSize + 3),
          ],
        ),
      ),
    );
  }
}
