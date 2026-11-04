import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../application/spotlight_providers.dart';
import '../../domain/spotlight_models.dart';
import '../spotlight_navigation.dart';
import 'spotlight_impression.dart';
import 'spotlight_tag.dart';

/// HOME_FEATURED_SELLER: a row of seller cards. Shown to everyone (seller
/// pages are public); a tap opens the seller's shop.
class SpotlightFeaturedSellers extends ConsumerStatefulWidget {
  const SpotlightFeaturedSellers({
    super.key,
    this.gutter = 16,
    this.padding = EdgeInsets.zero,
    this.heading,
  });

  final double gutter;
  final EdgeInsets padding;

  /// Replaces the default heading text style (e.g. the home serif).
  final Widget Function(String title, Widget tag)? heading;

  @override
  ConsumerState<SpotlightFeaturedSellers> createState() =>
      _SpotlightFeaturedSellersState();
}

class _SpotlightFeaturedSellersState
    extends ConsumerState<SpotlightFeaturedSellers> {
  final _visit = SpotlightVisit();

  static const SpotlightQuery _query = (
    placement: SpotlightPlacement.homeFeaturedSeller,
    category: null,
    excludeProductId: null,
    limit: null,
  );

  @override
  Widget build(BuildContext context) {
    final sellers = spotlightItemsOf<SpotlightFeaturedSeller>(
      ref.watch(spotlightProvider(_query)),
    );
    if (sellers.isEmpty) return const SizedBox.shrink();

    final p = LuxePalette.of(context);
    final gutter = widget.gutter;
    final title = context.tr(SpotlightL10n.featuredSellers);
    const tag = SpotlightTag();
    final textScaler = MediaQuery.textScalerOf(context);

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child:
                widget.heading?.call(title, tag) ??
                Row(
                  children: [
                    Flexible(
                      child: Text(title, style: LuxeType.display(22, p.ink)),
                    ),
                    const SizedBox(width: 8),
                    tag,
                  ],
                ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = ((constraints.maxWidth - gutter - 24) / 1.6).clamp(
                220.0,
                300.0,
              );
              final height =
                  width * 0.42 +
                  30 +
                  textScaler.scale(17 * 1.1) +
                  6 +
                  textScaler.scale(12.5 * 1.25) * 2 +
                  8 +
                  textScaler.scale(11.5 * 1.25) +
                  18;
              return SizedBox(
                height: height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  itemCount: sellers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final ad = sellers[i];
                    return SizedBox(
                      width: width,
                      child: SpotlightImpression(
                        adId: ad.adId,
                        visit: _visit,
                        child: SpotlightSellerCard(
                          seller: ad.seller,
                          onTap: () => openSpotlightSeller(
                            context,
                            ref,
                            adId: ad.adId,
                            sellerId: ad.seller.id,
                            profile: ad.seller,
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

/// Cover strip, logo, name, tagline, place and rating.
class SpotlightSellerCard extends StatelessWidget {
  const SpotlightSellerCard({
    required this.seller,
    required this.onTap,
    super.key,
  });

  final SpotlightSellerProfile seller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tagline = seller.tagline?.trim();
    final place = seller.place;

    return LuxeCardFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final coverHeight = c.maxWidth * 0.42;
              return SizedBox(
                height: coverHeight + 30,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 5,
                      right: 5,
                      top: 5,
                      height: coverHeight - 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          LuxeSpace.radius - 5,
                        ),
                        child: SellerCover(url: seller.bannerUrl),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: coverHeight - 26,
                      child: SellerLogo(
                        url: seller.logoUrl,
                        name: seller.name,
                        size: 52,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.display(17, p.ink).copyWith(height: 1.1),
                ),
                const SizedBox(height: 5),
                Text(
                  (tagline == null || tagline.isEmpty) ? ' ' : tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.inkMuted, size: 12.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (place != null) ...[
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: p.inkFaint,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.label(p.inkFaint, size: 11.5),
                        ),
                      ),
                    ],
                    if (place != null && seller.showsRating)
                      const SizedBox(width: 8),
                    if (seller.showsRating) SellerRating(seller: seller),
                    if (place == null && !seller.showsRating)
                      Text(' ', style: LuxeType.label(p.inkFaint, size: 11.5)),
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

/// Seller banner, or a soft gradient when the seller has none.
class SellerCover extends StatelessWidget {
  const SellerCover({required this.url, super.key});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.accentSoft, p.surfaceRaised],
        ),
      ),
    );
    final u = url;
    if (u == null || u.isEmpty) return fallback;
    return AppNetworkImage(url: u, memCacheWidth: 700, error: fallback);
  }
}

/// Round seller logo, or the name's initial.
class SellerLogo extends StatelessWidget {
  const SellerLogo({
    required this.url,
    required this.name,
    super.key,
    this.size = 48,
  });

  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();
    final monogram = Center(
      child: Text(initial, style: LuxeType.display(size * 0.42, p.accent)),
    );
    final u = url;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.surface,
        border: Border.all(color: p.surface, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: u == null || u.isEmpty
            ? ColoredBox(color: p.accentSoft, child: monogram)
            : AppNetworkImage(url: u, memCacheWidth: 200, error: monogram),
      ),
    );
  }
}

/// Star, average and review count.
class SellerRating extends StatelessWidget {
  const SellerRating({required this.seller, super.key});

  final SpotlightSellerProfile seller;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE0A526)),
        const SizedBox(width: 2),
        Text(
          seller.rating!.toStringAsFixed(1),
          style: LuxeType.figure(p.ink, size: 12),
        ),
        const SizedBox(width: 4),
        Text(
          '(${seller.reviewCount})',
          style: LuxeType.label(p.inkFaint, size: 11),
        ),
      ],
    );
  }
}
