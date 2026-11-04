import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diamonds/data/mappers/diamond_search_request_mapper.dart';
import '../../diamonds/domain/models/diamond.dart';
import '../../diamonds/domain/models/diamond_catalog_type.dart';
import '../../diamonds/domain/models/diamond_filter_state.dart';
import '../data/spotlight_repository.dart';
import '../domain/spotlight_models.dart';
import 'spotlight_providers.dart';

/// A stone drawn as one of the screen's own cards, with the ad it came from.
class SponsoredDiamond {
  const SponsoredDiamond({required this.adId, required this.diamond});

  final String adId;
  final Diamond diamond;
}

/// Sponsored stones fit one row of the results grid.
const kSponsoredDiamondSlots = 2;

/// Every diamond listing ad (up to 24), shared by results and search.
const SpotlightQuery kDiamondSponsoredQuery = (
  placement: SpotlightPlacement.categorySponsored,
  category: SpotlightCategory.diamonds,
  excludeProductId: null,
  limit: 24,
);

/// Lookup key for one results screen: its search body (filters, type, kind)
/// as JSON, so equal filters share one request.
typedef SponsoredDiamondKey = ({String bodyJson, bool isMelee, bool isLab});

/// Builds the key for a results screen showing [filters] in [catalog].
/// Null during a stock-number search, which shows no sponsored stones.
SponsoredDiamondKey? sponsoredDiamondKey(
  DiamondFilterState filters,
  DiamondCatalogType catalog,
) {
  final body = DiamondSearchRequestMapper.toBody(
    filters: filters,
    catalog: catalog,
    page: 1,
  )..removeWhere((k, _) => k == 'page' || k == 'limit' || k == 'sort_by');
  if (_isStockNumberSearch(body)) return null;
  return (
    bodyJson: jsonEncode(body),
    isMelee: body['kind'] == 'MELEE',
    isLab: catalog.isLabGrown,
  );
}

bool _isStockNumberSearch(Map<String, dynamic> body) {
  for (final key in const [
    'stock_number',
    'stockNumber',
    'stock_numbers',
    'stockNumbers',
  ]) {
    final v = body[key];
    if (v is String && v.trim().isNotEmpty) return true;
    if (v is List && v.isNotEmpty) return true;
  }
  return false;
}

/// Sponsored stones for a diamond results screen, in the ads' order and
/// filtered by the screen's own search, at most one row.
final sponsoredDiamondResultsProvider = FutureProvider.autoDispose
    .family<List<SponsoredDiamond>, SponsoredDiamondKey>((ref, key) async {
      final ads = await ref.watch(
        spotlightProvider(kDiamondSponsoredQuery).future,
      );
      final type = key.isMelee ? 'meleeDiamond' : 'diamond';
      final adOf = <String, String>{};
      for (final ad in ads.whereType<SpotlightSponsoredProduct>()) {
        if (ad.product.productType != type) continue;
        adOf.putIfAbsent(ad.product.productId, () => ad.adId);
      }
      if (adOf.isEmpty) return const [];
      final body = Map<String, dynamic>.from(jsonDecode(key.bodyJson) as Map);
      final stones = await ref
          .read(spotlightRepositoryProvider)
          .diamondsByIds(
            body: body,
            ids: adOf.keys.toList(),
            isMelee: key.isMelee,
            isLabGrown: key.isLab,
          );
      return [
        for (final d in stones.take(kSponsoredDiamondSlots))
          SponsoredDiamond(adId: adOf[d.id]!, diamond: d),
      ];
    });

/// The diamond search screen, before any results: every kind's sponsored
/// stones, each looked up under both NATURAL and LAB and drawn as the kind
/// that answered.
final sponsoredDiamondsAnyKindProvider =
    FutureProvider.autoDispose<List<SponsoredDiamond>>((ref) async {
      final ads = await ref.watch(
        spotlightProvider(kDiamondSponsoredQuery).future,
      );
      final single = <String, String>{};
      final melee = <String, String>{};
      final order = <String>[];
      for (final ad in ads.whereType<SpotlightSponsoredProduct>()) {
        final id = ad.product.productId;
        switch (ad.product.productType) {
          case 'diamond':
            if (single.containsKey(id)) continue;
            single[id] = ad.adId;
          case 'meleeDiamond':
            if (melee.containsKey(id)) continue;
            melee[id] = ad.adId;
          default:
            continue;
        }
        order.add(id);
      }
      if (order.isEmpty) return const [];

      final repo = ref.read(spotlightRepositoryProvider);
      Future<List<Diamond>> lookUp(
        Map<String, String> ids, {
        required bool lab,
        required bool isMelee,
      }) {
        if (ids.isEmpty) return Future.value(const []);
        return repo.diamondsByIds(
          body: {
            'type': lab ? 'LAB' : 'NATURAL',
            'kind': isMelee ? 'MELEE' : 'SINGLE',
          },
          ids: ids.keys.toList(),
          isMelee: isMelee,
          isLabGrown: lab,
        );
      }

      final found = await Future.wait([
        lookUp(single, lab: false, isMelee: false),
        lookUp(single, lab: true, isMelee: false),
        lookUp(melee, lab: false, isMelee: true),
        lookUp(melee, lab: true, isMelee: true),
      ]);
      final byId = <String, Diamond>{};
      for (final list in found) {
        for (final d in list) {
          byId.putIfAbsent(d.id, () => d);
        }
      }
      return [
        for (final id in order)
          if (byId[id] case final d?)
            SponsoredDiamond(adId: single[id] ?? melee[id]!, diamond: d),
      ];
    });
