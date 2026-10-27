import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/router/navigator_keys.dart';
import '../../bullions/data/mappers/bullion_mapper.dart';
import '../../bullions/data/models/bullion_dto.dart';
import '../../cart/domain/models/cart_product_type.dart';
import '../../diamonds/data/repositories/diamond_repository_impl.dart';
import '../../gemstones/data/repositories/gemstone_repository_impl.dart';
import '../../jewelry/data/repositories/jewelry_repository_impl.dart';
import '../../product_detail/domain/adapters/bullion_product_detail.dart';
import '../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../product_detail/domain/adapters/gemstone_product_detail.dart';
import '../../product_detail/domain/adapters/jewelry_product_detail.dart';
import '../../product_detail/domain/adapters/watch_product_detail.dart';
import '../../product_detail/domain/models/product_detail.dart';
import '../../product_detail/product_detail_navigation.dart';
import '../../watches/data/mappers/watch_mapper.dart';
import '../../watches/data/models/watch_dto.dart';
import '../data/mappers/ai_chat_catalog_mapper.dart';
import '../domain/models/ai_chat_product.dart';

/// Opens the shared product-detail route for a Gem AI match card.
abstract final class AiChatProductNavigation {
  static BuildContext? get _rootContext => rootNavigatorKey.currentContext;

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    AiChatProduct product, {
    VoidCallback? beforeNavigate,
  }) async {
    if (product.id.isEmpty) return;

    // Resolve while the chat panel is still mounted, then navigate via root.
    if (findRememberedProductDetail(product.id) != null) {
      beforeNavigate?.call();
      await Future<void>.delayed(Duration.zero);
      final target = _rootContext;
      if (target != null && target.mounted) {
        openRememberedProductDetail(target, product.id);
      }
      return;
    }

    final detail = await resolveDetail(ref, product);
    beforeNavigate?.call();
    await Future<void>.delayed(Duration.zero);

    final target = _rootContext;
    if (target == null || !target.mounted) return;

    if (detail != null) {
      openProductDetail(target, detail);
      return;
    }

    final type = AiChatCatalogMapper.normalizedType(product);
    if (type.contains('gem')) {
      openGemstoneDetail(target, AiChatCatalogMapper.toGemstone(product));
      return;
    }
    if (type.contains('jewel')) {
      openJewelryDetail(target, AiChatCatalogMapper.toJewelry(product));
      return;
    }
    openDiamondDetail(target, AiChatCatalogMapper.toDiamond(product));
  }

  static Future<ProductDetail?> resolveDetail(
    WidgetRef ref,
    AiChatProduct product,
  ) async {
    final id = product.id.trim();
    if (id.isEmpty) return null;
    final type = AiChatCatalogMapper.normalizedType(product);

    try {
      if (type.contains('gem')) {
        final result = await ref
            .read(gemstoneRepositoryProvider)
            .getGemstoneById(id: id);
        return switch (result) {
          Success(value: final gem) => gemstoneProductDetail(gem),
          ResultFailure() => null,
        };
      }

      if (type.contains('jewel')) {
        // Marketplace pages are looked up by slug: the last segment of a
        // `/product/{slug}` link, else the id itself.
        final segments = Uri.tryParse(product.href)?.pathSegments ?? const [];
        final slug = segments.length >= 2 && segments[segments.length - 2] ==
                'product'
            ? segments.last
            : id;
        final result = await ref.read(jewelryRepositoryProvider).getListing(
          slug,
        );
        return switch (result) {
          Success(value: final jewelry) => jewelryProductDetail(jewelry),
          ResultFailure() => null,
        };
      }

      if (type.contains('watch')) {
        return await _getByPath(
          ref,
          ApiEndpoints.watchById(id),
          (json) =>
              watchProductDetail(WatchMapper.toDomain(WatchDto.fromJson(json))),
        );
      }

      if (type.contains('bullion') || type.contains('gold')) {
        return await _getByPath(
          ref,
          ApiEndpoints.bullionById(id),
          (json) => bullionProductDetail(
            BullionMapper.toDomain(BullionDto.fromJson(json)),
          ),
        );
      }

      final isMelee =
          type.contains('melee') || type == CartProductType.meleeDiamond;
      final isLabGrown = AiChatCatalogMapper.toDiamond(product).isLabGrown;
      final diamondRepo = ref.read(diamondRepositoryProvider);

      var result = await diamondRepo.getDiamondById(
        id: id,
        isMelee: isMelee,
        isLabGrown: isLabGrown,
      );
      if (result is ResultFailure && !isMelee) {
        result = await diamondRepo.getDiamondById(
          id: id,
          isMelee: true,
          isLabGrown: isLabGrown,
        );
      }
      if (result is ResultFailure && !isLabGrown) {
        result = await diamondRepo.getDiamondById(
          id: id,
          isMelee: isMelee,
          isLabGrown: true,
        );
      }

      return switch (result) {
        Success(value: final diamond) => diamondProductDetail(diamond),
        ResultFailure() => null,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<ProductDetail?> _getByPath(
    WidgetRef ref,
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
}
