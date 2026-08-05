import '../../gemstones/domain/models/gemstone_filter_state.dart';
import '../../watches/domain/models/watch_brand_categories.dart';

/// Client-side spelling correction for marketplace search tokens.
///
/// Corrects typos like `emareld` → `Emerald` against known catalog vocabulary
/// (shapes, gem types, grades, brands, categories) before API fan-out.
abstract final class HomeSearchSpelling {
  static final List<String> _dictionary = _buildDictionary();

  /// Common hard-coded fixes for frequent marketplace typos.
  static const _aliases = <String, String>{
    // Gemstones
    'emareld': 'Emerald',
    'emeraled': 'Emerald',
    'emrald': 'Emerald',
    'emeralad': 'Emerald',
    'emmerald': 'Emerald',
    'saphire': 'Sapphire',
    'saphyre': 'Sapphire',
    'safire': 'Sapphire',
    'sappire': 'Sapphire',
    'sapphirre': 'Sapphire',
    'rubi': 'Ruby',
    'rubby': 'Ruby',
    'rubey': 'Ruby',
    'diamon': 'Diamond',
    'dimond': 'Diamond',
    'diamnd': 'Diamond',
    'diamonds': 'Diamond',
    'dyamond': 'Diamond',
    'tanzanit': 'Tanzanite',
    'tanzanite': 'Tanzanite',
    'tanzinite': 'Tanzanite',
    'tanzinitee': 'Tanzanite',
    'amethist': 'Amethyst',
    'amethyst': 'Amethyst',
    'amathest': 'Amethyst',
    'amathyst': 'Amethyst',
    'aquamarne': 'Aquamarine',
    'aquamrine': 'Aquamarine',
    'aquamaren': 'Aquamarine',
    'aqumariine': 'Aquamarine',
    'topaz': 'Topaz',
    'topazs': 'Topaz',
    'topaze': 'Topaz',
    'opal': 'Opal',
    'opel': 'Opal',
    'opall': 'Opal',
    'garnet': 'Garnet',
    'garnett': 'Garnet',
    'garnat': 'Garnet',
    'peridot': 'Peridot',
    'peridote': 'Peridot',
    'peridottt': 'Peridot',
    'morganite': 'Morganite',
    'morganit': 'Morganite',
    'morgonite': 'Morganite',
    'tourmaline': 'Tourmaline',
    'tourmaliine': 'Tourmaline',
    'tourmalene': 'Tourmaline',
    'citrine': 'Citrine',
    'citrin': 'Citrine',
    'citreen': 'Citrine',
    'spinel': 'Spinel',
    'spinell': 'Spinel',
    'spinle': 'Spinel',
    'alexandrite': 'Alexandrite',
    'alexandrit': 'Alexandrite',
    'alexandrte': 'Alexandrite',
    'turquoise': 'Turquoise',
    'turqoise': 'Turquoise',
    'turquose': 'Turquoise',
    'zircon': 'Zircon',
    'zircone': 'Zircon',
    'zirconn': 'Zircon',
    'moonstone': 'Moonstone',
    'moonstome': 'Moonstone',
    'moonstne': 'Moonstone',
    'onyx': 'Onyx',
    'onix': 'Onyx',
    'onyxx': 'Onyx',
    'jade': 'Jade',
    'jaed': 'Jade',
    'jadee': 'Jade',
    'pearl': 'Pearl',
    'pearle': 'Pearl',
    'peral': 'Pearl',
    'gemston': 'Gemstone',
    'gemstoe': 'Gemstone',
    'gemstonee': 'Gemstone',

    // Shapes / cuts
    'princces': 'Princess',
    'princes': 'Princess',
    'pricess': 'Princess',
    'priness': 'Princess',
    'cushin': 'Cushion',
    'cushon': 'Cushion',
    'cushen': 'Cushion',
    'cusion': 'Cushion',
    'marquize': 'Marquise',
    'marqise': 'Marquise',
    'marquisee': 'Marquise',
    'marqee': 'Marquise',
    'briliant': 'Round',
    'brilant': 'Round',
    'brillant': 'Round',
    'rond': 'Round',
    'rouond': 'Round',
    'ovval': 'Oval',
    'ovle': 'Oval',
    'ovall': 'Oval',
    'peare': 'Pear',
    'paar': 'Pear',
    'pearr': 'Pear',
    'radient': 'Radiant',
    'radiantt': 'Radiant',
    'radinat': 'Radiant',
    'ascher': 'Asscher',
    'assher': 'Asscher',
    'ascherr': 'Asscher',
    'haert': 'Heart',
    'heqrt': 'Heart',
    'heartt': 'Heart',
    'baguette': 'Baguette',
    'baggete': 'Baguette',
    'bagette': 'Baguette',
    'triliant': 'Trilliant',
    'trilliant': 'Trilliant',
    'trilllion': 'Trillion',
    'triliion': 'Trillion',

    // Categories / product types
    'jewellery': 'Jewelry',
    'jewlery': 'Jewelry',
    'jewelery': 'Jewelry',
    'jewllery': 'Jewelry',
    'jwellery': 'Jewelry',
    'bulion': 'Bullion',
    'bullien': 'Bullion',
    'bullon': 'Bullion',
    'bullioon': 'Bullion',
    'wacht': 'Watch',
    'wathc': 'Watch',
    'watvh': 'Watch',
    'wacth': 'Watch',
    'meele': 'Melee',
    'mele': 'Melee',
    'meleea': 'Melee',
    'natral': 'Natural',
    'naturall': 'Natural',
    'natrual': 'Natural',
    'labgrown': 'Lab',
    'labb': 'Lab',
    'ribbng': 'Ring',
    'ringg': 'Ring',
    'rinig': 'Ring',
    'necklase': 'Necklace',
    'neckless': 'Necklace',
    'neklace': 'Necklace',
    'braclet': 'Bracelet',
    'bracelit': 'Bracelet',
    'bracelete': 'Bracelet',
    'earing': 'Earring',
    'earings': 'Earrings',
    'earringss': 'Earrings',
    'pendent': 'Pendant',
    'pendannt': 'Pendant',
    'pendnat': 'Pendant',
    'coinn': 'Coin',
    'barr': 'Bar',

    // Metals
    'golld': 'Gold',
    'gld': 'Gold',
    'gould': 'Gold',
    'silvr': 'Silver',
    'sliver': 'Silver',
    'silveer': 'Silver',
    'platnum': 'Platinum',
    'platinam': 'Platinum',
    'platinium': 'Platinum',
    'paladium': 'Palladium',
    'palladuim': 'Palladium',
    'palldium': 'Palladium',

    // Clarity / cut grades
    'vs1': 'VS1',
    'vs2': 'VS2',
    'vvs1': 'VVS1',
    'vvs2': 'VVS2',
    'si1': 'SI1',
    'si2': 'SI2',
    'si3': 'SI3',
    'exellent': 'Excellent',
    'excelent': 'Excellent',
    'excellant': 'Excellent',
    'ideel': 'Ideal',
    'idael': 'Ideal',
    'verrygood': 'Very Good',
    'vreygood': 'Very Good',

    // Certifications / growth
    'giaa': 'GIA',
    'igg': 'IGI',
    'igii': 'IGI',
    'hrdd': 'HRD',
    'gcall': 'GCAL',
    'cvdd': 'CVD',
    'hphtt': 'HPHT',
    'hpth': 'HPHT',

    // Watch brands
    'rolexs': 'Rolex',
    'roleex': 'Rolex',
    'rollex': 'Rolex',
    'omgea': 'Omega',
    'omaga': 'Omega',
    'omege': 'Omega',
    'patek': 'Patek',
    'patekk': 'Patek',
    'patak': 'Patek',
    'cartierr': 'Cartier',
    'cartie': 'Cartier',
    'cartyer': 'Cartier',
    'tudor': 'Tudor',
    'tudorr': 'Tudor',
    'tudour': 'Tudor',
    'tagheuer': 'TAG Heuer',
    'taghuer': 'TAG Heuer',
    'tagheur': 'TAG Heuer',
    'breitlingg': 'Breitling',
    'breitlng': 'Breitling',
    'breitliing': 'Breitling',
    'iwcc': 'IWC',
    'paneraai': 'Panerai',
    'paneraii': 'Panerai',
    'paneria': 'Panerai',
    'seikoo': 'Seiko',
    'seiko': 'Seiko',
    'seikoe': 'Seiko',
  };

