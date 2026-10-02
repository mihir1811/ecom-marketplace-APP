import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';
import 'motion/press_tilt.dart';
import 'motion/scroll_reveal.dart';

/// Invitation for businesses to list on GemWorld, with a slow gold sheen.
class HomeSellCard extends StatelessWidget {
  const HomeSellCard({
    required this.isAuthenticatedIndividual,
    required this.onTap,
    super.key,
  });

  final bool isAuthenticatedIndividual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final gutter = homeGutter(context);
    final title = context.tr(RemainingL10n.sellOnGemWorld);

    Widget card = Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 18, 22),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(HomeSpace.radius),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(HomeL10n.sellEyebrow).toUpperCase(),
                  style: HomeType.eyebrow(palette.accent),
                ),
                const SizedBox(height: 12),
                Text(title, style: HomeType.display(30, palette.ink)),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    isAuthenticatedIndividual
                        ? RemainingL10n.sellerSeparateAccountNote
                        : RemainingL10n.sellerRegisterNote,
                  ),
                  style: HomeType.body(palette.inkMuted, size: 13.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.ink,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: palette.canvas,
            ),
          ),
        ],
      ),
    );
    if (!MediaQuery.disableAnimationsOf(context)) {
      card = card
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            delay: 2600.ms,
            duration: 1800.ms,
            color: palette.isDark
                ? const Color(0x1FFFFFFF)
                : const Color(0x80FFFFFF),
          );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, HomeSpace.section, gutter, 0),
      child: ScrollReveal(
        child: PressTilt(semanticLabel: title, onTap: onTap, child: card),
      ),
    );
  }
}
