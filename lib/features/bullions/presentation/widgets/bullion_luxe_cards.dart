import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/catalog_card_image_pager.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../catalog_flow/presentation/widgets/catalog_card_actions.dart';
import '../../../product_detail/domain/adapters/bullion_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../domain/models/billion.dart';

String bullionMetalLabel(BullionMetal metal) => switch (metal) {
  BullionMetal.gold => 'Gold',
  BullionMetal.silver => 'Silver',
  BullionMetal.platinum => 'Platinum',
  BullionMetal.palladium => 'Palladium',
  BullionMetal.copper => 'Copper',
};

/// Accent tone per metal, shared by cards and the metal presets.
Color bullionMetalTone(BullionMetal? metal) => switch (metal) {
  BullionMetal.gold => const Color(0xFFD8AE4A),
  BullionMetal.silver => const Color(0xFF9AA8BD),
  BullionMetal.platinum => const Color(0xFFBFB49C),
  BullionMetal.palladium => const Color(0xFF7FA6C9),
  BullionMetal.copper => const Color(0xFFC9814F),
  null => const Color(0xFF9C7A45),
};

String _join(Iterable<String> parts) =>
    parts.where((p) => p.trim().isNotEmpty).join(' · ');

String? _purity(Bullion b) => b.purity > 0
    ? '${b.purity.toStringAsFixed(1)} fine'
    : (b.presetVariant.isNotEmpty ? b.presetVariant : null);

/// "1 oz Gold · 999.9 fine".
String _grades(Bullion b) => _join([
  '${b.weightLabel} ${bullionMetalLabel(b.metal)}'.trim(),
  ?_purity(b),
]);

/// "Bar · PAMP · BU".
String _meta(Bullion b) => _join([b.shape, b.mintMark, b.condition]);

Widget _thumb(BuildContext context, Bullion b) {
  final p = LuxePalette.of(context);
  final tone = bullionMetalTone(b.metal);
  final fallback = ColoredBox(
    color: p.surfaceRaised,
    child: Center(
      child: Container(
        width: 58,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(tone, Colors.white, 0.45)!,
              tone,
              Color.lerp(tone, Colors.black, 0.2)!,
            ],
          ),
        ),
      ),
    ),
  );
  return CatalogCardImagePager(
    imageUrls: catalogListingImageUrls(
      imageUrl: b.imageUrl,
      imageUrls: b.imageUrls,
    ),
    fallback: fallback,
    memCacheWidth: 480,
  );
}

CatalogSaveButton _save(Bullion b, {bool onLight = false}) => CatalogSaveButton(
  item: WishlistItem.fromBullion(b),
  onAdded: () => rememberProductDetail(bullionProductDetail(b)),
  onLight: onLight,
);

/// Two-column bullion result card.
class BullionLuxeGridCard extends ConsumerWidget {
  const BullionLuxeGridCard({
    required this.bullion,
    required this.onTap,
    super.key,
  });

  final Bullion bullion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = bullion;
    return LuxeProductGridCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(b.id)),
      media: _thumb(context, b),
      title: b.name,
      subtitle: _grades(b),
      meta: _meta(b),
      price: LuxePriceRow(price: b.price),
      overlays: LuxeMediaOverlays(
        topLeft: AvailabilityStatusBadge(status: b.availability),
        topRight: _save(b),
      ),
    );
  }
}

/// Full-width bullion result row.
class BullionLuxeListCard extends ConsumerWidget {
  const BullionLuxeListCard({
    required this.bullion,
    required this.onTap,
    super.key,
  });

  final Bullion bullion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = bullion;
    return LuxeProductListCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(b.id)),
      media: _thumb(context, b),
      title: b.name,
      subtitle: _grades(b),
      detail: _join([_meta(b), if (b.mintYear != null) '${b.mintYear}']),
      price: LuxePriceRow(price: b.price),
      titleAction: _save(b, onLight: true),
      thumbTopLeft: AvailabilityStatusBadge(status: b.availability),
    );
  }
}
