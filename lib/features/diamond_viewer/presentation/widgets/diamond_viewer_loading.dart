import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/luxe_tokens.dart';

/// Luxe loading stage for the 360° viewer: a slowly turning brilliant,
/// a quiet caption and a hairline gold progress bar.
class DiamondViewerLoadingView extends StatelessWidget {
  const DiamondViewerLoadingView({super.key, this.progress = 0});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final animate = !MediaQuery.disableAnimationsOf(context);

    Widget gem = Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: LuxeStage.glassBorder),
        gradient: RadialGradient(
          colors: [LuxeStage.gold.withValues(alpha: 0.16), Colors.transparent],
        ),
      ),
      child: Icon(Icons.diamond_outlined, size: 38, color: LuxeStage.gold),
    );
    if (animate) {
      gem = gem
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: 6.seconds, curve: Curves.linear)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.96, end: 1.04, duration: 1400.ms);
    }

    return ColoredBox(
      color: LuxeStage.obsidian,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              gem,
              const SizedBox(height: 18),
              Text(
                'PREPARING 360° VIEW',
                style: LuxeType.eyebrow(LuxeStage.gold),
              ),
              const SizedBox(height: 6),
              Text(
                'Loading every facet in high resolution…',
                textAlign: TextAlign.center,
                style: LuxeType.body(LuxeStage.inkMuted, size: 13.5),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    // Indeterminate until the page reports progress.
                    value: clamped > 0 ? clamped : null,
                    minHeight: 2,
                    backgroundColor: LuxeStage.glassBorder,
                    color: LuxeStage.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
