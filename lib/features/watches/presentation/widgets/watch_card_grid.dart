import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/catalog_missing_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../domain/models/watch.dart';
import '../../../../core/utils/app_currency.dart';

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
        AppColors.textSecondaryLight;
    final inCompare = ref.watch(isInComparisonProvider(watch.id));

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _WatchCardImage(watch: watch),
                ),
                Positioned(
                  top: AppSpacing.s4,
                  right: AppSpacing.s4,
                  child: WishlistToggleButton(
                    item: WishlistItem.fromWatch(watch),
                    size: 18,
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
                AppSpacing.s12,
                AppSpacing.s12,
                AppSpacing.s12,
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
                      height: 1.35,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.cardLineGap),
                  Text(
                    watch.model,
                    style: AppTypography.label.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.cardLineGap),
                  Text(
                    watch.specsLine,
                    style: AppTypography.caption.copyWith(
                      color: mutedColor,
                      fontSize: 11,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.cardPriceGap),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppCurrency.format(formatGroupedPrice(watch.price)),
                          style: GoogleFonts.manrope(
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
    final secondaryColor =
        AppColors.textSecondaryLight;
    final inCompare = ref.watch(isInComparisonProvider(watch.id));

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 140,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 140),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: _WatchCardImage(watch: watch),
                    ),
                    Positioned(
                      bottom: AppSpacing.s8,
                      left: AppSpacing.s8,
                      child: WishlistToggleButton(
                        item: WishlistItem.fromWatch(watch),
                        size: 18,
                      ),
                    ),
                    Positioned(
                      bottom: AppSpacing.s8,
                      right: AppSpacing.s8,
                      child: CompareAddButton(
                        size: 32,
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
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      watch.brand,
                      style: AppTypography.caption.copyWith(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      watch.model,
                      style: AppTypography.label.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      watch.detailLine,
                      style: AppTypography.caption.copyWith(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      '${watch.specsLine} · ${watch.condition}',
                      style: AppTypography.caption.copyWith(
                        color: secondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.cardPriceGap),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppCurrency.format(formatGroupedPrice(watch.price)),
                            style: GoogleFonts.manrope(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ).copyWith(color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 18,
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

class _WatchCardImage extends StatelessWidget {
  const _WatchCardImage({required this.watch});

  final Watch watch;

  @override
  Widget build(BuildContext context) {
    final network = watch.renderableImageUrl;
    if (network != null) {
      return AppNetworkImage(
        url: network,
        fit: BoxFit.cover,
        memCacheWidth: 480,
        error: const CatalogMissingImage(),
      );
    }
    return const CatalogMissingImage();
  }
}
