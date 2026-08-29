import '../../diamonds/domain/models/diamond_filter_state.dart';
import '../../gemstones/domain/models/gemstone_filter_state.dart';
import '../domain/models/ai_chat_product.dart';

enum AiChatListingKind {
  diamondNatural,
  diamondLabGrown,
  gemstone,
  jewelry,
  other,
}

class AiChatInferredListing {
  const AiChatInferredListing({
    required this.kind,
    this.diamondFilters,
    this.gemstoneFilters,
  });

  final AiChatListingKind kind;
  final DiamondFilterState? diamondFilters;
  final GemstoneFilterState? gemstoneFilters;
}

/// Builds catalog filters from the user’s ask + AI match cards / group labels.
abstract final class AiChatFilterInference {
  static const _shapes = <String>[
    'Round',
    'Princess',
    'Cushion',
    'Oval',
    'Emerald',
    'Pear',
    'Marquise',
    'Radiant',
    'Heart',
    'Asscher',
    'Square Emerald',
    'Square Radiant',
    'Trillion',
    'Baguette',
    'Rose',
    'Half Moon',
    'Trapezoid',
    'Shield',
    'Hexagonal',
    'Octagonal',
    'Pentagonal',
    'Star',
    'Other',
  ];

  static const _cutMap = <String, String>{
    'id': 'Ideal',
    'ideal': 'Ideal',
    'ex': 'Excellent',
    'excellent': 'Excellent',
    'vg': 'Very Good',
    'very good': 'Very Good',
    'good': 'Good',
    'fair': 'Fair',
  };

  static AiChatInferredListing infer({
    required String userQuery,
    required List<AiChatProduct> products,
    List<AiChatProductGroup> productGroups = const [],
  }) {
    final q = userQuery.toLowerCase();
    final groupText = productGroups
        .map((g) => g.label.toLowerCase())
        .join(' · ');
    final blob =
        '$q $groupText ${products.map((p) => '${p.productType} ${p.href}').join(' ')}'
            .toLowerCase();

    final type = _resolveType(blob, products, productGroups);
    if (type == AiChatListingKind.gemstone) {
      return AiChatInferredListing(
        kind: type,
        gemstoneFilters: _gemstoneFilters(q, products, productGroups),
      );
    }
    if (type == AiChatListingKind.jewelry) {
      return const AiChatInferredListing(kind: AiChatListingKind.jewelry);
    }
    if (type == AiChatListingKind.other) {
      return const AiChatInferredListing(kind: AiChatListingKind.other);
    }

    return AiChatInferredListing(
      kind: type,
      diamondFilters: _diamondFilters(
        q: q,
        blob: blob,
        products: products,
        productGroups: productGroups,
        isLabGrown: type == AiChatListingKind.diamondLabGrown,
      ),
    );
  }

  static AiChatListingKind _resolveType(
    String blob,
    List<AiChatProduct> products,
    List<AiChatProductGroup> groups,
  ) {
    final sampleType =
        (products.isNotEmpty
                ? products.first.productType
                : (groups.isNotEmpty ? groups.first.productType : ''))
            .toLowerCase()
            .replaceAll(RegExp(r'[\s_-]'), '');

    final hasNaturalSignal =
        RegExp(r'\bnatural\b').hasMatch(blob) ||
        products.any((p) {
          final href = p.href.toLowerCase();
          return href.contains('/diamonds/') &&
              !href.contains('lab-grown') &&
              !href.contains('labgrown');
        });

    final hasLabGrownSignal =
        blob.contains('lab grown') ||
        blob.contains('lab-grown') ||
        blob.contains('labgrown') ||
        RegExp(r'\blab[-\s]?grown\b').hasMatch(blob) ||
        blob.contains('cvd') ||
        blob.contains('hpht') ||
        products.any((p) {
          final href = p.href.toLowerCase();
          final type = p.productType.toLowerCase();
          return href.contains('lab-grown') ||
              href.contains('labgrown') ||
              type.contains('labgrown') ||
              type.contains('lab-grown');
        });

    final isDiamondContext =
        sampleType.contains('diamond') ||
        sampleType.contains('melee') ||
        blob.contains('diamond') ||
        blob.contains('melee') ||
        blob.contains('carat') ||
        RegExp(r'\b\d+(\.\d+)?\s*ct\b').hasMatch(blob) ||
        products.isNotEmpty && sampleType.isNotEmpty;

    // Gemstones only when clearly not a diamond search (avoid "Emerald" cut).
    if (!isDiamondContext &&
        (sampleType.contains('gem') ||
            blob.contains('gemstone') ||
            blob.contains('ruby') ||
            blob.contains('sapphire') ||
            (blob.contains('emerald') && !blob.contains('cut')))) {
      return AiChatListingKind.gemstone;
    }
    if (!isDiamondContext &&
        (sampleType.contains('jewel') ||
            blob.contains('jewellery') ||
            blob.contains('jewelry'))) {
      return AiChatListingKind.jewelry;
    }

    // Natural wins when both appear or when natural is explicit.
    if (hasLabGrownSignal && !hasNaturalSignal) {
      return AiChatListingKind.diamondLabGrown;
    }
    if (isDiamondContext ||
        hasNaturalSignal ||
        products.isNotEmpty ||
        blob.contains('ct') ||
        blob.contains('carat')) {
      return AiChatListingKind.diamondNatural;
    }
    return AiChatListingKind.other;
  }

