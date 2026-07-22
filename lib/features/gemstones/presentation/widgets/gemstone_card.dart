import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../domain/models/gemstone.dart';
import 'gemstone_showcase_card.dart';

class GemstoneCardGrid extends ConsumerWidget {
  const GemstoneCardGrid({
    required this.gemstone,
    this.onTap,
    super.key,
  });

  final Gemstone gemstone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slateSurface : AppColors.warmWhite;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final inCompare = ref.watch(isInComparisonProvider(gemstone.id));
    final imagePath = gemstone.imageUrl ?? gemstoneImagePath(gemstone.type);

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
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: isDark
                          ? AppColors.charcoalLight
                          : AppColors.sandSurface,
                      child: imagePath != null
                          ? Padding(
                              padding: const EdgeInsets.all(AppSpacing.s24),
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.diamond_outlined,
                                  size: 40,
                                  color: gemstoneHue(gemstone.type),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.diamond_outlined,
                              size: 40,
                              color: gemstoneHue(gemstone.type),
                            ),
                    ),
                  ),
                  if (gemstone.discount != null && gemstone.discount! > 0)
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
                          '-${gemstone.discount!.round()}%',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warmWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: AppSpacing.s8,
                    right: AppSpacing.s8,
                    child: CompareAddButton(
                      isSelected: inCompare,
                      onPressed: () => handleCompareToggle(
                        context,
                        ref,
                        CompareItem.fromGemstone(gemstone),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s12,
                  AppSpacing.s8,
                  AppSpacing.s12,
                  AppSpacing.s8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${_formatPrice(gemstone.price)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ).copyWith(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${gemstone.carat}ct ${gemstone.type}',
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${gemstone.shape} · ${gemstone.origin}',
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class GemstoneCardList extends ConsumerWidget {
  const GemstoneCardList({
    required this.gemstone,
    this.onTap,
    super.key,
  });

  final Gemstone gemstone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slateSurface : AppColors.warmWhite;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final inCompare = ref.watch(isInComparisonProvider(gemstone.id));
    final imagePath = gemstone.imageUrl ?? gemstoneImagePath(gemstone.type);

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
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: isDark
                            ? AppColors.charcoalLight
                            : AppColors.sandSurface,
                        child: imagePath != null
                            ? Padding(
                                padding: const EdgeInsets.all(AppSpacing.s12),
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.diamond_outlined,
                                    color: gemstoneHue(gemstone.type),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.diamond_outlined,
                                color: gemstoneHue(gemstone.type),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: AppSpacing.s8,
                      right: AppSpacing.s8,
                      child: CompareAddButton(
                        size: 28,
                        isSelected: inCompare,
                        onPressed: () => handleCompareToggle(
                          context,
                          ref,
                          CompareItem.fromGemstone(gemstone),
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
                    children: [
                      Text(
                        '\$${_formatPrice(gemstone.price)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ).copyWith(color: textColor),
                      ),
                      Text(
                        '${gemstone.carat}ct ${gemstone.type}',
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${gemstone.color} · ${gemstone.clarity} · ${gemstone.shape}',
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
