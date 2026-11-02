import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../jewelry/application/jewelry_catalogue_providers.dart';
import '../../jewelry/domain/models/marketplace_listing.dart';
import '../../product_detail/data/repositories/suggested_seller_products_repository_impl.dart';
import '../../product_detail/domain/models/product_detail.dart';

/// One catalogue section of a seller's shop.
class SpotlightShopSection {
  const SpotlightShopSection({
    required this.segment,
    required this.items,
    required this.totalCount,
  });

  final ProductSegment segment;
  final List<ProductDetail> items;
  final int totalCount;
}

/// Segments a seller's shop lists, with [sellerType] (from a featured
/// seller ad) first. Jewellery lives in the seller's jewellery house.
List<ProductSegment> spotlightShopSegments(String? sellerType) {
  const all = [
    ProductSegment.naturalDiamond,
    ProductSegment.labGrownDiamond,
    ProductSegment.gemstone,
    ProductSegment.watch,
    ProductSegment.bullion,
  ];
  final first = switch (sellerType) {
    'naturalDiamond' => ProductSegment.naturalDiamond,
    'labGrownDiamond' => ProductSegment.labGrownDiamond,
    'gemstone' => ProductSegment.gemstone,
    'watch' => ProductSegment.watch,
    'bullion' => ProductSegment.bullion,
    _ => null,
  };
  if (first == null) return all;
  return [first, ...all.where((s) => s != first)];
}

/// Pieces a seller has for sale, per section; empty sections are left out.
final spotlightShopSectionsProvider = FutureProvider.autoDispose
    .family<List<SpotlightShopSection>, ({String sellerId, String? sellerType})>(
      (ref, key) async {
        final repo = ref.read(suggestedSellerProductsRepositoryProvider);
        final segments = spotlightShopSegments(key.sellerType);
        final pages = await Future.wait([
          for (final segment in segments)
            repo.getPage(
              segment: segment,
              excludeProductId: '',
              sellerId: key.sellerId,
              page: 1,
              pageSize: 12,
            ),
        ]);
        return [
          for (var i = 0; i < segments.length; i++)
            if (pages[i] case Success(:final value) when value.items.isNotEmpty)
              SpotlightShopSection(
                segment: segments[i],
                items: value.items,
                totalCount: value.totalCount,
              ),
        ];
      },
    );

/// The seller's jewellery house on the marketplace, when they have one.
final spotlightShopHouseProvider = FutureProvider.autoDispose
    .family<MarketplaceShop?, String>((ref, sellerId) async {
      try {
        final shops = await ref.watch(jewelryShopsProvider.future);
        for (final shop in shops) {
          if (shop.sellerId == sellerId && shop.slug.isNotEmpty) return shop;
        }
      } catch (_) {
        // No house link when the marketplace can't be reached.
      }
      return null;
    });
