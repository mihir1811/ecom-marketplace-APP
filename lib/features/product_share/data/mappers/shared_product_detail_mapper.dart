import '../../../bullions/data/mappers/bullion_mapper.dart';
import '../../../bullions/data/models/bullion_dto.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../diamonds/data/mappers/diamond_mapper.dart';
import '../../../diamonds/data/models/diamond_dto.dart';
import '../../../gemstones/data/mappers/gemstone_mapper.dart';
import '../../../gemstones/data/models/gemstone_dto.dart';
import '../../../jewelry/data/mappers/jewelry_mapper.dart';
import '../../../jewelry/data/models/jewelry_dto.dart';
import '../../../product_detail/domain/adapters/bullion_product_detail.dart';
import '../../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../../product_detail/domain/adapters/gemstone_product_detail.dart';
import '../../../product_detail/domain/adapters/jewelry_product_detail.dart';
import '../../../product_detail/domain/adapters/watch_product_detail.dart';
import '../../../product_detail/domain/models/product_detail.dart';
import '../../../watches/data/mappers/watch_mapper.dart';
import '../../../watches/data/models/watch_dto.dart';
import '../../domain/models/product_share.dart';

/// Maps GET `/product-share/{token}` payload into the shared product detail VM.
abstract final class SharedProductDetailMapper {
  static ProductDetail? toProductDetail(SharedProductPayload payload) {
    final product = payload.product;
    if (product.isEmpty && payload.productId.isEmpty) return null;

    final map = Map<String, dynamic>.from(product);
    if (!map.containsKey('id') && payload.productId.isNotEmpty) {
      map['id'] = payload.productId;
    }

    final type = payload.productType.trim();
    ProductDetail? detail;
    try {
      detail = switch (type) {
        CartProductType.diamond => _diamond(map, melee: false),
        CartProductType.meleeDiamond => _diamond(map, melee: true),
        CartProductType.gemstone => gemstoneProductDetail(
            GemstoneMapper.toDomain(GemstoneDto.fromJson(map)),
          ),
        CartProductType.jewellery => jewelryProductDetail(
            JewelryMapper.toDomain(JewelryDto.fromJson(map)),
          ),
        CartProductType.watch => watchProductDetail(
            WatchMapper.toDomain(WatchDto.fromJson(map)),
          ),
        CartProductType.bullion => bullionProductDetail(
            BullionMapper.toDomain(BullionDto.fromJson(map)),
          ),
        _ => null,
      };
    } catch (_) {
      detail = null;
    }

    if (detail == null) return null;
    return applyShareVisibility(
      detail,
      includePrice: payload.includePrice,
      includeImages: payload.includeImages,
      includeVideos: payload.includeVideos,
    );
  }

  static ProductDetail _diamond(
    Map<String, dynamic> map, {
    required bool melee,
  }) {
    final dto = DiamondDto.fromJson(map, isMelee: melee);
    final growth = dto.growthType?.trim().toLowerCase() ?? '';
    final labGrown = growth == 'cvd' || growth == 'hpht';
    return diamondProductDetail(
      DiamondMapper.toDomain(dto, isLabGrown: labGrown),
    );
  }

  /// Honours share checkboxes (Nivoda / RapNet style include flags).
  static ProductDetail applyShareVisibility(
    ProductDetail detail, {
    required bool includePrice,
    required bool includeImages,
    required bool includeVideos,
  }) {
    final price = includePrice
        ? detail.price
        : const ProductPrice(
            currencySymbol: '',
            amountLabel: 'Price on request',
            priceUsd: 0,
            priceInr: 0,
          );

    final media = ProductMedia(
      fallbackIcon: detail.media.fallbackIcon,
      fallbackTint: detail.media.fallbackTint,
      images: includeImages ? detail.media.images : const [],
      imageSlots: includeImages ? detail.media.imageSlots : 0,
      certificateLabel: detail.media.certificateLabel,
      certificateUrl: detail.media.certificateUrl,
      shapeKey: detail.media.shapeKey,
      fit: detail.media.fit,
      hasVideo: includeVideos && detail.media.hasVideo,
      videoLabel: includeVideos ? detail.media.videoLabel : null,
      videoUrl: includeVideos ? detail.media.videoUrl : null,
    );

    return ProductDetail(
      id: detail.id,
      segment: detail.segment,
      apiProductType: detail.apiProductType,
      title: detail.title,
      subtitle: detail.subtitle,
      referenceLabel: detail.referenceLabel,
      referenceValue: detail.referenceValue,
      media: media,
      price: price,
      highlights: detail.highlights,
      specSections: detail.specSections,
      badges: detail.badges,
      certification: detail.certification,
      availability: detail.availability,
      shapeKey: detail.shapeKey,
      note: detail.note,
    );
  }
}
