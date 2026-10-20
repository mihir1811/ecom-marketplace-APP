"""Bakes the fancy cut .glb models into the diamond simulator's assets.

    python -I tool/bake_fancy_shapes.py

Needs numpy and scipy. Reads `assets_src/fancy_shapes/*.glb` and writes

- `assets/models/fancy_shapes.json`: per shape, in slider order, the facet
  planes the ray tracer cuts the stone from (`n . p <= d`, half-width
  units, table up +y), each with its facet kind, and its kaleidoscope fold.
- `assets/shapes/fancy/<id>.svg`: the stone's top view, its crown facets
  as filled islands, like the other shape icons.

A stone is traced as one convex solid. A concave cut (a star, a lily) is
traced as one convex wedge of it between mirrors (fold k: the wedge
0 <= atan2(x, z) <= pi / k, replicated by the dihedral group of order
2k), so it is centred on its centre of symmetry. Curved girdles and
fine facets are simplified so every tier stays within the shader's
plane budget, and any two neighbours morph within it.
"""

import json
import math
import os
import struct
import sys

import numpy as np
from scipy.optimize import linprog
from scipy.spatial import ConvexHull, HalfspaceIntersection

SRC = 'assets_src/fancy_shapes'
OUT_JSON = 'assets/models/fancy_shapes.json'
OUT_SVG = 'assets/shapes/fancy'

# Slider order: neighbours alike, so each turn is a small recut. Each
# entry: id, display name (also the catalog translation key), source
# file, fold. A folded stone's neighbours share its symmetry.
SHAPES = [
    ('star_5', 'Star 5', 'STAR 5', 5),
    ('pentagon_brilliant', 'Pentagon Brilliant', 'PENTAGON BRILLIANT', 0),
    ('round_rose', 'Round Rose', 'ROUND ROSE', 0),
    ('portuguese', 'Portuguese', 'PROTUGUESE', 0),
    ('globe', 'Globe', 'GLOBE', 0),
    ('old_miner', 'Old Miner', 'OLD MINER', 0),
    ('octagonal_rose', 'Octagonal Rose', 'OCTAGONAL ROSE BRILLIANT', 0),
    ('octagon_step', 'Octagon Step', 'OCTAGON STEP', 0),
    ('flanders', 'Flanders', 'FLANDERS', 0),
    ('square', 'Square', 'SQUARE', 0),
    ('lily', 'Lily', 'LILLY', 2),
    ('cushion_modified_princess', 'Cushion Modified Princess',
     'CUHSION MODIFIED PRINCESS', 0),
    ('cushion_elongated', 'Cushion Elongated', 'CUSHION ELONGATED', 0),
    ('cushion_modified_step', 'Cushion Modified Step',
     'CUHSION MODIFIED STEP', 0),
    ('ashoka', 'Ashoka', 'ASHOKA', 0),
    ('moval_brilliant', 'Moval Brilliant', 'MOVAL BRILLIANT', 0),
    ('oval_step', 'Oval Step', 'OVAL STEP', 0),
    ('pear_step', 'Pear Step', 'PEAR STEP', 0),
    ('briolette', 'Briolette', 'BRIOLETTE', 0),
    ('flame', 'Flame', 'FLAME', 0),
    ('dutch_marquise', 'Dutch Marquise', 'DUTCH MARQUISE', 0),
    ('marquise_step', 'Marquise Step', 'MARQUISE STEP', 0),
    ('lozenge_modified', 'Lozenge Modified', 'LOZENGE MODIFIED', 0),
    ('lozenge', 'Lozenge', 'LOZENGE', 0),
    ('kite', 'Kite', 'KITE', 0),
    ('shield', 'Shield', 'SHIELD', 0),
    ('shield_modified', 'Shield Modified', 'SHIELD MODIFIED', 0),
    ('calf_head', 'Calf Head', 'CALF HEAD', 0),
    ('cadillac', 'Cadillac', 'CADILLAC', 0),
    ('baguette', 'Baguette', 'BAGUETTE', 0),
    ('tapered_baguette', 'Tapered Baguette', 'TAPERED BAGUETTE', 0),
    ('trapezoid', 'Trapezoid', 'TRAPEZOID', 0),
    ('half_moon', 'Half Moon', 'HALF MOON', 0),
    ('triangle', 'Triangle', 'TRIANGLE', 0),
    ('trilliant', 'Trilliant', 'TRILLIANT', 0),
    ('trillion_curved', 'Trillion Curved', 'TRILLION CURVED', 0),
    ('hexagon_brilliant', 'Hexagon Brilliant', 'HEXAGON BRILLIANT', 0),
    ('hexagon_step_elongated', 'Hexagon Step Elongated',
     'HEXAGON STEP ELONGATED', 0),
    ('hexagon_step', 'Hexagon Step', 'HEXAGON STEP', 0),
    ('star_6', 'Star 6', 'STAR 6', 6),
]

