import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../application/spotlight_providers.dart';
import '../../domain/spotlight_models.dart';
import '../spotlight_navigation.dart';
import 'spotlight_featured_sellers.dart';
import 'spotlight_impression.dart';
import 'spotlight_tag.dart';

/// JEWELLERY_FEATURED_SHOP: the "Featured shops" row on the jewellery home.
/// A tap opens the shop. Draws nothing when no shop ad is running.
class JewelleryFeaturedShops extends ConsumerWidget {
  const JewelleryFeaturedShops({
    super.key,
    this.gutter = 16,
    this.padding = EdgeInsets.zero,
    this.visit,
  });

  final double gutter;
  final EdgeInsets padding;
  final SpotlightVisit? visit;

  static const SpotlightQuery query = (
    placement: SpotlightPlacement.jewelleryFeaturedShop,
    category: null,
    excludeProductId: null,
    limit: null,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = spotlightItemsOf<SpotlightFeaturedShop>(
      ref.watch(spotlightProvider(query)),
    );
    if (shops.isEmpty) return const SizedBox.shrink();
    return _ShopStrip(
      shops: shops,
      gutter: gutter,
      padding: padding,
      visit: visit,
    );
  }
}

class _ShopStrip extends ConsumerStatefulWidget {
  const _ShopStrip({
    required this.shops,
    required this.gutter,
    required this.padding,
    required this.visit,
  });

  final List<SpotlightFeaturedShop> shops;
  final double gutter;
  final EdgeInsets padding;
  final SpotlightVisit? visit;

  @override
  ConsumerState<_ShopStrip> createState() => _ShopStripState();
}

class _ShopStripState extends ConsumerState<_ShopStrip> {
  late final SpotlightVisit _ownVisit = SpotlightVisit();

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit ?? _ownVisit;
    final gutter = widget.gutter;
    final textScaler = MediaQuery.textScalerOf(context);

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LuxeRowHeading(title: context.tr(SpotlightL10n.featuredShops)),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = ((constraints.maxWidth - gutter - 24) / 1.45).clamp(
                230.0,
                320.0,
              );
              final height =
                  JewelleryShopCard.coverHeight(width) +
                  JewelleryShopCard.logoOverhang +
                  textScaler.scale(17 * 1.15) +
                  5 +
                  textScaler.scale(12.5 * 1.3) * 2 +
                  8 +
                  textScaler.scale(11.5 * 1.3) +
                  14;
              return SizedBox(
                height: height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  itemCount: widget.shops.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final ad = widget.shops[i];
                    return SizedBox(
                      width: width,
                      child: SpotlightImpression(
                        adId: ad.adId,
                        visit: visit,
                        child: JewelleryShopCard(
                          ad: ad,
                          onTap: () => openSpotlightShop(
                            context,
                            ref,
                            adId: ad.adId,
                            shopSlug: ad.shop.slug,
                            preview: ad.shop,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 4:1 banner strip, logo, name, tagline, location and piece count, with
/// the Sponsored pill and the ads-blue outline.
class JewelleryShopCard extends StatelessWidget {
  const JewelleryShopCard({required this.ad, required this.onTap, super.key});

  final SpotlightFeaturedShop ad;
  final VoidCallback onTap;

  static const _inset = 5.0;
  static const _logo = 48.0;

  /// The logo hangs this far below the banner strip.
  static const logoOverhang = _logo / 2 + 6;

  static double coverHeight(double cardWidth) =>
      _inset + (cardWidth - _inset * 2) / 4;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final shop = ad.shop;
    final line = ad.line;
    final place = shop.location?.trim();
    final count = shop.listingCount;
    final meta = [
      if (place != null && place.isNotEmpty) _titleCase(place),
      if (count != null && count > 0)
        context.tr(SpotlightL10n.piecesCount, {'count': count}),
    ];

    return LuxeCardFrame(
      onTap: onTap,
      outlineColor: SpotlightColors.blueLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final cover = coverHeight(c.maxWidth);
              return SizedBox(
                height: cover + logoOverhang,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: _inset,
                      right: _inset,
                      top: _inset,
                      height: cover - _inset,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          LuxeSpace.cardRadius - _inset,
                        ),
                        child: SellerCover(url: shop.bannerUrl),
                      ),
                    ),
                    const Positioned(
                      top: _inset + 6,
                      right: _inset + 6,
                      child: SpotlightSponsoredPill(),
                    ),
                    Positioned(
                      left: 12,
                      top: cover - _logo / 2,
                      child: SellerLogo(
                        url: shop.logoUrl,
                        name: shop.name,
                        size: _logo,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.display(
                          17,
                          p.ink,
                        ).copyWith(height: 1.15),
                      ),
                    ),
                    if (shop.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: SpotlightColors.blueLight,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  line ?? ' ',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(
                    p.inkMuted,
                    size: 12.5,
                  ).copyWith(height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (place != null && place.isNotEmpty) ...[
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: p.inkFaint,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        meta.isEmpty ? ' ' : meta.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.label(
                          p.inkFaint,
                          size: 11.5,
                        ).copyWith(height: 1.3),
                      ),
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

  /// "surat" → "Surat".
  static String _titleCase(String s) => s
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
