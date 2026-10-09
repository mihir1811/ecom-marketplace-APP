import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'filter_advanced_range_input.dart';
import 'filter_proportion_diagram.dart';
import 'filter_section_divider.dart';

/// Shared L / W / H / ratio measurement ranges for diamond and gemstone search.
class CatalogMeasurementFilters extends StatelessWidget {
  const CatalogMeasurementFilters({
    required this.lengthMin,
    required this.lengthMax,
    required this.onLengthMinChanged,
    required this.onLengthMaxChanged,
    required this.widthMin,
    required this.widthMax,
    required this.onWidthMinChanged,
    required this.onWidthMaxChanged,
    required this.heightMin,
    required this.heightMax,
    required this.onHeightMinChanged,
    required this.onHeightMaxChanged,
    required this.ratioMin,
    required this.ratioMax,
    required this.onRatioMinChanged,
    required this.onRatioMaxChanged,
    this.dimensionLimits = const (0.0, 100.0),
    this.ratioLimits = const (0.5, 5.0),
    super.key,
  });

  final double lengthMin;
  final double lengthMax;
  final ValueChanged<double> onLengthMinChanged;
  final ValueChanged<double> onLengthMaxChanged;

  final double widthMin;
  final double widthMax;
  final ValueChanged<double> onWidthMinChanged;
  final ValueChanged<double> onWidthMaxChanged;

  final double heightMin;
  final double heightMax;
  final ValueChanged<double> onHeightMinChanged;
  final ValueChanged<double> onHeightMaxChanged;

  final double ratioMin;
  final double ratioMax;
  final ValueChanged<double> onRatioMinChanged;
  final ValueChanged<double> onRatioMaxChanged;

  final (double, double) dimensionLimits;
  final (double, double) ratioLimits;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: [
          FilterAdvancedRangeInput(
            title: context.tr(CatalogL10n.lengthRange),
            currentMin: lengthMin,
            currentMax: lengthMax,
            minLimit: dimensionLimits.$1,
            maxLimit: dimensionLimits.$2,
            unit: 'mm',
            infoText: context.tr(CatalogL10n.lengthHelp),
            infoDiagram: FilterProportionDiagramKind.length,
            onMinChanged: onLengthMinChanged,
            onMaxChanged: onLengthMaxChanged,
          ),
          const FilterSectionDivider(),
          FilterAdvancedRangeInput(
            title: context.tr(CatalogL10n.widthRange),
            currentMin: widthMin,
            currentMax: widthMax,
            minLimit: dimensionLimits.$1,
            maxLimit: dimensionLimits.$2,
            unit: 'mm',
            infoText: context.tr(CatalogL10n.widthHelp),
            infoDiagram: FilterProportionDiagramKind.width,
            onMinChanged: onWidthMinChanged,
            onMaxChanged: onWidthMaxChanged,
          ),
          const FilterSectionDivider(),
          FilterAdvancedRangeInput(
            title: context.tr(CatalogL10n.heightRange),
            currentMin: heightMin,
            currentMax: heightMax,
            minLimit: dimensionLimits.$1,
            maxLimit: dimensionLimits.$2,
            unit: 'mm',
            infoText: context.tr(CatalogL10n.heightHelp),
            infoDiagram: FilterProportionDiagramKind.height,
            onMinChanged: onHeightMinChanged,
            onMaxChanged: onHeightMaxChanged,
          ),
          const FilterSectionDivider(),
          FilterAdvancedRangeInput(
            title: context.tr(CatalogL10n.ratioRange),
            currentMin: ratioMin,
            currentMax: ratioMax,
            minLimit: ratioLimits.$1,
            maxLimit: ratioLimits.$2,
            infoText: context.tr(CatalogL10n.ratioHelp),
            infoDiagram: FilterProportionDiagramKind.ratio,
            onMinChanged: onRatioMinChanged,
            onMaxChanged: onRatioMaxChanged,
          ),
        ],
      ),
    );
  }
}
