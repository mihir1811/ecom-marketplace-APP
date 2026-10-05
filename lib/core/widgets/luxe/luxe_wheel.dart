import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Wheel motion for horizontal carousels: items ride the rim of a large
/// wheel whose hub sits far below the stage. Swiping turns the wheel, so
/// neighbours sink along the arc and lean outward (clockwise on the right,
/// anticlockwise on the left) while the centred item stands upright on top.
abstract final class LuxeWheel {
  /// Angle between neighbouring items, in radians.
  static const step = 0.17;

  /// Transform for an item [d] slots from the centre (positive = right) in
  /// a carousel whose items are [spacing] apart.
  static Matrix4 transform(double d, double spacing) {
    final radius = spacing / step;
    final a = d * step;
    // The page view already shifts the item by d · spacing; move it onto
    // the rim instead, then lean it along the radius.
    final dx = radius * math.sin(a) - d * spacing;
    final dy = radius * (1 - math.cos(a));
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..rotateZ(a);
  }
}

/// Places one [PageView] child on the [LuxeWheel], following [controller].
class LuxeWheelItem extends StatelessWidget {
  const LuxeWheelItem({
    required this.controller,
    required this.index,
    required this.fallbackPage,
    required this.child,
    super.key,
  });

  final PageController controller;
  final int index;

  /// Page to assume before the controller has dimensions.
  final double fallbackPage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final page =
              controller.hasClients && controller.position.haveDimensions
              ? controller.page ?? fallbackPage
              : fallbackPage;
          return Transform(
            alignment: Alignment.center,
            transform: LuxeWheel.transform(index - page, box.maxWidth),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}
