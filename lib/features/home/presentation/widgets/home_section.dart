import 'package:flutter/material.dart';

import '../theme/home_tokens.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';

/// Max content width so sections stay editorial on tablets and desktop.
const double kHomeMaxContentWidth = 760;

/// Horizontal gutter that centres content on wide screens.
double homeGutter(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width > kHomeMaxContentWidth + HomeSpace.gutter * 2
      ? (width - kHomeMaxContentWidth) / 2
      : HomeSpace.gutter;
}

/// Section title block: serif title with optional leading marker and
/// trailing action.
class HomeSectionHeading extends StatelessWidget {
  const HomeSectionHeading({
    required this.title,
    super.key,
    this.trailing,
    this.leading,
  });

  final String title;
  final Widget? trailing;

  /// Optional marker drawn before the title (e.g. a live pulse).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return ScrollReveal.builder(
      builder: (context, reveal) {
        return AnimatedBuilder(
          animation: reveal,
          builder: (context, _) {
            final t = reveal.value;
            final opacity = t.clamp(0.0, 1.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  Opacity(opacity: opacity, child: leading),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ClipRect(
                    child: FractionalTranslation(
                      translation: Offset(0, 1 - t),
                      child: Text(
                        title,
                        style: HomeType.display(34, palette.ink),
                      ),
                    ),
                  ),
                ),
                if (trailing != null)
                  Opacity(opacity: opacity, child: trailing),
              ],
            );
          },
        );
      },
    );
  }
}

/// Text link with an arrow, used for "See all" style actions.
class HomeArrowLink extends StatelessWidget {
  const HomeArrowLink({
    required this.label,
    required this.onTap,
    super.key,
    this.color,
  });

  final String label;
  final VoidCallback onTap;

  /// Defaults to the palette accent.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? HomePalette.of(context).accent;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: tint,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        minimumSize: const Size(48, 44),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: HomeType.label(tint)),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 16, color: tint),
        ],
      ),
    );
  }
}
