import 'package:flutter/material.dart';

import '../haptics/app_haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Sticky search/filter action bar (primary CTA + clear action).
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

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: AppColors.bg(context)),
      duration: AppColors.meleeBgDuration,
      curve: Curves.easeInOutCubic,
      builder: (context, color, child) {
        return Container(
          decoration: BoxDecoration(
            color: color,
            border: Border(top: BorderSide(color: AppColors.border(context))),
            boxShadow: AppShadows.modalLight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary(context),
                  side: BorderSide(color: AppColors.border(context)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                  ),
                ),
                onPressed: () {
                  AppHaptics.selection();
                  onClear();
                },
                child: _FittedLabel(
                  clearLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.4,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  foregroundColor: AppColors.warmWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                  ),
                ),
                onPressed: onPrimary == null
                    ? null
                    : () {
                        AppHaptics.medium();
                        onPrimary!();
                      },
                child: _FittedLabel(
                  primaryLabel,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmWhite,
                    fontSize: 12,
                    letterSpacing: 0.3,
                    height: 1.15,
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

class _FittedLabel extends StatelessWidget {
  const _FittedLabel(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: style,
      ),
    );
  }
}
