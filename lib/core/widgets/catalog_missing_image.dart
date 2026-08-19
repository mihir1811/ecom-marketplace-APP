import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shared “no product photo” placeholder for catalog cards (not diamonds).
///
/// Uses [assetPath] so listing cards and product detail share one visual.
class CatalogMissingImage extends StatelessWidget {
  const CatalogMissingImage({
    super.key,
    this.showLabel = true,
    this.padding = AppSpacing.s24,
  });

  static const String assetPath = 'public/images/placeholder-product.svg';

  final bool showLabel;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface(context),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: SvgPicture.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    AppColors.isDark(context)
                        ? const Color(0xFF4A5568)
                        : const Color(0xFFD1D5DB),
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (_) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                    color: AppColors.bronzeLight,
                  ),
                ),
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                'No image',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
