import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import 'filter_info_tooltip.dart';
import 'filter_proportion_diagram.dart';

class FilterSectionHeader extends StatelessWidget {
  const FilterSectionHeader({
    required this.title,
    this.infoText,
    this.infoDiagram,
    super.key,
  });

  final String title;
  final String? infoText;
  final FilterProportionDiagramKind? infoDiagram;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
        ),
        if (infoText != null) ...[
          const SizedBox(width: 6),
          FilterInfoTooltip(message: infoText!, diagram: infoDiagram),
        ],
      ],
    );
  }
}
