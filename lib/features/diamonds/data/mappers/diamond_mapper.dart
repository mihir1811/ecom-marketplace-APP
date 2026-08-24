import '../../../diamond_viewer/utils/viewer_url_resolver.dart';
import '../../../product_detail/domain/models/listing_seller_info.dart';
import '../../domain/models/diamond.dart';
import '../models/diamond_dto.dart';

/// Maps API diamond DTOs into domain listing models.
abstract final class DiamondMapper {
  static Diamond toDomain(DiamondDto dto, {required bool isLabGrown}) {
    final videoUrl = ViewerUrlResolver.resolve(_clean(dto.videoURL));
    final images = _images(dto, videoUrl: videoUrl);
    final firstImage = images.isEmpty ? null : images.first;
    final cert = _clean(dto.certificateCompanyName) ?? '';
    final growth = _clean(dto.growthType);
    final labGrown = isLabGrown || _isLabGrowthType(growth);

    if (dto.isMelee) {
      final color = _range(dto.colorFrom, dto.colorTo) ?? _clean(dto.color);
      final clarity =
          _range(dto.clarityMin, dto.clarityMax) ?? _clean(dto.clarity);
      final cut = _range(dto.cutFrom, dto.cutTo) ?? _clean(dto.cut);
      final polish = _range(dto.polishFrom, dto.polishTo) ?? _clean(dto.polish);
      final symmetry =
          _range(dto.symmetryFrom, dto.symmetryTo) ?? _clean(dto.symmetry);
      final fluorescence = _clean(dto.fluorescenceIntensityFrom) ??
          _clean(dto.fluorescenceIntensity);
      final carat = dto.totalCaratWeight ??
          dto.caratWeightPerpcs ??
          dto.caratWeight ??
          0;
      final sieve = _range(dto.sieveSizeMin, dto.sieveSizeMax);
      final measurement = _range(dto.measurementMin, dto.measurementMax) ??
          _clean(dto.measurement);

      return Diamond(
        id: dto.id,
        shape: _clean(dto.shape) ?? 'Round',
        carat: carat,
        price: dto.totalPrice ?? 0,
        cut: cut ?? '',
        color: color ?? '',
        clarity: clarity ?? '',
        certificate: cert,
        imageUrl: firstImage,
        imageUrls: images,
        pricePerCarat: dto.pricePerCarat,
        polish: polish,
        symmetry: symmetry,
        fluorescence: fluorescence,
        fluorescenceColor: _clean(dto.fluorescenceColor),
        lab: cert.isEmpty ? null : cert,
        hasVideo: videoUrl != null,
        hasImage: firstImage != null,
        discount: dto.discount,
        isLabGrown: labGrown,
        isMelee: true,
        stockNumber: _clean(dto.stockNumber),
        growthType: growth,
        sellerCompanyName: _clean(dto.sellerCompanyName),
        sellerCity: _clean(dto.sellerCity),
        sellerCountry: _clean(dto.sellerCountry),
        listingSeller: listingSellerFromMap(dto.seller),
        measurement: measurement,
        ratio: _clean(dto.ratio),
        tablePercent: _clean(dto.table),
        depthPercent: _clean(dto.depth),
        certificateNumber: _clean(dto.certificateNumber),
        certificateUrl: _asHttpUrl(dto.certification),
        shade: _clean(dto.shade),
        fancyColor: _clean(dto.fancyColor),
        fancyIntensity: _clean(dto.fancyIntencity),
        fancyOvertone: _clean(dto.fancyOvertone),
        origin: _clean(dto.origin),
        roughSource: _clean(dto.roughSource),
        enhancement: _clean(dto.treatment) ?? _clean(dto.enhancement),
        girdleCondition: _clean(dto.gridleCondition),
        culetCondition: _clean(dto.culetCondition),
        milky: _clean(dto.milky),
        comment: _clean(dto.comment),
        eyeClean: dto.eyeClean,
        bgm: dto.bgm,
        heartAndArrow: dto.ha,
        isOnAuction: dto.isOnAuction ?? false,
        isSold: dto.isSold ?? false,
        isMakeAnOfferAllowed: dto.isMakeAnOfferAllowed ?? false,
        minimumOfferPrice: dto.minimumOfferPrice,
        totalPcs: dto.totalPcs,
        caratPerPcs: dto.caratWeightPerpcs,
        totalCaratWeight: dto.totalCaratWeight,
        pricePerPcs: dto.pricePerPcs,
        sieveLabel: sieve,
        isSeparable: _isTruthy(dto.isSeparable),
        available: _clean(dto.available),
        videoUrl: videoUrl,
      );
    }

    return Diamond(
      id: dto.id,
      shape: _clean(dto.shape) ?? 'Round',
      carat: dto.caratWeight ?? 0,
      price: dto.totalPrice ?? 0,
      cut: _clean(dto.cut) ?? '',
      color: _clean(dto.color) ?? '',
      clarity: _clean(dto.clarity) ?? '',
      certificate: cert,
      imageUrl: firstImage,
      imageUrls: images,
      pricePerCarat: dto.pricePerCarat,
      polish: _clean(dto.polish),
      symmetry: _clean(dto.symmetry),
      fluorescence: _clean(dto.fluorescenceIntensity),
      fluorescenceColor: _clean(dto.fluorescenceColor),
      lab: cert.isEmpty ? null : cert,
      hasVideo: videoUrl != null,
      hasImage: firstImage != null,
      discount: dto.discount,
      isLabGrown: labGrown,
      isMelee: false,
      stockNumber: _clean(dto.stockNumber),
      growthType: growth,
      sellerCompanyName: _clean(dto.sellerCompanyName),
      sellerCity: _clean(dto.sellerCity),
      sellerCountry: _clean(dto.sellerCountry),
      listingSeller: listingSellerFromMap(dto.seller),
      measurement: _clean(dto.measurement),
      ratio: _clean(dto.ratio),
      tablePercent: _clean(dto.table),
      depthPercent: _clean(dto.depth),
      certificateNumber: _clean(dto.certificateNumber),
      certificateUrl: _asHttpUrl(dto.certification),
      shade: _clean(dto.shade),
      fancyColor: _clean(dto.fancyColor),
      fancyIntensity: _clean(dto.fancyIntencity),
      fancyOvertone: _clean(dto.fancyOvertone),
      origin: _clean(dto.origin),
      roughSource: _clean(dto.roughSource),
      enhancement: _clean(dto.enhancement),
      girdleCondition: _clean(dto.gridleCondition),
      culetCondition: _clean(dto.culetCondition),
      milky: _clean(dto.milky),
      comment: _clean(dto.comment),
      eyeClean: dto.eyeClean,
      bgm: dto.bgm,
      heartAndArrow: dto.ha,
      isOnAuction: dto.isOnAuction ?? false,
      isSold: dto.isSold ?? false,
      isMakeAnOfferAllowed: dto.isMakeAnOfferAllowed ?? false,
      minimumOfferPrice: dto.minimumOfferPrice,
      available: _clean(dto.available),
      videoUrl: videoUrl,
    );
  }

