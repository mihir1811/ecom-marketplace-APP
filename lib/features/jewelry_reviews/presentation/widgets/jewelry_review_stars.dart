import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';

/// "Excellent" for 5 stars, and so on.
String jewelryStarWord(BuildContext context, int stars) =>
    context.tr(switch (stars) {
      1 => JewelryReviewL10n.star1,
      2 => JewelryReviewL10n.star2,
      3 => JewelryReviewL10n.star3,
      4 => JewelryReviewL10n.star4,
      _ => JewelryReviewL10n.star5,
    });

/// "1 review" / "12 reviews".
String jewelryReviewCount(BuildContext context, int count) => count == 1
    ? context.tr(JewelryReviewL10n.countOne)
    : context.tr(JewelryReviewL10n.countMany, {'count': count});

/// "4.7", "5".
String jewelryAverageLabel(double average) {
  final rounded = (average * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
}

/// Five stars filled to [rating] (fractions fill part of a star).
class JewelryStars extends StatelessWidget {
  const JewelryStars({
    required this.rating,
    this.size = 16,
    this.color,
    this.track,
    super.key,
  });

  final double rating;
  final double size;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final fill = color ?? p.accent;
    final empty = track ?? p.hairline;
    return Semantics(
      label: '${jewelryAverageLabel(rating)} / 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Stack(
              children: [
                Icon(Icons.star_rounded, size: size, color: empty),
                ClipRect(
                  clipper: _FractionClip((rating - i).clamp(0.0, 1.0)),
                  child: Icon(Icons.star_rounded, size: size, color: fill),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FractionClip extends CustomClipper<Rect> {
  const _FractionClip(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionClip old) => old.fraction != fraction;
}

/// Compact "★ 4.7 (12)" for cards and headers; nothing without reviews.
class JewelryRatingChip extends StatelessWidget {
  const JewelryRatingChip({
    required this.average,
    required this.count,
    this.size = 11.5,
    this.color,
    this.mutedColor,
    this.showCount = true,
    super.key,
  });

  final double? average;
  final int count;
  final double size;
  final Color? color;
  final Color? mutedColor;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final avg = average;
    if (avg == null || count <= 0) return const SizedBox.shrink();
    final p = LuxePalette.of(context);
    final ink = color ?? p.ink;
    return Semantics(
      label:
          '${jewelryAverageLabel(avg)} / 5, ${jewelryReviewCount(context, count)}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: size + 2, color: p.accent),
          const SizedBox(width: 2),
          Text(
            jewelryAverageLabel(avg),
            style: LuxeType.label(ink, size: size),
          ),
          if (showCount)
            Text(
              ' ($count)',
              style: LuxeType.body(mutedColor ?? p.inkMuted, size: size),
            ),
        ],
      ),
    );
  }
}

/// Five tappable stars (the buyer's rating).
class JewelryStarPicker extends StatelessWidget {
  const JewelryStarPicker({
    required this.value,
    required this.onChanged,
    this.size = 34,
    super.key,
  });

  /// 0 = none chosen yet.
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          Semantics(
            button: true,
            selected: star == value,
            label: '$star · ${jewelryStarWord(context, star)}',
            excludeSemantics: true,
            child: InkResponse(
              radius: size * 0.7,
              onTap: () {
                AppHaptics.light();
                onChanged(star);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedScale(
                  scale: star <= value ? 1 : 0.92,
                  duration: LuxeMotion.fast,
                  child: Icon(
                    star <= value
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: size,
                    color: star <= value ? p.accent : p.inkFaint,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