# Shapes centred on their centre of symmetry (the culet) rather than
# their bounding box: the five-fold pair, whose box is off centre.
CENTRE_ON_CULET = {'star_5', 'pentagon_brilliant'}

# Facet planes per tier (crown, pavilion, girdle). Any two stones then
# morph within 56 + 44 + 32 + 2 mirrors = 134 of the shader's 140 slots.
CAPS = (56, 44, 32)

TABLE, CROWN, GIRDLE, PAVILION, CULET = range(5)


# ---- glTF ---------------------------------------------------------------

def _load_glb(path):
    data = open(path, 'rb').read()
    off, doc, blob = 12, None, None
    while off < len(data):
        length, kind = struct.unpack('<II', data[off:off + 8])
        chunk = data[off + 8:off + 8 + length]
        if kind == 0x4E4F534A:
            doc = json.loads(chunk)
        elif kind == 0x004E4942:
            blob = chunk
        off += 8 + length
    return doc, blob


def _accessor(doc, blob, i):
    a = doc['accessors'][i]
    view = doc['bufferViews'][a['bufferView']]
    fmt, size = {5126: ('f', 4), 5125: ('I', 4), 5123: ('H', 2),
                 5121: ('B', 1)}[a['componentType']]
    n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a['type']]
    start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = view.get('byteStride', size * n)
    out = np.zeros((a['count'], n))
    dt = np.dtype('<' + fmt)
    for k in range(a['count']):
        out[k] = np.frombuffer(blob, dtype=dt, count=n,
                               offset=start + k * stride)
    return out


def _node_matrix(node):
    if 'matrix' in node:
        return np.array(node['matrix'], float).reshape(4, 4).T
    x, y, z, w = node.get('rotation', [0, 0, 0, 1])
    r = np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ])
    m = np.eye(4)
    m[:3, :3] = r * np.array(node.get('scale', [1, 1, 1]))
    m[:3, 3] = node.get('translation', [0, 0, 0])
    return m


def load_triangles(path):
    doc, blob = _load_glb(path)
    tris = []

    def walk(i, parent):
        node = doc['nodes'][i]
        m = parent @ _node_matrix(node)
        if 'mesh' in node:
            for prim in doc['meshes'][node['mesh']]['primitives']:
                assert prim.get('mode', 4) == 4
                pos = _accessor(doc, blob, prim['attributes']['POSITION'])
                pos = (m @ np.c_[pos, np.ones(len(pos))].T).T[:, :3]
                idx = (_accessor(doc, blob, prim['indices']).astype(int)
                       .ravel() if 'indices' in prim
                       else np.arange(len(pos)))
                tris.extend(pos[idx[k:k + 3]] for k in range(0, len(idx), 3))
        for c in node.get('children', []):
            walk(c, m)

    for i in doc['scenes'][doc.get('scene', 0)]['nodes']:
        walk(i, np.eye(4))
    return np.array(tris)


# ---- Geometry -------------------------------------------------------------

def winding(points, tris):
    """Generalised winding number of each point (1 inside, 0 outside)."""
    w = np.zeros(len(points))
    for k in range(0, len(tris), 64):
        t = tris[k:k + 64]
        a = t[None, :, 0] - points[:, None]
        b = t[None, :, 1] - points[:, None]
        c = t[None, :, 2] - points[:, None]
        la, lb, lc = (np.linalg.norm(x, axis=2) for x in (a, b, c))
        det = np.einsum('ijk,ijk->ij', a, np.cross(b, c))
        den = (la * lb * lc + np.einsum('ijk,ijk->ij', a, b) * lc +
               np.einsum('ijk,ijk->ij', b, c) * la +
               np.einsum('ijk,ijk->ij', c, a) * lb)
        w += 2 * np.arctan2(det, den).sum(1)
    return w / (4 * np.pi)


