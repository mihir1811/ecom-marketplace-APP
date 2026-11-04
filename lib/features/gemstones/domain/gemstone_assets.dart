import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Asset path for a gemstone image, or null when none is available.
String? gemstoneImagePath(String name) {
  // Filenames in public/images/gemstones/ that differ from the display name.
  const aliases = {"Tiger's Eye": 'Tiger Eye'};
  final fileName = aliases[name] ?? name;
  return 'public/images/gemstones/$fileName.webp';
}

/// Representative display hue used when the image asset is missing.
Color gemstoneHue(String name) {
  return switch (name.toLowerCase()) {
    'ruby' || 'red coral' || 'rubellite' => const Color(0xFFB0173C),
    'sapphire' || 'lapis lazuli' || 'kyanite' => const Color(0xFF1E4FA3),
    'emerald' || 'tsavorite' || 'peridot' => const Color(0xFF1D8348),
    'tanzanite' || 'amethyst' || 'iolite' => const Color(0xFF6C3FA8),
    'aquamarine' || 'topaz' || 'turquoise' => const Color(0xFF3CA6C4),
    'garnet' || 'spessartite' => const Color(0xFF8E2323),
    'opal' || 'moonstone' || 'pearl' => const Color(0xFFCBD8DB),
    'tourmaline' || 'morganite' => const Color(0xFFD16BA5),
    'citrine' || 'amber' || 'heliodor' => const Color(0xFFDDA63A),
    _ => AppColors.bronzeLight,
  };
}
