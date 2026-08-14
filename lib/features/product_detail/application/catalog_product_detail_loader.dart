import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../watches/data/mappers/watch_mapper.dart';
import '../../watches/data/models/watch_dto.dart';
import '../domain/adapters/bullion_product_detail.dart';
import '../domain/adapters/diamond_product_detail.dart';
import '../domain/adapters/gemstone_product_detail.dart';
import '../domain/adapters/jewelry_product_detail.dart';
import '../domain/adapters/watch_product_detail.dart';
import '../domain/models/product_detail.dart';

/// Loads a [ProductDetail] from catalog APIs by cart `productType` + id.
abstract final class CatalogProductDetailLoader {
  static Future<ProductDetail?> load(
    T Function<T>(ProviderListenable<T> provider) read, {
    required String productType,
    required String productId,
  }) async {
    final id = productId.trim();
    if (id.isEmpty) return null;
    final type = productType.trim();

    try {
      switch (type) {
        case CartProductType.diamond:
        case CartProductType.meleeDiamond:
          final isMelee = type == CartProductType.meleeDiamond;
          final diamondRepo = read(diamondRepositoryProvider);
          var result = await diamondRepo.getDiamondById(
            id: id,
            isMelee: isMelee,
            isLabGrown: false,
          );
          if (result is ResultFailure) {
            result = await diamondRepo.getDiamondById(
              id: id,
              isMelee: isMelee,
              isLabGrown: true,
            );
          }
          if (result is ResultFailure && !isMelee) {
            result = await diamondRepo.getDiamondById(
              id: id,
              isMelee: true,
              isLabGrown: false,
            );
          }
          return switch (result) {
            Success(value: final diamond) => diamondProductDetail(diamond),
            ResultFailure() => null,
          };
        case CartProductType.gemstone:
          final result = await read(gemstoneRepositoryProvider).getGemstoneById(
                id: id,
              );
          return switch (result) {
            Success(value: final gem) => gemstoneProductDetail(gem),
            ResultFailure() => null,
          };
        case CartProductType.jewellery:
          return _getByPath(
            read,
            ApiEndpoints.jewelleryById(id),
            (json) => jewelryProductDetail(
              JewelryMapper.toDomain(JewelryDto.fromJson(json)),
            ),
          );
        case CartProductType.watch:
          return _getByPath(
            read,
            ApiEndpoints.watchById(id),
            (json) => watchProductDetail(
              WatchMapper.toDomain(WatchDto.fromJson(json)),
            ),
          );
        case CartProductType.bullion:
          return _getByPath(
            read,
            ApiEndpoints.bullionById(id),
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

  static Future<ProductDetail?> _getByPath(
    T Function<T>(ProviderListenable<T> provider) read,
    String path,
    ProductDetail Function(Map<String, dynamic> json) map,
  ) async {
    try {
      final dio = read(dioProvider);
      final response = await dio.get<Map<String, dynamic>>(path);
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return null;
      return map(data);
    } on DioException {
      return null;
    }
  }
}
