import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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

/// Depth of field for a [LuxeWheel] carousel: the centred item stays full
/// size and sharp while neighbours shrink, soften and fade with their
/// distance from centre, so the eye lands on the focused item.
class LuxeWheelFocus extends StatelessWidget {
  const LuxeWheelFocus({
    required this.controller,
    required this.index,
    required this.fallbackPage,
    required this.child,
    super.key,
    this.sideScale = 0.66,
    this.sideBlur = 3.2,
    this.sideOpacity = 0.55,
  });

  final PageController controller;
  final int index;

  /// Page to assume before the controller has dimensions.
  final double fallbackPage;
  final Widget child;

  /// Scale, blur sigma and opacity one slot (or more) away from centre.
  final double sideScale;
  final double sideBlur;
  final double sideOpacity;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final page = controller.hasClients && controller.position.haveDimensions
            ? controller.page ?? fallbackPage
            : fallbackPage;
        final t = (index - page).abs().clamp(0.0, 1.0);
        final sigma = still ? 0.0 : sideBlur * t;
        Widget out = Transform.scale(
          scale: 1 - (1 - sideScale) * t,
          child: child,
        );
        if (sigma > 0.05) {
          out = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: out,
          );
        }
        return Opacity(opacity: 1 - (1 - sideOpacity) * t, child: out);
      },
      child: child,
    );
  }
}
