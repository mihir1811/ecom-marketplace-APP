import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/diamond_grades.dart';
import '../../sim_labels.dart';
import 'sim_controls.dart';

/// Which inclusions sit inside the stone.
class SimInclusionsPanel extends ConsumerWidget {
  const SimInclusionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      diamondSimulatorProvider.select(
        (s) => (clarity: s.spec.clarity, types: s.spec.inclusionTypes),
      ),
    );
    final c = ref.read(diamondSimulatorProvider.notifier);
    final flawless = s.clarity.index <= ClarityGrade.internallyFlawless.index;
    final p = LuxePalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimToggleChips<InclusionType?>(
          options: const [null, ...InclusionType.values],
          isSelected: (t) =>
              t == null ? s.types == null : s.types?.contains(t) ?? false,
          labelOf: (t) => t == null
              ? context.tr(EducationL10n.asGraded)
              : context.inclusionName(t),
          leadingOf: (t) => t == null
              ? const SizedBox.shrink()
              : CustomPaint(painter: InclusionGlyph(t, p.ink)),
          enabled: !flawless,
          onTap: (t) =>
              t == null ? c.setInclusionTypes(null) : c.toggleInclusionType(t),
        ),
        // Flawless grades have none: one tap to a grade that does.
        if (flawless) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(EducationL10n.noInclusions),
                  style: LuxeType.label(p.inkMuted, size: 13),
                ),
              ),
              Flexible(
                child: SimChoiceChips<ClarityGrade>(
                  options: const [ClarityGrade.vs1],
                  selected: null,
                  labelOf: (_) => context.tr(EducationL10n.lowerClarity),
                  onSelected: c.setClarity,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A small picture of an inclusion kind, for its chip.
class InclusionGlyph extends CustomPainter {
  InclusionGlyph(this.type, this.color);

  final InclusionType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    switch (type) {
      case InclusionType.crystal:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = math.pi / 3 * i + math.pi / 6;
          final o = c + Offset(math.cos(a), math.sin(a)) * r * 0.62;
          i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(path..close(), line);
      case InclusionType.carbon:
        canvas.drawCircle(
          c,
          r * 0.42,
          Paint()..color = const Color(0xFF111111),
        );
        canvas.drawCircle(c, r * 0.42, line..strokeWidth = 1);
      case InclusionType.feather:
        final path = Path()
          ..moveTo(c.dx - r * 0.7, c.dy + r * 0.5)
          ..quadraticBezierTo(
            c.dx,
            c.dy - r * 0.1,
            c.dx + r * 0.7,
            c.dy - r * 0.6,
          );
        canvas.drawPath(path, line);
        for (final t in const [-0.35, 0.0, 0.35]) {
          final o = c + Offset(t * r, -t * r * 0.8);
          canvas.drawLine(o, o + Offset(-r * 0.2, -r * 0.35), line);
        }
      case InclusionType.cloud:
        for (final o in const [
          Offset(-0.4, -0.1),
          Offset(-0.1, -0.35),
          Offset(0.25, -0.2),
          Offset(0.4, 0.2),
          Offset(0.0, 0.15),
          Offset(-0.3, 0.35),
          Offset(0.15, 0.45),
        ]) {
          canvas.drawCircle(c + o * r, r * 0.09, fill);
        }
      case InclusionType.pinpoint:
        canvas.drawCircle(c, r * 0.14, fill);
      case InclusionType.needle:
        canvas.drawLine(
          c + Offset(-r * 0.65, r * 0.45),
          c + Offset(r * 0.65, -r * 0.45),
          line..strokeWidth = 1.6,
        );
    }
  }

  @override
  bool shouldRepaint(covariant InclusionGlyph old) =>
      old.type != type || old.color != color;
}

/// Face-up tint of a stone with a [level] tinge of [tinge] absorption.
Color tingeSwatch(SimRgb tinge, double level) {
  double t(double a) => math.exp(-a * level * 5);
  return Color.fromRGBO(
    (t(tinge.r) * 245).round(),
    (t(tinge.g) * 245).round(),
    (t(tinge.b) * 245).round(),
    1,
  );
}

/// Brown and green tinges: the B and G of BGM.
class SimBgmPanel extends ConsumerWidget {
  const SimBgmPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      diamondSimulatorProvider.select(
        (s) => (brown: s.spec.brown, green: s.spec.green),
      ),
    );
    final c = ref.read(diamondSimulatorProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimLabel(context.tr(EducationL10n.brown)),
        SimChoiceChips<TingeLevel>(
          options: TingeLevel.values,
          selected: s.brown,
          labelOf: context.tingeName,
          swatchOf: (l) => tingeSwatch(TingeLevel.brown, l.strength),
          onSelected: c.setBrown,
        ),
        const SizedBox(height: 14),
        SimLabel(context.tr(EducationL10n.green)),
        SimChoiceChips<TingeLevel>(
          options: TingeLevel.values,
          selected: s.green,
          labelOf: context.tingeName,
          swatchOf: (l) => tingeSwatch(TingeLevel.green, l.strength),
          onSelected: c.setGreen,
        ),
      ],
    );
  }
}

/// Milkiness, graded on its own.
class SimMilkyPanel extends ConsumerWidget {
  const SimMilkyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milky = ref.watch(
      diamondSimulatorProvider.select((s) => s.spec.milky),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimChoiceChips<MilkyLevel>(
          options: MilkyLevel.values,
          selected: milky,
          labelOf: context.milkyName,
          leadingOf: (l) => CustomPaint(painter: _HazeGlyph(l.scatter / 0.13)),
          onSelected: ref.read(diamondSimulatorProvider.notifier).setMilky,
        ),
      ],
    );
  }
}

/// A sparkle seen through [haze] (0..1) of milky veil.
class _HazeGlyph extends CustomPainter {
  _HazeGlyph(this.haze);

  final double haze;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r * 0.9, Paint()..color = const Color(0xFF2A2F36));
    final star = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(c - Offset(r * 0.55, 0), c + Offset(r * 0.55, 0), star)
      ..drawLine(c - Offset(0, r * 0.55), c + Offset(0, r * 0.55), star)
      ..drawCircle(
        c,
        r * 0.9,
        Paint()
          ..color = Color.fromRGBO(236, 236, 240, (haze * 0.85).clamp(0, 1)),
      );
  }

  @override
  bool shouldRepaint(covariant _HazeGlyph old) => old.haze != haze;
}

/// Treatments and what each does to a stone.
class SimEnhancementPanel extends ConsumerWidget {
  const SimEnhancementPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(
      diamondSimulatorProvider.select((s) => s.spec.enhancement),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimChoiceChips<Enhancement>(
          options: Enhancement.values,
          selected: e,
          labelOf: context.enhancementName,
          onSelected: ref
              .read(diamondSimulatorProvider.notifier)
              .setEnhancement,
        ),
      ],
    );
  }
}