  /// Returns a corrected query. Unchanged tokens keep original casing/shape.
  static String correct(String query) {
    final trimmed = query.trim();
    if (trimmed.length < 3) return trimmed;

    final parts = trimmed.split(RegExp(r'\s+'));
    final corrected = <String>[];
    for (final part in parts) {
      corrected.add(_correctToken(part));
    }
    return corrected.join(' ');
  }

  static bool didChange(String original, String corrected) {
    return original.trim().toLowerCase() != corrected.trim().toLowerCase();
  }

  static String _correctToken(String token) {
    final raw = token.trim();
    if (raw.length < 3) return raw;

    // Keep numeric / carat-like tokens untouched ("2ct", "1.5", "2.04").
    if (RegExp(r'^\d').hasMatch(raw) ||
        RegExp(r'(ct|carat)', caseSensitive: false).hasMatch(raw)) {
      return raw;
    }

    final lower = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (lower.length < 3) return raw;

    final alias = _aliases[lower];
    if (alias != null) return alias;

    String? best;
    var bestDistance = 1 << 30;

    for (final candidate in _dictionary) {
      final cLower = candidate.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (cLower.isEmpty) continue;
      if (cLower == lower) return _preserveCase(raw, candidate);

      // Prefer same starting letter for short words.
      if (cLower[0] != lower[0] && lower.length <= 5) continue;

      final maxDist = _maxDistance(lower.length);
      if ((cLower.length - lower.length).abs() > maxDist) continue;

      final dist = _levenshtein(lower, cLower);
      if (dist <= maxDist && dist < bestDistance) {
        bestDistance = dist;
        best = candidate;
      }
    }

    return best == null ? raw : _preserveCase(raw, best);
  }

