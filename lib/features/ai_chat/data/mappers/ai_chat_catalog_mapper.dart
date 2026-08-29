import '../../domain/models/ai_chat_product.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../../../jewelry/domain/models/jewelry.dart';

/// Maps Gem AI product cards onto catalog domain models for list-card UI.
abstract final class AiChatCatalogMapper {
  static Diamond toDiamond(AiChatProduct product) {
    final imageUrl = product.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Diamond(
      id: product.id,
      shape: product.shape?.trim().isNotEmpty == true
          ? product.shape!.trim()
          : 'round',
      carat: product.caratWeight ?? 0,
      price: product.totalPrice ?? 0,
      cut: product.cut?.trim() ?? '',
      color: product.color?.trim() ?? '',
      clarity: product.clarity?.trim() ?? '',
      certificate: product.certificateCompanyName?.trim() ?? '',
      imageUrl: hasImage ? imageUrl : null,
      imageUrls: hasImage ? [imageUrl] : const [],
      pricePerCarat: product.pricePerCarat,
      lab: product.certificateCompanyName?.trim(),
      hasImage: hasImage,
      stockNumber: product.stockNumber.trim().isEmpty
          ? null
          : product.stockNumber.trim(),
      isLabGrown: _isLabGrown(product),
      isMelee: _isMelee(product),
    );
  }

  static Gemstone toGemstone(AiChatProduct product) {
    final imageUrl = product.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Gemstone(
      id: product.id,
      type: product.title.trim().isEmpty ? 'Gemstone' : product.title.trim(),
      carat: product.caratWeight ?? 0,
      price: product.totalPrice ?? 0,
      origin: '',
      color: product.color?.trim() ?? '',
      clarity: product.clarity?.trim() ?? '',
      treatment: '',
      shape: product.shape?.trim() ?? '',
      hardness: 0,
      lab: product.certificateCompanyName?.trim() ?? '',
      dimensions: '',
      cut: product.cut?.trim(),
      certificate: product.certificateCompanyName?.trim(),
      imageUrl: hasImage ? imageUrl : null,
      imageUrls: hasImage ? [imageUrl] : const [],
      stockNumber: product.stockNumber.trim().isEmpty
          ? null
          : product.stockNumber.trim(),
      pricePerCarat: product.pricePerCarat,
    );
  }

  static Jewelry toJewelry(AiChatProduct product) {
    final imageUrl = product.imageUrl?.trim();
    return Jewelry(
      id: product.id,
      sku: product.stockNumber.trim().isEmpty
          ? product.id
          : product.stockNumber.trim(),
      name: product.title.trim().isEmpty ? 'Jewellery' : product.title.trim(),
      category: 'Jewellery',
      price: product.totalPrice ?? 0,
      metalType: '',
      metalColor: '',
      metalPurity: '',
      gender: '',
      occasion: '',
      condition: '',
      availability: '',
      stoneType: '',
      stoneCategory: '',
      stoneShape: product.shape?.trim() ?? '',
      certification: product.certificateCompanyName?.trim() ?? '',
      metalWeightG: 0,
      stoneWeightCt: product.caratWeight ?? 0,
      stoneCount: 0,
      colorVariants: const [],
      imageUrl: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
      hasMedia: imageUrl != null && imageUrl.isNotEmpty,
    );
  }

  static bool _isMelee(AiChatProduct product) {
    final type = product.productType.toLowerCase().replaceAll(
      RegExp(r'[\s_-]'),
      '',
    );
    return type.contains('melee');
  }

  static bool _isLabGrown(AiChatProduct product) {
    final href = product.href.toLowerCase();
    final type = product.productType.toLowerCase();
    return href.contains('lab-grown') ||
        href.contains('labgrown') ||
        type.contains('lab');
  }

  static String normalizedType(AiChatProduct product) {
    return product.productType.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  }
}
