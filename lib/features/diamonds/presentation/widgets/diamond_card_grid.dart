import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';

class DiamondCardGrid extends StatelessWidget {
  final Diamond diamond;
  final VoidCallback? onTap;

  const DiamondCardGrid({
    super.key,
    required this.diamond,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slateSurface : AppColors.warmWhite;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    color: isDark ? AppColors.charcoalLight : AppColors.sandSurface,
                    child: Center(
                      child: renderShapeSvg(
                        diamond.shape,
                        size: 56,
                        color: AppColors.bronze,
                      ),
                    ),
                  ),
                ),
                if (diamond.discount != null && diamond.discount! > 0)
                  Positioned(
                    top: AppSpacing.s8,
                    left: AppSpacing.s8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(AppSpacing.r4),
                      ),
                      child: Text(
                        '-${diamond.discount!.round()}%',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                if (diamond.hasVideo)
                  const Positioned(
                    top: AppSpacing.s8,
                    right: AppSpacing.s8,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: AppColors.bronze,
                      size: 18,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${_formatPrice(diamond.price)}',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '${diamond.carat}ct ${diamond.shape}',
                    style: AppTypography.body.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    children: [
                      _specChip(diamond.cut, context),
                      const SizedBox(width: AppSpacing.s4),
                      _specChip(diamond.color, context),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    children: [
                      Text(
                        diamond.clarity,
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        diamond.certificate,
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specChip(String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.r4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price >= 10000 ? 0 : 1)}K';
    }
    return price.toStringAsFixed(0);
  }
}