  static DiamondFilterState _diamondFilters({
    required String q,
    required String blob,
    required List<AiChatProduct> products,
    required List<AiChatProductGroup> productGroups,
    required bool isLabGrown,
  }) {
    final shapes = <String>{};
    final colors = <String>{};
    final clarities = <String>{};
    final cuts = <String>{};
    final labs = <String>{};

    for (final shape in _shapes) {
      if (RegExp('\\b${RegExp.escape(shape.toLowerCase())}\\b').hasMatch(q) ||
          RegExp(
            '\\b${RegExp.escape(shape.toLowerCase())}\\b',
          ).hasMatch(blob)) {
        shapes.add(shape);
      }
    }
    for (final p in products) {
      final mapped = _mapShape(p.shape);
      if (mapped != null) shapes.add(mapped);
      final color = _mapColor(p.color);
      if (color != null) colors.add(color);
      final clarity = _mapClarity(p.clarity);
      if (clarity != null) clarities.add(clarity);
      final cut = _mapCut(p.cut);
      if (cut != null) cuts.add(cut);
      final lab = p.certificateCompanyName?.trim().toUpperCase();
      if (lab != null &&
          lab.isNotEmpty &&
          DiamondFilterState.labs.any((l) => l.toUpperCase() == lab)) {
        labs.add(
          DiamondFilterState.labs.firstWhere((l) => l.toUpperCase() == lab),
        );
      }
    }

    // Query tokens for color / clarity (e.g. "VS1", "G").
    for (final c in DiamondFilterState.colors) {
      if (RegExp('\\b${c.toLowerCase()}\\b').hasMatch(q)) colors.add(c);
    }
    for (final c in DiamondFilterState.clarities) {
      if (RegExp('\\b${RegExp.escape(c.toLowerCase())}\\b').hasMatch(q)) {
        clarities.add(c);
      }
    }
    for (final entry in _cutMap.entries) {
      if (q.contains(entry.key)) cuts.add(entry.value);
    }

    // Group labels: "Round · 0.95–1.05ct · G · VS1 · natural · Single"
    for (final group in productGroups) {
      for (final part in group.label.split('·')) {
        final token = part.trim();
        final shape = _mapShape(token);
        if (shape != null) shapes.add(shape);
        final color = _mapColor(token);
        if (color != null) colors.add(color);
        final clarity = _mapClarity(token);
        if (clarity != null) clarities.add(clarity);
      }
    }

    final carat = _caratRange(q, products, productGroups);
    final isMelee =
        blob.contains('melee') ||
        blob.contains('parcel') ||
        products.any((p) => p.productType.toLowerCase().contains('melee'));

    return DiamondFilterState(
      labNatural: isMelee ? LabNaturalType.labGrown : LabNaturalType.natural,
      labCategory: isMelee ? 'Lab Melee' : 'Lab Diamond',
      shapes: List<String>.unmodifiable(shapes),
      minCarat: carat.$1,
      maxCarat: carat.$2,
      selectedStandardColors: List<String>.unmodifiable(colors),
      selectedClarityGrades: List<String>.unmodifiable(clarities),
      selectedCuts: List<String>.unmodifiable(cuts),
      selectedLabs: List<String>.unmodifiable(labs),
    );
  }

