import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/diamond_grades.dart';
import '../../sim_labels.dart';
import 'sim_controls.dart';

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
