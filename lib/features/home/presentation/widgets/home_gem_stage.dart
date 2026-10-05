import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gem3d/gem_field.dart';
import '../theme/home_tokens.dart';
import 'home_header.dart';

/// Last section of home, one full screen tall: a dark field of live 3D
/// diamonds in every cut drifting from the top-left to the bottom-right.
/// Touch lights the stones under the finger so they flare and glint; the
/// page does not scroll while touching the stones below the copy.
class HomeGemStage extends StatelessWidget {
  const HomeGemStage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final media = MediaQuery.of(context);
    final height = media.size.height;
    // Clear the floating home header that sits over the page top.
    final copyTop = media.padding.top + HomeHeader.barHeight + 28;
    // Touches above this line still scroll the page back up.
    final touchTop = copyTop + 200;
    final still = MediaQuery.disableAnimationsOf(context);

    Widget hint = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const ShapeDecoration(
        color: HomeStage.glass,
        shape: StadiumBorder(
          side: BorderSide(color: HomeStage.glassBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.touch_app_outlined,
            size: 16,
            color: HomeStage.gold,
          ),
          const SizedBox(width: 8),
          Text(
            context.tr(ExperienceL10n.stageHint),
            style: HomeType.label(HomeStage.ink, size: 12.5),
          ),
        ],
      ),
    );
    if (!still) {
      hint = hint
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -4, duration: 1400.ms, curve: Curves.easeInOut)
          .then()
          .shimmer(duration: 1600.ms, color: const Color(0x33FFFFFF));
    }

    return ClipRRect(
      borderRadius: palette.isDark
          ? BorderRadius.zero
          : const BorderRadius.vertical(top: Radius.circular(32)),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GemField(
              background: HomeStage.obsidian,
              touchTopInset: touchTop,
            ),
            // Scrims keep copy legible over the stones; they never block
            // touches so the whole stage stays playable.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xE6070709),
                      Color(0x00070709),
                      Color(0x00070709),
                      Color(0xB3070709),
                    ],
                    stops: [0, 0.34, 0.82, 1],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  copyTop,
                  24,
                  media.padding.bottom + 96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(ExperienceL10n.stageEyebrow).toUpperCase(),
                      style: HomeType.eyebrow(HomeStage.gold),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.tr(ExperienceL10n.stageHeadline),
                      style: HomeType.display(42, HomeStage.ink),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        context.tr(ExperienceL10n.stageBody),
                        style: HomeType.body(HomeStage.inkMuted, size: 13.5),
                      ),
                    ),
                    const Spacer(),
                    Center(child: hint),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
