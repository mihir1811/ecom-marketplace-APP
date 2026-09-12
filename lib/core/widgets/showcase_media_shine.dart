import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft static glow behind showcase media (diamond shapes / gemstones).
///
/// Keep the falloff soft — glow should read as shine, not a hard ring.
/// Pass [glowColor] for gemstone-tinted shading; omit for cool diamond white.
class ShowcaseMediaShine extends StatelessWidget {
  const ShowcaseMediaShine({required this.child, this.glowColor, super.key});

  final Widget child;

  /// Gemstone-specific tint. Null uses a cool diamond-white glow.
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final tint =
        glowColor ??
        (isDark ? const Color(0xFFF4F8FF) : const Color(0xFF8FA6C4));
    final mid = glowColor == null
        ? (isDark ? const Color(0xFFE8F0FF) : const Color(0xFFB7C6DC))
        : Color.lerp(glowColor!, Colors.white, 0.35)!;

    final coreA = isDark ? 0.55 : 0.42;
    final midA = isDark ? 0.32 : 0.26;
    final softA = isDark ? 0.14 : 0.12;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  tint.withValues(alpha: coreA),
                  mid.withValues(alpha: midA),
                  mid.withValues(alpha: softA),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.28, 0.58, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(alpha: isDark ? 0.38 : 0.28),
                  blurRadius: 40,
                  spreadRadius: 7,
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
