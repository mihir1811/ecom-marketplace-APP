import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Chrono24-style capsule swatches for material / color filter options.
class WatchFilterSwatchPillGrid extends StatelessWidget {
  const WatchFilterSwatchPillGrid({
    required this.options,
    required this.selected,
    required this.onToggle,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.s16,
      AppSpacing.s4,
      AppSpacing.s16,
      AppSpacing.s12,
    ),
  });

  /// Outer padding; luxe finder sections pass their own inset.
  final EdgeInsetsGeometry padding;

  final List<String> options;
  final Set<String> selected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columns = 3;
          const gap = AppSpacing.s12;
          // Floor so rounding never pushes the last cell onto a new row.
          final cellW = ((constraints.maxWidth - gap * (columns - 1)) / columns)
              .floorToDouble();

          return Wrap(
            spacing: gap,
            runSpacing: AppSpacing.s16,
            children: [
              for (final opt in options)
                SizedBox(
                  width: cellW,
                  child: _WatchFilterSwatchPill(
                    label: opt,
                    selected: selected.contains(opt),
                    onTap: () => onToggle(opt),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WatchFilterSwatchPill extends StatelessWidget {
  const _WatchFilterSwatchPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _WatchFilterPillStyle.resolve(label);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 22,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? AppColors.selectedFill(context)
                      : (style.needsBorder
                            ? AppColors.border(context)
                            : Colors.transparent),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.selectedFill(
                            context,
                          ).withValues(alpha: 0.18),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: CustomPaint(
                  painter: _PillPainter(style: style),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                height: 1.2,
                color: selected
                    ? AppColors.textPrimary(context)
                    : AppColors.textMuted(context),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.check, size: 14, color: AppColors.bronze),
              ),
          ],
        ),
      ),
    );
  }
}

enum _PillKind { solid, gradient, split, carbon, rainbow, mottled }

class _WatchFilterPillStyle {
  const _WatchFilterPillStyle({
    required this.kind,
    required this.colors,
    this.needsBorder = false,
  });

  final _PillKind kind;
  final List<Color> colors;
  final bool needsBorder;

  static _WatchFilterPillStyle resolve(String label) {
    final key = label.toLowerCase().trim();

    if (key.contains('carbon fiber') || key == 'carbon') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.carbon,
        colors: [Color(0xFF1A1A1A), Color(0xFF3A3A3A)],
      );
    }
    if (key.contains('forged carbon')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.mottled,
        colors: [Color(0xFF2A2A2A), Color(0xFF555555), Color(0xFF1C1C1C)],
      );
    }
    if (key.contains('two-tone') ||
        key.contains('steel & gold') ||
        key.contains('titanium & gold') ||
        key.contains('silver & gold') ||
        key == 'bicolour' ||
        key == 'bicolor') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.split,
        colors: [Color(0xFFD4AF37), Color(0xFFC8CCD0)],
      );
    }
    if (key.contains('silver & black')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.split,
        colors: [Color(0xFFC8CCD0), Color(0xFF1A1A1A)],
      );
    }
    if (key.contains('multicolour') || key.contains('multicolor')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.rainbow,
        colors: [
          Color(0xFFE53935),
          Color(0xFFFB8C00),
          Color(0xFFFDD835),
          Color(0xFF43A047),
          Color(0xFF1E88E5),
          Color(0xFF8E24AA),
        ],
      );
    }
    if (key.contains('sapphire')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFB3E5FC), Color(0xFF4FC3F7), Color(0xFF81D4FA)],
      );
    }
    if (key.contains('cerachrom') ||
        key.contains('ceramic') ||
        key.contains('high-tech ceramic')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF111111), Color(0xFF3A3A3A), Color(0xFF1A1A1A)],
      );
    }
    if (key.contains('904l') || key.contains('stainless')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF9EA3A8), Color(0xFFE8EAED), Color(0xFFB0B5BA)],
      );
    }
    if (key.contains('titanium')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF6E7378), Color(0xFFA8ADB2), Color(0xFF7A7F84)],
      );
    }
    if (key.contains('aluminum') || key.contains('aluminium')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFB8BCC0), Color(0xFFF0F2F4), Color(0xFFC4C8CC)],
      );
    }
    if (key.contains('platinum') || key.contains('palladium')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFC5C5C5), Color(0xFFF5F5F5), Color(0xFFD0D0D0)],
      );
    }
    if (key.contains('white gold')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFD0D0D0), Color(0xFFF7F7F7), Color(0xFFD8D8D8)],
      );
    }
    if (key.contains('rose gold')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFB76E79), Color(0xFFE8B4BC), Color(0xFFC98992)],
      );
    }
    if (key.contains('yellow gold') || key == 'gold') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFC9A227), Color(0xFFF5E6A3), Color(0xFFD4AF37)],
      );
    }
    if (key.contains('bronze')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF8B5A2B), Color(0xFFCD9B5C), Color(0xFFA0663A)],
      );
    }
    if (key.contains('brass')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFB5A642), Color(0xFFE6D88A), Color(0xFFC9B84A)],
      );
    }
    if (key.contains('tungsten')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF3A3A3A), Color(0xFF6E6E6E), Color(0xFF4A4A4A)],
      );
    }
    if (key.contains('leather')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF5D4037), Color(0xFF8D6E63), Color(0xFF6D4C41)],
      );
    }
    if (key.contains('rubber') || key.contains('silicone')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF212121), Color(0xFF424242), Color(0xFF1B1B1B)],
      );
    }
    if (key.contains('nato')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.split,
        colors: [Color(0xFF1A237E), Color(0xFFC62828)],
      );
    }
    if (key.contains('nylon') || key.contains('fabric')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF5C6BC0), Color(0xFF9FA8DA), Color(0xFF7986CB)],
      );
    }
    if (key.contains('denim')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF1565C0), Color(0xFF64B5F6), Color(0xFF1E88E5)],
      );
    }
    if (key.contains('satin')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFF5F5F5), Color(0xFFFFFFFF), Color(0xFFECECEC)],
        needsBorder: true,
      );
    }
    if (key.contains('mother of pearl')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFFFF8E7), Color(0xFFE8D5FF), Color(0xFFD5F3FF)],
        needsBorder: true,
      );
    }
    if (key.contains('skeleton')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFBDBDBD), Color(0xFFEEEEEE), Color(0xFF9E9E9E)],
        needsBorder: true,
      );
    }
    if (key.contains('champagne')) {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFFC9B896), Color(0xFFF5E6C8), Color(0xFFD4C4A8)],
      );
    }
    if (key.contains('anthracite') || key == 'grey' || key == 'gray') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF424242), Color(0xFF757575), Color(0xFF616161)],
      );
    }
    if (key == 'silver') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.gradient,
        colors: [Color(0xFF9E9E9E), Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
      );
    }
    if (key == 'black') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.solid,
        colors: [Color(0xFF111111)],
      );
    }
    if (key == 'blue') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.solid,
        colors: [Color(0xFF1565C0)],
      );
    }
    if (key == 'green') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.solid,
        colors: [Color(0xFF2E7D32)],
      );
    }
    if (key == 'brown') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.solid,
        colors: [Color(0xFF6D4C41)],
      );
    }
    if (key == 'orange') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.solid,
        colors: [Color(0xFFEF6C00)],
      );
    }
    if (key == 'red') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.solid,
        colors: [Color(0xFFC62828)],
      );
    }
    if (key == 'white') {
      return const _WatchFilterPillStyle(
        kind: _PillKind.solid,
        colors: [Color(0xFFFFFFFF)],
        needsBorder: true,
      );
    }

    return const _WatchFilterPillStyle(
      kind: _PillKind.gradient,
      colors: [Color(0xFF9E9E9E), Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
    );
  }
}

