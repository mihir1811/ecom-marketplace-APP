import 'package:flutter/widgets.dart';

import '../../../core/l10n/app_localizations.dart';
import '../domain/jewelry_reference.dart';

/// Localized names for the jewelry education page.
extension JewelryLabels on BuildContext {
  String typeName(JewelryType t) => tr(switch (t) {
    JewelryType.ring => JewelryEduL10n.ring,
    JewelryType.earrings => JewelryEduL10n.earrings,
    JewelryType.necklace => JewelryEduL10n.necklace,
    JewelryType.bracelet => JewelryEduL10n.bracelet,
  });

  String metalName(JewelryMetal m) => tr(switch (m) {
    JewelryMetal.yellowGold => JewelryEduL10n.yellowGold,
    JewelryMetal.whiteGold => JewelryEduL10n.whiteGold,
    JewelryMetal.roseGold => JewelryEduL10n.roseGold,
    JewelryMetal.platinum => JewelryEduL10n.platinum,
    JewelryMetal.silver => JewelryEduL10n.silver,
  });

  String lengthNote(ChainLength l) => tr(switch (l) {
    ChainLength.in14 => JewelryEduL10n.len14,
    ChainLength.in16 => JewelryEduL10n.len16,
    ChainLength.in18 => JewelryEduL10n.len18,
    ChainLength.in20 => JewelryEduL10n.len20,
    ChainLength.in22 => JewelryEduL10n.len22,
    ChainLength.in24 => JewelryEduL10n.len24,
    ChainLength.in30 => JewelryEduL10n.len30,
  });
}

/// Swatch colours (sRGB) for each metal.
abstract final class MetalSwatch {
  static Color of(JewelryMetal m) => switch (m) {
    JewelryMetal.yellowGold => const Color(0xFFE2BE6A),
    JewelryMetal.whiteGold => const Color(0xFFE4E4E2),
    JewelryMetal.roseGold => const Color(0xFFE8B4A0),
    JewelryMetal.platinum => const Color(0xFFCFCDC8),
    JewelryMetal.silver => const Color(0xFFF0EEEA),
  };
}