  static GemstoneFilterState _gemstoneFilters(
    String q,
    List<AiChatProduct> products,
    List<AiChatProductGroup> groups,
  ) {
    final types = <String>{};
    final shapes = <String>{};
    final allTypes = [
      ...GemstoneFilterState.primaryGemstoneTypes,
      ...GemstoneFilterState.extendedGemstoneTypes,
    ];
    for (final type in allTypes) {
      if (q.contains(type.toLowerCase())) types.add(type);
    }
    for (final p in products) {
      final mapped = _mapShape(p.shape);
      if (mapped != null) shapes.add(mapped);
      for (final type in allTypes) {
        if (p.title.toLowerCase().contains(type.toLowerCase())) {
          types.add(type);
        }
      }
    }

    final isLab = q.contains('lab');
    final isMelee = q.contains('melee');
    final carat = _caratRange(q, products, groups);

    return GemstoneFilterState(
      stoneType: isLab ? 'Lab Grown' : 'Natural',
      lotType: isMelee ? 'Melee' : 'Single',
      selectedGemstoneTypes: List<String>.unmodifiable(types),
      selectedShapes: List<String>.unmodifiable(shapes),
      minTotalCarat: carat.$1 < GemstoneFilterState.caratMin
          ? GemstoneFilterState.caratMin
          : carat.$1,
      maxTotalCarat: carat.$2,
    );
  }

  static (double, double) _caratRange(
    String q,
    List<AiChatProduct> products,
    List<AiChatProductGroup> groups,
  ) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:-|–|to)?\s*(\d+(?:\.\d+)?)?\s*(?:ct|carat)',
    ).firstMatch(q);
    if (match != null) {
      final a = double.tryParse(match.group(1)!);
      final b = match.group(2) != null
          ? double.tryParse(match.group(2)!)
          : null;
      if (a != null && b != null) {
        return (a < b ? a : b, a < b ? b : a);
      }
      if (a != null) {
        final pad = a >= 1 ? 0.1 : 0.05;
        return ((a - pad).clamp(0.0, 100.0), (a + pad).clamp(0.0, 100.0));
      }
    }

    // Group label ranges: 0.95–1.05ct
    for (final group in groups) {
      final gm = RegExp(
        r'(\d+(?:\.\d+)?)\s*[–-]\s*(\d+(?:\.\d+)?)\s*ct',
      ).firstMatch(group.label.toLowerCase());
      if (gm != null) {
        final a = double.tryParse(gm.group(1)!);
        final b = double.tryParse(gm.group(2)!);
        if (a != null && b != null) {
          return (a < b ? a : b, a < b ? b : a);
        }
      }
    }

    final weights = products
        .map((p) => p.caratWeight)
        .whereType<double>()
        .toList(growable: false);
    if (weights.isNotEmpty) {
      weights.sort();
      final min = weights.first;
      final max = weights.last;
      const pad = 0.05;
      return ((min - pad).clamp(0.0, 100.0), (max + pad).clamp(0.0, 100.0));
    }

    return (0.0, 100.0);
  }

  static String? _mapShape(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    for (final shape in _shapes) {
      if (shape.toLowerCase() == lower) return shape;
    }
    if (lower == 'sq emerald' || lower == 'squareemerald') {
      return 'Square Emerald';
    }
    return null;
  }

  static String? _mapColor(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim().toUpperCase();
    if (DiamondFilterState.colors.contains(value)) return value;
    return null;
  }

  static String? _mapClarity(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim().toUpperCase();
    if (DiamondFilterState.clarities.contains(value)) return value;
    return null;
  }

  static String? _mapCut(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final key = raw.trim().toLowerCase();
    return _cutMap[key];
  }
}
