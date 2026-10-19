import 'package:flutter/widgets.dart';

import '../../../core/l10n/app_localizations.dart';
import '../domain/jewelry_design.dart';
import '../domain/jewelry_metal.dart';

/// Localized names for the jewelry simulator's options.
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

  /// "18K Yellow gold", "PT950 Platinum".
  String metalLine(JewelryMetal m, MetalPurity p) =>
      '${p.label} ${metalName(m)}';

  String finishName(MetalFinish f) => tr(switch (f) {
    MetalFinish.polished => JewelryEduL10n.polished,
    MetalFinish.satin => JewelryEduL10n.satin,
    MetalFinish.matte => JewelryEduL10n.matte,
  });

  String headName(HeadStyle h) => tr(switch (h) {
    HeadStyle.prong4 => JewelryEduL10n.prong4,
    HeadStyle.prong6 => JewelryEduL10n.prong6,
    HeadStyle.bezel => JewelryEduL10n.bezel,
  });

  String haloName(HaloStyle h) => tr(switch (h) {
    HaloStyle.none => JewelryEduL10n.none,
    HaloStyle.single => JewelryEduL10n.single,
    HaloStyle.double => JewelryEduL10n.double,
  });

  String profileName(BandProfile p) => tr(switch (p) {
    BandProfile.comfort => JewelryEduL10n.comfort,
    BandProfile.flat => JewelryEduL10n.flat,
    BandProfile.knifeEdge => JewelryEduL10n.knifeEdge,
    BandProfile.dShape => JewelryEduL10n.dShape,
  });

  String accentName(BandAccent a) => tr(switch (a) {
    BandAccent.plain => JewelryEduL10n.plain,
    BandAccent.pave => JewelryEduL10n.pave,
    BandAccent.eternity => JewelryEduL10n.eternity,
  });

  String earringName(EarringStyle e) => tr(switch (e) {
    EarringStyle.stud => JewelryEduL10n.stud,
    EarringStyle.drop => JewelryEduL10n.drop,
    EarringStyle.hoop => JewelryEduL10n.hoop,
  });

  String chainName(ChainStyle c) => tr(switch (c) {
    ChainStyle.cable => JewelryEduL10n.cable,
    ChainStyle.curb => JewelryEduL10n.curb,
    ChainStyle.box => JewelryEduL10n.box,
    ChainStyle.rope => JewelryEduL10n.rope,
  });

  String lengthNote(ChainLength l) => tr(switch (l) {
    ChainLength.in16 => JewelryEduL10n.len16,
    ChainLength.in18 => JewelryEduL10n.len18,
    ChainLength.in20 => JewelryEduL10n.len20,
    ChainLength.in24 => JewelryEduL10n.len24,
  });

  String braceletName(BraceletStyle b) => tr(switch (b) {
    BraceletStyle.tennis => JewelryEduL10n.tennis,
    BraceletStyle.bangle => JewelryEduL10n.bangle,
    BraceletStyle.chain => JewelryEduL10n.chainBracelet,
  });
}

/// Swatch colours (sRGB) for each metal in pickers.
abstract final class MetalSwatch {
  static Color of(JewelryMetal m) => switch (m) {
    JewelryMetal.yellowGold => const Color(0xFFE2BE6A),
    JewelryMetal.whiteGold => const Color(0xFFE4E4E2),
    JewelryMetal.roseGold => const Color(0xFFE8B4A0),
    JewelryMetal.platinum => const Color(0xFFCFCDC8),
    JewelryMetal.silver => const Color(0xFFF0EEEA),
  };
}