def prepare(sid, file):
    """Triangles wound outward, table up, centred, 2 wide across the
    larger plan extent."""
    t = load_triangles(os.path.join(SRC, file + '.glb'))
    if sid == 'briolette':
        # Modelled standing on its point: lay it down, point along +z.
        t = t @ np.array([[1, 0, 0], [0, 0, 1], [0, -1, 0]]).T
    n = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
    t = t[np.linalg.norm(n, axis=1) > 1e-14]
    v = t.reshape(-1, 3)
    lo, hi = v.min(0), v.max(0)
    t = (t - (lo + hi) / 2) * (2 / max(hi[0] - lo[0], hi[2] - lo[2]))
    n = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
    n /= np.linalg.norm(n, axis=1)[:, None]
    out = np.abs(winding(t.mean(1) + n * 1e-3, t)) > 0.5
    t[out] = t[out][:, ::-1]
    if sid == 'star_6':
        # An elongated hexagram: brought back to a regular one, so it
        # folds six ways (side points to 60 degrees off the long axis).
        v = t.reshape(-1, 3)
        tip = v[np.argmax(v[:, 0])]
        t[..., 2] /= abs(tip[2]) * math.tan(math.pi / 3) / tip[0]
        v = t.reshape(-1, 3)
        lo, hi = v.min(0), v.max(0)
        t = (t - (lo + hi) / 2) * (2 / max(hi[0] - lo[0], hi[2] - lo[2]))
    v = t.reshape(-1, 3)
    if sid in CENTRE_ON_CULET:
        culet = v[np.argmin(v[:, 1])]
        t = t - np.array([culet[0], 0, culet[2]])
    v = t.reshape(-1, 3)
    lo, hi = v.min(0), v.max(0)
    t = t - np.array([0, (lo[1] + hi[1]) / 2, 0])
    return t


