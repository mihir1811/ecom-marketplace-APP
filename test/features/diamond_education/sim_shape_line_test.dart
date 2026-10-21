import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_grades.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_proportions.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_fancy.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_mesh.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_morph.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_renderer.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_shape_line.dart';

/// Share of a grid of points that [a] and [b] disagree on, inside or out.
double _mismatch(SimMesh a, SimMesh b) {
  var differ = 0, total = 0;
  for (var i = -22; i <= 22; i++) {
    for (var j = -12; j <= 12; j++) {
      for (var k = -22; k <= 22; k++) {
        final x = i / 11 + 0.0137, y = j / 11 + 0.0071, z = k / 11 + 0.0093;
        if ((a.inset(x, y, z) > 0) != (b.inset(x, y, z) > 0)) differ++;
        total++;
      }
    }
  }
  return differ / total;
}

void main() {
  final fancy = SimFancyCatalog.parse(
    File(SimFancyCatalog.asset).readAsStringSync(),
  );
  final line = SimShapeLine.of(fancy);

  test('holds every classic shape and fancy cut once', () {
    expect(line, hasLength(SimShape.values.length + fancy.length));
    expect(
      line.map((s) => s.classic).whereType<SimShape>().toSet(),
      SimShape.values.toSet(),
    );
    expect(
      line.map((s) => s.fancy?.id).whereType<String>().toSet(),
      hasLength(fancy.length),
    );
  });

  test('classic shapes keep their dial neighbours', () {
    const dial = SimShape.values;
    for (var i = 0; i + 1 < SimShapeLine.classics.length; i++) {
      final a = dial.indexOf(SimShapeLine.classics[i]);
      final b = dial.indexOf(SimShapeLine.classics[i + 1]);
      expect((b - a) % dial.length == 1 || (a - b) % dial.length == 1, isTrue);
    }
  });

  // Where a classic shape meets a fancy cut; the rest are tested as dial
  // and slider neighbours.
  group('classic to fancy morphs', () {
    for (final grade in [CutGrade.excellent, CutGrade.good]) {
      for (var i = 0; i + 1 < line.length; i++) {
        final sa = line[i], sb = line[i + 1];
        if ((sa.classic == null) == (sb.classic == null)) continue;
        SimMesh mesh(SimLineShape s) =>
            s.fancy?.mesh ??
            SimMesh.build(
              s.classic!,
              DiamondProportions.forGrade(s.classic!, grade),
            );
        final name =
            '${sa.classic?.name ?? sa.fancy!.id} → '
            '${sb.classic?.name ?? sb.fancy!.id} (${grade.name})';
        test('$name is one smooth solid', () {
          final a = mesh(sa), b = mesh(sb);
          final m = SimShapeMorph(a, b);
          expect(_mismatch(m.at(1e-4), a), lessThan(0.003));
          expect(_mismatch(m.at(1 - 1e-4), b), lessThan(0.003));
          final average = (math.log(b.volume / a.volume) / 24).abs();
          double? last;
          for (var k = 1; k < 24; k++) {
            final f = m.at(k / 24);
            expect(SimRenderer.fitsShader(f), isTrue);
            expect(f.volume, greaterThan(0.2));
            if (last != null) {
              expect(
                math.log(f.volume / last).abs(),
                lessThan(3 * average + 0.04),
              );
            }
            last = f.volume;
          }
        });
      }
    }
  });
}
