import 'package:flutter/services.dart';

import 'diamond_mesh.dart';
import 'gem_mesh.dart';

/// The baked diamond cuts bundled with the app (see
/// `tool/bake_gem_models.dart`), loaded once and shared.
abstract final class DiamondModels {
  static const asset = 'assets/models/gems.bin';

  static Future<List<DiamondModel>>? _models;

  /// Every bundled cut. Decoding is a few typed-array copies, cheap enough
  /// for the UI isolate.
  static Future<List<DiamondModel>> load() {
    return _models ??= () async {
      try {
        final models = DiamondModelCodec.decode(await rootBundle.load(asset));
        if (models.isEmpty) throw const FormatException('No models baked');
        return models;
      } catch (_) {
        _models = null;
        rethrow;
      }
    }();
  }

  /// Procedural pear, used if the bundle cannot be read.
  static List<DiamondModel> fallback() {
    final mesh = DiamondMesh.fromGemMesh(GemMesh.of(GemCut.pear));
    return [DiamondModel(name: 'pear', detail: mesh, coarse: mesh)];
  }
}
