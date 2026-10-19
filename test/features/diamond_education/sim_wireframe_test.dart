import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_grades.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_proportions.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_shape.dart';
import 'package:gemstone/features/diamond_education/domain/diamond_spec.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_inclusions.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_mesh.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_optics.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_renderer.dart';
import 'package:gemstone/features/diamond_education/simulation/sim_wireframe.dart';

void main() {
  group('SimWireMesh', () {
    for (final shape in SimShape.values) {
      for (final grade in CutGrade.values) {
        test('${shape.name} ${grade.name}: every edge joins two facets', () {
          final mesh = SimMesh.build(
            shape,
            DiamondProportions.forGrade(shape, grade),
          );
          final wire = SimWireMesh.of(mesh);
          expect(wire.edgeCount, greaterThan(90));
          for (var e = 0; e < wire.edgeCount; e++) {
            expect(wire.adjStart[e + 1] - wire.adjStart[e], 2);
          }
        });
      }
    }

    test('a round brilliant draws its 57 facets and girdle exactly', () {
      final mesh = SimMesh.build(
        SimShape.round,
        DiamondProportions.ideal(SimShape.round),
      );
      final wire = SimWireMesh.of(mesh);
      // Closed solid: V − E + F = 2, girdle seams included.
      final used = <int>{
        for (var e = 0; e < wire.edgeCount * 2; e++) wire.edges[e],
      };
      expect(used.length - wire.edgeCount + mesh.facetCount, 2);
      var smooth = 0;
      for (var e = 0; e < wire.edgeCount; e++) {
        smooth += wire.smooth[e];
      }
      // Its curved girdle's segment joins show only on the outline.
      expect(smooth, 48);
      expect(wire.convex, isTrue);
    });

    test('a heart is clipped where its far lobe hides', () {
      final mesh = SimMesh.build(
        SimShape.heart,
        DiamondProportions.ideal(SimShape.heart),
      );
      expect(SimWireMesh.of(mesh).convex, isFalse);
    });
  });

  test('SimWireStyle tints lines with the body colour', () {
    Color line(DiamondSpec s) =>
        SimWireStyle.of(SimOptics.of(s, SimLighting.daylight)).line;
    final base = DiamondSpec(
      shape: SimShape.round,
      proportions: DiamondProportions.ideal(SimShape.round),
    );
    final d = line(base);
    expect(d.r, closeTo(1, 0.03));
    expect(d.b, closeTo(1, 0.03));
    final yellow = line(base.copyWith(fancyColor: FancyColor.yellow));
    expect(yellow.b, lessThan(yellow.r - 0.3));
  });

  test('SimWireRenderer paints every shape with inclusions', () {
    final renderer = SimWireRenderer();
    for (final shape in SimShape.values) {
      final mesh = SimMesh.build(shape, DiamondProportions.ideal(shape));
      final spec = DiamondSpec(
        shape: shape,
        proportions: DiamondProportions.ideal(shape),
        clarity: ClarityGrade.i2,
      );
      for (final tilt in [-math.pi / 2, 0.0, 0.95, math.pi / 2]) {
        final rec = ui.PictureRecorder();
        renderer.paint(
          Canvas(rec),
          const Size(300, 300),
          mesh: mesh,
          view: SimView(tilt: tilt, spin: 0.7),
          pxPerUnit: 110,
          style: SimWireStyle.of(SimOptics.of(spec, SimLighting.daylight)),
          inclusions: SimInclusions.generate(mesh, spec.clarity),
        );
        rec.endRecording().dispose();
      }
    }
  });
}
