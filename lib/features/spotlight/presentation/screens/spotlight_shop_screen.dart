import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../../jewelry/domain/models/marketplace_listing.dart';
import '../../../product_detail/domain/models/product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/spotlight_shop_providers.dart';
import '../../domain/spotlight_models.dart';
import '../widgets/spotlight_featured_sellers.dart';

/// A seller's public shop, opened from a featured seller card or a banner
/// that links to the seller: who they are, then what they have for sale in
/// each section, and their jewellery house when they have one.
class SpotlightShopScreen extends ConsumerWidget {
  const SpotlightShopScreen({required this.sellerId, super.key, this.profile});

  final String sellerId;

  /// What the ad already told us about the seller, if anything.
  final SpotlightSellerProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LuxeScope(
      child: Builder(builder: (context) => _build(context, ref)),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final key = (sellerId: sellerId, sellerType: profile?.sellerType);
    final sections = ref.watch(spotlightShopSectionsProvider(key));
    final house = ref.watch(spotlightShopHouseProvider(sellerId)).valueOrNull;
    final loaded = sections.valueOrNull ?? const <SpotlightShopSection>[];

    // A banner link carries only the id: take the name from the listings.
    var name = profile?.name.trim() ?? '';
    if (name.isEmpty) {
      for (final s in loaded) {
        final n = s.items.first.listingSeller?.displayName.trim() ?? '';
        if (n.isNotEmpty && n != 'Seller') {
          name = n;
          break;
        }
      }
    }
    if (name.isEmpty) name = house?.name ?? '';
    final header = SpotlightSellerProfile(
      id: sellerId,
      name: name,
      logoUrl: profile?.logoUrl ?? house?.logoUrl,
      bannerUrl: profile?.bannerUrl ?? house?.bannerUrl,
      sellerType: profile?.sellerType,
      city: profile?.city,
      state: profile?.state,
      rating: profile?.rating,
      reviewCount: profile?.reviewCount ?? 0,
      tagline: profile?.tagline ?? house?.headline,
    );

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: name.isEmpty ? context.tr(SpotlightL10n.shopTitle) : name,
        actions: const [TopBarActions()],
      ),
      body: RefreshIndicator(
        color: p.ink,
        backgroundColor: p.surface,
        onRefresh: () async {
          ref.invalidate(spotlightShopSectionsProvider(key));
          await ref
              .read(spotlightShopSectionsProvider(key).future)
              .catchError((_) => const <SpotlightShopSection>[]);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _ShopHeader(seller: header)),
            if (house != null)
              SliverToBoxAdapter(child: _HouseCard(house: house)),
            ...sections.when(
              loading: () => [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 28, 16, 0),
                    child: LuxeSkeleton(height: 260),
                  ),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: LuxeStateView(
                    icon: Icons.cloud_off_rounded,
                    tone: LuxeTone.error,
                    title: context.tr(SpotlightL10n.shopTitle),
                    message: e.toString(),
                  ),
                ),
              ],
              data: (list) => list.isEmpty
                  ? [
                      if (house == null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: LuxeStateView(
                            icon: Icons.storefront_outlined,
                            title: context.tr(SpotlightL10n.shopEmpty),
                            message: context.tr(SpotlightL10n.shopEmptyBody),
                          ),
                        ),
                    ]
                  : [
                      for (final s in list)
                        SliverToBoxAdapter(child: _ShopSectionRow(section: s)),
                    ],
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 48 + MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.seller});

  final SpotlightSellerProfile seller;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tagline = seller.tagline?.trim();
    final place = seller.place;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final cover = c.maxWidth / 2.6;
              return SizedBox(
                height: cover + 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: cover,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(LuxeSpace.radius),
                        child: SellerCover(url: seller.bannerUrl),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: cover - 40,
                      child: SellerLogo(
                        url: seller.logoUrl,
                        name: seller.name,
                        size: 80,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (seller.name.isNotEmpty)
            Text(seller.name, style: LuxeType.display(30, p.ink)),
          if (tagline != null && tagline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(tagline, style: LuxeType.body(p.inkMuted, size: 14.5)),
          ],
          if (place != null || seller.showsRating) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (place != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: p.inkFaint,
                      ),
                      const SizedBox(width: 4),
                      Text(place, style: LuxeType.label(p.inkMuted)),
                    ],
                  ),
                if (seller.showsRating) SellerRating(seller: seller),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HouseCard extends StatelessWidget {
  const _HouseCard({required this.house});

  final MarketplaceShop house;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: LuxeCardFrame(
        onTap: () => context.push(
          AppRouteNames.jewelryHousePath(house.slug),
          extra: house,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: p.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(SpotlightL10n.jewelleryHouse).toUpperCase(),
                      style: LuxeType.eyebrow(p.accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      house.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.display(18, p.ink),
                    ),
                  ],
                ),
              ),
              Text(
                context.tr(SpotlightL10n.openJewelleryHouse),
                style: LuxeType.label(p.accent),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 16, color: p.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Heading with the section's count, then a horizontal strip of pieces.
class _ShopSectionRow extends StatelessWidget {
  const _ShopSectionRow({required this.section});

  final SpotlightShopSection section;

  static String _titleKey(ProductSegment s) => switch (s) {
    ProductSegment.naturalDiamond => SpotlightL10n.naturalDiamonds,
    ProductSegment.labGrownDiamond => SpotlightL10n.labGrownDiamonds,
    ProductSegment.gemstone => SpotlightL10n.gemstones,
    ProductSegment.jewelry => SpotlightL10n.jewelleryHouse,
    ProductSegment.watch => SpotlightL10n.watches,
    ProductSegment.bullion => SpotlightL10n.bullion,
  };

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final width = ((MediaQuery.sizeOf(context).width - 16 - 24) / 2.3).clamp(
      140.0,
      210.0,
    );
    final textBlock =
        12 +
        scaler.scale(15 * 1.1) +
        4 +
        scaler.scale(12 * 1.25) +
        10 +
        scaler.scale(14 * 1.2) +
        14;
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    context.tr(_titleKey(section.segment)),
                    style: LuxeType.display(22, p.ink),
                  ),
                ),
                Text(
                  '${section.totalCount}',
                  style: LuxeType.figure(p.inkMuted, size: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: width + textBlock,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: section.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final d = section.items[i];
                return SizedBox(
                  width: width,
                  child: _ShopProductCard(
                    detail: d,
                    onTap: () => openProductDetail(context, d),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  const _ShopProductCard({required this.detail, required this.onTap});

  final ProductDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final shape = (detail.shapeKey ?? detail.media.shapeKey)?.trim();
    final fallback = ColoredBox(
      color: p.surfaceRaised,
      child: Center(
        child: shape != null && shape.isNotEmpty
            ? renderShapeSvg(shape, size: 52, color: p.accent)
            : Icon(detail.media.fallbackIcon, size: 40, color: p.accent),
      ),
    );
    final url = detail.media.firstNetworkUrl;
    return LuxeCardFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LuxeSpace.radius - 5),
                child: url == null
                    ? fallback
                    : AppNetworkImage(
                        url: url,
                        memCacheWidth: 440,
                        error: fallback,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.display(15, p.ink).copyWith(height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  detail.subtitle.trim().isEmpty ? ' ' : detail.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.inkMuted, size: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  detail.price.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.figure(
                    p.ink,
                    size: 14,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
