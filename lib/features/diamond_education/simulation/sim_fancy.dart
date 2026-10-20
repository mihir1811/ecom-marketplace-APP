import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'sim_mesh.dart';

/// A fancy cut the simulator shows as it comes from its 3D model, with
/// no controls of its own: the stone and its top view.
///
/// Baked from `assets_src/fancy_shapes/*.glb` by
/// `tool/bake_fancy_shapes.py`, as the facet planes that bound it.
class SimFancyShape {
  SimFancyShape({
    required this.id,
    required this.fold,
    required this.planes,
    required this.kinds,
  });

  /// Stable id: the icon's file name and the name's translation key.
  final String id;

  /// How it is traced ([SimMesh.fold]): stars and the lily are concave.
  final int fold;

  /// Facet planes `n · p <= d` (nx ny nz d each), half-width units.
  final Float64List planes;
  final List<SimFacetKind> kinds;

  String get svgAsset => 'assets/shapes/fancy/$id.svg';

  /// The cut stone; worked out on first use (a few milliseconds).
  late final SimMesh mesh = SimMesh.fromPlanes(planes, kinds, fold: fold);
}

/// The fancy cuts, in the order the shape slider shows them: alike
/// shapes side by side, so each step is a small recut.
abstract final class SimFancyCatalog {
  static const asset = 'assets/models/fancy_shapes.json';

  static Future<List<SimFancyShape>>? _shapes;

  /// The catalog, once [load] has finished.
  static List<SimFancyShape>? loaded;

  /// Loads the catalog once per run.
  static Future<List<SimFancyShape>> load() =>
      _shapes ??= rootBundle.loadString(asset).then((source) {
        return loaded = parse(source);
      });

  static List<SimFancyShape> parse(String source) {
    final doc = jsonDecode(source) as Map<String, Object?>;
    return [
      for (final raw in doc['shapes']! as List<Object?>)
        () {
          final s = raw! as Map<String, Object?>;
          final rows = s['planes']! as List<Object?>;
          final planes = Float64List(rows.length * 4);
          final kinds = <SimFacetKind>[];
          for (var i = 0; i < rows.length; i++) {
            final r = rows[i]! as List<Object?>;
            for (var k = 0; k < 4; k++) {
              planes[i * 4 + k] = (r[k]! as num).toDouble();
            }
            kinds.add(SimFacetKind.values[(r[4]! as num).toInt()]);
          }
          return SimFancyShape(
            id: s['id']! as String,
            fold: (s['fold']! as num).toInt(),
            planes: planes,
            kinds: kinds,
          );
        }(),
    ];
  }
}
