import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../domain/gemstone_assets.dart';
import '../../domain/models/gemstone.dart';
import '../../../../core/utils/app_currency.dart';

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
    final textColor =
        AppColors.textPrimaryLight;
    final mutedColor =
        AppColors.textMutedLight;
    final inCompare = ref.watch(isInComparisonProvider(gemstone.id));
    final imagePath = gemstone.imageUrl ?? gemstoneImagePath(gemstone.type);

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Container(
                      color: AppColors.sandSurface,
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
                    left: AppSpacing.s4,
                    child: WishlistToggleButton(
                      item: WishlistItem.fromGemstone(gemstone),
                      size: 18,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s12,
                AppSpacing.s8,
                AppSpacing.s12,
                AppSpacing.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppCurrency.format(formatCatalogPrice(gemstone.price)),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ).copyWith(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${gemstone.carat.toStringAsFixed(2)}ct · ${gemstone.type}',
                    style: AppTypography.caption.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
          ],
        ),
    );
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
    final textColor =
        AppColors.textPrimaryLight;
    final mutedColor =
        AppColors.textMutedLight;
    final inCompare = ref.watch(isInComparisonProvider(gemstone.id));
    final imagePath = gemstone.imageUrl ?? gemstoneImagePath(gemstone.type);

    return MarketplaceProductCardShell(
      onTap: onTap,
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
                        color: AppColors.sandSurface,
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
                      left: AppSpacing.s4,
                      child: WishlistToggleButton(
                        item: WishlistItem.fromGemstone(gemstone),
                        size: 16,
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
                        AppCurrency.format(formatCatalogPrice(gemstone.price)),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ).copyWith(color: textColor),
                      ),
                      Text(
                        '${gemstone.carat.toStringAsFixed(2)}ct · ${gemstone.type}',
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
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
    );
  }
}
