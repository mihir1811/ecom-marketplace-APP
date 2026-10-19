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
    HeadStyle.prong3 => JewelryEduL10n.prong3,
    HeadStyle.prong4 => JewelryEduL10n.prong4,
    HeadStyle.prong6 => JewelryEduL10n.prong6,
    HeadStyle.prong8 => JewelryEduL10n.prong8,
    HeadStyle.compass => JewelryEduL10n.compass,
    HeadStyle.doubleClaw => JewelryEduL10n.doubleClaw,
    HeadStyle.bezel => JewelryEduL10n.bezel,
    HeadStyle.halfBezel => JewelryEduL10n.halfBezel,
  });

  String tipName(ProngTip t) => tr(switch (t) {
    ProngTip.round => JewelryEduL10n.tipRound,
    ProngTip.claw => JewelryEduL10n.tipClaw,
    ProngTip.tab => JewelryEduL10n.tipTab,
    ProngTip.vTip => JewelryEduL10n.tipV,
  });

  String galleryName(GalleryStyle g) => tr(switch (g) {
    GalleryStyle.basket => JewelryEduL10n.basket,
    GalleryStyle.trellis => JewelryEduL10n.trellis,
    GalleryStyle.open => JewelryEduL10n.openGallery,
  });

  String heightName(SettingHeight h) => tr(switch (h) {
    SettingHeight.low => JewelryEduL10n.low,
    SettingHeight.medium => JewelryEduL10n.medium,
    SettingHeight.high => JewelryEduL10n.high,
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

  String shankName(ShankStyle s) => tr(switch (s) {
    ShankStyle.straight => JewelryEduL10n.straight,
    ShankStyle.tapered => JewelryEduL10n.tapered,
    ShankStyle.reverseTapered => JewelryEduL10n.reverseTapered,
    ShankStyle.split => JewelryEduL10n.split,
    ShankStyle.bypass => JewelryEduL10n.bypass,
    ShankStyle.twisted => JewelryEduL10n.twisted,
  });

  String accentName(BandAccent a) => tr(switch (a) {
    BandAccent.plain => JewelryEduL10n.plain,
    BandAccent.half => JewelryEduL10n.half,
    BandAccent.threeQuarter => JewelryEduL10n.threeQuarter,
    BandAccent.eternity => JewelryEduL10n.eternity,
  });

  String accentSettingName(AccentSetting a) => tr(switch (a) {
    AccentSetting.pave => JewelryEduL10n.pave,
    AccentSetting.channel => JewelryEduL10n.channel,
    AccentSetting.sharedProng => JewelryEduL10n.sharedProng,
    AccentSetting.bezel => JewelryEduL10n.bezel,
  });

  String earringName(EarringStyle e) => tr(switch (e) {
    EarringStyle.stud => JewelryEduL10n.stud,
    EarringStyle.drop => JewelryEduL10n.drop,
    EarringStyle.hoop => JewelryEduL10n.hoop,
    EarringStyle.huggie => JewelryEduL10n.huggie,
  });

  String backName(EarringBack b) => tr(switch (b) {
    EarringBack.butterfly => JewelryEduL10n.butterfly,
    EarringBack.screw => JewelryEduL10n.screwBack,
    EarringBack.disc => JewelryEduL10n.discBack,
  });

  String fittingName(DropFitting f) => tr(switch (f) {
    DropFitting.post => JewelryEduL10n.postTop,
    DropFitting.frenchHook => JewelryEduL10n.frenchHook,
    DropFitting.leverBack => JewelryEduL10n.leverBack,
  });

  String hoopShapeName(HoopShape s) => tr(switch (s) {
    HoopShape.round => JewelryEduL10n.tipRound,
    HoopShape.oval => JewelryEduL10n.oval,
  });

  String closureName(HoopClosure c) => tr(switch (c) {
    HoopClosure.hinged => JewelryEduL10n.hinged,
    HoopClosure.latch => JewelryEduL10n.latch,
    HoopClosure.endless => JewelryEduL10n.endless,
  });

  String chainName(ChainStyle c) => tr(switch (c) {
    ChainStyle.cable => JewelryEduL10n.cable,
    ChainStyle.curb => JewelryEduL10n.curb,
    ChainStyle.box => JewelryEduL10n.box,
    ChainStyle.rope => JewelryEduL10n.rope,
    ChainStyle.figaro => JewelryEduL10n.figaro,
    ChainStyle.paperclip => JewelryEduL10n.paperclip,
    ChainStyle.snake => JewelryEduL10n.snake,
    ChainStyle.bead => JewelryEduL10n.bead,
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

  String bailName(BailStyle b) => tr(switch (b) {
    BailStyle.loop => JewelryEduL10n.bailLoop,
    BailStyle.hidden => JewelryEduL10n.bailHidden,
    BailStyle.pave => JewelryEduL10n.pave,
    BailStyle.slide => JewelryEduL10n.bailSlide,
  });

  String braceletName(BraceletStyle b) => tr(switch (b) {
    BraceletStyle.tennis => JewelryEduL10n.tennis,
    BraceletStyle.bangle => JewelryEduL10n.bangle,
    BraceletStyle.chain => JewelryEduL10n.chainBracelet,
  });

  String tennisSettingName(TennisSetting t) => tr(switch (t) {
    TennisSetting.prong4 => JewelryEduL10n.prong4,
    TennisSetting.prong3 => JewelryEduL10n.prong3,
    TennisSetting.bezel => JewelryEduL10n.bezel,
    TennisSetting.channel => JewelryEduL10n.channel,
  });

  String bangleName(BangleStyle b) => tr(switch (b) {
    BangleStyle.slipOn => JewelryEduL10n.slipOn,
    BangleStyle.hinged => JewelryEduL10n.hinged,
    BangleStyle.cuff => JewelryEduL10n.cuff,
  });

  String bangleShapeName(BangleShape s) => tr(switch (s) {
    BangleShape.round => JewelryEduL10n.tipRound,
    BangleShape.oval => JewelryEduL10n.oval,
  });

  String claspName(ClaspStyle c) => tr(switch (c) {
    ClaspStyle.lobster => JewelryEduL10n.lobster,
    ClaspStyle.springRing => JewelryEduL10n.springRing,
    ClaspStyle.toggle => JewelryEduL10n.toggle,
    ClaspStyle.box => JewelryEduL10n.box,
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
