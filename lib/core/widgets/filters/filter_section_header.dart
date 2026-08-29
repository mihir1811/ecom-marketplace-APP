import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class FilterSectionHeader extends StatelessWidget {
  const FilterSectionHeader({required this.title, this.infoText, super.key});

  final String title;
  final String? infoText;

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
          Tooltip(
            message: infoText!,
            triggerMode: TooltipTriggerMode.tap,
            preferBelow: false,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
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
      ],
    );
  }
}
