import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/app_swatches.dart';
import '../../theme/luxe_tokens.dart';

/// Base tones a metal label is painted with: one for solid metals, two or
/// three for mixed-tone pieces.
List<Color> luxeMetalTones(String label) => switch (label.trim()) {
  'Two-Tone' => const [AppSwatches.yellowGold, AppSwatches.whiteGold],
  'Tri-Color' => const [
    AppSwatches.yellowGold,
    AppSwatches.whiteGold,
    AppSwatches.roseGold,
  ],
  final l => [AppSwatches.jewelryMetal(l)],
};

/// Polished metal disc: a lit sheen over the metal tone, split into equal
/// segments for two-tone and tri-colour pieces.
class LuxeMetalSwatch extends StatelessWidget {
  const LuxeMetalSwatch({
    required this.label,
    super.key,
    this.size = 14,
    this.ring,
  });

  final String label;
  final double size;

  /// Outline colour; defaults to a soft hairline.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MetalPainter(
          tones: luxeMetalTones(label),
          ring: ring ?? p.hairline,
        ),
      ),
    );
  }
}

class _MetalPainter extends CustomPainter {
  const _MetalPainter({required this.tones, required this.ring});

  final List<Color> tones;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.shortestSide / 2;
    final center = rect.center;
    final sweep = 2 * math.pi / tones.length;
    var start = -math.pi / 2;
    for (final tone in tones) {
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.1,
          colors: [
            Color.lerp(tone, Colors.white, 0.55)!,
            tone,
            Color.lerp(tone, Colors.black, 0.22)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect);
      if (tones.length == 1) {
        canvas.drawCircle(center, radius, paint);
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          true,
          paint,
        );
      }
      start += sweep;
    }
    canvas.drawCircle(
      center,
      radius - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_MetalPainter old) =>
      old.ring != ring || !_sameTones(old.tones, tones);

  static bool _sameTones(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Small overlapping stack of metal discs (e.g. a piece's colour variants),
/// with a "+n" tail when more exist.
class LuxeMetalSwatchStack extends StatelessWidget {
  const LuxeMetalSwatchStack({
    required this.labels,
    super.key,
    this.max = 3,
    this.size = 14,
    this.onImage = false,
  });

  final List<String> labels;
  final int max;
  final double size;

  /// True when drawn over photography (adds a soft backing pill).
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final shown = labels.take(max).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final extra = labels.length - shown.length;
    final overlap = size * 0.35;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size + (shown.length - 1) * (size - overlap),
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * (size - overlap),
                  child: LuxeMetalSwatch(
                    label: shown[i],
                    size: size,
                    ring: onImage ? Colors.white : p.surface,
                  ),
                ),
            ],
          ),
        ),
        if (extra > 0) ...[
          const SizedBox(width: 4),
          Text('+$extra', style: LuxeType.figure(p.inkMuted, size: 10.5)),
        ],
      ],
    );
    if (!onImage) return row;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: ShapeDecoration(
        color: p.isDark ? const Color(0x66000000) : const Color(0xE6FFFFFF),
        shape: const StadiumBorder(),
      ),
      child: row,
    );
  }
}

/// Labelled multi-select metal tones used by filters and quick picks.
/// Selected discs lift, gain an ink ring and a check.
class LuxeMetalSwatchPicker extends StatelessWidget {
  const LuxeMetalSwatchPicker({
    required this.options,
    required this.selected,
    required this.onToggle,
    super.key,
    this.labelOf,
  });

  final List<String> options;
  final Iterable<String> selected;
  final ValueChanged<String> onToggle;
  final String Function(String)? labelOf;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 14,
      children: [
        for (final o in options)
          _SwatchTile(
            label: labelOf?.call(o) ?? o,
            value: o,
            selected: selected.contains(o),
            palette: p,
            onTap: () {
              AppHaptics.selection();
              onToggle(o);
            },
          ),
      ],
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({
    required this.label,
    required this.value,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 70,
          child: Column(
            children: [
              AnimatedContainer(
                duration: LuxeMotion.medium,
                curve: LuxeMotion.settle,
                padding: const EdgeInsets.all(3),
                transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? p.ink : Colors.transparent,
                    width: 1.4,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: p.accent.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : const [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    LuxeMetalSwatch(label: value, size: 38),
                    AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: LuxeMotion.fast,
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.ink,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: p.canvas,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: LuxeType.label(
                  selected ? p.ink : p.inkMuted,
                  size: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
