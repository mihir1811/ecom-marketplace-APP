import 'package:flutter/widgets.dart';

import '../../../core/l10n/app_localizations.dart';
import '../domain/average_hand.dart';
import '../domain/diamond_grades.dart';
import '../domain/diamond_shape.dart';
import '../domain/inclusion_catalog.dart';
import '../simulation/sim_fancy.dart';
import '../simulation/sim_mesh.dart';

/// Localized display names for the simulator's grades and options.
extension SimLabels on BuildContext {
  String shapeName(SimShape s) => trCatalogValue(s.catalogValue);

  String fancyShapeName(SimFancyShape s) => tr(EducationL10n.fancyShape(s.id));

  String cutName(CutGrade g) => tr(switch (g) {
    CutGrade.excellent => EducationL10n.excellent,
    CutGrade.veryGood => EducationL10n.veryGood,
    CutGrade.good => EducationL10n.good,
    CutGrade.fair => EducationL10n.fair,
    CutGrade.poor => EducationL10n.poor,
  });

  String cutBody(CutGrade g) => tr(switch (g) {
    CutGrade.excellent => EducationL10n.excellentBody,
    CutGrade.veryGood => EducationL10n.veryGoodBody,
    CutGrade.good => EducationL10n.goodBody,
    CutGrade.fair => EducationL10n.fairBody,
    CutGrade.poor => EducationL10n.poorBody,
  });

  String colorGroupName(ColorGroup g) => tr(switch (g) {
    ColorGroup.colorless => EducationL10n.colorless,
    ColorGroup.nearColorless => EducationL10n.nearColorless,
    ColorGroup.faint => EducationL10n.faintColor,
    ColorGroup.veryLight => EducationL10n.veryLightColor,
    ColorGroup.light => EducationL10n.lightColor,
  });

  String colorGroupBody(ColorGroup g) => tr(switch (g) {
    ColorGroup.colorless => EducationL10n.colorlessBody,
    ColorGroup.nearColorless => EducationL10n.nearColorlessBody,
    ColorGroup.faint => EducationL10n.faintColorBody,
    ColorGroup.veryLight => EducationL10n.veryLightColorBody,
    ColorGroup.light => EducationL10n.lightColorBody,
  });

  String fancyName(FancyColor c) => tr(switch (c) {
    FancyColor.yellow => EducationL10n.fancyYellow,
    FancyColor.pink => EducationL10n.fancyPink,
    FancyColor.blue => EducationL10n.fancyBlue,
    FancyColor.green => EducationL10n.fancyGreen,
    FancyColor.orange => EducationL10n.fancyOrange,
    FancyColor.purple => EducationL10n.fancyPurple,
    FancyColor.champagne => EducationL10n.fancyChampagne,
  });

  String fancyIntensityName(FancyIntensity i) => tr(switch (i) {
    FancyIntensity.fancyLight => EducationL10n.fancyLight,
    FancyIntensity.fancy => EducationL10n.fancyPlain,
    FancyIntensity.fancyIntense => EducationL10n.fancyIntense,
    FancyIntensity.fancyVivid => EducationL10n.fancyVivid,
    FancyIntensity.fancyDeep => EducationL10n.fancyDeep,
  });

  /// One-line meaning of a clarity grade.
  String clarityBody(ClarityGrade g) => tr(switch (g) {
    ClarityGrade.fl => EducationL10n.clarityFl,
    ClarityGrade.internallyFlawless => EducationL10n.clarityIf,
    ClarityGrade.vvs1 || ClarityGrade.vvs2 => EducationL10n.clarityVvs,
    ClarityGrade.vs1 || ClarityGrade.vs2 => EducationL10n.clarityVs,
    ClarityGrade.si1 || ClarityGrade.si2 => EducationL10n.claritySi,
    _ => EducationL10n.clarityI,
  });

