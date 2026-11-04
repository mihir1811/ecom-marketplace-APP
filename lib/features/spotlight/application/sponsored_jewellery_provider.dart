import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../jewelry/data/mappers/jewelry_list_query_mapper.dart';
import '../../jewelry/data/repositories/jewelry_repository_impl.dart';
import '../../jewelry/domain/models/jewelry.dart';
import '../../jewelry/domain/models/jewelry_filter_state.dart';
import '../domain/spotlight_models.dart';
import 'spotlight_providers.dart';

/// A piece drawn as one of the screen's own cards, with the ad it came from.
class SponsoredJewellery {
  const SponsoredJewellery({required this.adId, required this.piece});

  final String adId;
  final Jewelry piece;
}

/// Most sponsored pieces kept for a listing screen; the grid then shows
/// one row of them.
const kSponsoredJewelleryMax = 4;

/// Sponsored pieces drawn on a two-column results grid: one row.
const kSponsoredJewellerySlots = 2;

/// Every listing ad (up to 24), shared by every listing screen.
const SpotlightQuery kJewelleryListingSponsoredQuery = (
  placement: SpotlightPlacement.jewelleryListingSponsored,
  category: null,
  excludeProductId: null,
  limit: 24,
);

/// One listing screen's filters, equal when they ask the same question, so
/// equal filters share one request.
class SponsoredJewelleryKey {
  SponsoredJewelleryKey(this.filters)
    : _signature = jsonEncode(JewelryListQueryMapper.toQuery(filters: filters));

  final JewelryFilterState filters;
  final String _signature;

  @override
  bool operator ==(Object other) =>
      other is SponsoredJewelleryKey && other._signature == _signature;

  @override
  int get hashCode => _signature.hashCode;
}

/// Sponsored pieces for a listing, category or search screen: the running
/// listing ads, kept to those the marketplace search returns for the
/// screen's own filters (`ids=`), in the ads' order, at most
/// [kSponsoredJewelleryMax]. Any failure gives none.
final sponsoredJewelleryResultsProvider = FutureProvider.autoDispose
    .family<List<SponsoredJewellery>, SponsoredJewelleryKey>((ref, key) async {
      final ads = await ref.watch(
        spotlightProvider(kJewelleryListingSponsoredQuery).future,
      );
      final adOf = <String, String>{};
      for (final ad in ads.whereType<SpotlightSponsoredListing>()) {
        adOf.putIfAbsent(ad.listingId, () => ad.adId);
      }
      if (adOf.isEmpty) return const [];

      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final result = await ref
          .read(jewelryRepositoryProvider)
          .getByIds(
            filters: key.filters,
            ids: adOf.keys.toList(),
            cancelToken: cancel,
          );
      return switch (result) {
        Success(value: final pieces) => [
          for (final piece in pieces.take(kSponsoredJewelleryMax))
            if (adOf[piece.listingId ?? piece.id] case final adId?)
              SponsoredJewellery(adId: adId, piece: piece),
        ],
        ResultFailure() => const [],
      };
    });
