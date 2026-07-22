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
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.warmBorder),
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
