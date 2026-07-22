import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';

class DiamondCardList extends ConsumerWidget {
  final Diamond diamond;
  final VoidCallback? onTap;

  const DiamondCardList({
    super.key,
    required this.diamond,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slateSurface : AppColors.warmWhite;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final inCompare = ref.watch(isInComparisonProvider(diamond.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
        ),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: 148,
          child: Row(
            children: [
              _buildImageSection(isDark, context, ref, inCompare),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPriceRow(textColor, mutedColor),
                      const SizedBox(height: AppSpacing.s4),
                      _buildDetailsRow(mutedColor),
                      const SizedBox(height: AppSpacing.s4),
                      _buildSpecRow(textColor, mutedColor, isDark),
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

  Widget _buildImageSection(
    bool isDark,
    BuildContext context,
    WidgetRef ref,
    bool inCompare,
  ) {
    return SizedBox(
      width: 100,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: isDark ? AppColors.charcoalLight : AppColors.sandSurface,
              child: Center(
                child: renderShapeSvg(
                  diamond.shape,
                  size: 48,
                  color: AppColors.bronze,
                ),
              ),
            ),
          ),
          if (diamond.discount != null && diamond.discount! > 0)
            Positioned(
              top: AppSpacing.s4,
              right: AppSpacing.s4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(AppSpacing.r4),
                ),
                child: Text(
                  '-${diamond.discount!.round()}%',
                  style: GoogleFontsInter.caption.copyWith(
                    color: AppColors.warmWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
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
                CompareItem.fromDiamond(diamond),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(Color textColor, Color mutedColor) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '\$${_formatPrice(diamond.price)}',
            style: GoogleFontsInter.title.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (diamond.pricePerCarat != null) ...[
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: Text(
              '\$${diamond.pricePerCarat!.round()}/ct',
              style: GoogleFontsInter.caption.copyWith(
                color: mutedColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildDetailsRow(Color mutedColor) {
    return Text(
      '${diamond.carat}ct ${diamond.shape} • ${diamond.cut}',
      style: GoogleFontsInter.body.copyWith(
        color: mutedColor,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSpecRow(Color textColor, Color mutedColor, bool isDark) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '${diamond.color} • ${diamond.clarity}',
            style: GoogleFontsInter.label.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.charcoalDark : AppColors.sandSurface,
              borderRadius: BorderRadius.circular(AppSpacing.r4),
            ),
            child: Text(
              diamond.certificate,
              style: GoogleFontsInter.caption.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price >= 10000 ? 0 : 1)}K';
    }
    return price.toStringAsFixed(0);
  }
}

/// Wrapper to use Inter (normal) font instead of PlayfairDisplay for card content.
class GoogleFontsInter {
  const GoogleFontsInter._();

  static TextStyle get title => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );
}
