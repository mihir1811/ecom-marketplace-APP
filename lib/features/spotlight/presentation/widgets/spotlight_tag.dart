import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';

/// Blue used for sponsored stones in diamond results.
abstract final class SpotlightColors {
  static const blueLight = Color(0xFF1E5AA8);
  static const blueDark = Color(0xFF6EA8F0);

  static Color blue(BuildContext context) =>
      LuxePalette.of(context).isDark ? blueDark : blueLight;
}

/// Small "Sponsored" label.
///
/// [onImage] is the frosted version for banners; the default sits beside a
/// row heading; [pill] is the blue pill on sponsored diamond cards.
class SpotlightTag extends StatelessWidget {
  const SpotlightTag({super.key, this.onImage = false, this.pill = false});

  final bool onImage;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final label = context.tr(SpotlightL10n.sponsored);
    if (pill) {
      final blue = SpotlightColors.blue(context);
      return Container(
        // Fits the card's one-line meta row without changing its height.
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: ShapeDecoration(
          color: blue.withValues(alpha: p.isDark ? 0.18 : 0.1),
          shape: StadiumBorder(side: BorderSide(color: blue)),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: LuxeType.label(
            blue,
            size: 9.5,
          ).copyWith(fontWeight: FontWeight.w600, height: 1.2),
        ),
      );
    }
    final fg = onImage ? Colors.white : p.inkMuted;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: onImage ? const Color(0x66000000) : p.surfaceRaised,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: onImage ? const Color(0x40FFFFFF) : p.hairline,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: LuxeType.label(fg, size: 10).copyWith(letterSpacing: 0.4),
        ),
      ),
    );
  }
}

/// Jewellery paid spots: "SPONSORED" with a sparkle, white on the ads
/// blue. Sits on the image (top-left on cards, top-right on banners and
/// shop cards).
class SpotlightSponsoredPill extends StatelessWidget {
  const SpotlightSponsoredPill({super.key});

  @override
  Widget build(BuildContext context) {
    final label = context.tr(SpotlightL10n.sponsored);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
        decoration: const ShapeDecoration(
          color: SpotlightColors.blueLight,
          shape: StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              style: LuxeType.label(Colors.white, size: 9.5).copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
