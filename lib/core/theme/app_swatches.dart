import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Named swatches shared across multiple feature files.
class AppSwatches {
  const AppSwatches._();

  // Jewelry metals
  static const yellowGold = Color(0xFFD4AF37);
  static const whiteGold = Color(0xFFE5E5E5);
  static const roseGold = Color(0xFFB76E79);
  static const greenGold = Color(0xFF8B9A5B);
  static const blackGold = Color(0xFF2C2C2C);
  static const twoTone = Color(0xFFC9A227);
  static const platinum = Color(0xFFD8D8D8);
  static const silver = Color(0xFFC0C0C0);
  static const jewelryAccent = Color(0xFFE8C547);

  // Bullion / ticker copper
  static const copper = Color(0xFFDD915E);

  // Seller inquiry categories
  static const inquiryGemstone = Color(0xFF7C3AED);
  static const inquiryBullion = Color(0xFFEA580C);
  static const inquiryJewelry = Color(0xFFDC2626);

  // Seller card surface
  static const sellerCardSurface = Color(0xFFF3EDE4);

  static Color jewelryMetal(String label) {
    return switch (label) {
      'Yellow Gold' => yellowGold,
      'White Gold' => whiteGold,
      'Rose Gold' => roseGold,
      'Green Gold' => greenGold,
      'Black Gold' => blackGold,
      'Two-Tone' => twoTone,
      'Tri-Color' => roseGold,
      'Platinum' => platinum,
      'Silver' => silver,
      _ => AppColors.bronze,
    };
  }
}
