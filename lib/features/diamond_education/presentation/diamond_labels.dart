import 'package:flutter/widgets.dart';

import '../../../core/l10n/app_localizations.dart';
import '../domain/diamond_grades.dart';
import '../domain/diamond_shape.dart';

/// Localized display names for diamond grades on the education page.
extension DiamondLabels on BuildContext {
  String shapeName(SimShape s) => trCatalogValue(s.catalogValue);

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

  /// One-line meaning of a clarity grade.
  String clarityBody(ClarityGrade g) => tr(switch (g) {
    ClarityGrade.fl => EducationL10n.clarityFl,
    ClarityGrade.internallyFlawless => EducationL10n.clarityIf,
    ClarityGrade.vvs1 || ClarityGrade.vvs2 => EducationL10n.clarityVvs,
    ClarityGrade.vs1 || ClarityGrade.vs2 => EducationL10n.clarityVs,
    ClarityGrade.si1 || ClarityGrade.si2 => EducationL10n.claritySi,
    _ => EducationL10n.clarityI,
  });

  String fluorescenceName(FluorescenceIntensity i) =>
      trCatalogValue(i.catalogValue);

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