  static int _maxDistance(int length) {
    if (length <= 4) return 1;
    if (length <= 7) return 2;
    return 3;
  }

  static String _preserveCase(String original, String canonical) {
    // Keep dictionary/canonical form (title case) for known catalog terms.
    return canonical;
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1,
          curr[j - 1] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      for (var j = 0; j <= b.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }

  static List<String> _buildDictionary() {
    final set = <String>{
      // Categories
      'Diamond', 'Diamonds', 'Gemstone', 'Gemstones', 'Jewelry', 'Jewellery',
      'Watch', 'Watches', 'Bullion', 'Bullions', 'Melee', 'Lab', 'Natural',
      // Shapes
      'Round', 'Oval', 'Pear', 'Cushion', 'Princess', 'Emerald', 'Radiant',
      'Asscher', 'Marquise', 'Heart', 'Trilliant', 'Trillion', 'Baguette',
      // Colors / clarity / cut
      'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
      'FL', 'IF', 'VVS1', 'VVS2', 'VS1', 'VS2', 'SI1', 'SI2', 'SI3', 'I1', 'I2', 'I3',
      'Excellent', 'Ideal', 'Very Good', 'Good', 'Fair', 'Poor',
      // Certs / metals / jewelry
      'GIA', 'IGI', 'HRD', 'AGS', 'GCAL', 'SSEF', 'AGL', 'GRS',
      'Gold', 'Silver', 'Platinum', 'Palladium',
      'Ring', 'Necklace', 'Bracelet', 'Earring', 'Earrings', 'Pendant',
      'Bar', 'Coin',
      // Growth
      'CVD', 'HPHT',
      ...GemstoneFilterState.allGemstoneTypes,
      ...GemstoneFilterState.certifications,
      ...GemstoneFilterState.origins,
      for (final group in watchBrandCategories) ...group.brands,
    };

    // Split multi-word brands into searchable tokens too.
    final extras = <String>{};
    for (final entry in set) {
      for (final part in entry.split(RegExp(r'[\s&]+'))) {
        final clean = part.trim();
        if (clean.length >= 3) extras.add(clean);
      }
    }
    set.addAll(extras);
    return set.toList(growable: false);
  }
}

/// Parses intentional carat cues from free text (`2ct`, `2 carat`, `1.5`).
abstract final class HomeSearchCaratParser {
  /// Treated as an exact carat hit (e.g. `5 carat` ↔ `5.00ct`).
  static const double exactTolerance = 0.05;

  static double? parse(String query) {
    final trimmed = query.trim();
    final explicit = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:ct|carat|carats)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    final bare = RegExp(r'^(\d+(?:\.\d+)?)$').firstMatch(trimmed);
    final match = explicit ?? bare;
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!);
    if (value == null || value <= 0 || value > 100) return null;
    return value;
  }

  static bool isExactMatch(double distance) => distance <= exactTolerance;

  /// True when the query is only a carat cue (`5`, `5ct`, `5 carat`).
  static bool isCaratDominant(String query) {
    final trimmed = query.trim();
    if (parse(trimmed) == null) return false;
    final leftover = trimmed
        .replaceAll(
          RegExp(
            r'(\d+(?:\.\d+)?)\s*(?:ct|carat|carats)?\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
        .trim();
    return leftover.isEmpty;
  }

  /// Tight window used for primary carat lookup (exact intent).
  static (double min, double max) exactRange(double target) {
    return (
      (target - exactTolerance).clamp(0.0, 100.0),
      (target + exactTolerance).clamp(0.0, 100.0),
    );
  }

  /// Wider window used only when no exact carat hits exist.
  static (double min, double max) nearbyRange(double target) {
    final pad = target < 1 ? 0.12 : (target < 2 ? 0.18 : 0.25);
    return (
      (target - pad).clamp(0.0, 100.0),
      (target + pad).clamp(0.0, 100.0),
    );
  }
}
