import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shared capsule select card used by diamond shape + gemstone showcase carousels.
class ShowcaseSelectCard extends StatelessWidget {
  const ShowcaseSelectCard({
    required this.name,
    required this.isSelected,
    required this.onTap,
    required this.media,
    super.key,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  /// Visual for the 84×84 media slot (image, SVG, hue fallback, etc.).
  final Widget media;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.bronze;
    final inactiveBorderColor = AppColors.border(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bg(context) : AppColors.card(context),
          borderRadius: const BorderRadius.all(Radius.circular(60.0)),
          border: Border.all(
            color: isSelected ? activeColor : inactiveBorderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? AppShadows.cardLight : AppShadows.none,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s24,
          horizontal: AppSpacing.s12,
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: media,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
