import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Reusable elevation / shadow configurations for a premium UI feel.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> none = [];

  // Card shadow strong enough to lift a white card off the white page.
  static List<BoxShadow> get cardLight => [
    BoxShadow(
      color: AppPalette.current.chrome.shadowTint.withValues(alpha: 0.08),
      blurRadius: 12,
      spreadRadius: -2,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppPalette.current.chrome.shadowTint.withValues(alpha: 0.05),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  // Elevated modal/dialog shadow
  static List<BoxShadow> get modalLight => [
    BoxShadow(
      color: AppPalette.current.chrome.shadowTint.withValues(alpha: 0.14),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];
}
