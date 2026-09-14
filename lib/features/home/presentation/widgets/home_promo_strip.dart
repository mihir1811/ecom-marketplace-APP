import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Full-bleed editorial promo strip (layout distinct from banner carousel).
class HomePromoStrip extends StatelessWidget {
  const HomePromoStrip({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
    super.key,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      child: Material(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            color: AppColors.warmWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warmWhite.withValues(alpha: 0.82),
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          ctaLabel.toUpperCase(),
                          style: AppTypography.label.copyWith(
                            color: AppColors.bronzeLight,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: AppNetworkImage(url: imageUrl, memCacheWidth: 700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
