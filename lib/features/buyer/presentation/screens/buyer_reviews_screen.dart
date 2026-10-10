import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../seller/application/seller_reviews_provider.dart';
import '../../../seller/domain/models/seller_review.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';
import '../widgets/reviews/buyer_review_card.dart';
import '../widgets/reviews/review_ledger.dart';

enum _ReviewLens {
  all('All'),
  replied('Replied'),
  photos('With photos'),
  hidden('Hidden');

  const _ReviewLens(this.label);
  final String label;

  bool matches(SellerReview r) => switch (this) {
    _ReviewLens.all => true,
    _ReviewLens.replied => r.sellerReply?.trim().isNotEmpty == true,
    _ReviewLens.photos => r.imageUrls.isNotEmpty,
    _ReviewLens.hidden => !r.isVisible,
  };
}

enum _ReviewSort {
  newest('Newest first'),
  oldest('Oldest first'),
  highest('Highest rated'),
  lowest('Lowest rated');

  const _ReviewSort(this.label);
  final String label;
}

/// Every review the buyer has left for a seller: their average and
/// rating spread up top (bars filter by stars), then the reviews by month
/// with seller replies, photos and a way back to each order.
class BuyerReviewsScreen extends ConsumerStatefulWidget {
  const BuyerReviewsScreen({super.key});

  @override
  ConsumerState<BuyerReviewsScreen> createState() => _BuyerReviewsScreenState();
}

