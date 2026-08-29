import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Expandable filter section used by end-drawers and full-screen filters.
class FilterAccordionSection extends StatelessWidget {
  const FilterAccordionSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.titleStyle,
    super.key,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s20,
              vertical: AppSpacing.s16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style:
                        titleStyle ??
                        AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (expanded) child,
        const Divider(height: 1),
      ],
    );
  }
}
