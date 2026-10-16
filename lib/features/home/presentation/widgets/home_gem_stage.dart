import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_field.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';

/// Last section of home, one full screen tall: a dark field of live 3D
/// diamonds in every bundled cut and size (baked from the .glb models in
/// `assets_src/gem_models`) streaming from the top-left to the
/// bottom-right.
/// The finger parts the stones like a body moving through them and lights
/// them warm; the page does not scroll while touching the stones below the
/// copy. Legal links sit along the bottom edge.
class HomeGemStage extends StatelessWidget {
  const HomeGemStage({this.height, super.key});

  /// Defaults to the screen height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final media = MediaQuery.of(context);
    final gutter = homeGutter(context);
    final height = this.height ?? media.size.height;
    final copyTop = media.padding.top + 28;
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
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      HomeStage.obsidian.withValues(alpha: 0.9),
                      HomeStage.obsidian.withValues(alpha: 0),
                      HomeStage.obsidian.withValues(alpha: 0),
                      HomeStage.obsidian.withValues(alpha: 0.7),
                    ],
                    stops: const [0, 0.34, 0.82, 1],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  copyTop,
                  gutter,
                  media.padding.bottom + 96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              left: gutter,
              right: gutter,
              bottom: media.padding.bottom + 20,
              child: Column(
                children: [
                  Container(width: 48, height: 1, color: HomeStage.glassBorder),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    children: [
                      link(
                        EducationL10n.navEducation,
                        AppRouteNames.diamondEducation,
                      ),
                      link(RemainingL10n.aboutGemWorld, AppRouteNames.aboutUs),
                      link(
                        AccountCommerceL10n.privacyPolicy,
                        AppRouteNames.privacyPolicy,
                      ),
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
