import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/jewelry_repository_impl.dart';
import '../domain/models/jewelry.dart';
import '../domain/models/jewelry_filter_state.dart';
import '../domain/models/marketplace_listing.dart';

/// The parts of the filters that narrow facet counts.
typedef JewelryFacetKey = ({
  String search,
  String? category,
  String? shop,
  String? tag,
});

JewelryFacetKey jewelryFacetKeyOf(JewelryFilterState f) => (
  search: f.searchQuery.trim(),
  category: f.categorySlug,
  shop: f.shop,
  tag: f.tag,
);

/// Filter-sheet counts for [JewelryFacetKey]; reloads only when category,
/// search, shop or tag change.
final jewelryFacetsProvider = FutureProvider.autoDispose
    .family<MarketplaceFacets, JewelryFacetKey>((ref, key) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final result = await ref
          .watch(jewelryRepositoryProvider)
          .getFacets(
            filters: JewelryFilterState(
              searchQuery: key.search,
              category: key.category,
              shop: key.shop,
              tag: key.tag,
            ),
            cancelToken: cancel,
          );
      return switch (result) {
        Success(value: final facets) => facets,
        ResultFailure(failure: final failure) => throw failure,
      };
    });

/// The full product page for a listing slug. Each fetch counts as a view,
/// so only the product on screen should watch this.
final jewelryListingProvider = FutureProvider.autoDispose
    .family<Jewelry, String>((ref, slug) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final result = await ref
          .watch(jewelryRepositoryProvider)
          .getListing(slug, cancelToken: cancel);
      switch (result) {
        case Success(value: final jewelry):
          // Revisits (sheet paging, back and forth) reuse it: no extra views.
          ref.keepAlive();
          return jewelry;
        case ResultFailure(failure: final failure):
          throw failure;
      }
    });

/// Every active shop, newest first.
final jewelryShopsProvider = FutureProvider<List<MarketplaceShop>>((ref) async {
  final result = await ref.watch(jewelryRepositoryProvider).getShops();
  return switch (result) {
    Success(value: final shops) => shops,
    ResultFailure(failure: final failure) => throw failure,
  };
});

/// One shop with every live listing.
final jewelryShopProvider = FutureProvider.autoDispose
    .family<MarketplaceShop, String>((ref, slug) async {
      final result = await ref.watch(jewelryRepositoryProvider).getShop(slug);
      return switch (result) {
        Success(value: final shop) => shop,
        ResultFailure(failure: final failure) => throw failure,
      };
    });
