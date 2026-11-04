import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../diamonds/data/mappers/diamond_mapper.dart';
import '../../diamonds/data/models/diamond_dto.dart';
import '../../diamonds/domain/models/diamond.dart';
import '../../jewelry/data/mappers/jewelry_mapper.dart';
import '../../jewelry/data/mappers/marketplace_mapper.dart';
import '../domain/spotlight_models.dart';

final spotlightRepositoryProvider = Provider<SpotlightRepository>(
  (ref) => SpotlightRepository(ref.watch(dioProvider)),
);

/// A view or a click, sent to POST /spotlight/events.
enum SpotlightEventType {
  impression('IMPRESSION'),
  click('CLICK');

  const SpotlightEventType(this.api);

  final String api;
}

/// Public spotlight calls. No login is needed for any of them.
class SpotlightRepository {
  SpotlightRepository(this._dio);

  final Dio _dio;

  /// Most events one POST /spotlight/events takes.
  static const maxEventsPerCall = 50;

  /// Most ids one POST /diamond/search takes (more is a 400).
  static const maxDiamondIds = 50;

  /// One placement's live ads, in the server's (random) order. Any failure
  /// is an empty list: a missing ad block is never an error for the shopper.
  Future<List<SpotlightItem>> fetch(
    SpotlightQuery query, {
    CancelToken? cancelToken,
  }) async {
    final category = query.category;
    if (query.placement.needsCategory && category == null) return const [];
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.spotlight,
        queryParameters: {
          'placement': query.placement.api,
          'category': ?category?.api,
          if (query.excludeProductId?.trim().isNotEmpty ?? false)
            'excludeProductId': query.excludeProductId!.trim(),
          if (query.placement.isSponsoredProducts && query.limit != null)
            'limit': query.limit!.clamp(1, 24),
        },
        cancelToken: cancelToken,
      );
      final data = SpotlightJson.map(response.data?['data']);
      return [
        for (final raw in SpotlightJson.list(data?['items'])) ?parseItem(raw),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// One `items[]` entry of any kind; null for unknown shapes.
  static SpotlightItem? parseItem(Object? raw) =>
      SpotlightItem.fromJson(raw) ?? _jewelleryItem(raw);

  /// FEATURED_SHOP and SPONSORED_LISTING (jewellery marketplace). Their
  /// `shop` and `listing` are the marketplace's own shapes.
  static SpotlightItem? _jewelleryItem(Object? raw) {
    final j = SpotlightJson.map(raw);
    final adId = SpotlightJson.text(j?['adId']);
    if (j == null || adId == null) return null;
    try {
      switch (SpotlightJson.text(j['kind'])?.toUpperCase()) {
        case 'FEATURED_SHOP':
          final shopJson = SpotlightJson.map(j['shop']);
          if (shopJson == null) return null;
          final shop = MarketplaceMapper.shop(shopJson);
          if (shop.slug.isEmpty) return null;
          return SpotlightFeaturedShop(
            adId: adId,
            shop: shop,
            tagline: SpotlightJson.text(j['tagline']),
          );
        case 'SPONSORED_LISTING':
          final listingJson = SpotlightJson.map(j['listing']);
          if (listingJson == null) return null;
          final listing = MarketplaceMapper.listing(listingJson);
          if (listing.slug.isEmpty) return null;
          return SpotlightSponsoredListing(
            adId: adId,
            piece: JewelryMapper.fromListing(listing),
            seller: SpotlightSellerRef.fromJson(j['seller']),
          );
      }
    } catch (_) {
      // A malformed item is skipped, never the whole placement.
    }
    return null;
  }

  /// Fire and forget: no retries and no errors surfaced.
  Future<void> sendEvents(
    List<({String adId, SpotlightEventType type})> events,
  ) async {
    for (var i = 0; i < events.length; i += maxEventsPerCall) {
      final chunk = events.sublist(
        i,
        (i + maxEventsPerCall).clamp(0, events.length),
      );
      try {
        await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.spotlightEvents,
          data: {
            'events': [
              for (final e in chunk) {'adId': e.adId, 'type': e.type.api},
            ],
          },
        );
      } catch (_) {
        // Counting is best effort.
      }
    }
  }

  /// Sponsored stones for a diamond results screen: POST /diamond/search
  /// with the screen's own [body] (type, kind, filters) plus [ids]. Only
  /// stones that fit the screen and its filters come back; they are
  /// returned in [ids] order (the ads' order).
  Future<List<Diamond>> diamondsByIds({
    required Map<String, dynamic> body,
    required List<String> ids,
    required bool isMelee,
    required bool isLabGrown,
    CancelToken? cancelToken,
  }) async {
    final wanted = ids.take(maxDiamondIds).toList();
    if (wanted.isEmpty) return const [];
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.diamondSearch,
        data: {...body, 'ids': wanted, 'page': 1, 'limit': wanted.length},
        cancelToken: cancelToken,
      );
      final payload = SpotlightJson.map(response.data?['data']);
      final byId = <String, Diamond>{};
      for (final raw in SpotlightJson.list(payload?['data'])) {
        final json = SpotlightJson.map(raw);
        if (json == null) continue;
        final dto = DiamondDto.fromJson(json, isMelee: isMelee);
        if (dto.id.isEmpty) continue;
        byId[dto.id] = DiamondMapper.toDomain(dto, isLabGrown: isLabGrown);
      }
      return [for (final id in wanted) ?byId[id]];
    } catch (_) {
      return const [];
    }
  }
}
