import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../domain/models/billion.dart';

enum BullionCardLayout { grid, list }

/// Card UI for a single bullion product.
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
    const textColor = AppColors.textPrimaryLight;
    const mutedColor = AppColors.textSecondaryLight;

    final accent = _accentColor(bullion.metal);
    final gradient = _metalGradient(bullion.metal);
    final icon = _metalIcon(bullion.metal);

    return MarketplaceProductCardShell(
      onTap: onTap,
      borderRadius: AppSpacing.r12,
      child: layout == BullionCardLayout.grid
          ? SizedBox.expand(
              child: _GridCardBody(
                bullion: bullion,
                gradient: gradient,
                icon: icon,
                accent: accent,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
            )
          : _ListCardBody(
              bullion: bullion,
              gradient: gradient,
              icon: icon,
              accent: accent,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
    );
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

  LinearGradient _metalGradient(BullionMetal metal) {
    final bronze = AppColors.bronze;
    final bronze2 = AppColors.bronzeLight;

    return switch (metal) {
      BullionMetal.gold => LinearGradient(
          colors: [
            bronze2.withValues(alpha: 0.25),
            bronze.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      BullionMetal.silver => LinearGradient(
          colors: [
            AppColors.slateBorder.withValues(alpha: 0.35),
            AppColors.textMutedDark.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      BullionMetal.platinum => LinearGradient(
          colors: [
            AppColors.warmWhite.withValues(alpha: 0.35),
            AppColors.sandSurface.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      BullionMetal.palladium => LinearGradient(
          colors: [
            AppColors.bronzeLight.withValues(alpha: 0.25),
            AppColors.terracotta.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      BullionMetal.copper => LinearGradient(
          colors: [
            const Color(0xFFDD915E).withValues(alpha: 0.35),
            const Color(0xFFB86B3C).withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
}

String _metalLabel(BullionMetal metal) => switch (metal) {
      BullionMetal.gold => 'Gold',
      BullionMetal.silver => 'Silver',
      BullionMetal.platinum => 'Platinum',
      BullionMetal.palladium => 'Palladium',
      BullionMetal.copper => 'Copper',
    };

/// Grid card matching [WatchCardGrid] layout with bullion data.
class _GridCardBody extends StatelessWidget {
  const _GridCardBody({
    required this.bullion,
    required this.gradient,
    required this.icon,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
  });

  final Bullion bullion;
  final LinearGradient gradient;
  final IconData icon;
  final Color accent;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final category = _metalLabel(bullion.metal);
    final title = '${bullion.weightLabel} ${bullion.presetVariant}';
    final specs =
        '${bullion.shape} · ${bullion.purity.toStringAsFixed(1)} · ${bullion.condition}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.05,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.sandSurface,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: gradient),
                    child: Center(
                      child: Icon(icon, size: 56, color: accent),
                    ),
                  ),
                ),
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
              AppSpacing.s8,
              AppSpacing.s12,
              AppSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  specs,
                  style: AppTypography.caption.copyWith(
                    color: mutedColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppCurrency.format(formatGroupedPrice(bullion.price)),
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
    );
  }
}

class _ListCardBody extends StatelessWidget {
  const _ListCardBody({
    required this.bullion,
    required this.gradient,
    required this.icon,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
  });

  final Bullion bullion;
  final LinearGradient gradient;
  final IconData icon;
  final Color accent;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 112,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(gradient: gradient),
                    child: Center(
                      child: Icon(icon, size: 44, color: accent),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.s8,
                  left: AppSpacing.s8,
                  child: _VariantChip(label: bullion.presetVariant),
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
                    bullion.name,
                    style: AppTypography.label.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '${bullion.weightLabel}  •  ${bullion.shape}  •  ${bullion.condition}',
                    style: AppTypography.caption.copyWith(color: mutedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '${bullion.certification}  •  ${bullion.mintMark}',
                    style: AppTypography.caption.copyWith(color: mutedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppCurrency.format(formatGroupedPrice(bullion.price)),
                          style: AppTypography.title.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        'Qty ${bullion.quantityAvailable}',
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.warmWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
