import '../../../../core/network/api_config.dart';
import '../../domain/models/jewelry.dart';
import '../models/jewelry_dto.dart';

/// Maps jewellery API DTOs into listing domain models.
abstract final class JewelryMapper {
  static Jewelry toDomain(JewelryDto dto) {
    final variant = dto.variants.isNotEmpty ? dto.variants.first : null;
    final stone = variant != null && variant.stones.isNotEmpty
        ? variant.stones.first
        : null;
    final categoryApi = dto.subcategory?.category?.name;
    final categoryUi = _mapCategoryToUi(categoryApi);
    final images = _images(variant);
    final colorVariants = dto.variants
        .map((v) => _clean(v.metalColor))
        .whereType<String>()
        .toSet()
        .toList();
    if (colorVariants.isEmpty && variant?.metalColor != null) {
      final c = _clean(variant!.metalColor);
      if (c != null) colorVariants.add(c);
    }

    final sizeOptions = <String>{};
    for (final v in dto.variants) {
      final ring = _clean(v.ringSize);
      final bracelet = _clean(v.braceletSize);
      final chain = _clean(v.chainLength);
      if (ring != null) sizeOptions.add(ring);
      if (bracelet != null) sizeOptions.add(bracelet);
      if (chain != null) sizeOptions.add(chain);
    }

    final price = variant?.totalPrice ?? 0;
    final discountAmount = variant?.discount;
    final discountPct = (discountAmount != null &&
            discountAmount > 0 &&
            price > 0)
        ? ((discountAmount / (price + discountAmount)) * 100)
        : null;

    final stoneTypeRaw = _clean(stone?.centerStoneType);
    final availability = _mapAvailability(variant?.available);
    final metalWeight = variant?.metalWeight ?? 0;
    final stoneWeight =
        variant?.totalStoneCarat ?? stone?.centerStoneWeight ?? 0;
    final stones = _stones(variant);
    final variants = dto.variants.map(_variantOption).toList(growable: false);
    final totalWeight =
        variant?.totalJewelryWeight ?? _totalWeightG(metalWeight, stoneWeight);

    return Jewelry(
      id: dto.id,
      sku: _clean(variant?.stockNumber) ?? dto.id,
      name: _clean(dto.productTitle) ?? 'Jewellery',
      category: categoryUi,
      subCategory: _clean(dto.subcategory?.name),
      price: price,
      metalType: _clean(variant?.metalType) ?? '',
      metalColor: _clean(variant?.metalColor) ?? '',
      metalPurity: _clean(variant?.metalPurity) ?? '',
      gender: _mapGender(dto.gender),
      occasion: _clean(dto.occasion) ?? '',
      condition: _clean(variant?.condition) ?? '',
      availability: availability,
      stoneType: _mapStoneType(stoneTypeRaw),
      stoneCategory: _clean(stone?.centerStoneCategory) ?? '',
      stoneShape: _clean(stone?.centerStoneShape) ?? '',
      certification: _clean(variant?.certificateCompanyName) ?? '',
      metalWeightG: metalWeight,
      stoneWeightCt: stoneWeight,
      stoneCount: variant?.totalStonePcs ?? stone?.centerStonePcs ?? 0,
      colorVariants: colorVariants,
      sizeOptions: sizeOptions.toList(),
      braceletSize: _clean(variant?.braceletSize),
      chainLength: _clean(variant?.chainLength),
      ringSize: _clean(variant?.ringSize),
      badge: dto.isOnAuction == true ? 'Auction' : null,
      imageUrl: images.isEmpty ? null : images.first,
      imageAsset: null,
      discount: discountPct,
      discountAmount: discountAmount,
      metalPrice: variant?.totalMetalPrice,
      stonePrice: variant?.totalStonePrice,
      makingCharge: variant?.totalMakingCharge,
      hasMedia: images.isNotEmpty || (_clean(dto.videoURL) != null),
      sellerId: _clean(dto.sellerId),
      description: _clean(dto.description),
      metalFinish: _clean(variant?.metalFinish),
      style: _clean(dto.style),
      totalWeightG: totalWeight,
      stones: stones,
      variants: variants,
    );
  }

