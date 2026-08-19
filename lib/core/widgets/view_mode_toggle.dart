import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum ViewModeToggleStyle { labeled, iconOnly }

/// Shared grid/list view-mode control.
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBtn(
            icon: Icons.grid_view,
            selected: isGrid,
            onTap: onGrid,
          ),
          Container(width: 1, height: 28, color: border),
          _IconBtn(
            icon: Icons.view_agenda_outlined,
            selected: !isGrid,
            onTap: onList,
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s8),
        color: selected ? AppColors.surface(context) : Colors.transparent,
        child: Icon(
          icon,
          size: 18,
          color: selected ? AppColors.bronze : AppColors.textMuted(context),
        ),
      ),
    );
  }
}
