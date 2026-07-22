import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../domain/models/watch.dart';
import 'watch_brand_assets.dart';

class WatchCardGrid extends ConsumerWidget {
  const WatchCardGrid({
    required this.watch,
    this.onTap,
    super.key,
  });

  final Watch watch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor =
        AppColors.textPrimaryLight;
    final mutedColor =
        AppColors.textMutedLight;
    final logo = WatchBrandAssets.logoPath(watch.brand);
    final inCompare = ref.watch(isInComparisonProvider(watch.id));

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.05,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: AppColors.sandSurface,
                      child: Center(
                        child: logo != null
                            ? Padding(
                                padding: const EdgeInsets.all(AppSpacing.s24),
                                child: Image.asset(
                                  logo,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.watch,
                                    size: 48,
                                    color: AppColors.bronze,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.watch,
                                size: 48,
                                color: AppColors.bronze,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.s8,
                    right: AppSpacing.s8,
                    child: Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: mutedColor,
                    ),
                  ),
                  if (watch.discount != null && watch.discount! > 0)
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
                          '-${watch.discount!.round()}%',
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
                        CompareItem.fromWatch(watch),
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
                      watch.brand,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      watch.model,
                      style: AppTypography.label.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      watch.specsLine,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${formatGroupedPrice(watch.price)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ).copyWith(color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.bronze,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class WatchCardList extends ConsumerWidget {
  const WatchCardList({
    required this.watch,
    this.onTap,
    super.key,
  });

  final Watch watch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor =
        AppColors.textPrimaryLight;
    final mutedColor =
        AppColors.textMutedLight;
    final logo = WatchBrandAssets.logoPath(watch.brand);
    final inCompare = ref.watch(isInComparisonProvider(watch.id));

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 112,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: AppColors.sandSurface,
                        child: Center(
                          child: logo != null
                              ? Padding(
                                  padding: const EdgeInsets.all(AppSpacing.s16),
                                  child: Image.asset(
                                    logo,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.watch,
                                      size: 36,
                                      color: AppColors.bronze,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.watch,
                                  size: 36,
                                  color: AppColors.bronze,
                                ),
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
                          CompareItem.fromWatch(watch),
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
                        watch.brand,
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        watch.model,
                        style: AppTypography.label.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        watch.detailLine,
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Row(
                        children: [
                          Text(
                            '\$${formatGroupedPrice(watch.price)}',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ).copyWith(color: textColor),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.bronze,
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
}
