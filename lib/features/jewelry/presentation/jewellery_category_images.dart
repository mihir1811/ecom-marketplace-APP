import 'package:flutter/painting.dart';

import '../../../core/l10n/app_localizations.dart';

/// Bundled art for jewellery category tiles: marketplace categories usually
/// have no `imageUrl`.
abstract final class JewelleryCategoryImages {
  static const _dir = 'public/images/jewelryCategoryImages';

  /// Art for a category slug (or name).
  static String assetFor(String slug) {
    return switch (slug.trim().toLowerCase()) {
      'ring' || 'rings' => '$_dir/ring.webp',
      'bracelet' || 'bracelets' => '$_dir/bracelet.webp',
      'earring' || 'earrings' => '$_dir/earrings.webp',
      'necklace' || 'necklaces' || 'chain' || 'chains' => '$_dir/necklace.webp',
      _ => '$_dir/set.webp',
    };
  }

  static String? absoluteUrl(String? imageUrl) {
    final raw = imageUrl?.trim() ?? '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return null;
  }
}

/// One cut-out hero piece on the jewelry house stage.
class JewelryShowcasePiece {
  const JewelryShowcasePiece({
    required this.asset,
    required this.labelKey,
    required this.category,
    required this.glow,
  });

  /// Transparent cut-out art.
  final String asset;

  /// Localized collection label ("Rings").
  final String labelKey;

  /// UI category name the piece opens (matched to the live API name).
  final String category;

  /// Warm light behind the piece.
  final Color glow;

  static const _dir = 'public/images/jewelryShowcase';

  static const all = [
    JewelryShowcasePiece(
      asset: '$_dir/necklace.webp',
      labelKey: JewelryFlowL10n.necklaces,
      category: 'Necklaces',
      glow: Color(0xFFDDBF88),
    ),
    JewelryShowcasePiece(
      asset: '$_dir/ring.webp',
      labelKey: JewelryFlowL10n.rings,
      category: 'Rings',
      glow: Color(0xFFA066D9),
    ),
    JewelryShowcasePiece(
      asset: '$_dir/earrings.webp',
      labelKey: JewelryFlowL10n.earrings,
      category: 'Earrings',
      glow: Color(0xFFEAD9B0),
    ),
    JewelryShowcasePiece(
      asset: '$_dir/bracelet.webp',
      labelKey: JewelryFlowL10n.bracelets,
      category: 'Bracelets',
      glow: Color(0xFFD9B26A),
    ),
  ];
}
