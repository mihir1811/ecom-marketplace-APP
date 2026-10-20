import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_education/application/diamond_simulator_controller.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_grades.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_proportions.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_mesh.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_morph.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_renderer.dart';

/// Whether (x, y, z) lies inside every traced plane of [mesh].
bool _inside(SimMesh mesh, double x, double y, double z) =>
    mesh.inset(x, y, z) > 0;

/// Share of a grid of points that [a] and [b] disagree on, inside or out.
double _mismatch(SimMesh a, SimMesh b) {
  var differ = 0, total = 0;
  for (var i = -24; i <= 24; i++) {
    for (var j = -12; j <= 12; j++) {
      for (var k = -24; k <= 24; k++) {
        // Off the round numbers facets sit on.
        final x = i / 11 + 0.0137, y = j / 11 + 0.0071, z = k / 11 + 0.0093;
        if (_inside(a, x, y, z) != _inside(b, x, y, z)) differ++;
        total++;
      }
    }
  }
  return differ / total;
}

void main() {
  group('SimShapeMorph', () {
    const shapes = SimShape.values;
    for (final grade in [CutGrade.excellent, CutGrade.good]) {
      for (var i = 0; i < shapes.length; i++) {
        final sa = shapes[i], sb = shapes[(i + 1) % shapes.length];
        test('${sa.name} → ${sb.name} (${grade.name}) is one smooth solid', () {
          final a = SimMesh.build(sa, DiamondProportions.forGrade(sa, grade));
          final b = SimMesh.build(sb, DiamondProportions.forGrade(sb, grade));
          final m = SimShapeMorph(a, b);

          // The ends are the stones themselves.
          expect(identical(m.at(0), a), isTrue);
          expect(identical(m.at(1), b), isTrue);
          // Leaving either end changes nothing visible.
          expect(_mismatch(m.at(1e-4), a), lessThan(0.002));
          expect(_mismatch(m.at(1 - 1e-4), b), lessThan(0.002));

          double? last;
          for (var k = 1; k < 40; k++) {
            final mesh = m.at(k / 40);
            // Fits the tracer's plane budget, so the GPU draws every
            // frame; and stays one closed convex solid.
            expect(SimRenderer.fitsShader(mesh), isTrue);
            expect(mesh.mirrorX, a.mirrorX || b.mirrorX);
            expect(mesh.volume, greaterThan(0.5));
            final pos = mesh.positions;
            for (var v = 0; v < mesh.vertexCount; v++) {
              expect(
                mesh.inset(pos[v * 3], pos[v * 3 + 1], pos[v * 3 + 2]),
                greaterThan(-1e-6),
              );
            }
            // No jumps between neighbouring frames.
            if (last != null) {
              expect((mesh.volume - last).abs() / last, lessThan(0.06));
            }
            last = mesh.volume;
          }
        });
      }
    }
  });

  group('Shape dial support', () {
    test('preview cuts a shape without switching to it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(diamondSimulatorProvider.notifier);
      final before = container.read(diamondSimulatorProvider);
      final oval = c.preview(SimShape.oval);
      expect(oval.spec.shape, SimShape.oval);
      expect(
        identical(container.read(diamondSimulatorProvider), before),
        isTrue,
      );
      expect(identical(c.preview(SimShape.round), before), isTrue);

      c.commitShape(oval);
      final after = container.read(diamondSimulatorProvider);
      expect(after.spec.shape, SimShape.oval);
      expect(identical(after.mesh, oval.mesh), isTrue);
    });

    test('committing a fancy shape leaves the hearts & arrows scope', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(diamondSimulatorProvider.notifier)
        ..setHeartsArrows(true);
      expect(
        container.read(diamondSimulatorProvider).lighting,
        SimLighting.heartsArrows,
      );
      c.commitShape(c.preview(SimShape.pear));
      expect(
        container.read(diamondSimulatorProvider).lighting,
        SimLighting.daylight,
      );
    });
  });
}
