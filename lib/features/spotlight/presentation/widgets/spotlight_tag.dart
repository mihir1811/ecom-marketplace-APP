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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: ShapeDecoration(
          color: blue.withValues(alpha: p.isDark ? 0.18 : 0.1),
          shape: StadiumBorder(side: BorderSide(color: blue)),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: LuxeType.label(blue, size: 9.5).copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      );
    }
    final fg = onImage ? Colors.white : p.inkMuted;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
