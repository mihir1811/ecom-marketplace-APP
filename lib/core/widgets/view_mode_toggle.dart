import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum ViewModeToggleStyle { labeled, iconOnly }

/// Shared grid/list view-mode control (compact icon-only matches jewelry).
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    required this.isGrid,
    required this.onGrid,
    required this.onList,
    this.style = ViewModeToggleStyle.iconOnly,
    this.gridLabel = 'Grid',
    this.listLabel = 'List',
    super.key,
  });

  final bool isGrid;
  final VoidCallback onGrid;
  final VoidCallback onList;
  final ViewModeToggleStyle style;
  final String gridLabel;
  final String listLabel;

  @override
  Widget build(BuildContext context) {
    if (style == ViewModeToggleStyle.labeled) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LabeledBtn(
              icon: Icons.grid_view,
              label: gridLabel,
              isSelected: isGrid,
              onTap: onGrid,
            ),
            Container(
              width: 1,
              height: 24,
              color: AppColors.border(context),
            ),
            _LabeledBtn(
              icon: Icons.view_list,
              label: listLabel,
              isSelected: !isGrid,
              onTap: onList,
            ),
          ],
        ),
      );
    }

    final border = AppColors.border(context);
    return Material(
      color: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 28,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBtn(
              icon: Icons.grid_view_outlined,
              selected: isGrid,
              onTap: onGrid,
            ),
            Container(width: 1, height: double.infinity, color: border),
            _IconBtn(
              icon: Icons.view_agenda_outlined,
              selected: !isGrid,
              onTap: onList,
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledBtn extends StatelessWidget {
  const _LabeledBtn({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bronze : Colors.transparent,
          borderRadius:
              isSelected ? BorderRadius.circular(AppSpacing.r8) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isSelected ? AppColors.warmWhite : AppColors.textMuted(context),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.warmWhite
                    : AppColors.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedBg = AppColors.isDark(context)
        ? AppColors.surface(context)
        : AppColors.sandSurface;

    return InkWell(
      onTap: onTap,
      child: ColoredBox(
        color: selected ? selectedBg : Colors.transparent,
        child: SizedBox(
          width: 30,
          height: 28,
          child: Icon(
            icon,
            size: 15,
            color: selected ? AppColors.bronze : AppColors.textMuted(context),
          ),
        ),
      ),
    );
  }
}
