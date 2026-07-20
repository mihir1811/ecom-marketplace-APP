import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/melee_background_shell.dart';

/// One selectable entry of a [GemstoneSegmentedControl].
class SegmentOption {
  const SegmentOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

/// Pill-style segmented control.
class GemstoneSegmentedControl extends StatelessWidget {
  const GemstoneSegmentedControl({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<SegmentOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSelection = selected != null;

    return Container(
      height: 35,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: hasSelection
            ? (isDark ? AppColors.charcoalLight : AppColors.warmWhite)
            : (isDark ? Colors.black26 : AppColors.sandSurface),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(
          color: hasSelection
              ? AppColors.bronze
              : (isDark ? AppColors.slateBorder : AppColors.warmBorder),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: options.map((opt) {
          final isCurrent = opt.value == selected;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTapDown: (details) {
                  MeleeRippleOriginNotification(details.globalPosition)
                      .dispatch(context);
                },
                onTap: () => onSelected(opt.value),
                splashColor: (opt.value == 'Melee'
                        ? AppColors.screenBg(isDark: isDark, melee: true)
                        : AppColors.bronzeLight)
                    .withValues(alpha: 0.55),
                highlightColor: (opt.value == 'Melee'
                        ? AppColors.screenBg(isDark: isDark, melee: true)
                        : AppColors.bronzeLight)
                    .withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppSpacing.r12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.charcoal : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.r12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        opt.icon,
                        size: 15,
                        color: isCurrent
                            ? AppColors.warmWhite
                            : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          opt.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            height: 1,
                            color: isCurrent
                                ? AppColors.warmWhite
                                : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
