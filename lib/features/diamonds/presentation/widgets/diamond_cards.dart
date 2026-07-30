import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_display.dart';
import 'diamond_svg_data.dart';
import 'diamond_list_card.dart';
export 'diamond_list_card.dart' show DiamondCardList;

Widget _diamondThumb(Diamond diamond, {double shapeSize = 48}) {
  final url = diamond.imageUrl;
  if (url != null && url.isNotEmpty) {
    return AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      memCacheWidth: 400,
    );
  }
  return ColoredBox(
    color: AppColors.sandSurface,
    child: Center(
      child: renderShapeSvg(
        diamond.shape,
        size: shapeSize,
        color: AppColors.bronze,
      ),
    ),
  );
}

class DiamondCardGrid extends ConsumerWidget {
  final Diamond diamond;
  final VoidCallback? onTap;

  const DiamondCardGrid({
    super.key,
    required this.diamond,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor =
        AppColors.textPrimaryLight;
    final mutedColor =
        AppColors.textMutedLight;
    final inCompare = ref.watch(isInComparisonProvider(diamond.id));
    final certLab = DiamondDisplay.labBadge(diamond.lab ?? diamond.certificate);

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: _diamondThumb(diamond)),
                  if (diamond.discount != null && diamond.discount! > 0)
                    Positioned(
                      top: AppSpacing.s8,
                      right: AppSpacing.s8,
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
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  if (certLab != null)
                    Positioned(
                      top: AppSpacing.s8,
                      left: AppSpacing.s8,
                      child: _CertificateLabBadge(label: certLab),
                    ),
                  Positioned(
                    bottom: AppSpacing.s8,
                    left: AppSpacing.s4,
                    child: WishlistToggleButton(
                      item: WishlistItem.fromDiamond(diamond),
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
                        CompareItem.fromDiamond(diamond),
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
                AppSpacing.s12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppCurrency.format(formatCatalogPrice(diamond.price)),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ).copyWith(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${diamond.carat}ct ${DiamondDisplay.shape(diamond.shape)}',
                    style: AppTypography.caption.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  _DiamondSpecGrid(
                    cut: diamond.cut,
                    color: diamond.color,
                    clarity: diamond.clarity,
                    certificate: diamond.certificate,
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

}

class _CertificateLabBadge extends StatelessWidget {
  const _CertificateLabBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.bronze,
        borderRadius: BorderRadius.circular(AppSpacing.r4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.warmWhite,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          height: 1.1,
          letterSpacing: 0.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DiamondSpecGrid extends StatelessWidget {
  const _DiamondSpecGrid({
    required this.cut,
    required this.color,
    required this.clarity,
    required this.certificate,
  });

  final String cut;
  final String color;
  final String clarity;
  final String certificate;

  @override
  Widget build(BuildContext context) {
    final specs = <(String, String)>[
      ('Cut', DiamondDisplay.gradeChip(cut)),
      ('Color', DiamondDisplay.gradeChip(color)),
      ('Clarity', DiamondDisplay.gradeChip(clarity)),
      ('Certificate', DiamondDisplay.gradeChip(certificate)),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _DiamondSpecItem(label: specs[0].$1, value: specs[0].$2)),
            const SizedBox(width: AppSpacing.s8),
            Expanded(child: _DiamondSpecItem(label: specs[1].$1, value: specs[1].$2)),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Row(
          children: [
            Expanded(child: _DiamondSpecItem(label: specs[2].$1, value: specs[2].$2)),
            const SizedBox(width: AppSpacing.s8),
            Expanded(child: _DiamondSpecItem(label: specs[3].$1, value: specs[3].$2)),
          ],
        ),
      ],
    );
  }
}

class _DiamondSpecItem extends StatelessWidget {
  const _DiamondSpecItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isMissing = value == 'N/A';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(AppSpacing.r4),
        border: Border.all(
          color: AppColors.warmBorder.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.15,
              color: AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: isMissing
                  ? AppColors.textMutedLight
                  : AppColors.textPrimaryLight,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class DiamondGridView extends StatelessWidget {
  final List<Diamond> diamonds;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const DiamondGridView({
    super.key,
    required this.diamonds,
    required this.scrollController,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s8,
        bottom: AppSpacing.s24,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.s12,
        mainAxisSpacing: AppSpacing.s12,
        childAspectRatio: 0.62,
      ),
      itemCount: diamonds.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= diamonds.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final diamond = diamonds[index];
        return RepaintBoundary(
          child: DiamondCardGrid(
            key: ValueKey(diamond.id),
            diamond: diamond,
            onTap: () => openDiamondDetail(context, diamond),
          ),
        );
      },
    );
  }
}


class DiamondListView extends StatelessWidget {
  final List<Diamond> diamonds;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const DiamondListView({
    super.key,
    required this.diamonds,
    required this.scrollController,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s8,
        bottom: AppSpacing.s24,
      ),
      itemCount: diamonds.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= diamonds.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  'Loading more...',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          );
        }
        final diamond = diamonds[index];
        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: DiamondCardList(
              key: ValueKey(diamond.id),
              diamond: diamond,
              onTap: () => openDiamondDetail(context, diamond),
            ),
          ),
        );
      },
    );
  }
}
