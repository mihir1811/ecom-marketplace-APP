import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../domain/models/marketplace_listing.dart';
import 'jewelry_house_parts.dart';

/// Always-dark stage for the jewelry houses: the featured houses in a
/// swipeable row with a link to every house.
class JewelryShowcaseStage extends ConsumerWidget {
  const JewelryShowcaseStage({
    required this.topInset,
    required this.onOpenHouse,
    required this.onShowAll,
    super.key,
  });

  static const _featuredCount = 5;

  /// Space reserved for the floating header.
  final double topInset;
  final ValueChanged<MarketplaceShop> onOpenHouse;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ref.watch(jewelryShopsProvider);

    return Stack(
      children: [
        const Positioned.fill(child: JewelryStageBackdrop()),
        Padding(
          // Room at the bottom for the search that floats over the edge.
          padding: EdgeInsets.only(top: topInset, bottom: 64),
          child: shops.when(
            skipLoadingOnRefresh: false,
            loading: () => const _StageSkeleton(),
            error: (error, _) => JewelryStageMessage(
              icon: Icons.cloud_off_rounded,
              title: context.tr(CatalogFlowL10n.errorTitle),
              message: error is Failure
                  ? error.message
                  : context.tr(JewelryFlowL10n.housesError),
              actionLabel: context.tr(CatalogL10n.retry),
              onAction: () => ref.invalidate(jewelryShopsProvider),
            ),
            data: (all) => all.isEmpty
                ? JewelryStageMessage(
                    icon: Icons.storefront_outlined,
                    title: context.tr(JewelryFlowL10n.housesEmpty),
                    message: context.tr(JewelryFlowL10n.housesEmptyBody),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 22,
                              height: 1,
                              color: LuxeStage.gold,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context
                                    .tr(JewelryFlowL10n.houseEyebrow)
                                    .toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LuxeType.eyebrow(LuxeStage.gold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            JewelryStageChip(
                              label: context.tr(JewelryFlowL10n.showAllHouses),
                              trailingIcon: Icons.arrow_forward_rounded,
                              selected: false,
                              onTap: onShowAll,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FeaturedRow(
                        houses: JewelryHouses.ranked(
                          all,
                        ).take(_featuredCount).toList(),
                        onOpen: onOpenHouse,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Swipeable featured houses: banner, logo, name and piece count.
class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({required this.houses, required this.onOpen});

  final List<MarketplaceShop> houses;
  final ValueChanged<MarketplaceShop> onOpen;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = math.min(width * 0.78, 340.0);
    return SizedBox(
      height: cardWidth * 0.82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: houses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: houses.length == 1 ? width - 32 : cardWidth,
          child: _FeaturedCard(
            house: houses[i],
            onTap: () => onOpen(houses[i]),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.house, required this.onTap});

  final MarketplaceShop house;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final banner = house.bannerUrl;
    final city = JewelryHouses.cityOf(house);
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LuxeStage.raised, LuxeStage.obsidian],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.diamond_outlined,
          size: 40,
          color: LuxeStage.gold.withValues(alpha: 0.5),
        ),
      ),
    );

    return PressTilt(
      semanticLabel: house.name,
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LuxeSpace.radius),
          border: Border.all(color: LuxeStage.glassBorder),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            banner == null
                ? placeholder
                : AppNetworkImage(url: banner, error: placeholder),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x26000000),
                    Color(0xD9000000),
                  ],
                  stops: [0.25, 0.5, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: ShapeDecoration(
                  color: LuxeStage.obsidian.withValues(alpha: 0.6),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: LuxeStage.gold.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 12, color: LuxeStage.gold),
                    const SizedBox(width: 4),
                    Text(
                      context.tr(JewelryFlowL10n.sortFeatured).toUpperCase(),
                      style: LuxeType.eyebrow(
                        LuxeStage.gold,
                      ).copyWith(fontSize: 9, letterSpacing: 1.8),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  JewelryHouseLogo(house: house, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          house.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.display(24, LuxeStage.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            context.tr(JewelryMarketL10n.shopPieces, {
                              'count': house.listingCount ?? 0,
                            }),
                            ?city,
                          ].join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.label(LuxeStage.inkMuted, size: 12),
                        ),
                      ],
                    ),
                  ),
                  const JewelryHouseArrow(size: 34),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass placeholders shaped like the heading and featured row.
class _StageSkeleton extends StatelessWidget {
  const _StageSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = math.min(width * 0.78, 340.0);
    Widget block(double? w, double h, [double r = 8]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: LuxeStage.glass,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    final skeleton = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [block(120, 10)],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: cardWidth * 0.82,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              block(cardWidth, cardWidth * 0.82, LuxeSpace.radius),
              const SizedBox(width: 12),
              block(cardWidth, cardWidth * 0.82, LuxeSpace.radius),
            ],
          ),
        ),
      ],
    );

    if (MediaQuery.disableAnimationsOf(context)) return skeleton;
    return skeleton
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.55, end: 1, duration: 900.ms);
  }
}
