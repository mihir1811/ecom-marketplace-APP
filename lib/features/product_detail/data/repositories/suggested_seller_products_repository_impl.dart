import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/pagination/paginated_async_notifier.dart';
import '../../../bullions/data/repositories/bullions_repository_impl.dart';
import '../../../bullions/domain/models/bullions_filter_state.dart';
import '../../../bullions/domain/repositories/bullions_repository.dart';
import '../../../diamonds/data/repositories/diamond_repository_impl.dart';
import '../../../diamonds/domain/models/diamond_catalog_type.dart';
import '../../../diamonds/domain/models/diamond_filter_state.dart';
import '../../../diamonds/domain/repositories/diamond_repository.dart';
import '../../../gemstones/data/repositories/gemstone_repository_impl.dart';
import '../../../gemstones/domain/models/gemstone_filter_state.dart';
import '../../../gemstones/domain/repositories/gemstone_repository.dart';
import '../../../jewelry/data/repositories/jewelry_repository_impl.dart';
import '../../../jewelry/domain/models/jewelry_filter_state.dart';
import '../../../jewelry/domain/repositories/jewelry_repository.dart';
import '../../../watches/data/repositories/watch_repository_impl.dart';
import '../../../watches/domain/models/watch_filter_state.dart';
import '../../../watches/domain/repositories/watch_repository.dart';
import '../../domain/adapters/bullion_product_detail.dart';
import '../../domain/adapters/diamond_product_detail.dart';
import '../../domain/adapters/gemstone_product_detail.dart';
import '../../domain/adapters/jewelry_product_detail.dart';
import '../../domain/adapters/watch_product_detail.dart';
import '../../domain/models/product_detail.dart';
import '../../domain/repositories/suggested_seller_products_repository.dart';

final suggestedSellerProductsRepositoryProvider =
    Provider<SuggestedSellerProductsRepository>(
  (ref) => SuggestedSellerProductsRepositoryImpl(
    diamonds: ref.watch(diamondRepositoryProvider),
    gemstones: ref.watch(gemstoneRepositoryProvider),
    jewelry: ref.watch(jewelryRepositoryProvider),
    watches: ref.watch(watchRepositoryProvider),
    bullions: ref.watch(bullionsRepositoryProvider),
  ),
);

