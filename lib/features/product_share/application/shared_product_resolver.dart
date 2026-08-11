import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../bullions/data/mappers/bullion_mapper.dart';
import '../../bullions/data/models/bullion_dto.dart';
import '../../cart/domain/models/cart_product_type.dart';
import '../../diamonds/data/repositories/diamond_repository_impl.dart';
import '../../gemstones/data/repositories/gemstone_repository_impl.dart';
import '../../jewelry/data/mappers/jewelry_mapper.dart';
import '../../jewelry/data/models/jewelry_dto.dart';
import '../../product_detail/domain/adapters/bullion_product_detail.dart';
import '../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../product_detail/domain/adapters/gemstone_product_detail.dart';
import '../../product_detail/domain/adapters/jewelry_product_detail.dart';
import '../../product_detail/domain/adapters/watch_product_detail.dart';
import '../../product_detail/domain/models/product_detail.dart';
import '../../watches/data/mappers/watch_mapper.dart';
import '../../watches/data/models/watch_dto.dart';
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

  final fetched = await _fetchCatalogDetail(
    ref,
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

Future<ProductDetail?> _fetchCatalogDetail(
  Ref ref, {
  required String productType,
  required String productId,
}) async {
  if (productId.isEmpty) return null;
  final type = productType.trim();

  try {
    switch (type) {
      case CartProductType.diamond:
      case CartProductType.meleeDiamond:
        final result =
            await ref.read(diamondRepositoryProvider).getDiamondById(
                  id: productId,
                  isMelee: type == CartProductType.meleeDiamond,
                  isLabGrown: false,
                );
        return switch (result) {
          Success(value: final diamond) => diamondProductDetail(diamond),
          ResultFailure() => null,
        };
      case CartProductType.gemstone:
        final result =
            await ref.read(gemstoneRepositoryProvider).getGemstoneById(
                  id: productId,
                );
        return switch (result) {
          Success(value: final gem) => gemstoneProductDetail(gem),
          ResultFailure() => null,
        };
      case CartProductType.jewellery:
        return _getByPath(
          ref,
          ApiEndpoints.jewelleryById(productId),
          (json) => jewelryProductDetail(
            JewelryMapper.toDomain(JewelryDto.fromJson(json)),
          ),
        );
      case CartProductType.watch:
        return _getByPath(
          ref,
          ApiEndpoints.watchById(productId),
          (json) => watchProductDetail(
            WatchMapper.toDomain(WatchDto.fromJson(json)),
          ),
        );
      case CartProductType.bullion:
        return _getByPath(
          ref,
          ApiEndpoints.bullionById(productId),
          (json) => bullionProductDetail(
            BullionMapper.toDomain(BullionDto.fromJson(json)),
          ),
        );
      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}

Future<ProductDetail?> _getByPath(
  Ref ref,
  String path,
  ProductDetail Function(Map<String, dynamic> json) map,
) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(path);
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return null;
    return map(data);
  } on DioException {
    return null;
  }
}
