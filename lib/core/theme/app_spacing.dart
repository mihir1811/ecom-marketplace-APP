/// Spacing and Radius tokens for layout consistency.
class AppSpacing {
  const AppSpacing._();

  // Padding & Margin scale (optimized for tight mobile viewport)
  static const double s4 = 2.0;
  static const double s8 = 4.0;
  static const double s12 = 8.0;
  static const double s16 = 12.0;
  static const double s20 = 14.0;
  static const double s24 = 16.0;
  static const double s32 = 20.0;
  static const double s40 = 24.0;
  static const double s48 = 32.0;
  static const double s64 = 40.0;

  /// Vertical gap between text lines inside product cards (grid + list).
  static const double cardLineGap = 6.0;

  /// Gap before the price row inside product cards.
  static const double cardPriceGap = 12.0;

  // Corner Radius scale
  static const double r4 = 3.0;
  static const double r8 = 6.0;
  static const double r12 = 8.0;
  static const double r16 = 12.0;
  static const double r20 = 14.0;
  static const double r24 = 16.0;
  static const double r32 = 20.0;
  static const double circular = 999.0;
}
