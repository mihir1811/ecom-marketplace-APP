import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_create_action.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/spotlight_seller_providers.dart';
import '../../domain/spotlight_models.dart';
import '../../domain/spotlight_seller_models.dart';

/// Seller Advertising studio: book paid placements and follow each ad's
/// state, spend, views and clicks.
class SellerSpotlightScreen extends ConsumerWidget {
  const SellerSpotlightScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(sellerSpotlightAdsProvider)
      ..invalidate(spotlightOverviewProvider);
    await Future.wait([
      ref
          .read(sellerSpotlightAdsProvider.future)
          .catchError((_) => const <SpotlightSellerAd>[]),
      ref
          .read(spotlightOverviewProvider.future)
          .then<Object?>((v) => v)
          .catchError((_) => null),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(sellerSpotlightAdsProvider);
    final overview = ref.watch(spotlightOverviewProvider);
    final list = ads.value ?? const <SpotlightSellerAd>[];
    final live = list.where((a) => a.state == SpotlightAdState.live).length;
    final views = list.fold<int>(0, (s, a) => s + a.views);
    final clicks = list.fold<int>(0, (s, a) => s + a.clicks);
    final loaded = ads.hasValue;
    final canBook = overview.value?.canBook ?? false;

    void book() => context.push(AppRouteNames.sellerSpotlightNew);

    return TopBarCreateAction(
      create: TopBarCreate(
        label: 'Book',
        tooltip: 'Book a spotlight',
        icon: Icons.campaign_outlined,
        onPressed: canBook ? book : null,
      ),
      child: AtelierPage(
        onRefresh: () => _refresh(ref),
        children: [
          AtelierHero(
            title: context.tr(SpotlightL10n.advertising),
            footer: AtelierHeroStats(
              stats: [
                AtelierHeroStat(
                  label: 'Live now',
                  value: loaded ? '$live' : '—',
                  caption: '${list.length} booked',
                  tone: live > 0 ? AtelierTone.emerald : null,
                ),
                AtelierHeroStat(
                  label: 'Views',
                  value: loaded ? _compact(views) : '—',
                  caption: 'Across all ads',
                ),
                AtelierHeroStat(
                  label: 'Clicks',
                  value: loaded ? _compact(clicks) : '—',
                  caption: views == 0
                      ? 'No views yet'
                      : '${(clicks / views * 100).toStringAsFixed(1)}% CTR',
                ),
              ],
            ),
          ),
          const SizedBox(height: AtelierSpace.s16),
          overview.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => AtelierNotice(
              text: spotlightErrorText(e),
              tone: AtelierTone.ruby,
              icon: Icons.error_outline_rounded,
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(spotlightOverviewProvider),
            ),
            data: (o) => o.canBook
                ? _BookCard(overview: o, onBook: book)
                : AtelierNotice(
                    text:
                        o.blockedReason ??
                        'Advertising opens once your seller account is verified.',
                    tone: AtelierTone.amber,
                    icon: Icons.lock_outline_rounded,
                  ),
          ),
          const SizedBox(height: AtelierSpace.s24),
          const AtelierSectionHeader(title: 'Your ads'),
          const SizedBox(height: AtelierSpace.s12),
          ...ads.when(
            loading: () => [const AtelierSkeletonList(count: 3, height: 112)],
            error: (e, _) => [
              AtelierErrorState(
                message: spotlightErrorText(e),
                onRetry: () => ref.invalidate(sellerSpotlightAdsProvider),
              ),
            ],
            data: (items) => items.isEmpty
                ? [
                    AtelierEmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'No ads yet',
                      message:
                          'Put your shop or your best pieces in front of '
                          'buyers on the home screen, section pages and '
                          'product pages.',
                      actionLabel: canBook ? 'Book a spotlight' : null,
                      onAction: canBook ? book : null,
                    ),
                  ]
                : [
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AtelierSpace.s12,
                        ),
                        child: Reveal(
                          index: i.clamp(0, 8),
                          child: SpotlightAdTile(
                            ad: items[i],
                            onTap: () => context.push(
                              AppRouteNames.sellerSpotlightDetailPath(
                                items[i].id,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}

String _compact(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return '$v';
}

/// Wallet balance and the way into booking.
class _BookCard extends StatelessWidget {
  const _BookCard({required this.overview, required this.onBook});

  final SpotlightOverview overview;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final open = overview.placements.length;
    return AtelierCard(
      child: Row(
        children: [
          const AtelierIconBadge(icon: Icons.campaign_outlined),
          const SizedBox(width: AtelierSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book a spotlight', style: AtelierType.title(p.ink)),
                const SizedBox(height: 3),
                Text(
                  open == 0
                      ? 'No placement is open for booking right now.'
                      : '$open placements open · wallet '
                            '${maisonInr(overview.availableBalance)}',
                  style: AtelierType.caption(p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AtelierSpace.s8),
          AtelierButton(
            label: 'Book',
            compact: true,
            onPressed: open == 0 ? null : onBook,
          ),
        ],
      ),
    );
  }
}

/// State tone shared by the list and the detail page.
AtelierTone spotlightStateTone(SpotlightAdState s) => switch (s) {
  SpotlightAdState.live => AtelierTone.emerald,
  SpotlightAdState.scheduled => AtelierTone.sapphire,
  SpotlightAdState.pendingReview => AtelierTone.amber,
  SpotlightAdState.rejected || SpotlightAdState.stopped => AtelierTone.ruby,
  _ => AtelierTone.neutral,
};

String spotlightPlacementName(SpotlightSellerAd ad) =>
    ad.placementLabel ??
    switch (ad.placement) {
      SpotlightPlacement.homeBanner => 'Home banner',
      SpotlightPlacement.homeFeaturedSeller => 'Featured seller',
      SpotlightPlacement.categoryBanner => 'Section banner',
      SpotlightPlacement.categorySponsored => 'Sponsored products',
      SpotlightPlacement.productSponsored => 'Product page products',
      SpotlightPlacement.jewelleryHomeBanner => 'Jewellery home banner',
      SpotlightPlacement.jewelleryFeaturedShop => 'Featured shop',
      SpotlightPlacement.jewelleryListingSponsored => 'Sponsored pieces',
      SpotlightPlacement.jewelleryProductSponsored => 'Product page pieces',
      null => 'Spotlight',
    };

String spotlightCategoryName(SpotlightCategory c) => switch (c) {
  SpotlightCategory.diamonds => 'Diamonds',
  SpotlightCategory.gemstones => 'Gemstones',
  SpotlightCategory.jewellery => 'Jewellery',
  SpotlightCategory.watches => 'Watches',
  SpotlightCategory.bullion => 'Bullion',
};

String spotlightRange(DateTime? start, DateTime? end) {
  if (start == null) return '';
  final s = maisonDayLabel(start);
  if (end == null || end == start) return s;
  return '$s – ${maisonDayLabel(end)}';
}

/// One booked ad in the list.
class SpotlightAdTile extends StatelessWidget {
  const SpotlightAdTile({required this.ad, required this.onTap, super.key});

  final SpotlightSellerAd ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final title = ad.title?.trim();
    final heading = (title != null && title.isNotEmpty)
        ? title
        : spotlightPlacementName(ad);
    final image =
        ad.mobileImageUrl ??
        ad.imageUrl ??
        (ad.products.isEmpty ? null : ad.products.first.imageUrl);
    final where = [
      spotlightPlacementName(ad),
      if (ad.category != null) spotlightCategoryName(ad.category!),
    ].join(' · ');

    return AtelierCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AtelierSpace.s12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AtelierRadius.sm),
            child: SizedBox(
              width: 72,
              height: 72,
              child: image == null
                  ? ColoredBox(
                      color: p.sunken,
                      child: Icon(Icons.campaign_outlined, color: p.gold),
                    )
                  : AppNetworkImage(url: image, memCacheWidth: 220),
            ),
          ),
          const SizedBox(width: AtelierSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        heading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.title(p.ink, size: 15),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AtelierPill(
                      label: ad.state.label,
                      tone: spotlightStateTone(ad.state),
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  where,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.caption(p.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  spotlightRange(ad.startDate, ad.endDate),
                  style: AtelierType.caption(p.muted),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: p.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${ad.views}',
                      style: AtelierType.figure(p.inkSoft, size: 12.5),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.ads_click_rounded, size: 14, color: p.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${ad.clicks}',
                      style: AtelierType.figure(p.inkSoft, size: 12.5),
                    ),
                    const Spacer(),
                    Text(
                      maisonInr(ad.netAmount),
                      style: AtelierType.figure(p.ink, size: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
