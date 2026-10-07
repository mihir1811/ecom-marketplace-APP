import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_field.dart';
import '../theme/home_tokens.dart';
import 'home_header.dart';

/// Last section of home, one full screen tall: a dark field of live 3D
/// pear diamonds (from the bundled .glb model) streaming from the top-left
/// to the bottom-right.
/// The finger parts the stones like a body moving through them and lights
/// them warm; the page does not scroll while touching the stones below the
/// copy. Legal links sit along the bottom edge.
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

    Widget link(String key, String route) => TextButton(
      onPressed: () => context.openRoute(route),
      style: TextButton.styleFrom(
        foregroundColor: HomeStage.ink,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        minimumSize: const Size(44, 44),
      ),
      child: Text(context.tr(key), style: HomeType.label(HomeStage.inkMuted)),
    );

    return ClipRRect(
      borderRadius: palette.isDark
          ? BorderRadius.zero
          : const BorderRadius.vertical(top: Radius.circular(32)),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GemField(background: HomeStage.obsidian, touchTopInset: touchTop),
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
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: media.padding.bottom + 20,
              child: Column(
                children: [
                  Container(width: 48, height: 1, color: HomeStage.glassBorder),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    children: [
                      link(RemainingL10n.aboutGemWorld, AppRouteNames.aboutUs),
                      link(
                        RemainingL10n.termsConditions,
                        AppRouteNames.termsAndConditions,
                      ),
                      link(RemainingL10n.policies, AppRouteNames.policies),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