  static bool _isLabGrowthType(String? growth) {
    if (growth == null || growth.isEmpty) return false;
    final lower = growth.toLowerCase();
    return lower == 'cvd' || lower == 'hpht';
  }

  static bool _isTruthy(String? value) {
    if (value == null) return false;
    final lower = value.trim().toLowerCase();
    return lower == 'yes' || lower == 'true' || lower == '1';
  }

  /// Maps API `certification` column to a viewable URL (http/https/www only).
  static String? _asHttpUrl(String? value) {
    final cleaned = _clean(value);
    if (cleaned == null) return null;
    final lower = cleaned.toLowerCase();
    if (lower.startsWith('https://') || lower.startsWith('http://')) {
      return cleaned;
    }
    if (lower.startsWith('www.')) return 'https://$cleaned';
    return null;
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

  /// Collects photo URLs from image1–6 (API often puts the 360 still in image2).
  /// When only `videoURL` is present, derives the CDN still for listing thumbs.
  static List<String> _images(DiamondDto dto, {String? videoUrl}) {
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
      final cleaned = ViewerUrlResolver.normalizeImageUrl(_clean(url));
      if (cleaned == null) continue;
      if (!seen.add(cleaned)) continue;
      out.add(cleaned);
    }
    if (out.isEmpty && videoUrl != null) {
      final still = ViewerUrlResolver.stillUrlFromViewer(videoUrl);
      if (still != null) out.add(still);
    }
    return out;
  }

  static String? _range(String? from, String? to) {
    final a = _clean(from);
    final b = _clean(to);
    if (a != null && b != null) {
      if (a.toLowerCase() == b.toLowerCase()) return a;
      return '$a–$b';
    }
    return a ?? b;
  }
}

extension DiamondDtoMapper on DiamondDto {
  Diamond toDomain({required bool isLabGrown}) =>
      DiamondMapper.toDomain(this, isLabGrown: isLabGrown);
}
