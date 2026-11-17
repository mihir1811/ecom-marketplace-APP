import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'gem_mesh.dart';

/// Faceted stone laid out for the diamond renderer: shared vertices and a
/// list of flat facets. Each facet lists the vertices it uses and its
/// triangles over them (local indices, counter-clockwise seen from
/// outside); a convex facet is a simple fan.
///
/// Sharing lets the renderer transform and project every vertex once per
/// stone, and shade, cull and colour once per facet instead of once per
/// triangle corner. Model space matches [GemMesh]: table up (+y), girdle
/// within the unit circle, centred on the stone's height.
class DiamondMesh {
  DiamondMesh({
    required this.positions,
    required this.normals,
    required this.seeds,
    required this.kinds,
    required this.vertStart,
    required this.verts,
    required this.triStart,
    required this.tris,
  }) : radius = _radius(positions);

  /// Each triangle of a procedural [GemMesh] as its own facet; the
  /// fallback when the baked models are unavailable.
  factory DiamondMesh.fromGemMesh(GemMesh mesh) {
    final count = mesh.triangleCount;
    return DiamondMesh(
      positions: Float32List.fromList(mesh.vertices),
      normals: Float32List.fromList(mesh.normals),
      seeds: Float32List.fromList(mesh.seeds),
      kinds: Uint8List.fromList([for (final k in mesh.kinds) k.index]),
      vertStart: Uint32List.fromList([for (var f = 0; f <= count; f++) f * 3]),
      verts: Uint16List.fromList([for (var i = 0; i < count * 3; i++) i]),
      triStart: Uint32List.fromList([for (var f = 0; f <= count; f++) f * 3]),
      tris: Uint16List.fromList([
        for (var f = 0; f < count; f++) ...[0, 1, 2],
      ]),
    );
  }

  /// Vertex positions, xyz.
  final Float32List positions;

  /// Unit outward normal per facet, xyz.
  final Float32List normals;

  /// Stable 0..1 value per facet; varies how it returns light.
  final Float32List seeds;

  /// [GemFacetKind] index per facet.
  final Uint8List kinds;

  /// Facet `f` uses vertices `verts[vertStart[f] .. vertStart[f + 1]]`.
  final Uint32List vertStart;

  /// Vertex indices used by each facet, facet after facet.
  final Uint16List verts;

  /// Facet `f` owns triangles `tris[triStart[f] .. triStart[f + 1]]`, as
  /// indices into its own slice of [verts].
  final Uint32List triStart;

  /// Local triangle corner indices, facet after facet.
  final Uint16List tris;

  /// Bounding radius around the model origin.
  final double radius;

  int get triangleCount => tris.length ~/ 3;

  int get vertexCount => positions.length ~/ 3;
  int get facetCount => seeds.length;

  static double _radius(Float32List p) {
    var r = 0.0;
    for (var i = 0; i < p.length; i += 3) {
      r = math.max(r, p[i] * p[i] + p[i + 1] * p[i + 1] + p[i + 2] * p[i + 2]);
    }
    return math.sqrt(r);
  }
}

/// One cut in two levels of detail.
class DiamondModel {
  const DiamondModel({
    required this.name,
    required this.detail,
    required this.coarse,
  });

  final String name;

  /// Every facet; for stones drawn large.
  final DiamondMesh detail;

  /// Sub-pixel facets and the girdle band dropped; for small or defocused
  /// stones.
  final DiamondMesh coarse;
}

/// Compact binary container for baked [DiamondModel]s (little endian):
/// `GEMS`, version, model count, then per model its name and both meshes
/// as raw typed arrays padded to 4 bytes. Decoding is a handful of views
/// and copies, so it is cheap on any device.
abstract final class DiamondModelCodec {
  static const _magic = 0x534D4547; // "GEMS"
  static const _version = 2;

  static Uint8List encode(List<DiamondModel> models) {
    final out = BytesBuilder();
    void u32(int v) => out.add(
      (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List(),
    );
    void bytes(TypedData data) {
      out.add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      final pad = (4 - data.lengthInBytes % 4) % 4;
      out.add(Uint8List(pad));
    }

    void mesh(DiamondMesh m) {
      u32(m.vertexCount);
      u32(m.facetCount);
      u32(m.verts.length);
      u32(m.tris.length);
      bytes(m.positions);
      bytes(m.normals);
      bytes(m.seeds);
      bytes(m.kinds);
      bytes(m.vertStart);
      bytes(m.verts);
      bytes(m.triStart);
      bytes(m.tris);
    }

    u32(_magic);
    u32(_version);
    u32(models.length);
    for (final model in models) {
      final name = Uint8List.fromList(utf8.encode(model.name));
      u32(name.length);
      bytes(name);
      mesh(model.detail);
      mesh(model.coarse);
    }
    return out.toBytes();
  }

  static List<DiamondModel> decode(ByteData data) {
    var at = 0;
    int u32() {
      final v = data.getUint32(at, Endian.little);
      at += 4;
      return v;
    }

    Uint8List take(int length) {
      final copy = Uint8List(length)
        ..setRange(
          0,
          length,
          data.buffer.asUint8List(data.offsetInBytes + at, length),
        );
      at += length + (4 - length % 4) % 4;
      return copy;
    }

    DiamondMesh mesh() {
      final vertices = u32(), facets = u32();
      final used = u32(), corners = u32();
      return DiamondMesh(
        positions: take(vertices * 12).buffer.asFloat32List(),
        normals: take(facets * 12).buffer.asFloat32List(),
        seeds: take(facets * 4).buffer.asFloat32List(),
        kinds: take(facets),
        vertStart: take((facets + 1) * 4).buffer.asUint32List(),
        verts: take(used * 2).buffer.asUint16List(),
        triStart: take((facets + 1) * 4).buffer.asUint32List(),
        tris: take(corners * 2).buffer.asUint16List(),
      );
    }

    if (u32() != _magic || u32() != _version) {
      throw const FormatException('Not a baked diamond model file');
    }
    final count = u32();
    return [
      for (var i = 0; i < count; i++)
        DiamondModel(
          name: utf8.decode(take(u32())),
          detail: mesh(),
          coarse: mesh(),
        ),
    ];
  }
}
