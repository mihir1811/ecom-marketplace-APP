import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../product_detail/application/catalog_product_detail_loader.dart';
import '../../product_detail/domain/models/product_detail.dart';
import '../data/mappers/shared_product_detail_mapper.dart';
import '../data/repositories/product_share_repository_impl.dart';
import '../domain/models/product_share.dart';

/// Loads a shared product by token and returns a [ProductDetail] for in-app open.
final sharedProductDetailProvider =
    FutureProvider.autoDispose.family<ProductDetail, String>((ref, token) async {
  final clean = Uri.decodeComponent(token.trim());
  if (clean.isEmpty) {
    throw const NetworkFailure('This share link is invalid.');
  }

  final shareResult =
      await ref.read(productShareRepositoryProvider).getByToken(token: clean);
  late final SharedProductPayload payload;
  switch (shareResult) {
    case Success(value: final value):
      payload = value;
    case ResultFailure(failure: final failure):
      throw failure;
  }

  final fromPayload = SharedProductDetailMapper.toProductDetail(payload);
  if (fromPayload != null) return fromPayload;

  final fetched = await CatalogProductDetailLoader.load(
    ref.read,
    productType: payload.productType,
    productId: payload.productId,
  );
  if (fetched == null) {
    throw const NetworkFailure('This shared product could not be opened.');
  }
  return SharedProductDetailMapper.applyShareVisibility(
    fetched,
    includePrice: payload.includePrice,
    includeImages: payload.includeImages,
    includeVideos: payload.includeVideos,
  );
});