class _PillPainter extends CustomPainter {
  const _PillPainter({required this.style});

  final _WatchFilterPillStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    switch (style.kind) {
      case _PillKind.solid:
        canvas.drawRect(rect, Paint()..color = style.colors.first);
      case _PillKind.gradient:
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: style.colors.length >= 3
                ? style.colors
                : [
                    style.colors.first,
                    Color.lerp(style.colors.first, Colors.white, 0.55)!,
                    style.colors.length > 1
                        ? style.colors.last
                        : style.colors.first,
                  ],
          ).createShader(rect);
        canvas.drawRect(rect, paint);
      case _PillKind.split:
        final mid = size.width / 2;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, mid, size.height),
          Paint()..color = style.colors[0],
        );
        canvas.drawRect(
          Rect.fromLTWH(mid, 0, mid, size.height),
          Paint()..color = style.colors[1],
        );
        // Metallic sheen overlay on each half
        final sheen = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.28),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.12),
            ],
          ).createShader(rect);
        canvas.drawRect(rect, sheen);
      case _PillKind.rainbow:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(colors: style.colors).createShader(rect),
        );
      case _PillKind.carbon:
        canvas.drawRect(rect, Paint()..color = style.colors.first);
        final line = Paint()
          ..color = style.colors.last.withValues(alpha: 0.55)
          ..strokeWidth = 1.2;
        const step = 5.0;
        for (var x = -size.height; x < size.width + size.height; x += step) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x + size.height, size.height),
            line,
          );
          canvas.drawLine(
            Offset(x + step / 2, 0),
            Offset(x + step / 2 + size.height, size.height),
            line..color = Colors.white.withValues(alpha: 0.08),
          );
        }
      case _PillKind.mottled:
        canvas.drawRect(rect, Paint()..color = style.colors.first);
        final blob = Paint()..style = PaintingStyle.fill;
        final rng = _HashRng(labelHash: style.colors.hashCode);
        for (var i = 0; i < 28; i++) {
          blob.color = style.colors[1 + (i % (style.colors.length - 1))]
              .withValues(alpha: 0.35 + rng.next() * 0.35);
          final cx = rng.next() * size.width;
          final cy = rng.next() * size.height;
          final r = 2.0 + rng.next() * 5;
          canvas.drawCircle(Offset(cx, cy), r, blob);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _PillPainter oldDelegate) =>
      oldDelegate.style != style;
}

/// Tiny deterministic RNG so mottled patterns stay stable across rebuilds.
class _HashRng {
  _HashRng({required int labelHash}) : _s = labelHash == 0 ? 1 : labelHash;

  int _s;

  double next() {
    _s = (1103515245 * _s + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }
}
