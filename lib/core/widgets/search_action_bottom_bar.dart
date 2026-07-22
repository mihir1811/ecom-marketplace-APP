import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Sticky search/filter action bar (primary CTA + clear link).
class SearchActionBottomBar extends StatelessWidget {
  const SearchActionBottomBar({
    required this.primaryLabel,
    required this.onPrimary,
    required this.clearLabel,
    required this.onClear,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String clearLabel;
  final VoidCallback onClear;

  static String formatCount(int count) {
    return count.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: AppColors.creamBg),
      duration: AppColors.meleeBgDuration,
      curve: Curves.easeInOutCubic,
      builder: (context, color, child) {
        return Container(
          decoration: BoxDecoration(
            color: color,
            border: Border(
              top: BorderSide(color: AppColors.warmBorder),
            ),
            boxShadow: AppShadows.modalLight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s16,
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryLight,
                  side: BorderSide(color: AppColors.warmBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                  ),
                ),
                onPressed: onClear,
                child: Text(
                  clearLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  foregroundColor: AppColors.warmWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                  ),
                ),
                onPressed: onPrimary,
                child: Text(
                  primaryLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmWhite,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
