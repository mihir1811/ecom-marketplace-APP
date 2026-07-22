import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'filter_advanced_range_input.dart';

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
            title: 'Length Range',
            currentMin: lengthMin,
            currentMax: lengthMax,
            minLimit: dimensionLimits.$1,
            maxLimit: dimensionLimits.$2,
            unit: 'mm',
            infoText:
                'Filter by the physical length of the stone in millimeters.',
            onMinChanged: onLengthMinChanged,
            onMaxChanged: onLengthMaxChanged,
          ),
          const SizedBox(height: AppSpacing.s16),
          FilterAdvancedRangeInput(
            title: 'Width Range',
            currentMin: widthMin,
            currentMax: widthMax,
            minLimit: dimensionLimits.$1,
            maxLimit: dimensionLimits.$2,
            unit: 'mm',
            infoText:
                'Filter by the physical width of the stone in millimeters.',
            onMinChanged: onWidthMinChanged,
            onMaxChanged: onWidthMaxChanged,
          ),
          const SizedBox(height: AppSpacing.s16),
          FilterAdvancedRangeInput(
            title: 'Height Range',
            currentMin: heightMin,
            currentMax: heightMax,
            minLimit: dimensionLimits.$1,
            maxLimit: dimensionLimits.$2,
            unit: 'mm',
            infoText:
                'Filter by the physical height of the stone in millimeters.',
            onMinChanged: onHeightMinChanged,
            onMaxChanged: onHeightMaxChanged,
          ),
          const SizedBox(height: AppSpacing.s16),
          FilterAdvancedRangeInput(
            title: 'Length to Width Ratio Range',
            currentMin: ratioMin,
            currentMax: ratioMax,
            minLimit: ratioLimits.$1,
            maxLimit: ratioLimits.$2,
            infoText: 'Filter by the ratio of length divided by width.',
            onMinChanged: onRatioMinChanged,
            onMaxChanged: onRatioMaxChanged,
          ),
        ],
      ),
    );
  }
}
