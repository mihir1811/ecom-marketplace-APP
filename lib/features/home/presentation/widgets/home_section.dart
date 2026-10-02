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

/// Section title block: numbered eyebrow, hairline and serif title.
class HomeSectionHeading extends StatelessWidget {
  const HomeSectionHeading({
    required this.index,
    required this.eyebrow,
    required this.title,
    super.key,
    this.trailing,
    this.leading,
  });

  final String index;
  final String eyebrow;
  final String title;
  final Widget? trailing;

  /// Optional marker drawn before the eyebrow (e.g. a live pulse).
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(index, style: HomeType.eyebrow(palette.accent)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 28,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 28 * t,
                          height: 1,
                          color: palette.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Text(
                          eyebrow.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeType.eyebrow(palette.inkMuted),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                      Opacity(opacity: t.clamp(0.0, 1.0), child: trailing),
                  ],
                ),
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
  const HomeArrowLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        minimumSize: const Size(48, 44),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: HomeType.label(palette.accent)),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 16, color: palette.accent),
        ],
      ),
    );
  }
}
