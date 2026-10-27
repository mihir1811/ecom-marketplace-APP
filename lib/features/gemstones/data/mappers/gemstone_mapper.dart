import '../../../../core/network/api_config.dart';
import '../../../../core/utils/certificate_url.dart';
import '../../../product_detail/domain/models/listing_seller_info.dart';
import '../../domain/models/gemstone.dart';
import '../models/gemstone_dto.dart';

/// Maps API gemstone DTOs into domain listing models.
abstract final class GemstoneMapper {
  static Gemstone toDomain(GemstoneDto dto) {
    final images = _images(dto);
    final firstImage = images.isEmpty ? null : images.first;
    final lab = _clean(dto.certificateCompanyName) ?? '';
    final carat = dto.totalCarat ?? dto.caratPerPcs ?? 0;

    return Gemstone(
      id: dto.id,
      type: _clean(dto.gemsType) ?? 'Gemstone',
      carat: carat,
      price: dto.totalPrice ?? 0,
      origin: _clean(dto.origin) ?? '',
      color: _clean(dto.primaryColor) ?? '',
      clarity: _clean(dto.clarity) ?? '',
      treatment: _clean(dto.treatment) ?? '',
      shape: _clean(dto.shape) ?? '',
      hardness: dto.hardness ?? 0,
      lab: lab,
      dimensions: _clean(dto.measurement) ?? '',
      cut: _clean(dto.cut),
      certificate: _clean(dto.certificateNumber),
      certificateUrl: CertificateUrl.resolve(
        lab: lab,
        certificateNumber: dto.certificateNumber,
        certificateFileUrl: dto.certification,
        fallbackUrl: _asHttpUrl(dto.certification),
      ),
      imageUrl: firstImage,
      discount: dto.discount,
      stockNumber: _clean(dto.stockNumber),
      subType: _clean(dto.subType),
      qualityGrade: _clean(dto.qualityGrade),
      pricePerCarat: dto.pricePerCarat,
      pricePerPcs: dto.pricePerPcs,
      caratPerPcs: dto.caratPerPcs,
      quantity: dto.quantity,
      colorIntensity: _clean(dto.colorIntensity),
      imageUrls: images,
      isSeparable: _isTruthy(dto.isSeparable),
      isOnAuction: dto.isOnAuction ?? false,
      isSold: dto.isSold ?? false,
      isMakeAnOfferAllowed: dto.isMakeAnOfferAllowed ?? false,
      minimumOfferPrice: dto.minimumOfferPrice,
      maxOfferAttemptsPerUser: dto.maxOfferAttemptsPerUser ?? 5,
      availability: _clean(dto.availability),
      videoUrl: _resolveMediaUrl(dto.videoURL),
      listingSeller: listingSellerFromMap(dto.seller),
    );
  }

  static bool _isTruthy(String? value) {
    if (value == null) return false;
    final lower = value.trim().toLowerCase();
    return lower == 'yes' || lower == 'true' || lower == '1';
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

  static List<String> _images(GemstoneDto dto) {
    final out = <String>[];
    final seen = <String>{};
    for (final url in [
      dto.image1,
      dto.image2,
      dto.image3,
      dto.image4,
      dto.image5,
      dto.image6,
    ]) {
      final resolved = _resolveMediaUrl(url);
      if (resolved == null) continue;
      if (!seen.add(resolved)) continue;
      out.add(resolved);
    }
    return out;
  }

  /// Maps API `certification` to a viewable URL (http/https/www/relative).
  static String? _asHttpUrl(String? value) {
    final cleaned = _clean(value);
    if (cleaned == null) return null;
    final lower = cleaned.toLowerCase();
    if (lower.startsWith('https://') || lower.startsWith('http://')) {
      return cleaned;
    }
    if (lower.startsWith('www.')) return 'https://$cleaned';
    // Relative certificate paths hosted on the API origin.
    if (cleaned.startsWith('/') ||
        lower.endsWith('.pdf') ||
        lower.contains('/certificate')) {
      return _resolveMediaUrl(cleaned);
    }
    return null;
  }

  /// Absolute URL for API media (supports relative `/images/...` paths).
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
