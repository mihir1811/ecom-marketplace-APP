import '../../../../core/network/api_config.dart';
import '../../domain/models/billion.dart';
import '../models/bullion_dto.dart';

/// Maps bullion API DTOs into listing domain models.
abstract final class BullionMapper {
  static Bullion toDomain(BullionDto dto) {
    final weight = dto.metalWeight ?? 0;
    final fineness = dto.metalFinenessValue?.trim() ?? '';
    final purity = double.tryParse(fineness) ?? 0;
    final images = _images(dto);
    final metalName = dto.metalTypeName ?? '';
    final shape = _titleCase(dto.metalShapeName) ?? '';
    final design = _clean(dto.design);
    final stock = _clean(dto.stockNumber);

    final name = design ??
        [
          if (weight > 0) _weightLabel(weight),
          if (metalName.isNotEmpty) _titleCase(metalName),
          if (shape.isNotEmpty) shape,
        ].whereType<String>().where((s) => s.isNotEmpty).join(' ');

    return Bullion(
      id: dto.id,
      metal: _mapMetal(metalName),
      name: name.isEmpty ? (stock ?? dto.id) : name,
      presetVariant: fineness.isNotEmpty ? fineness : _purityVariant(purity),
      shape: shape,
      weightLabel: _weightLabel(weight),
      weightGrams: weight,
      purity: purity,
      price: dto.price ?? 0,
      quantityAvailable: dto.quantity ?? 0,
      condition: _clean(dto.condition) ?? '',
      certification: _clean(dto.certification) ?? '',
      mintMark: _clean(dto.mintMark) ?? '',
      lengthMm: 0,
      widthMm: 0,
      heightMm: 0,
      stockNumber: stock,
      demention: _clean(dto.demention),
      certificateNumber: _clean(dto.certificateNumber),
      availability: _mapAvailability(dto.availability),
      mintYear: dto.mintYear,
      imageUrl: images.isEmpty ? null : images.first,
      imageUrls: images,
      sellerId: _clean(dto.sellerId),
    );
  }

  static BullionMetal _mapMetal(String raw) {
    return switch (raw.trim().toUpperCase()) {
      'GOLD' => BullionMetal.gold,
      'SILVER' => BullionMetal.silver,
      'PLATINUM' => BullionMetal.platinum,
      'PALLADIUM' => BullionMetal.palladium,
      'COPPER' => BullionMetal.copper,
      _ => BullionMetal.gold,
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

  static String _weightLabel(double grams) {
    if (grams <= 0) return '';
    const oz = 31.103;
    if ((grams - oz).abs() < 0.05) return '1oz';
    if (grams >= 1000 && (grams % 1000).abs() < 0.01) {
      final kg = grams / 1000;
      return kg == kg.roundToDouble()
          ? '${kg.toInt()}kg'
          : '${kg.toStringAsFixed(1)}kg';
    }
    if (grams == grams.roundToDouble()) return '${grams.toInt()}g';
    return '${grams.toStringAsFixed(3)}g';
  }

  static String _purityVariant(double purity) {
    if (purity <= 0) return '';
    if ((purity - 999.9).abs() < 0.05) return '24K';
    if ((purity - 916.7).abs() < 1 || (purity - 916).abs() < 1) return '22K';
    if ((purity - 750).abs() < 1) return '18K';
    return purity == purity.roundToDouble()
        ? purity.toInt().toString()
        : purity.toStringAsFixed(1);
  }

  static List<String> _images(BullionDto dto) {
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

  static String? _titleCase(String? raw) {
    final cleaned = _clean(raw);
    if (cleaned == null) return null;
    if (cleaned.length == 1) return cleaned.toUpperCase();
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1).toLowerCase()}';
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
