import 'package:flutter/material.dart';

/// Reusable elevation / shadow configurations for a premium UI feel.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> none = [];

  // Soft premium card shadow (subtle blur, low opacity)
  static final List<BoxShadow> cardLight = [
    BoxShadow(
      color: const Color(0xFF111827).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF111827).withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> cardDark = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Elevated modal/dialog shadow
  static final List<BoxShadow> modalLight = [
    BoxShadow(
      color: const Color(0xFF111827).withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> modalDark = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
