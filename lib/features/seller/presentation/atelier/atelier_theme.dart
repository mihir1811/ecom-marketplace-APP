import 'package:flutter/material.dart';
import 'package:gemworld/core/theme/app_fonts.dart';

import '../../../../core/theme/atelier_palette.dart';

export '../../../../core/theme/atelier_palette.dart';

extension AtelierContext on BuildContext {
  AtelierPalette get atelier => AtelierPalette.of(this);

  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}

/// Spacing scale (4pt grid).
abstract final class AtelierSpace {
  static const s2 = 2.0;
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s8 = 6.0;
  static const s10 = 8.0;
  static const s12 = 8.0;
  static const s16 = 12.0;
  static const s20 = 14.0;
  static const s24 = 16.0;
  static const s32 = 20.0;
  static const s40 = 24.0;
  static const s48 = 28.0;

  /// Horizontal page gutter that grows with the viewport.
  static double gutter(double width) => width >= 1200
      ? 40
      : width >= 720
      ? 28
      : 14;
}

/// Corner radii.
abstract final class AtelierRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Motion tokens.
abstract final class AtelierMotion {
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 560);
  static const lazy = Duration(milliseconds: 900);

  /// Material 3 "emphasized" — fast start, long soft landing.
  static const emphasized = Cubic(0.2, 0, 0, 1);

  /// Gentle overshoot for selection indicators.
  static const settle = Cubic(0.34, 1.36, 0.64, 1);

  /// Per-item stagger for list reveals.
  static const stagger = Duration(milliseconds: 45);
}

/// Typography: [AppFonts.display] for display numerals, [AppFonts.primary] for titles,
/// [AppFonts.secondary] for everything functional.
abstract final class AtelierType {
  static const _tabular = [FontFeature.tabularFigures()];

  /// Lining, tabular numerals so figures align.
  static const _display = [
    FontFeature.tabularFigures(),
    FontFeature.liningFigures(),
  ];

  /// Large display — page titles, hero values.
  static TextStyle display(
    Color color, {
    double size = 34,
    FontWeight? weight,
  }) => AppFonts.display(
    fontSize: size,
    fontWeight: weight ?? FontWeight.w600,
    height: 1.05,
    letterSpacing: -0.4,
    color: color,
    fontFeatures: _display,
  );

  /// Section / card titles.
  static TextStyle title(Color color, {double size = 16}) => AppFonts.primary(
    fontSize: size,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
    color: color,
  );

  static TextStyle body(Color color, {double size = 14}) => AppFonts.secondary(
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: color,
  );

  static TextStyle label(Color color, {double size = 13, FontWeight? weight}) =>
      AppFonts.secondary(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.05,
        color: color,
      );

  static TextStyle caption(Color color, {double size = 12}) =>
      AppFonts.secondary(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: color,
      );

  /// Spaced small caps used as quiet section markers.
  static TextStyle overline(Color color) => AppFonts.secondary(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.6,
    color: color,
  );

  /// Functional numbers (amounts in rows, counts) — tabular so they align.
  static TextStyle figure(
    Color color, {
    double size = 15,
    FontWeight? weight,
  }) => AppFonts.primary(
    fontSize: size,
    fontWeight: weight ?? FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
    color: color,
    fontFeatures: _tabular,
  );
}
