import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/jewelry.dart';
import '../models/jewelry_filter_state.dart';
import '../models/jewelry_premium.dart';
import '../models/marketplace_listing.dart';

/// Page size for catalogue reads (API allows 1–100, default 48).
abstract final class JewelryPageSize {
  static const int defaultSize = 24;
}

/// Public jewellery marketplace catalogue (`/marketplace`). No sign-in.
abstract class JewelryRepository {
  /// One page of live listings via `GET /marketplace/listings`.
  Future<Result<JewelryListResponse, Failure>> getJewelry({
    required JewelryFilterState filters,
    required int page,
    int pageSize = JewelryPageSize.defaultSize,
    JewelrySortOption? sort,
    CancelToken? cancelToken,
  });

  /// The product page via `GET /marketplace/listings/{slug}`. Each call
  /// counts as a view, so never prefetch these in bulk.
  Future<Result<Jewelry, Failure>> getListing(
    String slug, {
    CancelToken? cancelToken,
  });

  /// Same category first, then same shop, most-favourited first.
  Future<Result<List<Jewelry>, Failure>> getRelated(
    String slug, {
    int limit = 8,
    CancelToken? cancelToken,
  });

  /// Filter-sheet counts; only category, search, shop and tag narrow them.
  Future<Result<MarketplaceFacets, Failure>> getFacets({
    required JewelryFilterState filters,
    CancelToken? cancelToken,
  });

  /// Premium pieces (`GET /marketplace/premium`), optionally one top-level
  /// [category]. A 404 (route not deployed) gives
  /// [JewelryPremiumPage.unavailable].
  Future<Result<JewelryPremiumPage, Failure>> getPremium({
    required int page,
    int pageSize = JewelryPageSize.defaultSize,
    String? category,
    JewelrySortOption? sort,
    CancelToken? cancelToken,
  });

  /// Top-level categories with their active sub-categories.
  Future<Result<List<MarketplaceCategory>, Failure>> getCategories({
    CancelToken? cancelToken,
  });

  Future<Result<List<MarketplaceShop>, Failure>> getShops({
    CancelToken? cancelToken,
  });

  /// One shop with all its live listings.
  Future<Result<MarketplaceShop, Failure>> getShop(
    String slug, {
    CancelToken? cancelToken,
  });
}
