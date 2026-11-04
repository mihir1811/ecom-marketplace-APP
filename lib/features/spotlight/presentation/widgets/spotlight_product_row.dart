import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../application/spotlight_providers.dart';
import '../../domain/spotlight_models.dart';
import '../spotlight_navigation.dart';
import 'spotlight_impression.dart';
import 'spotlight_tag.dart';

/// "Sponsored" row of advertised products (CATEGORY_SPONSORED,
/// PRODUCT_SPONSORED). The heading carries the Sponsored tag; the whole
/// block, heading and [padding] included, is skipped when nothing is live.
class SpotlightProductRow extends ConsumerWidget {
  const SpotlightProductRow({
    required this.query,
    required this.titleKey,
    super.key,
    this.gutter = 16,
    this.padding = EdgeInsets.zero,
    this.visit,
  });

  final SpotlightQuery query;

  /// Localization key of the row heading.
  final String titleKey;

  /// Leading inset of the heading and first card; the strip runs on to the
  /// trailing edge so the next card peeks in.
  final double gutter;
  final EdgeInsets padding;
  final SpotlightVisit? visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = spotlightItemsOf<SpotlightSponsoredProduct>(
      ref.watch(spotlightProvider(query)),
    );
    if (items.isEmpty) return const SizedBox.shrink();
    return _SpotlightProductStrip(
      items: items,
      title: context.tr(titleKey),
      gutter: gutter,
      padding: padding,
      visit: visit,
    );
  }
}

class _SpotlightProductStrip extends ConsumerStatefulWidget {
  const _SpotlightProductStrip({
    required this.items,
    required this.title,
    required this.gutter,
    required this.padding,
    required this.visit,
  });

  final List<SpotlightSponsoredProduct> items;
  final String title;
  final double gutter;
  final EdgeInsets padding;
  final SpotlightVisit? visit;

  @override
  ConsumerState<_SpotlightProductStrip> createState() =>
      _SpotlightProductStripState();
}

class _SpotlightProductStripState
    extends ConsumerState<_SpotlightProductStrip> {
  late final SpotlightVisit _ownVisit = SpotlightVisit();

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
    final visit = widget.visit ?? _ownVisit;
    final gutter = widget.gutter;
    final textScaler = MediaQuery.textScalerOf(context);

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.display(22, p.ink),
                  ),
                ),
                const SizedBox(width: 8),
                const SpotlightTag(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth =
                  ((constraints.maxWidth - gutter - _gap * 2) / 2.3).clamp(
                    140.0,
                    210.0,
                  );
              final textBlock =
                  14 +
                  textScaler.scale(15 * 1.1) +
                  4 +
                  textScaler.scale(12 * 1.25) +
                  (signedIn ? 2 + textScaler.scale(11 * 1.25) : 0) +
                  10 +
                  textScaler.scale(14 * 1.2) +
                  16;
              return SizedBox(
                height: cardWidth + textBlock,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  itemCount: widget.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) {
                    final item = widget.items[i];
                    return SizedBox(
                      width: cardWidth,
                      child: SpotlightImpression(
                        adId: item.adId,
                        visit: visit,
                        child: SpotlightProductCard(
                          item: item,
                          showSeller: signedIn,
                          onTap: () => openSpotlightProduct(
                            context,
                            ref,
                            adId: item.adId,
                            productType: item.product.productType,
                            productId: item.product.productId,
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

/// One advertised product: photo (or the shape drawing), title, subtitle,
/// the seller for signed-in shoppers, and the dollar price.
class SpotlightProductCard extends StatelessWidget {
  const SpotlightProductCard({
    required this.item,
    required this.onTap,
    required this.showSeller,
    super.key,
  });

  final SpotlightSponsoredProduct item;
  final VoidCallback onTap;
  final bool showSeller;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final product = item.product;
    final subtitle = product.subtitle?.trim();
    final sellerName = item.seller?.name.trim();
    final price = product.price;

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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _SpotlightProductImage(product: product),
                    if (product.isOnAuction)
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: ShapeDecoration(
                            color: p.caution,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            context.tr(SpotlightL10n.onAuction),
                            style: LuxeType.label(Colors.white, size: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.display(15, p.ink).copyWith(height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  (subtitle == null || subtitle.isEmpty) ? ' ' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.inkMuted, size: 12),
                ),
                if (showSeller) ...[
                  const SizedBox(height: 2),
                  Text(
                    (sellerName == null || sellerName.isEmpty)
                        ? ' '
                        : sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.inkFaint, size: 11),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  price == null
                      ? context.tr(SpotlightL10n.priceOnRequest)
                      : '\$${formatGroupedWhole(price)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: price == null
                      ? LuxeType.label(p.inkMuted, size: 13)
                      : LuxeType.figure(
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

/// The photo, or the app's drawing for the listing's shape when there is
/// no photo or it fails to load.
class _SpotlightProductImage extends StatelessWidget {
  const _SpotlightProductImage({required this.product});

  final SpotlightProduct product;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final shape = product.shape?.trim();
    final fallback = ColoredBox(
      color: p.surfaceRaised,
      child: Center(
        child: shape != null && shape.isNotEmpty
            ? renderShapeSvg(shape, size: 52, color: p.accent)
            : Icon(_iconFor(product.productType), size: 40, color: p.accent),
      ),
    );
    final url = product.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return AppNetworkImage(url: url, memCacheWidth: 440, error: fallback);
  }

  static IconData _iconFor(String productType) => switch (productType) {
    'watch' => Icons.watch_outlined,
    'bullion' => Icons.view_agenda_outlined,
    'jewellery' => Icons.auto_awesome_outlined,
    _ => Icons.diamond_outlined,
  };
}
