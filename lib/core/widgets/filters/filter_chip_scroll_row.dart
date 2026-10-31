import 'package:flutter/material.dart';

/// One-line, horizontally scrolling row of filter chips (replaces a [Wrap]
/// where options should not stack into several lines).
class FilterChipScrollRow extends StatelessWidget {
  const FilterChipScrollRow({
    required this.children,
    super.key,
    this.spacing = 8,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}
