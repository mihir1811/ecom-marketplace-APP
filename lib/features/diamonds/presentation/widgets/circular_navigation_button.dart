import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CircularNavigationButton extends StatelessWidget {
  const CircularNavigationButton({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateSurface : AppColors.sandSurface,
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? AppColors.slateBorder : AppColors.warmBorder),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon, color: AppColors.bronze),
        onPressed: onPressed,
      ),
    );
  }
}