  static JewelryVariantOption _variantOption(JewelryVariantDto v) {
    final price = v.totalPrice ?? 0;
    final discountAmount = v.discount;
    final discountPct = (discountAmount != null &&
            discountAmount > 0 &&
            price > 0)
        ? ((discountAmount / (price + discountAmount)) * 100)
        : null;
    final sizeLabel =
        _clean(v.ringSize) ?? _clean(v.braceletSize) ?? _clean(v.chainLength);
    final metalWeight = v.metalWeight;
    final stoneWeight = v.totalStoneCarat ??
        (v.stones.isNotEmpty ? v.stones.first.centerStoneWeight : null);

    return JewelryVariantOption(
      id: v.id,
      price: price,
      sku: _clean(v.stockNumber),
      metalPurity: _clean(v.metalPurity),
      sizeLabel: sizeLabel,
      stoneWeightCt: stoneWeight,
      metalWeightG: metalWeight,
      totalWeightG: v.totalJewelryWeight ??
          (metalWeight == null
              ? null
              : _totalWeightG(metalWeight, stoneWeight ?? 0)),
      discountAmount: discountAmount,
      discountPercent: discountPct,
      metalPrice: v.totalMetalPrice,
      stonePrice: v.totalStonePrice,
      makingCharge: v.totalMakingCharge,
      metalType: _clean(v.metalType),
      metalColor: _clean(v.metalColor),
      metalFinish: _clean(v.metalFinish),
      braceletSize: _clean(v.braceletSize),
      ringSize: _clean(v.ringSize),
      chainLength: _clean(v.chainLength),
      stoneCount: v.totalStonePcs ??
          (v.stones.isNotEmpty ? v.stones.first.centerStonePcs : null),
      stones: _stones(v),
    );
  }

  static List<JewelryStone> _stones(JewelryVariantDto? variant) {
    if (variant == null || variant.stones.isEmpty) return const [];
    return variant.stones
        .map(
          (s) => JewelryStone(
            type: _mapStoneType(_clean(s.centerStoneType)),
            category: _clean(s.centerStoneCategory),
            shape: _clean(s.centerStoneShape),
            color: _clean(s.centerStoneColor),
            clarity: _clean(s.centerStoneClarity),
            weightCt: s.centerStoneWeight,
            pieces: s.centerStonePcs,
          ),
        )
        .toList(growable: false);
  }

  /// Approximate finished weight when API does not send a total.
  static double? _totalWeightG(double metalWeightG, double stoneWeightCt) {
    if (metalWeightG <= 0 && stoneWeightCt <= 0) return null;
    // 1 carat ≈ 0.2 g
    return metalWeightG + (stoneWeightCt * 0.2);
  }

  static String _mapCategoryToUi(String? apiName) {
    final name = (apiName ?? '').trim().toLowerCase();
    return switch (name) {
      'ring' => 'Rings',
      'earring' => 'Earrings',
      'bracelet' => 'Bracelets',
      'necklace' => 'Necklaces',
      'chain' => 'Chains',
      _ => apiName?.trim().isNotEmpty == true ? apiName!.trim() : 'All Accessories',
    };
  }

  static String _mapGender(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'women' || 'woman' || 'female' => 'Women',
      'men' || 'man' || 'male' => 'Men',
      'unisex' => 'Unisex',
      'kids' || 'kid' || 'children' => 'Kids',
      _ => raw?.trim().isNotEmpty == true ? raw!.trim() : 'Unisex',
    };
  }

  static String _mapAvailability(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'yes' || 'available' || 'in stock' => 'In Stock',
      'hold' || 'on hold' => 'On Hold',
      'memo' => 'Memo',
      _ => raw?.trim().isNotEmpty == true ? raw!.trim() : 'In Stock',
    };
  }

  static String _mapStoneType(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.contains('lab')) return 'Lab-Grown';
    if (v.contains('natural')) return 'Natural';
    return raw?.trim().isNotEmpty == true ? raw!.trim() : '';
  }

  static List<String> _images(JewelryVariantDto? variant) {
    if (variant == null) return const [];
    final out = <String>[];
    final seen = <String>{};
    for (final url in [
      variant.image1,
      variant.image2,
      variant.image3,
      variant.image4,
      variant.image5,
      variant.image6,
    ]) {
      final resolved = _resolveMediaUrl(url);
      if (resolved == null) continue;
      if (!seen.add(resolved)) continue;
      out.add(resolved);
    }
    return out;
  }

  static String? _clean(String? value) {
    if (value == null) return null;
    final t = value.trim();
    if (t.isEmpty) return null;
    if (t == '-' || t == '—' || t == '–' || t.toLowerCase() == 'n/a') {
      return null;
    }
    return t;
  }

  static String? _resolveMediaUrl(String? raw) {
    final cleaned = _clean(raw);
    if (cleaned == null) return null;
    final lower = cleaned.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return cleaned;
    }
    final origin = Uri.parse(ApiConfig.baseUrl).origin;
    if (cleaned.startsWith('/')) return '$origin$cleaned';
    return '$origin/$cleaned';
  }
}
