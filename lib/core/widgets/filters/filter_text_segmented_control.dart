import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../melee_background_shell.dart';

/// String-based single-select segmented control (switch) — used by the
/// lab-grown Diamond Category section.
class FilterTextSegmentedControl extends StatelessWidget {
  const FilterTextSegmentedControl({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> options;
  final String selected;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    const borderColor = AppColors.warmBorder;

    return MeleeTintExtentAnchor(
      child: Container(
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: options.map((opt) {
          final isCurrent = opt == selected;
          final isMeleeOpt = opt.toLowerCase().contains('melee');
          final splash = isMeleeOpt
              ? AppColors.screenBg(
                  melee: true,
                  family: MeleeBgFamily.labGrown,
                )
              : AppColors.bronzeLight;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTapDown: (details) {
                  MeleeRippleOriginNotification(details.globalPosition)
                      .dispatch(context);
                },
                onTap: () => onSelected(opt),
                splashColor: splash.withValues(alpha: 0.55),
                highlightColor: splash.withValues(alpha: 0.22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.charcoal
                        : (AppColors.warmWhite),
                    borderRadius: BorderRadius.circular(AppSpacing.r8 - 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    opt.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: 0.5,
                      color: isCurrent
                          ? AppColors.warmWhite
                          : (AppColors.textPrimaryLight),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
    );
  }
}
