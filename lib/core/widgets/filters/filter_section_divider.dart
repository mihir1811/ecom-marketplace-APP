import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/luxe_scope.dart';

/// Thin hairline between sibling filter blocks, with roomy padding so
/// stacked internals (e.g. Finish / Cut / Polish) read as separate groups.
class FilterSectionDivider extends StatelessWidget {
  const FilterSectionDivider({super.key, this.top = 24, this.bottom = 20});

  /// Space below the previous block (above the line).
  final double top;

  /// Space above the next block (below the line).
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final color =
        LuxeScope.paletteOf(context)?.hairline ?? AppColors.border(context);

    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Divider(
        height: 1,
        thickness: 1,
        color: color.withValues(alpha: 0.85),
      ),
    );
  }
}
