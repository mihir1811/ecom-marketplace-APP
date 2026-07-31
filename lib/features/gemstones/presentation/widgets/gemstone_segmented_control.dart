import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/melee_background_shell.dart';

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

class GemstoneSegmentedControl extends StatelessWidget {
  const GemstoneSegmentedControl({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.family = MeleeBgFamily.gemstoneNatural,
    this.isMelee = false,
    super.key,
  });

  final List<SegmentOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final MeleeBgFamily family;
  final bool isMelee;

  Color _splashFor(String value) {
    // Lot type: preview Single vs Melee within the active stone-type family.
    if (value == 'Melee') {
      return AppColors.screenBg(melee: true, family: family);
    }
    if (value == 'Single') {
      return AppColors.screenBg(melee: false, family: family);
    }
    // Stone type: preview destination Natural / Lab Grown at current lot.
    if (value == 'Lab Grown') {
      return AppColors.screenBg(
        melee: isMelee,
        family: MeleeBgFamily.gemstoneLabGrown,
      );
    }
    if (value == 'Natural') {
      return AppColors.screenBg(
        melee: isMelee,
        family: MeleeBgFamily.gemstoneNatural,
      );
    }
    return AppColors.screenBg(melee: isMelee, family: family);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;

    return MeleeTintExtentAnchor(
      child: Container(
        height: 35,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: hasSelection ? AppColors.warmWhite : AppColors.sandSurface,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(
            color: hasSelection ? AppColors.bronze : AppColors.warmBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: options.map((opt) {
            final isCurrent = opt.value == selected;
            final splash = _splashFor(opt.value);

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTapDown: (details) {
                    MeleeRippleOriginNotification(details.globalPosition)
                        .dispatch(context);
                  },
                  onTap: () => onSelected(opt.value),
                  splashColor: splash.withValues(alpha: 0.55),
                  highlightColor: splash.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isCurrent ? AppColors.charcoal : Colors.transparent,
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
                              : AppColors.textMutedLight,
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
                                  : AppColors.textMutedLight,
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
      ),
    );
  }
}
