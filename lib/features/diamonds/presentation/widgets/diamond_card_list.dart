import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';

class DiamondCardList extends StatelessWidget {
  final Diamond diamond;
  final VoidCallback? onTap;

  const DiamondCardList({
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
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 120,
              child: Stack(
                children: [
                  Container(
                    color: isDark ? AppColors.charcoalLight : AppColors.sandSurface,
                    child: Center(
                      child: renderShapeSvg(
                        diamond.shape,
                        size: 48,
                        color: AppColors.bronze,
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
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          '\$${_formatPrice(diamond.price)}',
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                        if (diamond.pricePerCarat != null) ...[
                          const SizedBox(width: AppSpacing.s8),
                          Text(
                            '\$${diamond.pricePerCarat!.round()}/ct',
                            style: AppTypography.caption.copyWith(
                              color: mutedColor,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (diamond.hasVideo)
                          const Icon(
                            Icons.play_circle_fill,
                            color: AppColors.bronze,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      '${diamond.carat}ct ${diamond.shape} • ${diamond.cut}',
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
                        Text(
                          '${diamond.color} • ${diamond.clarity}',
                          style: AppTypography.label.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.charcoalDark : AppColors.sandSurface,
                            borderRadius: BorderRadius.circular(AppSpacing.r4),
                          ),
                          child: Text(
                            diamond.certificate,
                            style: AppTypography.caption.copyWith(
                              color: mutedColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
