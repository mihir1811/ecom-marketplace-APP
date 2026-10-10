import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Reusable elevation / shadow configurations for a premium UI feel.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> none = [];

  // Soft premium card shadow (subtle blur, low opacity)
  static List<BoxShadow> get cardLight => [
    BoxShadow(
      color: AppPalette.current.chrome.shadowTint.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppPalette.current.chrome.shadowTint.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  // Elevated modal/dialog shadow
  static List<BoxShadow> get modalLight => [
    BoxShadow(
      color: AppPalette.current.chrome.shadowTint.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
