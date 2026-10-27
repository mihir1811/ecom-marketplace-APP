/// Marketplace filter enums and their display words.
///
/// The API sends upper-snake values (`YELLOW_GOLD`); the app shows them as
/// catalog words (`Yellow Gold`) so they also match metal swatches and
/// localized catalog labels.
abstract final class MarketplaceEnums {
  static const metals = [
    'YELLOW_GOLD',
    'WHITE_GOLD',
    'ROSE_GOLD',
    'PLATINUM',
    'STERLING_SILVER',
    'TITANIUM',
    'TWO_TONE',
    'MIXED',
    'OTHER',
  ];

  static const gemstones = [
    'DIAMOND',
    'SAPPHIRE',
    'RUBY',
    'EMERALD',
    'MOISSANITE',
    'PEARL',
    'AMETHYST',
    'AQUAMARINE',
    'TOPAZ',
    'TANZANITE',
    'MORGANITE',
    'OPAL',
    'GARNET',
    'TOURMALINE',
    'PERIDOT',
    'CITRINE',
    'SPINEL',
    'ALEXANDRITE',
    'ONYX',
    'TURQUOISE',
    'OTHER',
  ];

  static const origins = ['NATURAL', 'LAB_GROWN'];

  /// Metal tones offered as one-tap quick filters.
  static const quickMetals = ['YELLOW_GOLD', 'WHITE_GOLD', 'ROSE_GOLD', 'PLATINUM'];

  /// `YELLOW_GOLD` → `Yellow Gold`; `LAB_GROWN` → `Lab-Grown`.
  static String label(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '';
    return switch (v) {
      'LAB_GROWN' => 'Lab-Grown',
      'TWO_TONE' => 'Two-Tone',
      'STERLING_SILVER' => 'Sterling Silver',
      _ => v
          .split('_')
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' '),
    };
  }

  /// Label a [LuxeMetalSwatch] knows how to paint.
  static String swatchLabel(String? metal) => switch (metal) {
    'STERLING_SILVER' => 'Silver',
    final m => label(m),
  };
}
