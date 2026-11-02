import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/spotlight_seller_repository.dart';
import '../domain/spotlight_seller_models.dart';

T _unwrap<T>(Result<T, SpotlightError> result) => switch (result) {
  Success(:final value) => value,
  ResultFailure(:final failure) => throw failure,
};

/// Rate card, sections, wallet balance and whether the seller can book.
final spotlightOverviewProvider = FutureProvider.autoDispose<SpotlightOverview>(
  (ref) async =>
      _unwrap(await ref.read(spotlightSellerRepositoryProvider).overview()),
);

/// The seller's ads, newest first.
final sellerSpotlightAdsProvider =
    FutureProvider.autoDispose<List<SpotlightSellerAd>>(
      (ref) async =>
          _unwrap(await ref.read(spotlightSellerRepositoryProvider).myAds()),
    );

/// One ad with its products and daily counts.
final sellerSpotlightAdProvider = FutureProvider.autoDispose
    .family<SpotlightSellerAd, String>(
      (ref, id) async =>
          _unwrap(await ref.read(spotlightSellerRepositoryProvider).ad(id)),
    );

/// Message for an [AsyncValue] error from the providers above.
String spotlightErrorText(Object error) =>
    error is SpotlightError ? error.message : 'Something went wrong.';