class _BuyerReviewsScreenState extends ConsumerState<BuyerReviewsScreen> {
  final _search = TextEditingController();
  _ReviewLens _lens = _ReviewLens.all;
  _ReviewSort _sort = _ReviewSort.newest;
  int? _rating;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(mySellerReviewsProvider);
    try {
      await ref.read(mySellerReviewsProvider.future);
    } catch (_) {
      // The error surfaces through the provider state.
    }
  }

  Future<void> _pickSort() async {
    final sort = await showAtelierOptions<_ReviewSort>(
      context: context,
      title: 'Sort reviews',
      options: [
        for (final s in _ReviewSort.values)
          AtelierOption(
            value: s,
            label: s.label,
            selected: s == _sort,
            icon: switch (s) {
              _ReviewSort.newest => Icons.south_rounded,
              _ReviewSort.oldest => Icons.north_rounded,
              _ReviewSort.highest => Icons.star_rounded,
              _ReviewSort.lowest => Icons.star_outline_rounded,
            },
          ),
      ],
    );
    if (sort != null && mounted) setState(() => _sort = sort);
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _lens = _ReviewLens.all;
      _rating = null;
    });
  }

  void _openOrder(SellerReview review) =>
      context.openRoute(AppRouteNames.buyerOrderDetailPath(review.orderId));

  List<SellerReview> _view(List<SellerReview> reviews) {
    final q = _search.text.trim().toLowerCase();
    final out = [
      for (final r in reviews)
        if (_lens.matches(r) &&
            (_rating == null || r.rating.clamp(1, 5) == _rating) &&
            (q.isEmpty ||
                (r.sellerName ?? '').toLowerCase().contains(q) ||
                (r.title ?? '').toLowerCase().contains(q) ||
                (r.comment ?? '').toLowerCase().contains(q) ||
                r.orderId.toLowerCase().contains(q) ||
                maisonShortId(r.orderId).toLowerCase().contains(q)))
          r,
    ];
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    int byDate(SellerReview a, SellerReview b) =>
        (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch);
    switch (_sort) {
      case _ReviewSort.newest:
        out.sort(byDate);
      case _ReviewSort.oldest:
        out.sort((a, b) => byDate(b, a));
      case _ReviewSort.highest:
        out.sort((a, b) {
          final c = b.rating.compareTo(a.rating);
          return c != 0 ? c : byDate(a, b);
        });
      case _ReviewSort.lowest:
        out.sort((a, b) {
          final c = a.rating.compareTo(b.rating);
          return c != 0 ? c : byDate(a, b);
        });
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final async = ref.watch(mySellerReviewsProvider);
    final reviews = async.valueOrNull ?? const <SellerReview>[];
    final lenses = [
      for (final l in _ReviewLens.values)
        if (l != _ReviewLens.hidden || reviews.any(l.matches)) l,
    ];
    // "Hidden" disappears once nothing is hidden; fall back to All.
    final lens = lenses.contains(_lens) ? _lens : _ReviewLens.all;
    if (lens != _lens) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _lens = _ReviewLens.all);
      });
    }
    final visible = _view(reviews);
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);

    return MaisonLayout(
      detail: true,
      child: RefreshIndicator(
        color: p.gold,
        backgroundColor: p.surface,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 18),
              sliver: SliverToBoxAdapter(
                child: MaisonCentered(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MaisonHeader(
                        title: context.tr(AccountCommerceL10n.myReviews),
                        cut: GemCut.radiant,
                        look: GemLook.champagne,
                      ),
                      if (reviews.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Reveal(
                          index: 3,
                          child: ReviewLedgerCard(
                            reviews: reviews,
                            selectedRating: _rating,
                            onRating: (r) => setState(() => _rating = r),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (reviews.isNotEmpty)
              MaisonPinnedBar(
                height: 124,
                gutter: gutter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AtelierSegmented<_ReviewLens>(
                      dense: true,
                      segments: [
                        for (final l in lenses)
                          AtelierSegment(
                            value: l,
                            label: l == _ReviewLens.all
                                ? context.tr(RemainingL10n.all)
                                : l.label,
                            icon: switch (l) {
                              _ReviewLens.all => null,
                              _ReviewLens.replied => Icons.reply_rounded,
                              _ReviewLens.photos =>
                                Icons.photo_library_outlined,
                              _ReviewLens.hidden =>
                                Icons.visibility_off_outlined,
                            },
                            count: reviews.where(l.matches).length,
                          ),
                      ],
                      selected: lens,
                      onChanged: (l) => setState(() => _lens = l),
                    ),
                    const SizedBox(height: 12),
                    MaisonSearchRow(
                      controller: _search,
                      hint: 'Search seller, words or order no.',
                      onChanged: (_) => setState(() {}),
                      sortLabel: _sort.label,
                      sortActive: _sort != _ReviewSort.newest,
                      onSort: _pickSort,
                    ),
                  ],
                ),
              ),
            MaisonRefreshHairline(
              visible: async.isLoading && reviews.isNotEmpty,
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 40),
              sliver: SliverToBoxAdapter(
                child: MaisonCentered(
                  maxWidth: 760,
                  child: _body(context, async, reviews, visible),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AsyncValue<List<SellerReview>> async,
    List<SellerReview> reviews,
    List<SellerReview> visible,
  ) {
    final error = async.error;
    final errorText = error is Failure
        ? error.message
        : context.tr(AccountCommerceL10n.reviewsLoadFailed);

    if (reviews.isEmpty && async.isLoading) {
      return const Column(
        children: [
          SkeletonBox(height: 168, radius: AtelierRadius.lg),
          SizedBox(height: 18),
          BuyerReviewSkeleton(),
          SizedBox(height: 14),
          BuyerReviewSkeleton(),
        ],
      );
    }
    if (reviews.isEmpty && async.hasError) {
      return AtelierErrorState(
        title: 'Reviews unavailable',
        message: errorText,
        onRetry: _refresh,
      );
    }
    if (reviews.isEmpty) {
      return MaisonEmptyState(
        cut: GemCut.radiant,
        title: context.tr(AccountCommerceL10n.noReviews),
        message:
            'Once an order is paid you can rate the atelier behind it — '
            'your words guide other collectors.',
        actionLabel: context.tr(AccountCommerceL10n.viewOrders),
        actionIcon: Icons.arrow_forward_rounded,
        onAction: () => context.switchToRoute(AppRouteNames.buyerOrders),
      );
    }

    final children = <Widget>[];
    if (async.hasError && !async.isLoading) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: AtelierNotice(
            text: 'Showing your last loaded reviews — $errorText',
            tone: AtelierTone.ruby,
            icon: Icons.cloud_off_rounded,
            actionLabel: context.tr(AccountCommerceL10n.retry),
            onAction: _refresh,
          ),
        ),
      );
    }
    children.add(
      AnimatedSize(
        duration: AtelierMotion.base,
        curve: AtelierMotion.emphasized,
        alignment: Alignment.topCenter,
        child: _rating == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: _RatingFilterChip(
                  rating: _rating!,
                  count: visible.length,
                  onClear: () => setState(() => _rating = null),
                ),
              ),
      ),
    );

    if (visible.isEmpty) {
      final q = _search.text.trim();
      children.add(
        AtelierEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No matches',
          message: q.isNotEmpty
              ? 'None of your reviews mention “$q”.'
              : 'No reviews fit these filters.',
          actionLabel: 'Clear filters',
          onAction: _clearFilters,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    final byMonth = _sort == _ReviewSort.newest || _sort == _ReviewSort.oldest;
    String? month;
    for (var i = 0; i < visible.length; i++) {
      final review = visible[i];
      if (byMonth) {
        final label = maisonMonthLabel(review.createdAt);
        if (label != month) {
          month = label;
          children.add(
            MaisonGroupLabel(
              label: label,
              count: visible
                  .where((r) => maisonMonthLabel(r.createdAt) == label)
                  .length,
            ),
          );
        }
      } else if (i == 0) {
        children.add(const SizedBox(height: 10));
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Reveal(
            key: ValueKey('review-${review.id}'),
            index: i < 8 ? i : 0,
            child: BuyerReviewCard(
              review: review,
              onOpenOrder: () => _openOrder(review),
            ),
          ),
        ),
      );
    }
    children.add(
      MaisonListFooter(
        loadingMore: false,
        hasMore: false,
        onLoadMore: _refresh,
        endLabel: visible.length == reviews.length
            ? 'Every review you’ve written'
            : '${visible.length} of ${reviews.length} reviews shown',
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _RatingFilterChip extends StatelessWidget {
  const _RatingFilterChip({
    required this.rating,
    required this.count,
    required this.onClear,
  });

  final int rating;
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      children: [
        Flexible(
          child: Pressable(
            onTap: onClear,
            scale: 0.95,
            semanticLabel: 'Clear $rating star filter',
            borderRadius: BorderRadius.circular(AtelierRadius.pill),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(AtelierRadius.pill),
                border: Border.all(color: p.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReviewStars(rating: rating.toDouble(), size: 12),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$count ${count == 1 ? 'review' : 'reviews'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.label(p.ink, size: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.close_rounded, size: 15, color: p.inkSoft),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
