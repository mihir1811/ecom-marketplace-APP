import '../../../../core/network/api_config.dart';
import '../../domain/models/watch.dart';
import '../models/watch_dto.dart';

/// Maps watch API DTOs into listing domain models.
abstract final class WatchMapper {
  static Watch toDomain(WatchDto dto) {
    final caseSize = dto.caseSize ?? 0;
    final year = dto.modelYear ?? 0;
    final waterM = _parseWaterMeters(dto.waterResistance);
    final images = _images(dto);
    final materials = <String>{
      if (_clean(dto.caseMaterial) != null) _clean(dto.caseMaterial)!,
      if (_clean(dto.strapMaterial) != null) _clean(dto.strapMaterial)!,
    }.toList();

    final category = dto.style.isNotEmpty
        ? dto.style.first
        : (_clean(dto.collection) ?? 'Luxury');

    return Watch(
      id: dto.id,
      brand: _clean(dto.brand) ?? '',
      model: _clean(dto.model) ?? '',
      collection: _clean(dto.collection) ?? '',
      year: year,
      price: dto.price ?? 0,
      condition: _mapCondition(dto.condition),
      caseSizeMm: caseSize,
      caseSizeRange: _caseSizeRangeFor(caseSize),
      caseMaterial: _clean(dto.caseMaterial) ?? '',
      caseShape: _clean(dto.caseShape) ?? '',
      caseBack: _clean(dto.caseBack) ?? '',
      dialColor: _clean(dto.dialColor) ?? '',
      strapColor: _clean(dto.strapColor) ?? '',
      strapMaterial: _clean(dto.strapMaterial) ?? '',
      crownType: _clean(dto.crownType) ?? '',
      claspType: _clean(dto.claspType) ?? '',
      claspMaterial: _clean(dto.claspMaterial) ?? '',
      movement: _mapMovement(dto.movementType),
      gender: _mapGender(dto.gender),
      waterResistanceM: waterM,
      glassMaterial: _clean(dto.glass) ?? '',
      lugWidth: _mapLugWidth(dto.lugWidth),
      powerReserveRange: _mapPowerReserve(dto.powerReserve),
      certification: _clean(dto.certification) ?? '',
      bezelType: _clean(dto.bezelType) ?? '',
      bezelMaterial: _clean(dto.bezelMaterial) ?? '',
      configurations: dto.complications.isNotEmpty
          ? dto.complications
          : dto.features,
      materials: materials,
      preciousStoneTypes: dto.preciousStoneType,
      indexes: _clean(dto.indexes) ?? '',
      category: category,
      availabilityStatus: _mapAvailability(dto.availabilityStatus),
      imageUrl: images.isEmpty ? null : images.first,
      hasVideo: _clean(dto.videoURL) != null,
      boxIncluded: dto.boxIncluded ?? false,
      papersIncluded: dto.papersIncluded ?? false,
      warrantyCardIncluded: dto.warrantyCardIncluded ?? false,
      inStock: _mapAvailability(dto.availabilityStatus) == 'Available',
      sellerId: _clean(dto.sellerId),
    );
  }

  static String _caseSizeRangeFor(int mm) {
    if (mm <= 0) return '';
    if (mm <= 25) return '10-25 mm';
    if (mm <= 30) return '26-30 mm';
    if (mm <= 35) return '31-35 mm';
    if (mm <= 40) return '36-40 mm';
    if (mm <= 45) return '41-45 mm';
    return '>46 mm';
  }

  static int _parseWaterMeters(String? raw) {
    if (raw == null) return 0;
    final match = RegExp(r'(\d+)').firstMatch(raw);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static String _mapLugWidth(String? raw) {
    final cleaned = _clean(raw);
    if (cleaned == null) return '';
    final mm = int.tryParse(RegExp(r'(\d+)').firstMatch(cleaned)?.group(1) ?? '');
    if (mm == null) return cleaned;
    if (mm < 18) return 'Under 18 mm';
    if (mm <= 20) return '18–20 mm';
    if (mm <= 22) return '21–22 mm';
    if (mm <= 24) return '23–24 mm';
    return 'Over 24 mm';
  }

  static String _mapPowerReserve(int? hours) {
    if (hours == null || hours <= 0) return '';
    if (hours < 40) return 'Under 40h';
    if (hours <= 48) return '40–48h';
    if (hours <= 72) return '49–72h';
    return 'Over 72h';
  }

  static String _mapMovement(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    return switch (v) {
      'AUTOMATIC' => 'Automatic (Self-winding)',
      'MANUAL' => 'Manual (Hand-winding)',
      'QUARTZ' => 'Quartz (Battery)',
      'SPRING_DRIVE' => 'Spring Drive',
      'SOLAR' => 'Solar Powered',
      'KINETIC' => 'Kinetic',
      _ => raw?.trim().isNotEmpty == true ? raw!.trim() : '',
    };
  }

  static String _mapGender(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'women' || 'woman' || 'female' => 'Women',
      'men' || 'man' || 'male' => 'Men',
      'unisex' => 'Unisex',
      'kids' || 'kid' => 'Kids',
      _ => raw?.trim().isNotEmpty == true ? raw!.trim() : 'Unisex',
    };
  }

  static String _mapAvailability(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'yes' || 'available' => 'Available',
      'hold' || 'on hold' => 'On Hold',
      'memo' => 'Memo',
      _ => raw?.trim().isNotEmpty == true ? raw!.trim() : 'Available',
    };
  }

  static String _mapCondition(String? raw) {
    final cleaned = _clean(raw);
    if (cleaned == null) return '';
    final lower = cleaned.toLowerCase();
    if (lower == 'new' || lower == 'new / unworn') return 'New / Unworn';
    return cleaned;
  }

  static List<String> _images(WatchDto dto) {
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