class SuggestedSellerProductsRepositoryImpl
    implements SuggestedSellerProductsRepository {
  const SuggestedSellerProductsRepositoryImpl({
    required this._diamonds,
    required this._gemstones,
    required this._jewelry,
    required this._watches,
    required this._bullions,
  });

  final DiamondRepository _diamonds;
  final GemstoneRepository _gemstones;
  final JewelryRepository _jewelry;
  final WatchRepository _watches;
  final BullionsRepository _bullions;

  @override
  Future<Result<PaginatedPage<ProductDetail>, Failure>> getPage({
    required ProductSegment segment,
    required String excludeProductId,
    String? sellerId,
    String? companyName,
    required int page,
    int pageSize = SuggestedSellerProductsPageSize.defaultSize,
    CancelToken? cancelToken,
  }) {
    final sid = sellerId?.trim();
    final company = _usableCompanyName(companyName);
    if ((sid == null || sid.isEmpty) && company == null) {
      return Future.value(
        const Success(
          PaginatedPage<ProductDetail>(
            items: [],
            hasMore: false,
            totalCount: 0,
          ),
        ),
      );
    }

    return switch (segment) {
      ProductSegment.naturalDiamond || ProductSegment.labGrownDiamond =>
        _loadDiamonds(
          segment: segment,
          excludeProductId: excludeProductId,
          sellerId: sid,
          companyName: company,
          page: page,
          pageSize: pageSize,
          cancelToken: cancelToken,
        ),
      ProductSegment.gemstone => _loadGemstones(
          excludeProductId: excludeProductId,
          sellerId: sid,
          companyName: company,
          page: page,
          pageSize: pageSize,
          cancelToken: cancelToken,
        ),
      ProductSegment.jewelry => _loadJewelry(
          excludeProductId: excludeProductId,
          sellerId: sid,
          page: page,
          pageSize: pageSize,
          cancelToken: cancelToken,
        ),
      ProductSegment.watch => _loadWatches(
          excludeProductId: excludeProductId,
          sellerId: sid,
          page: page,
          pageSize: pageSize,
          cancelToken: cancelToken,
        ),
      ProductSegment.bullion => _loadBullions(
          excludeProductId: excludeProductId,
          sellerId: sid,
          page: page,
          pageSize: pageSize,
          cancelToken: cancelToken,
        ),
    };
  }

  Future<Result<PaginatedPage<ProductDetail>, Failure>> _loadDiamonds({
    required ProductSegment segment,
    required String excludeProductId,
    required String? sellerId,
    required String? companyName,
    required int page,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    final catalog = segment == ProductSegment.labGrownDiamond
        ? DiamondCatalogType.labGrown
        : DiamondCatalogType.natural;
    final filters = DiamondFilterState(
      companyNames: companyName == null ? const [] : [companyName],
    );
    final result = await _diamonds.getDiamonds(
      filters: filters,
      catalog: catalog,
      page: page,
      pageSize: pageSize,
      sellerId: sellerId,
      cancelToken: cancelToken,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<ProductDetail>(
            items: [
              for (final d in response.diamonds)
                if (d.id != excludeProductId) diamondProductDetail(d),
            ],
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }

  Future<Result<PaginatedPage<ProductDetail>, Failure>> _loadGemstones({
    required String excludeProductId,
    required String? sellerId,
    required String? companyName,
    required int page,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    final filters = GemstoneFilterState(
      companyNames: companyName == null ? const [] : [companyName],
    );
    final result = await _gemstones.getGemstones(
      filters: filters,
      page: page,
      pageSize: pageSize,
      sellerId: sellerId,
      cancelToken: cancelToken,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<ProductDetail>(
            items: [
              for (final g in response.gemstones)
                if (g.id != excludeProductId) gemstoneProductDetail(g),
            ],
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }

  Future<Result<PaginatedPage<ProductDetail>, Failure>> _loadJewelry({
    required String excludeProductId,
    required String? sellerId,
    required int page,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (sellerId == null || sellerId.isEmpty) {
      return const Success(
        PaginatedPage<ProductDetail>(
          items: [],
          hasMore: false,
          totalCount: 0,
        ),
      );
    }
    final result = await _jewelry.getJewelry(
      filters: const JewelryFilterState(),
      page: page,
      pageSize: pageSize,
      sellerId: sellerId,
      cancelToken: cancelToken,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<ProductDetail>(
            items: [
              for (final j in response.items)
                if (j.id != excludeProductId) jewelryProductDetail(j),
            ],
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }

  Future<Result<PaginatedPage<ProductDetail>, Failure>> _loadWatches({
    required String excludeProductId,
    required String? sellerId,
    required int page,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (sellerId == null || sellerId.isEmpty) {
      return const Success(
        PaginatedPage<ProductDetail>(
          items: [],
          hasMore: false,
          totalCount: 0,
        ),
      );
    }
    final result = await _watches.getWatches(
      filters: const WatchFilterState(),
      page: page,
      pageSize: pageSize,
      sellerId: sellerId,
      cancelToken: cancelToken,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<ProductDetail>(
            items: [
              for (final w in response.watches)
                if (w.id != excludeProductId) watchProductDetail(w),
            ],
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }

  Future<Result<PaginatedPage<ProductDetail>, Failure>> _loadBullions({
    required String excludeProductId,
    required String? sellerId,
    required int page,
    required int pageSize,
    CancelToken? cancelToken,
  }) async {
    if (sellerId == null || sellerId.isEmpty) {
      return const Success(
        PaginatedPage<ProductDetail>(
          items: [],
          hasMore: false,
          totalCount: 0,
        ),
      );
    }
    final result = await _bullions.searchBullions(
      filters: const BullionsFilterState(),
      page: page,
      pageSize: pageSize,
      sellerId: sellerId,
      cancelToken: cancelToken,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<ProductDetail>(
            items: [
              for (final b in response.bullions)
                if (b.id != excludeProductId) bullionProductDetail(b),
            ],
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }

  String? _usableCompanyName(String? raw) {
    final name = raw?.trim() ?? '';
    if (name.isEmpty) return null;
    if (name.toLowerCase() == 'seller') return null;
    return name;
  }
}
