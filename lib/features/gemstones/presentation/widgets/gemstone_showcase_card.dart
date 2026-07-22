import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Asset path for a featured gemstone image, or null when none is available.
String? gemstoneImagePath(String name) {
  // Filenames in public/images/gemstones/ that differ from the display name.
  const aliases = {
    "Tiger's Eye": 'Tiger Eye',
  };
  final fileName = aliases[name] ?? name;
  return 'public/images/gemstones/$fileName.png';
}

/// Maps a gemstone name to a representative display hue used as a fallback
/// when the image asset is missing.
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

/// Showcase card for the featured gemstone carousel: a large circular
/// gemstone image with the gemstone name centered underneath.
class GemstoneShowcaseCard extends StatelessWidget {
  const GemstoneShowcaseCard({
    required this.name,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hue = gemstoneHue(name);
    const activeColor = AppColors.bronze;
    final inactiveBorderColor =
        AppColors.warmBorder;
    final imagePath = gemstoneImagePath(name);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (AppColors.creamBg)
              : (AppColors.warmWhite),
          borderRadius: const BorderRadius.all(Radius.circular(60.0)),
          border: Border.all(
            color: isSelected ? activeColor : inactiveBorderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? AppShadows.cardLight : AppShadows.none,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s24,
          horizontal: AppSpacing.s12,
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: imagePath == null
                      ? _HueFallback(hue: hue)
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _HueFallback(hue: hue),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : (AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HueFallback extends StatelessWidget {
  const _HueFallback({required this.hue});

  final Color hue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [
            Color.lerp(hue, Colors.white, 0.55)!,
            hue,
            Color.lerp(hue, Colors.black, 0.25)!,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
      ),
      child: Icon(
        Icons.diamond_outlined,
        size: 30,
        color: Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}
