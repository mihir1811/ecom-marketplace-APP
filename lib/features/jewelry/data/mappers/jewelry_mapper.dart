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
      metalWeightG: variant?.metalWeight ?? 0,
      stoneWeightCt: variant?.totalStoneCarat ?? stone?.centerStoneWeight ?? 0,
      stoneCount: variant?.totalStonePcs ?? stone?.centerStonePcs ?? 0,
      colorVariants: colorVariants,
      sizeOptions: sizeOptions.toList(),
      braceletSize: _clean(variant?.braceletSize),
      chainLength: _clean(variant?.chainLength),
      ringSize: _clean(variant?.ringSize),
      badge: dto.isOnAuction == true ? 'Auction' : null,
      imageUrl: images.isEmpty ? null : images.first,
      imageAsset: _categoryAsset(categoryUi),
      discount: discountPct,
      hasMedia: images.isNotEmpty ||
          (_clean(dto.videoURL) != null),
    );
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

  static String? _categoryAsset(String category) {
    return switch (category) {
      'Bracelets' => 'public/images/jewelryCategoryImages/bracelet.webp',
      'Necklaces' || 'Chains' =>
        'public/images/jewelryCategoryImages/necklace.webp',
      'Earrings' => 'public/images/jewelryCategoryImages/earrings.webp',
      'Rings' => 'public/images/jewelryCategoryImages/ring.webp',
      _ => 'public/images/jewelryCategoryImages/set.webp',
    };
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
