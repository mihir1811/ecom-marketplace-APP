import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/theme_preference_provider.dart';
import '../../../../core/widgets/language_menu_button.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';

/// Closing colophon: wordmark, promise line, legal links and preferences.
class HomeFooter extends ConsumerWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = HomePalette.of(context);
    final gutter = homeGutter(context);
    final dark = ref.watch(themePreferenceProvider);

    Widget link(String key, String route) => TextButton(
      onPressed: () => context.openRoute(route),
      style: TextButton.styleFrom(
        foregroundColor: palette.ink,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        minimumSize: const Size(44, 44),
      ),
      child: Text(context.tr(key), style: HomeType.label(palette.inkMuted)),
    );

    return Padding(
      // Bottom room keeps the floating Gem AI button off the legal line.
      padding: EdgeInsets.fromLTRB(gutter, HomeSpace.section + 12, gutter, 96),
      child: ScrollReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 0.8, color: palette.hairline),
            const SizedBox(height: 36),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => LinearGradient(
                colors: palette.isDark
                    ? const [Color(0xFFF1DDB5), Color(0xFFB8925A)]
                    : const [Color(0xFF16140F), Color(0xFF9C7A45)],
              ).createShader(rect),
              // Right padding keeps the italic overhang inside the mask.
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  'GemWorld',
                  style: HomeType.displayItalic(58, Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr(
                RemainingL10n
                    .certifiedStonesTransparentSellersWorldwideShipping,
              ),
              style: HomeType.body(palette.inkMuted, size: 13.5),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 18,
              children: [
                link(RemainingL10n.aboutGemWorld, AppRouteNames.aboutUs),
                link(
                  RemainingL10n.termsConditions,
                  AppRouteNames.termsAndConditions,
                ),
                link(RemainingL10n.policies, AppRouteNames.policies),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _AppearanceToggle(
                    dark: dark,
                    onChanged: (value) => ref
                        .read(themePreferenceProvider.notifier)
                        .setDarkMode(value),
                  ),
                ),
                const SizedBox(width: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.hairline),
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: palette.ink),
                    child: const LanguageMenuButton(iconSize: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              context.tr(HomeL10n.rights, {'year': DateTime.now().year}),
              style: HomeType.label(palette.inkFaint, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-segment light/dark switch with a sliding thumb.
class _AppearanceToggle extends StatelessWidget {
  const _AppearanceToggle({required this.dark, required this.onChanged});

  final bool dark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    Widget segment(bool value, IconData icon, String key) {
      final selected = value == dark;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: context.tr(key),
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? palette.canvas : palette.inkMuted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: HomeMotion.fast,
                      style: HomeType.label(
                        selected ? palette.canvas : palette.inkMuted,
                      ),
                      child: Text(
                        context.tr(key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: palette.hairline)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: HomeMotion.medium,
              curve: HomeMotion.settle,
              alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: palette.ink,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              segment(false, Icons.light_mode_outlined, HomeL10n.light),
              segment(true, Icons.dark_mode_outlined, HomeL10n.dark),
            ],
          ),
        ],
      ),
    );
  }
}
