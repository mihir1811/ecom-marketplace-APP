import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_fancy.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_mesh.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_morph.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_renderer.dart';

/// Share of a grid of points that [a] and [b] disagree on, inside or out.
double _mismatch(SimMesh a, SimMesh b) {
  var differ = 0, total = 0;
  for (var i = -22; i <= 22; i++) {
    for (var j = -12; j <= 12; j++) {
      for (var k = -22; k <= 22; k++) {
        // Off the round numbers facets sit on.
        final x = i / 11 + 0.0137, y = j / 11 + 0.0071, z = k / 11 + 0.0093;
        if ((a.inset(x, y, z) > 0) != (b.inset(x, y, z) > 0)) differ++;
        total++;
      }
    }
  }
  return differ / total;
}

void main() {
  final shapes = SimFancyCatalog.parse(
    File(SimFancyCatalog.asset).readAsStringSync(),
  );

  test('every fancy cut has its icon and a unique id', () {
    expect(shapes, hasLength(40));
    expect(shapes.map((s) => s.id).toSet(), hasLength(shapes.length));
    for (final s in shapes) {
      expect(File(s.svgAsset).existsSync(), isTrue, reason: s.id);
    }
  });

  group('fancy cuts', () {
    for (final s in shapes) {
      test('${s.id} is one closed stone within the tracer budget', () {
        final mesh = s.mesh;
        expect(mesh.fold, s.fold);
        expect(SimRenderer.fitsShader(mesh), isTrue);
        expect(mesh.volume, greaterThan(0.2));
        expect(mesh.radius, inInclusiveRange(1, 3));
        final pos = mesh.positions;
        for (final v in pos) {
          expect(v.isFinite, isTrue);
        }
        // About 2 across, as the classic shapes.
        var w = 0.0;
        for (var v = 0; v < mesh.vertexCount; v++) {
          w = math.max(w, math.max(pos[v * 3].abs(), pos[v * 3 + 2].abs()));
        }
        expect(w, closeTo(1, 0.15));
        // Every corner, its mirror images too, lies on the stone.
        for (var v = 0; v < mesh.vertexCount; v++) {
          expect(
            mesh.inset(pos[v * 3], pos[v * 3 + 1], pos[v * 3 + 2]),
            greaterThan(-1e-6),
          );
        }
      });
    }
  });

  group('fancy slider morphs', () {
    for (var i = 0; i + 1 < shapes.length; i++) {
      final sa = shapes[i], sb = shapes[i + 1];
      test('${sa.id} → ${sb.id} is one smooth solid', () {
        final a = sa.mesh, b = sb.mesh;
        final m = SimShapeMorph(a, b);
        expect(identical(m.at(0), a), isTrue);
        expect(identical(m.at(1), b), isTrue);
        // Leaving either end changes nothing visible, even where the
        // morph is traced folded (the neighbour shares the symmetry).
        expect(_mismatch(m.at(1e-4), a), lessThan(0.003));
        expect(_mismatch(m.at(1 - 1e-4), b), lessThan(0.003));

        // No jumps between neighbouring frames: never more than a few
        // times the average step, however different the two stones.
        final average = (math.log(b.volume / a.volume) / 24).abs();
        double? last;
        for (var k = 1; k < 24; k++) {
          final mesh = m.at(k / 24);
          expect(SimRenderer.fitsShader(mesh), isTrue);
          expect(mesh.fold, math.max(a.fold, b.fold));
          expect(mesh.volume, greaterThan(0.2));
          if (last != null) {
            expect(
              math.log(mesh.volume / last).abs(),
              lessThan(3 * average + 0.04),
            );
          }
          last = mesh.volume;
        }
      });
    }
  });
}
