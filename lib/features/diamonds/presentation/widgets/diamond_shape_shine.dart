import 'package:flutter/material.dart';

import '../../../../core/widgets/showcase_media_shine.dart';

/// Soft static shine around a diamond shape image.
/// Glow only — no sparkle animation. Falloff is intentionally tight.
class DiamondShapeShine extends StatelessWidget {
  const DiamondShapeShine({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShowcaseMediaShine(child: child);
  }
}
