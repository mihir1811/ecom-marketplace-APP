import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../seller/domain/models/seller_review.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';

/// One word for a rating, so the stars read at a glance.
String reviewRatingWord(num rating) {
  if (rating >= 4.5) return 'Exceptional';
  if (rating >= 3.5) return 'Very good';
  if (rating >= 2.5) return 'Good';
  if (rating >= 1.5) return 'Fair';
  if (rating > 0) return 'Poor';
  return 'Not rated';
}

/// Five gold stars with fractional fill; they pop in one after another.
class ReviewStars extends StatelessWidget {
  const ReviewStars({
    required this.rating,
    this.size = 16,
    this.color,
    this.animate = true,
    this.delay = Duration.zero,
    super.key,
  });

  final double rating;
  final double size;
  final Color? color;
  final bool animate;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final gold = color ?? p.gold;
    final track = gold.withValues(alpha: p.isDark ? 0.22 : 0.26);
    return Semantics(
      label: '${rating.toStringAsFixed(1)} out of 5 stars',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) SizedBox(width: size * 0.12),
              _star(context, (rating - i).clamp(0.0, 1.0), gold, track, i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _star(
    BuildContext context,
    double fill,
    Color gold,
    Color track,
    int i,
  ) {
    Widget star = SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Icon(Icons.star_rounded, size: size, color: track),
          if (fill > 0)
            ClipRect(
              clipper: _FractionClipper(fill),
              child: Icon(Icons.star_rounded, size: size, color: gold),
            ),
        ],
      ),
    );
    if (animate && !context.reduceMotion) {
      star = star
          .animate(delay: delay + (70 * i).ms)
          .fadeIn(duration: 260.ms)
          .scaleXY(
            begin: 0.4,
            end: 1,
            duration: 520.ms,
            curve: AtelierMotion.settle,
          );
    }
    return star;
  }
}

class _FractionClipper extends CustomClipper<Rect> {
  const _FractionClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionClipper old) => old.fraction != fraction;
}

/// Headline of the reviews page: the buyer's average in a large serif
/// figure beside a 5→1 distribution. Each bar is a filter.
class ReviewLedgerCard extends StatelessWidget {
  const ReviewLedgerCard({
    required this.reviews,
    required this.selectedRating,
    required this.onRating,
    super.key,
  });

  final List<SellerReview> reviews;
  final int? selectedRating;

  /// Called with a rating to filter by, or null to clear.
  final ValueChanged<int?> onRating;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final counts = {for (var r = 1; r <= 5; r++) r: 0};
    for (final review in reviews) {
      final r = review.rating.clamp(1, 5);
      counts[r] = counts[r]! + 1;
    }
    final total = reviews.length;
    final average = total == 0
        ? 0.0
        : reviews.fold<int>(0, (s, r) => s + r.rating.clamp(1, 5)) / total;
    final most = counts.values.fold<int>(0, (a, b) => a > b ? a : b);

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('YOUR AVERAGE', style: AtelierType.overline(p.muted)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CountUpText(
                average.toStringAsFixed(1),
                style: AtelierType.display(
                  p.ink,
                  size: 54,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text('/ 5', style: AtelierType.caption(p.muted, size: 13)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ReviewStars(rating: average, size: 17, delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          '${reviewRatingWord(average)} · $total '
          '${total == 1 ? 'review' : 'reviews'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AtelierType.caption(p.inkSoft, size: 12),
        ),
      ],
    );

    final bars = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 5; r >= 1; r--)
          _DistributionBar(
            rating: r,
            count: counts[r]!,
            fraction: most == 0 ? 0 : counts[r]! / most,
            selected: selectedRating == r,
            dimmed: selectedRating != null && selectedRating != r,
            index: 5 - r,
            onTap: counts[r]! == 0
                ? null
                : () => onRating(selectedRating == r ? null : r),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.hairline),
        boxShadow: p.softShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 16), bars],
            );
          }
          return Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.46,
                ),
                child: summary,
              ),
              Container(
                width: 1,
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: p.hairline,
              ),
              Expanded(child: bars),
            ],
          );
        },
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.rating,
    required this.count,
    required this.fraction,
    required this.selected,
    required this.dimmed,
    required this.index,
    required this.onTap,
  });

  final int rating;
  final int count;
  final double fraction;
  final bool selected;
  final bool dimmed;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    Widget fill = FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: fraction.clamp(0.0, 1.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: p.goldGradient,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
    if (!context.reduceMotion) {
      fill = fill
          .animate(delay: (240 + index * 70).ms)
          .scaleX(
            begin: 0,
            end: 1,
            alignment: Alignment.centerLeft,
            duration: 900.ms,
            curve: AtelierMotion.emphasized,
          );
    }
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        scale: 0.97,
        semanticLabel:
            '$rating star, $count ${count == 1 ? 'review' : 'reviews'}'
            '${onTap == null ? '' : ', filter'}',
        borderRadius: BorderRadius.circular(AtelierRadius.xs),
        child: AnimatedOpacity(
          duration: AtelierMotion.base,
          opacity: dimmed ? 0.4 : 1,
          child: AnimatedContainer(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? p.goldSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(AtelierRadius.xs),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  child: Text(
                    '$rating',
                    style: AtelierType.figure(p.inkSoft, size: 12),
                  ),
                ),
                Icon(Icons.star_rounded, size: 12, color: p.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: p.sunken,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: fill,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 22,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: AtelierType.figure(
                      count == 0 ? p.muted : p.ink,
                      size: 12,
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
}
