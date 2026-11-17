import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/widgets/gem3d/gem_mesh.dart';

void main() {
  for (final cut in GemCut.values) {
    test('${cut.name} mesh is closed, finite and faces outward', () {
      final mesh = GemMesh.of(cut);
      expect(mesh.triangleCount, greaterThan(40));
      expect(mesh.vertices.length, mesh.triangleCount * 9);
      expect(mesh.normals.length, mesh.triangleCount * 3);

      var minY = double.infinity, maxY = -double.infinity, maxR = 0.0;
      for (var i = 0; i < mesh.vertices.length; i += 3) {
        final x = mesh.vertices[i], y = mesh.vertices[i + 1];
        final z = mesh.vertices[i + 2];
        expect(x.isFinite && y.isFinite && z.isFinite, isTrue);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
        maxR = math.max(maxR, math.sqrt(x * x + z * z));
      }
      // Centred on height, girdle within the unit circle (plus rounding).
      expect((maxY + minY).abs(), lessThan(1e-4));
      expect(maxR, lessThanOrEqualTo(1.0001 * math.sqrt2));

      // Table faces up; the culet region faces down.
      final tableIndex = mesh.kinds.indexOf(GemFacetKind.table);
      expect(mesh.normals[tableIndex * 3 + 1], greaterThan(0.99));
      final pavilion = mesh.kinds.lastIndexOf(GemFacetKind.pavilion);
      expect(mesh.normals[pavilion * 3 + 1], lessThan(0));

      // Every facet normal points away from the stone's vertical axis at
      // its height (holds for all cuts except the heart's cleft).
      if (cut != GemCut.heart) {
        for (var t = 0; t < mesh.triangleCount; t++) {
          var cx = 0.0, cy = 0.0, cz = 0.0;
          for (var c = 0; c < 3; c++) {
            cx += mesh.vertices[t * 9 + c * 3];
            cy += mesh.vertices[t * 9 + c * 3 + 1];
            cz += mesh.vertices[t * 9 + c * 3 + 2];
          }
          final dot =
              mesh.normals[t * 3] * cx +
              mesh.normals[t * 3 + 1] * cy +
              mesh.normals[t * 3 + 2] * cz;
          expect(dot, greaterThan(0), reason: '${cut.name} triangle $t');
        }
      }
    });
  }

  test('meshes are cached', () {
    expect(identical(GemMesh.of(GemCut.pear), GemMesh.of(GemCut.pear)), isTrue);
  });
}
