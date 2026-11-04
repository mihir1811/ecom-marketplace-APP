import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../application/jewelry_review_providers.dart';
import '../../data/jewelry_review_repository.dart';
import '../../domain/models/jewelry_review.dart';
import 'jewelry_review_card.dart';
import 'jewelry_review_stars.dart';

/// A piece's or a shop's reviews, ordered like the website: the average
/// and a bar per star count (tap to filter), then the list with a sort
/// control and "Show more". Hidden entirely while there are no reviews.
class JewelryReviewsSection extends ConsumerWidget {
  const JewelryReviewsSection({
    required this.source,
    required this.slug,
    required this.shopName,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final JewelryReviewSource source;
  final String slug;

  /// For "Reply from {shop}".
  final String shopName;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (slug.isEmpty) return const SizedBox.shrink();
    final key = (source: source, slug: slug);
    final s = ref.watch(jewelryReviewListProvider(key));
    final list = ref.read(jewelryReviewListProvider(key).notifier);
    // First load, a failed first load, or no reviews: nothing to show.
    if (s.summary.count == 0) return const SizedBox.shrink();

    final p = LuxePalette.of(context);
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 4),
          border: Border.all(color: p.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(JewelryReviewL10n.title).toUpperCase(),
              style: LuxeType.eyebrow(p.accent),
            ),
            const SizedBox(height: 10),
            JewelryReviewSummaryPanel(
              summary: s.summary,
              selected: s.rating,
              onSelect: list.setRating,
            ),
            const SizedBox(height: 8),
            JewelryReviewListBar(
              rating: s.rating,
              sort: s.sort,
              onClear: () => list.setRating(null),
              onSort: list.setSort,
            ),
            Divider(height: 1, color: p.hairline),
            AnimatedOpacity(
              opacity: s.loading ? 0.45 : 1,
              duration: LuxeMotion.fast,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (s.items.isEmpty && !s.loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        context.tr(JewelryReviewL10n.noneForFilter),
                        textAlign: TextAlign.center,
                        style: LuxeType.body(p.inkMuted, size: 13),
                      ),
                    ),
                  for (var i = 0; i < s.items.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: p.hairline),
                    JewelryReviewCard(
                      review: s.items[i],
                      shopName: shopName,
                      showPiece: source == JewelryReviewSource.shop,
                    ),
                  ],
                ],
              ),
            ),
            if (s.error != null && s.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  jewelryReviewError(s.error!),
                  style: LuxeType.body(p.caution, size: 12.5),
                ),
              ),
            if (s.hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: LuxeButton(
                  label: context.tr(JewelryReviewL10n.showMore),
                  variant: LuxeButtonVariant.secondary,
                  height: 42,
                  expand: true,
                  loading: s.loadingMore,
                  onPressed: s.loadingMore ? null : list.loadMore,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Big average with stars, and one bar per star count. Tapping a bar
/// filters by it (tap again to clear).
class JewelryReviewSummaryPanel extends StatelessWidget {
  const JewelryReviewSummaryPanel({
    required this.summary,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final JewelryReviewSummary summary;
  final int? selected;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final avg = summary.average ?? 0;
    final most = summary.breakdown.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 104,
          child: Column(
            children: [
              Text(
                jewelryAverageLabel(avg),
                style: LuxeType.display(40, p.ink),
              ),
              JewelryStars(rating: avg, size: 15),
              const SizedBox(height: 4),
              Text(
                jewelryReviewCount(context, summary.count),
                style: LuxeType.body(p.inkMuted, size: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              for (var star = 5; star >= 1; star--)
                _Bar(
                  star: star,
                  count: summary.breakdown[star] ?? 0,
                  most: most,
                  selected: selected == star,
                  dimmed: selected != null && selected != star,
                  onTap: () => onSelect(star),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.star,
    required this.count,
    required this.most,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final int star;
  final int count;
  final int most;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tone = dimmed ? p.inkFaint : p.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: '$star ★, $count',
      excludeSemantics: true,
      child: InkWell(
        onTap: count == 0 && !selected ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          child: Row(
            children: [
              SizedBox(
                width: 12,
                child: Text('$star', style: LuxeType.label(tone, size: 12)),
              ),
              Icon(Icons.star_rounded, size: 12, color: p.accent),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: most == 0 ? 0 : count / most,
                    minHeight: 7,
                    color: selected || !dimmed ? p.accent : p.inkFaint,
                    backgroundColor: p.surfaceRaised,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 26,
                child: Text(
                  '$count',
                  textAlign: TextAlign.end,
                  style: LuxeType.body(tone, size: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "4-star reviews · Show all" and the sort menu.
class JewelryReviewListBar extends StatelessWidget {
  const JewelryReviewListBar({
    required this.rating,
    required this.sort,
    required this.onClear,
    required this.onSort,
    super.key,
  });

  final int? rating;
  final JewelryReviewSort sort;
  final VoidCallback onClear;
  final ValueChanged<JewelryReviewSort> onSort;

  static String sortLabel(BuildContext context, JewelryReviewSort s) =>
      context.tr(switch (s) {
        JewelryReviewSort.newest => JewelryReviewL10n.sortNewest,
        JewelryReviewSort.highest => JewelryReviewL10n.sortHighest,
        JewelryReviewSort.lowest => JewelryReviewL10n.sortLowest,
      });

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Row(
      children: [
        if (rating != null) ...[
          Flexible(
            child: Text(
              context.tr(JewelryReviewL10n.filtered, {'stars': rating}),
              overflow: TextOverflow.ellipsis,
              style: LuxeType.label(p.ink, size: 12.5),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: p.accent,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(context.tr(JewelryReviewL10n.clearFilter)),
          ),
        ],
        const Spacer(),
        PopupMenuButton<JewelryReviewSort>(
          initialValue: sort,
          onSelected: onSort,
          tooltip: '',
          itemBuilder: (context) => [
            for (final s in JewelryReviewSort.values)
              PopupMenuItem(value: s, child: Text(sortLabel(context, s))),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 16, color: p.inkMuted),
                const SizedBox(width: 4),
                Text(
                  sortLabel(context, sort),
                  style: LuxeType.label(p.ink, size: 12.5),
                ),
                Icon(Icons.arrow_drop_down_rounded, color: p.inkMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