  String inclusionName(InclusionType t) => tr(switch (t) {
    InclusionType.crystal => EducationL10n.incTypeCrystal,
    InclusionType.carbon => EducationL10n.incTypeCarbon,
    InclusionType.feather => EducationL10n.incTypeFeather,
    InclusionType.cloud => EducationL10n.incTypeCloud,
    InclusionType.pinpoint => EducationL10n.incTypePinpoint,
    InclusionType.needle => EducationL10n.incTypeNeedle,
    InclusionType.graining => EducationL10n.incTypeGraining,
    InclusionType.twinningWisp => EducationL10n.incTypeTwinningWisp,
    InclusionType.openFeather => EducationL10n.incTypeOpenFeather,
    InclusionType.knot => EducationL10n.incTypeKnot,
    InclusionType.cavity => EducationL10n.incTypeCavity,
    InclusionType.chip => EducationL10n.incTypeChip,
    InclusionType.bruise => EducationL10n.incTypeBruise,
    InclusionType.bearding => EducationL10n.incTypeBearding,
    InclusionType.indentedNatural => EducationL10n.incTypeIndentedNatural,
    InclusionType.etchChannel => EducationL10n.incTypeEtchChannel,
    InclusionType.laserDrillHole => EducationL10n.incTypeLaserDrillHole,
    InclusionType.filledFeather => EducationL10n.incTypeFilledFeather,
    InclusionType.cleavage => EducationL10n.incTypeCleavage,
    InclusionType.grainCenter => EducationL10n.incTypeGrainCenter,
    InclusionType.abrasion => EducationL10n.incTypeAbrasion,
    InclusionType.natural => EducationL10n.incTypeNatural,
    InclusionType.nick => EducationL10n.incTypeNick,
    InclusionType.pit => EducationL10n.incTypePit,
    InclusionType.polishLines => EducationL10n.incTypePolishLines,
    InclusionType.burnMark => EducationL10n.incTypeBurnMark,
    InclusionType.scratch => EducationL10n.incTypeScratch,
    InclusionType.surfaceGraining => EducationL10n.incTypeSurfaceGraining,
    InclusionType.extraFacet => EducationL10n.incTypeExtraFacet,
  });

  /// What an inclusion kind is, in a sentence, after GIA's definitions.
  String inclusionBody(InclusionType t) => tr(switch (t) {
    InclusionType.crystal => EducationL10n.incDefCrystal,
    InclusionType.carbon => EducationL10n.incDefCarbon,
    InclusionType.feather => EducationL10n.incDefFeather,
    InclusionType.cloud => EducationL10n.incDefCloud,
    InclusionType.pinpoint => EducationL10n.incDefPinpoint,
    InclusionType.needle => EducationL10n.incDefNeedle,
    InclusionType.graining => EducationL10n.incDefGraining,
    InclusionType.twinningWisp => EducationL10n.incDefTwinningWisp,
    InclusionType.openFeather => EducationL10n.incDefOpenFeather,
    InclusionType.knot => EducationL10n.incDefKnot,
    InclusionType.cavity => EducationL10n.incDefCavity,
    InclusionType.chip => EducationL10n.incDefChip,
    InclusionType.bruise => EducationL10n.incDefBruise,
    InclusionType.bearding => EducationL10n.incDefBearding,
    InclusionType.indentedNatural => EducationL10n.incDefIndentedNatural,
    InclusionType.etchChannel => EducationL10n.incDefEtchChannel,
    InclusionType.laserDrillHole => EducationL10n.incDefLaserDrillHole,
    InclusionType.filledFeather => EducationL10n.incDefFilledFeather,
    InclusionType.cleavage => EducationL10n.incDefCleavage,
    InclusionType.grainCenter => EducationL10n.incDefGrainCenter,
    InclusionType.abrasion => EducationL10n.incDefAbrasion,
    InclusionType.natural => EducationL10n.incDefNatural,
    InclusionType.nick => EducationL10n.incDefNick,
    InclusionType.pit => EducationL10n.incDefPit,
    InclusionType.polishLines => EducationL10n.incDefPolishLines,
    InclusionType.burnMark => EducationL10n.incDefBurnMark,
    InclusionType.scratch => EducationL10n.incDefScratch,
    InclusionType.surfaceGraining => EducationL10n.incDefSurfaceGraining,
    InclusionType.extraFacet => EducationL10n.incDefExtraFacet,
  });

  String inclusionReachName(InclusionReach r) => tr(switch (r) {
    InclusionReach.closed => EducationL10n.incReachClosed,
    InclusionReach.open => EducationL10n.incReachOpen,
  });

  String inclusionFamilyName(InclusionFamily f) => tr(switch (f) {
    InclusionFamily.mineral => EducationL10n.incFamilyMineral,
    InclusionFamily.fracture => EducationL10n.incFamilyFracture,
    InclusionFamily.growth => EducationL10n.incFamilyGrowth,
    InclusionFamily.damage => EducationL10n.incFamilyDamage,
    InclusionFamily.etching => EducationL10n.incFamilyEtching,
    InclusionFamily.treatment => EducationL10n.incFamilyTreatment,
  });

  String inclusionOriginName(InclusionOrigin o) => tr(switch (o) {
    InclusionOrigin.growth => EducationL10n.incOriginGrowth,
    InclusionOrigin.afterGrowth => EducationL10n.incOriginAfterGrowth,
    InclusionOrigin.cutting => EducationL10n.incOriginCutting,
    InclusionOrigin.treatment => EducationL10n.incOriginTreatment,
  });