def facets(t):
    """Coplanar, edge-connected triangles merged: [(normal, d, points)]."""
    n = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
    n /= np.linalg.norm(n, axis=1)[:, None]
    d = (n * t[:, 0]).sum(1)
    key = lambda p: tuple(np.round(p * 1e5).astype(int))
    parent = list(range(len(t)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    edges = {}
    for i, tri in enumerate(t):
        for a in range(3):
            e = tuple(sorted([key(tri[a]), key(tri[(a + 1) % 3])]))
            for j in edges.get(e, []):
                if n[i] @ n[j] > 1 - 2e-6 and abs(d[i] - d[j]) < 2e-4:
                    parent[find(i)] = find(j)
            edges.setdefault(e, []).append(i)
    groups = {}
    for i in range(len(t)):
        groups.setdefault(find(i), []).append(i)
    out = []
    for g in groups.values():
        area = np.linalg.norm(np.cross(t[g, 1] - t[g, 0], t[g, 2] - t[g, 0]),
                              axis=1)
        nn = (n[g] * area[:, None]).sum(0)
        nn /= np.linalg.norm(nn)
        pts = t[g].reshape(-1, 3)
        out.append((nn, float((pts @ nn).mean()), pts))
    return out


def wedge_planes(fold):
    """Mirror planes bounding the traced wedge of a folded stone."""
    if fold == 0:
        return []
    out = [np.array([-1.0, 0, 0, 0])]
    if fold >= 2:
        a = math.pi / fold
        out.append(np.array([math.cos(a), 0, -math.sin(a), 0]))
    return out


def kind_of(normal):
    y = normal[1]
    if y > 0.9995:
        return TABLE
    if y < -0.9995:
        return CULET
    if y >= 0.12:
        return CROWN
    if y <= -0.12:
        return PAVILION
    return GIRDLE


def tier(kind):
    return {TABLE: 0, CROWN: 0, PAVILION: 1, CULET: 1, GIRDLE: 2}[kind]


def merge_planes(planes, points, cos_tol):
    """Merges near-parallel planes; each kept as a supporting plane of
    [points] (it never cuts the stone)."""
    planes = sorted(planes, key=lambda p: -p[1])
    out = []
    for normal, area in planes:
        for q in out:
            if q[0] @ normal > cos_tol:
                w = q[1] + area
                m = q[0] * q[1] + normal * area
                q[0] = m / np.linalg.norm(m)
                q[1] = w
                break
        else:
            out.append([normal.copy(), area])
    return [(q[0], float((points @ q[0]).max())) for q in out]


def solid(planes, fixed):
    """Corners of the convex solid n . p <= d, and each plane's facet
    area (0 where it is redundant)."""
    allp = [np.r_[n, d] for n, d in planes] + list(fixed)
    hs = np.array([np.r_[p[:3], -p[3]] for p in allp])
    norm = np.linalg.norm(hs[:, :3], axis=1)
    res = linprog(np.r_[np.zeros(3), -1],
                  A_ub=np.c_[hs[:, :3], norm], b_ub=-hs[:, 3],
                  bounds=[(None, None)] * 3 + [(0, None)])
    inner = res.x[:3]
    hi = HalfspaceIntersection(hs, inner)
    pts = hi.intersections
    hull = ConvexHull(pts)
    areas = []
    for n, d in planes:
        on = pts[np.abs(pts @ n - d) < 1e-7]
        if len(on) < 3:
            areas.append(0.0)
            continue
        u = np.cross(n, [0, 1, 0] if abs(n[1]) < 0.9 else [1, 0, 0])
        u /= np.linalg.norm(u)
        w = np.cross(n, u)
        q = np.c_[on @ u, on @ w]
        try:
            areas.append(ConvexHull(q).volume)
        except Exception:
            areas.append(0.0)
    return pts, hull.volume, areas


def simplify(planes, fixed, caps):
    """Drops facets, cheapest first, until every tier fits its cap."""
    planes = list(planes)
    _, vol, areas = solid(planes, fixed)
    planes = [p for p, a in zip(planes, areas) if a > 1e-9]
    while True:
        _, vol, areas = solid(planes, fixed)
        counts = [0, 0, 0]
        for n, _ in planes:
            counts[tier(kind_of(n))] += 1
        over = {g for g in range(3) if counts[g] > caps[g]}
        if not over:
            return planes, vol
        excess = max(counts[g] - caps[g] for g in over)
        if excess > 12:
            # Far over: the smallest facets go a few at a time (curved
            # girdles and domes tessellated finely), cheaply.
            small = sorted((a, i) for i, a in enumerate(areas)
                           if tier(kind_of(planes[i][0])) in over)
            drop = {i for _, i in small[:max(1, excess // 6)]}
            planes = [p for i, p in enumerate(planes) if i not in drop]
            continue
        cands = sorted((a, i) for i, a in enumerate(areas)
                       if tier(kind_of(planes[i][0])) in over)[:10]
        best = None
        for a, i in cands:
            if a <= 1e-9:
                best = (0, i)
                break
            rest = planes[:i] + planes[i + 1:]
            try:
                _, v2, _ = solid(rest, fixed)
            except Exception:
                continue
            if best is None or v2 - vol < best[0]:
                best = (v2 - vol, i)
        planes.pop(best[1])


def wedge_clip(poly, fold):
    for p in wedge_planes(fold):
        out = []
        for i in range(len(poly)):
            a, b = poly[i], poly[(i + 1) % len(poly)]
            fa, fb = a @ p[:3], b @ p[:3]
            if fa <= 1e-12:
                out.append(a)
            if (fa < -1e-12 < fb) or (fb < -1e-12 < fa):
                out.append(a + (b - a) * (fa / (fa - fb)))
        poly = out
        if len(poly) < 3:
            return []
    return poly


def tracer_planes(sid, t, fold):
    """The planes the stone is traced from, before simplifying."""
    pts = t.reshape(-1, 3)
    if fold == 0:
        hull = ConvexHull(pts)
        raw = []
        for simplex, eq in zip(hull.simplices, hull.equations):
            a, b, c = pts[simplex]
            raw.append((eq[:3], np.linalg.norm(np.cross(b - a, c - a)) / 2))
        return merge_planes(raw, pts, math.cos(math.radians(0.35)))
    # Folded: the facets reaching into the wedge.
    raw = []
    for tri in t:
        clipped = wedge_clip(list(tri), fold)
        if len(clipped) < 3:
            continue
        c = np.array(clipped)
        area = np.linalg.norm(sum(np.cross(c[k] - c[0], c[k + 1] - c[0])
                                  for k in range(1, len(c) - 1))) / 2
        if area < 1e-9:
            continue
        n = np.cross(tri[1] - tri[0], tri[2] - tri[0])
        raw.append((n / np.linalg.norm(n), area))
    wpts = np.array([p for tri in t for p in wedge_clip(list(tri), fold)])
    return merge_planes(raw, wpts, math.cos(math.radians(0.35)))


def check_fold(sid, t, fold, planes):
    """How far the traced wedge strays from the model: the share of the
    stone's bounding box where they disagree."""
    rng = np.random.default_rng(7)
    v = t.reshape(-1, 3)
    lo, hi = v.min(0), v.max(0)
    p = lo + rng.random((30000, 3)) * (hi - lo)
    # Fold every sample into the wedge.
    q = p.copy()
    ang = np.arctan2(q[:, 0], q[:, 2])
    r = np.hypot(q[:, 0], q[:, 2])
    if fold == 1:
        q[:, 0] = np.abs(q[:, 0])
    else:
        sector = 2 * math.pi / fold
        a = np.mod(ang, sector)
        a = np.where(a > sector / 2, sector - a, a)
        q[:, 0], q[:, 2] = r * np.sin(a), r * np.cos(a)
    traced = np.ones(len(p), bool)
    for n, d in planes:
        traced &= q @ n <= d + 1e-9
    model = np.abs(winding(p, t)) > 0.5
    return float((traced != model).mean()), float(model.mean())


# ---- Icons ----------------------------------------------------------------

def _inset(poly, w):
    """Convex polygon (ccw) moved in by w along every edge."""
    out = poly
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        e = b - a
        n = np.array([e[1], -e[0]]) / np.linalg.norm(e)  # outward for ccw
        res = []
        for k in range(len(out)):
            p, q = out[k], out[(k + 1) % len(out)]
            fp, fq = (p - a) @ n + w, (q - a) @ n + w
            if fp <= 0:
                res.append(p)
            if (fp < 0 < fq) or (fq < 0 < fp):
                res.append(p + (q - p) * (fp / (fp - fq)))
        out = res
        if len(out) < 3:
            return None
    return out


def icon(t):
    """Top view: every crown facet a filled island, the gaps between
    them the facet lines. Same 14.16 box as the other shape icons."""
    size, margin, gap = 14.16, 0.62, 0.17
    scale = (size - 2 * margin) / 2
    v = t.reshape(-1, 3)
    cx = (v[:, 0].min() + v[:, 0].max()) / 2
    cz = (v[:, 2].min() + v[:, 2].max()) / 2
    ext = max(v[:, 0].max() - v[:, 0].min(), v[:, 2].max() - v[:, 2].min())
    scale = (size - 2 * margin) / ext
    paths = []
    for n, _, pts in facets(t):
        if n[1] < 0.03:
            continue
        q = np.c_[(pts[:, 0] - cx) * scale + size / 2,
                  (pts[:, 2] - cz) * scale + size / 2]
        try:
            h = ConvexHull(q)
        except Exception:
            continue
        poly = [q[i] for i in h.vertices]  # ccw in a y-down box: fine
        # Make it counter-clockwise in maths orientation for _inset.
        s = sum(poly[i][0] * poly[(i + 1) % len(poly)][1] -
                poly[(i + 1) % len(poly)][0] * poly[i][1]
                for i in range(len(poly)))
        if s < 0:
            poly = poly[::-1]
        poly = _inset(poly, gap / 2)
        if poly is None:
            continue
        paths.append('M' + ' L'.join(f'{p[0]:.3f},{p[1]:.3f}'
                                     for p in poly) + ' Z')
    return (f'<svg viewBox="0 0 {size} {size}" '
            'xmlns="http://www.w3.org/2000/svg" width="100%" height="100%">'
            f'<path fill="#000" d="{" ".join(paths)}"/></svg>\n')


# ---- Main -----------------------------------------------------------------

def bake(sid, file, fold, caps):
    t = prepare(sid, file)
    planes = tracer_planes(sid, t, fold)
    fixed = wedge_planes(fold)
    planes, _ = simplify(planes, fixed, caps)
    return t, planes


def main():
    os.makedirs(OUT_SVG, exist_ok=True)
    out = []
    counts = {}
    for sid, name, file, fold in SHAPES:
        t, planes = bake(sid, file, fold, CAPS)
        per = [0, 0, 0]
        for n, _ in planes:
            per[tier(kind_of(n))] += 1
        counts[sid] = per
        if fold:
            err, full = check_fold(sid, t, fold, planes)
            print(f'{sid:28s} fold {fold} mismatch {err:.4f} of box '
                  f'(stone {full:.3f})')
        print(f'{sid:28s} planes {len(planes):3d} {per}')
        out.append({
            'id': sid,
            'name': name,
            'fold': fold,
            'planes': [[round(float(x), 6) for x in n] +
                       [round(d, 6), kind_of(n)] for n, d in planes],
        })
        with open(os.path.join(OUT_SVG, sid + '.svg'), 'w') as f:
            f.write(icon(t))
    # Neighbours must morph within the plane budget.
    for a, b in zip(SHAPES, SHAPES[1:]):
        slots = sum(max(counts[a[0]][g], counts[b[0]][g]) for g in range(3))
        slots += len(wedge_planes(max(a[3], b[3])))
        assert slots <= 140, (a[0], b[0], slots)
    with open(OUT_JSON, 'w') as f:
        json.dump({'shapes': out}, f, separators=(',', ':'))
    print('wrote', OUT_JSON, os.path.getsize(OUT_JSON), 'bytes')


if __name__ == '__main__':
    sys.exit(main())
