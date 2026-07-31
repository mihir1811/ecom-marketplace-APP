import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../domain/models/billion.dart';

enum BullionCardLayout { grid, list }

/// Card UI for a single bullion product (grid or list), matching watch cards.
class BullionCard extends StatelessWidget {
  const BullionCard({
    required this.bullion,
    this.layout = BullionCardLayout.grid,
    this.onTap,
    super.key,
  });

  final Bullion bullion;
  final BullionCardLayout layout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return layout == BullionCardLayout.grid
        ? BullionCardGrid(bullion: bullion, onTap: onTap)
        : BullionCardList(bullion: bullion, onTap: onTap);
  }
}

/// Grid card — mirrors [WatchCardGrid] layout and padding (no compare).
class BullionCardGrid extends StatelessWidget {
  const BullionCardGrid({
    required this.bullion,
    this.onTap,
    super.key,
  });

  final Bullion bullion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimaryLight;
    final mutedColor = AppColors.textSecondaryLight;
    final metalLabel = _metalLabel(bullion.metal);
    final title = _gridTitle(bullion);
    final specs = _gridSpecs(bullion);

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.05,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _BullionCardImage(bullion: bullion),
                  ),
                  Positioned(
                    top: AppSpacing.s4,
                    right: AppSpacing.s4,
                    child: WishlistToggleButton(
                      item: WishlistItem.fromBullion(bullion),
                      size: 18,
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
                      metalLabel,
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
                      title,
                      style: AppTypography.label.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specs,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppCurrency.format(
                              formatGroupedPrice(bullion.price),
                            ),
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
      ),
    );
  }
}

/// List card — mirrors [WatchCardList] layout and padding (no compare).
class BullionCardList extends StatelessWidget {
  const BullionCardList({
    required this.bullion,
    this.onTap,
    super.key,
  });

  final Bullion bullion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimaryLight;
    final secondaryColor = AppColors.textSecondaryLight;
    final metalLabel = _metalLabel(bullion.metal);
    final detailLine = _listDetailLine(bullion);
    final specsLine = _listSpecsLine(bullion);

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: SizedBox(
        height: 156,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 140,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _BullionCardImage(bullion: bullion),
                  ),
                  Positioned(
                    bottom: AppSpacing.s8,
                    left: AppSpacing.s8,
                    child: WishlistToggleButton(
                      item: WishlistItem.fromBullion(bullion),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s12,
                  AppSpacing.s16,
                  AppSpacing.s12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metalLabel,
                      style: AppTypography.caption.copyWith(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bullion.name,
                      style: AppTypography.label.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detailLine,
                      style: AppTypography.caption.copyWith(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specsLine,
                      style: AppTypography.caption.copyWith(
                        color: secondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          AppCurrency.format(
                            formatGroupedPrice(bullion.price),
                          ),
                          style: GoogleFonts.manrope(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ).copyWith(color: textColor),
                        ),
                        const Spacer(),
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

class _BullionCardImage extends StatelessWidget {
  const _BullionCardImage({required this.bullion});

  final Bullion bullion;

  @override
  Widget build(BuildContext context) {
    final network = bullion.renderableImageUrl;
    if (network != null) {
      return AppNetworkImage(
        url: network,
        fit: BoxFit.cover,
        memCacheWidth: 480,
        error: _metalFallback(),
      );
    }
    return _metalFallback();
  }

  Widget _metalFallback() {
    final accent = _accentColor(bullion.metal);
    return ColoredBox(
      color: AppColors.sandSurface,
      child: Center(
        child: Icon(
          _metalIcon(bullion.metal),
          size: 40,
          color: accent,
        ),
      ),
    );
  }
}

String _metalLabel(BullionMetal metal) => switch (metal) {
      BullionMetal.gold => 'Gold',
      BullionMetal.silver => 'Silver',
      BullionMetal.platinum => 'Platinum',
      BullionMetal.palladium => 'Palladium',
      BullionMetal.copper => 'Copper',
    };

String _gridTitle(Bullion b) {
  final parts = [
    if (b.weightLabel.isNotEmpty) b.weightLabel,
    if (b.presetVariant.isNotEmpty) b.presetVariant,
  ];
  if (parts.isEmpty) return b.name;
  return parts.join(' ');
}

String _gridSpecs(Bullion b) {
  final purity = b.purity > 0
      ? b.purity.toStringAsFixed(1)
      : (b.presetVariant.isNotEmpty ? b.presetVariant : null);
  return [
    if (b.shape.isNotEmpty) b.shape,
    if (purity != null) purity,
    if (b.condition.isNotEmpty) b.condition,
  ].join(' · ');
}

String _listDetailLine(Bullion b) {
  return [
    if (b.weightLabel.isNotEmpty) b.weightLabel,
    if (b.shape.isNotEmpty) b.shape,
    if (b.mintYear != null) '${b.mintYear}',
  ].join(' · ');
}

String _listSpecsLine(Bullion b) {
  final purity = b.purity > 0
      ? b.purity.toStringAsFixed(1)
      : (b.presetVariant.isNotEmpty ? b.presetVariant : null);
  return [
    if (purity != null) purity,
    if (b.mintMark.isNotEmpty) b.mintMark,
    if (b.condition.isNotEmpty) b.condition,
  ].join(' · ');
}

Color _accentColor(BullionMetal metal) {
  return switch (metal) {
    BullionMetal.gold => AppColors.bronze,
    BullionMetal.silver => AppColors.slateBorder,
    BullionMetal.platinum => AppColors.bronzeLight,
    BullionMetal.palladium => AppColors.bronzeDark,
    BullionMetal.copper => AppSwatches.copper,
  };
}

IconData _metalIcon(BullionMetal metal) {
  return switch (metal) {
    BullionMetal.gold => Icons.currency_bitcoin_outlined,
    BullionMetal.silver => Icons.currency_exchange_outlined,
    BullionMetal.platinum => Icons.sports_martial_arts_outlined,
    BullionMetal.palladium => Icons.monetization_on_outlined,
    BullionMetal.copper => Icons.hardware_outlined,
  };
}
