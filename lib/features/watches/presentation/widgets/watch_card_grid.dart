import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/watch.dart';
import 'watch_brand_assets.dart';

class WatchCardGrid extends StatelessWidget {
  const WatchCardGrid({
    required this.watch,
    this.onTap,
    super.key,
  });

  final Watch watch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slateSurface : AppColors.warmWhite;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final logo = WatchBrandAssets.logoPath(watch.brand);

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
              aspectRatio: 1.05,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: isDark
                          ? AppColors.charcoalLight
                          : AppColors.sandSurface,
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
                            '\$${formatWatchPrice(watch.price)}',
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
      ),
    );
  }
}

String formatWatchPrice(double price) {
  if (price >= 1000000) {
    return '${(price / 1000000).toStringAsFixed(1)}M';
  }
  if (price >= 1000) {
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
  return price.toStringAsFixed(0);
}

class WatchCardList extends StatelessWidget {
  const WatchCardList({
    required this.watch,
    this.onTap,
    super.key,
  });

  final Watch watch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slateSurface : AppColors.warmWhite;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final logo = WatchBrandAssets.logoPath(watch.brand);

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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 112,
                child: Container(
                  color: isDark
                      ? AppColors.charcoalLight
                      : AppColors.sandSurface,
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
                            '\$${formatWatchPrice(watch.price)}',
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
      ),
    );
  }
}
