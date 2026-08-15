import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Parameterized empty state for catalog listing screens.
class CatalogEmptyState extends StatelessWidget {
  const CatalogEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconSize = 48,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.actionIsOutlined = true,
    this.actionIcon,
    this.padding = const EdgeInsets.all(AppSpacing.s32),
    this.titleStyle,
    super.key,
  });

  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionIsOutlined;
  final IconData? actionIcon;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    const muted = AppColors.textMutedLight;
    final resolvedIconColor = iconColor ?? AppColors.bronze;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: resolvedIconColor),
            SizedBox(height: iconSize >= 64 ? AppSpacing.s24 : AppSpacing.s16),
            Text(
              title,
              style: titleStyle ??
                  AppTypography.title.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: iconSize >= 64 ? AppSpacing.s12 : AppSpacing.s8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: muted,
                fontSize: iconSize >= 64 ? null : 14,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: iconSize >= 64 ? AppSpacing.s24 : AppSpacing.s20),
              if (actionIsOutlined)
                actionIcon != null
                    ? OutlinedButton.icon(
                        onPressed: onAction,
                        icon: Icon(actionIcon, size: 18),
                        label: Text(actionLabel!),
                      )
                    : OutlinedButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      )
              else
                ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
