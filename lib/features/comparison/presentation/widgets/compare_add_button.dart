import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Circular "add to compare" control matching the overlapping-squares + plus icon.
class CompareAddButton extends StatelessWidget {
  const CompareAddButton({
    required this.isSelected,
    required this.onPressed,
    this.size = 32,
    super.key,
  });

  final bool isSelected;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isSelected
        ? AppColors.bronze
        : (isDark ? AppColors.slateBorder : AppColors.warmBorder);
    final fill = isSelected
        ? AppColors.bronze.withValues(alpha: 0.12)
        : (isDark ? AppColors.slateSurface : AppColors.warmWhite);
    final ink = isSelected
        ? AppColors.bronze
        : (isDark ? AppColors.textPrimaryDark : AppColors.charcoal);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Semantics(
          button: true,
          label: isSelected ? 'Remove from comparison' : 'Add to comparison',
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: border),
            ),
            child: CustomPaint(
              painter: _CompareIconPainter(color: ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareIconPainter extends CustomPainter {
  _CompareIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Back square (offset up-left).
    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.18, w * 0.42, h * 0.42),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(back, stroke);

    // Front square.
    final frontRect = Rect.fromLTWH(w * 0.34, h * 0.34, w * 0.42, h * 0.42);
    final front = RRect.fromRectAndRadius(
      frontRect,
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(front, stroke);

    // Plus in front square.
    final cx = frontRect.center.dx;
    final cy = frontRect.center.dy;
    final arm = w * 0.09;
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: arm * 2, height: 1.5), fill);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 1.5, height: arm * 2), fill);
  }

  @override
  bool shouldRepaint(covariant _CompareIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Shows a snackbar for comparison add/toggle outcomes.
void showCompareFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          88,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}