  String inclusionLevelName(InclusionLevel l) => tr(switch (l) {
    InclusionLevel.none => EducationL10n.incLevelNone,
    InclusionLevel.low => EducationL10n.incLevelLow,
    InclusionLevel.medium => EducationL10n.incLevelMedium,
    InclusionLevel.high => EducationL10n.incLevelHigh,
  });

  /// Where in the stone a characteristic sits, by its nearest facet.
  String facetPlace(SimFacetKind f) => tr(switch (f) {
    SimFacetKind.table => EducationL10n.incAtTable,
    SimFacetKind.crown => EducationL10n.incAtCrown,
    SimFacetKind.girdle => EducationL10n.incAtGirdle,
    SimFacetKind.pavilion => EducationL10n.incAtPavilion,
    SimFacetKind.culet => EducationL10n.incAtCulet,
  });

  String tingeName(TingeLevel l) => tr(switch (l) {
    TingeLevel.none => EducationL10n.tingeNone,
    TingeLevel.faint => EducationL10n.tingeFaint,
    TingeLevel.light => EducationL10n.tingeLight,
    TingeLevel.medium => EducationL10n.tingeMedium,
    TingeLevel.strong => EducationL10n.tingeStrong,
  });

  String milkyName(MilkyLevel l) => trCatalogValue(l.catalogValue);

  String enhancementName(Enhancement e) => trCatalogValue(e.catalogValue);

  String enhancementBody(Enhancement e) => tr(switch (e) {
    Enhancement.none => EducationL10n.enhNoneBody,
    Enhancement.hpht => EducationL10n.enhHphtBody,
    Enhancement.irradiation => EducationL10n.enhIrradiationBody,
    Enhancement.fractureFilling => EducationL10n.enhFillingBody,
    Enhancement.laserDrilling => EducationL10n.enhDrillingBody,
    Enhancement.surfaceCoating => EducationL10n.enhCoatingBody,
  });

  String fingerName(HandFinger f) => tr(switch (f) {
    HandFinger.little => EducationL10n.fingerLittle,
    HandFinger.ring => EducationL10n.fingerRing,
    HandFinger.middle => EducationL10n.fingerMiddle,
    HandFinger.forefinger => EducationL10n.fingerIndex,
  });

  String fluorescenceName(FluorescenceIntensity i) =>
      trCatalogValue(i.catalogValue);

  String fluorescenceColorName(FluorescenceColor c) =>
      trCatalogValue(c.catalogValue);

  String girdleName(GirdleThickness g) => tr(switch (g) {
    GirdleThickness.extremelyThin => EducationL10n.girdleExtremelyThin,
    GirdleThickness.veryThin => EducationL10n.girdleVeryThin,
    GirdleThickness.thin => EducationL10n.girdleThin,
    GirdleThickness.medium => EducationL10n.girdleMedium,
    GirdleThickness.slightlyThick => EducationL10n.girdleSlightlyThick,
    GirdleThickness.thick => EducationL10n.girdleThick,
    GirdleThickness.veryThick => EducationL10n.girdleVeryThick,
    GirdleThickness.extremelyThick => EducationL10n.girdleExtremelyThick,
  });

  String culetName(CuletSize c) => tr(switch (c) {
    CuletSize.none => EducationL10n.culetNone,
    CuletSize.verySmall => EducationL10n.culetVerySmall,
    CuletSize.small => EducationL10n.culetSmall,
    CuletSize.medium => EducationL10n.culetMedium,
    CuletSize.slightlyLarge => EducationL10n.culetSlightlyLarge,
    CuletSize.large => EducationL10n.culetLarge,
    CuletSize.veryLarge => EducationL10n.culetVeryLarge,
    CuletSize.extremelyLarge => EducationL10n.culetExtremelyLarge,
  });

  String shapeNote(SimShape s) => tr(switch (s) {
    SimShape.round => EducationL10n.shapeRound,
    SimShape.princess => EducationL10n.shapePrincess,
    SimShape.cushion => EducationL10n.shapeCushion,
    SimShape.oval => EducationL10n.shapeOval,
    SimShape.emerald => EducationL10n.shapeEmerald,
    SimShape.pear => EducationL10n.shapePear,
    SimShape.marquise => EducationL10n.shapeMarquise,
    SimShape.radiant => EducationL10n.shapeRadiant,
    SimShape.asscher => EducationL10n.shapeAsscher,
    SimShape.heart => EducationL10n.shapeHeart,
  });
}
