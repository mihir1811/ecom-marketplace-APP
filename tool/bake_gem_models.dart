// Bakes the diamond .glb models into the app's compact model asset.
//
//   dart run tool/bake_gem_models.dart
//
// Reads every `assets_src/gem_models/*.glb` (sorted by name) and writes
// `assets/models/gems.bin`. Re-run after adding or replacing a model.
import 'dart:io';

import 'package:gemworld/core/widgets/gem3d/diamond_mesh.dart';
import 'package:gemworld/core/widgets/gem3d/gem_glb.dart';

void main() {
  final sources =
      Directory('assets_src/gem_models')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.glb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (sources.isEmpty) {
    stderr.writeln('No .glb files in assets_src/gem_models');
    exitCode = 1;
    return;
  }

  final models = <DiamondModel>[];
  for (final file in sources) {
    final name = file.uri.pathSegments.last.replaceAll('.glb', '');
    final model = GemGlb.convert(name, file.readAsBytesSync());
    models.add(model);
    stdout.writeln(
      '${name.padRight(20)} detail ${model.detail.triangleCount} tris '
      '/ ${model.detail.vertexCount} verts, '
      'coarse ${model.coarse.triangleCount} tris',
    );
  }

  final out = File('assets/models/gems.bin')
    ..createSync(recursive: true)
    ..writeAsBytesSync(DiamondModelCodec.encode(models));
  stdout.writeln('Wrote ${out.path} (${out.lengthSync()} bytes)');
}
