"""Bakes the LibHand scan (CC BY 3.0) into assets/models/hand.* and hand_scan_data.dart.

Inputs in ../libhand/ (relative to this folder), from
https://cdn.jsdelivr.net/gh/libhand/libhand@master/hand_model/: ogre/hand.mesh,
ogre/hand.skeleton, blender/hand_texture.png. Needs numpy, pillow, scipy, pymeshlab.
Run: python bake.py ../out && python gen_dart.py <repo>/lib/features/diamond_education/domain/hand_scan_data.dart
"""
import numpy as np, struct, sys, os, json
from PIL import Image
from scipy import ndimage
from scipy.spatial import cKDTree
from stage1 import load, M

S = 48.0                    # mm per scan unit: hand ~168 mm wrist to middle tip, breadth ~77 mm
SLIM = {1: 7.45, 2: 8.25, 3: 8.65, 4: 8.45}   # seat half widths: little US4, ring US6, middle US7, index US6.5
# Along each straightened finger from its MCP joint (mm): where a ring
# sits, just past the web (found from the width profile, where the palm
# gives way to the finger), and where the finger's ring size is measured.
SEAT_MM = {1: 33.0, 2: 33.0, 3: 31.0, 4: 37.0}
MEASURE_MM = {f: v + 5 for f, v in SEAT_MM.items()}
NBINS = 48
THUMB_SLIM = 0.84
OUT = sys.argv[1] if len(sys.argv) > 1 else '../out'
os.makedirs(OUT, exist_ok=True)

P0, UV0, F0, Fc, W0, world, names = load()
# ---- weld seam duplicates
key = np.round(P0 / 1e-5).astype(np.int64)
_, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
inv = inv.ravel()
P = P0[first] @ M.T * S
W = W0[first]
F = inv[F0][:, [0, 2, 1]]               # mirrored: flip winding back to CCW-out
WUV = UV0[F0][:, [0, 2, 1]].copy()      # wedge uvs (F,3,2); ogre v runs down like image rows
used = np.unique(F); remap = -np.ones(len(P), np.int64); remap[used] = np.arange(len(used))
P = P[used]; W = W[used]; F = remap[F]
J = {n: (M @ world[h][:3, 3]) * S for n, h in names.items()}
print('welded verts', len(P), 'faces', len(F))


def frame(u):
    d0 = np.array([0, 0, 1.0]); d = d0 - u * (d0 @ u); d /= np.linalg.norm(d)
    return d, np.cross(u, d)


def section(Q, mask, a, b, h, band=0.035):
    """Centre, half width, dorsal/palmar extents of the cut at h along a->b."""
    u = b - a; L = np.linalg.norm(u); u = u / L
    d, l = frame(u)
    t = (Q - a) @ u
    pts = Q[mask & (np.abs(t - h * L) < max(band * L, 0.9))]
    c0 = a + u * h * L
    rel = pts - c0; pl = rel @ l; pd = rel @ d
    cl = (pl.max() + pl.min()) / 2; cd = (pd.max() + pd.min()) / 2
    c = c0 + l * cl + d * cd
    hw = (pl.max() - pl.min()) / 2
    near = np.abs(pl - cl) < 0.3 * hw
    return dict(c=c, u=u, d=d, l=l, hw=hw, top=pd[near].max() - cd, bot=cd - pd[near].min())


def tip_of(Q, mask, a, b):
    u = (b - a) / np.linalg.norm(b - a)
    t = (Q[mask] - b) @ u
    return b + u * t.max()


def joints(f):
    return [J['finger%djoint%d' % (f, k)] for k in (1, 2, 3)]


def own(Q, f):
    """Vertices nearer finger f's axis than any other finger's (all for the thumb)."""
    if f == 5: return np.ones(len(Q), bool)
    ds = []
    for g in (1, 2, 3, 4):
        j1, j2, _ = joints(g); ab = j2 - j1
        t = np.clip(((Q - j1) @ ab) / (ab @ ab), 0, 1)
        ds.append(np.linalg.norm(Q - (j1 + t[:, None] * ab), axis=1))
    return np.argmin(np.stack(ds, 1), 1) == f - 1


def centreline(Q, f):
    j1, j2, j3 = joints(f)
    b1, b2, b3 = [names['finger%djoint%d' % (f, k)] for k in (1, 2, 3)]
    tip = tip_of(Q, W[:, b3] > 0.5, j2, j3)
    pts = []
    mine = own(Q, f)
    h0 = 0.45 if f != 5 else 0.3
    for (a, b, bone, hs) in [(j1, j2, b1, np.linspace(h0, 0.95, 6)), (j2, j3, b2, np.linspace(0.1, 0.9, 5)),
                             (j3, tip, b3, np.linspace(0.1, 0.75, 4))]:
        for h in hs:
            pts.append(section(Q, mine & (W[:, bone] > 0.4), a, b, h)['c'])
    return np.array(pts), tip


def nearest_on_polyline(Q, pl):
    best = np.full(len(Q), 1e18); out = np.zeros_like(Q); tt = np.zeros(len(Q))
    for i in range(len(pl) - 1):
        a, b = pl[i], pl[i + 1]; ab = b - a
        t = np.clip(((Q - a) @ ab) / (ab @ ab), 0, 1)
        q = a + t[:, None] * ab; dd = ((Q - q) ** 2).sum(1)
        m = dd < best; best[m] = dd[m]; out[m] = q[m]; tt[m] = i + t[m]
    return out, tt


def slim(Q, f, k):
    pl, tip = centreline(Q, f)
    # extend the line down into the knuckle so the slimming eases off over it
    pl = np.vstack([pl[0] - (pl[1] - pl[0]) * 3, pl])
    bones = [names['finger%djoint%d' % (f, kk)] for kk in (1, 2, 3)]
    wf = W[:, bones].sum(1)
    q, t = nearest_on_polyline(Q, pl)
    ramp = np.clip((t - 0.5) / 2.0, 0, 1)
    ramp = ramp * ramp * (3 - 2 * ramp)
    s = 1 + (k - 1) * wf * ramp
    return np.where((wf > 1e-3)[:, None], q + (Q - q) * s[:, None], Q)


# ---- straighten the four fingers: every segment along one line in the
# plane of the hand, the back of each segment facing +z (no curl, no roll)
def vertex_normals(P, F):
    n = np.cross(P[F[:, 1]] - P[F[:, 0]], P[F[:, 2]] - P[F[:, 0]])
    out = np.zeros_like(P)
    for k in range(3): np.add.at(out, F[:, k], n)
    return out / np.maximum(np.linalg.norm(out, axis=1, keepdims=True), 1e-12)


def min_rotation(a, b):
    """Rotation matrix taking unit a onto unit b."""
    v = np.cross(a, b); c = a @ b
    if np.linalg.norm(v) < 1e-9: return np.eye(3)
    k = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3) + k + k @ k / (1 + c)


N0 = vertex_normals(P, F)
moved = np.zeros_like(P); weight = np.zeros(len(P))
Z = np.array([0, 0, 1.0])
for f in (1, 2, 3, 4):
    bones = [names['finger%djoint%d' % (f, k)] for k in (1, 2, 3)]
    j = joints(f)
    tip = tip_of(P, W[:, bones[2]] > 0.5, j[1], j[2])
    pts = [j[0], j[1], j[2], tip]
    # straight along the finger's own heading seen from the back of the hand
    D = tip - j[0]; D[2] = 0; D /= np.linalg.norm(D)
    T = np.stack([D, Z, np.cross(D, Z)], 1)
    guess = Z.copy()
    new = [j[0]]
    for k in range(3):
        u = pts[k + 1] - pts[k]; L = np.linalg.norm(u); u /= L
        if k > 0:
            guess = min_rotation(prev_u, u) @ guess
        sel = W[:, bones[k]] > 0.5
        nn = N0[sel]; nn = nn[nn @ guess > 0.3]
        d = nn.mean(0) if len(nn) else guess
        d = d - u * (d @ u); d /= np.linalg.norm(d)
        guess = d; prev_u = u
        B = np.stack([u, d, np.cross(u, d)], 1)
        R = T @ B.T
        w = W[:, bones[k]]
        moved += w[:, None] * ((P - pts[k]) @ R.T + new[k])
        weight += w
        new.append(new[k] + D * L)
    for k in (1, 2, 3):
        J['finger%djoint%d' % (f, k)] = new[k - 1]
P = moved + (1 - weight)[:, None] * P
print('fingers straightened')
if os.environ.get('HAND_POSE_ONLY'):
    np.save(os.path.join(OUT, 'preview_data.npy'), dict(P=P, F=F, UV=WUV.mean(1)), allow_pickle=True); sys.exit(0)


def finger_mask(Q, f):
    bones = [names['finger%djoint%d' % (f, k)] for k in (1, 2, 3)]
    return (W[:, bones].sum(1) > 0.3) & own(Q, f)


def at_mm(f, mm):
    j1, j2, _ = joints(f)
    return j1, j2, mm / np.linalg.norm(j2 - j1)


for f, target in list(SLIM.items()) * 2:
    j1, j2, h = at_mm(f, MEASURE_MM[f])
    hw = section(P, finger_mask(P, f), j1, j2, h)['hw']
    # the knuckle end eases in, so iterate to land on the chart width
    for _ in range(3):
        cur = section(P, finger_mask(P, f), j1, j2, h)['hw']
        P = slim(P, f, target / cur)
    hw2 = section(P, finger_mask(P, f), j1, j2, h)['hw']
    print('finger', f, 'hw %.2f -> %.2f (target %.2f)' % (hw, hw2, target))
P = slim(P, 5, THUMB_SLIM)


def normals(P, F):
    n = np.cross(P[F[:, 1]] - P[F[:, 0]], P[F[:, 2]] - P[F[:, 0]])
    N = np.zeros_like(P)
    for k in range(3): np.add.at(N, F[:, k], n)
    return N / np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-12)


N = normals(P, F)
print('bounds mm', P.min(0).round(1), P.max(0).round(1))

# ---- seats, proxies
seats = {}


def axis_dist(Q, f):
    j1, j2, _ = joints(f)
    ab = j2 - j1
    t = np.clip(((Q - j1) @ ab) / (ab @ ab), 0, 1)
    return np.linalg.norm(Q - (j1 + t[:, None] * ab), axis=1)


AXD = np.stack([axis_dist(P, f) for f in (1, 2, 3, 4)], 1)
for f in SLIM:
    j1, j2, _ = joints(f)
    m1 = finger_mask(P, f)
    hw = section(P, m1, *at_mm(f, MEASURE_MM[f]))['hw']
    u = j2 - j1; u[2] = 0; u /= np.linalg.norm(u)
    c0 = section(P, m1, *at_mm(f, SEAT_MM[f]))['c']
    # this finger's own skin around the seat: nearest to its own axis
    mine = (AXD.argmin(1) == f - 1)
    t = (P - c0) @ u
    rel = P - c0 - np.outer(t, u)
    slab = mine & (np.abs(t) < 1.6) & (np.linalg.norm(rel, axis=1) < 1.7 * hw)
    # straightened fingers: the back of each faces +z, square to its axis
    d, l = frame(u)
    pl = rel[slab] @ l; pd = rel[slab] @ d
    c = c0 + l * (pl.max() + pl.min()) / 2 + d * (pd.max() + pd.min()) / 2
    rel2 = P[slab] - c; rel2 -= np.outer(rel2 @ u, u)
    ang = np.arctan2(rel2 @ l, rel2 @ d) % (2 * np.pi)
    rad = np.linalg.norm(rel2, axis=1)
    bins = (ang / (2 * np.pi) * NBINS).astype(int) % NBINS
    r = np.full(NBINS, np.nan)
    for k in range(NBINS):
        if (bins == k).any(): r[k] = rad[bins == k].max()
    ok = ~np.isnan(r); idx = np.arange(NBINS)
    r = np.interp(idx, np.concatenate([idx[ok] - NBINS, idx[ok], idx[ok] + NBINS]), np.tile(r[ok], 3))
    r = np.minimum(r, np.median(r) * 1.25)
    for _ in range(3):
        r = (np.roll(r, 1) + 2 * r + np.roll(r, -1)) / 4
    seats[f] = dict(pos=c + d * r[0], normal=d, along=u, hw=hw, centre=c, radii=r)
    print('seat', f, np.round(seats[f]['pos'], 1), 'hw %.2f r0 %.2f rmin %.2f rmax %.2f' % (hw, r[0], r.min(), r.max()))


def seg_radius(sec):
    return min(sec['hw'], sec['top'], sec['bot'])


bones = []  # (a, b, r0, r1)
seat_bone = {}
for f in (1, 2, 3, 4, 5):
    j1, j2, j3 = joints(f)
    b1, b2, b3 = [names['finger%djoint%d' % (f, k)] for k in (1, 2, 3)]
    tip = tip_of(P, W[:, b3] > 0.5, j2, j3)
    h0 = at_mm(f, SEAT_MM[f] - 6)[2] if f != 5 else 0.25
    chain = [(j1, j2, b1, h0, 0.92), (j2, j3, b2, 0.08, 0.92), (j3, tip, b3, 0.08, 0.7)]
    for i, (a, b, bone, ha, hb) in enumerate(chain):
        sa = section(P, W[:, bone] > 0.4, a, b, ha); sb = section(P, W[:, bone] > 0.4, a, b, hb)
        if i == 0 and f != 5: seat_bone[f] = len(bones)
        bones.append((sa['c'], sb['c'], seg_radius(sa), seg_radius(sb)))
palm_mask = W[:, [names['finger5joint%d' % k] for k in (1, 2, 3)]].sum(1) < 0.3
for f in (1, 2, 3, 4):
    j1 = joints(f)[0]
    a = np.array([j1[0] * 0.55, -48.0, 0]); b = np.array([j1[0], j1[1] - 6, 0])
    cs = []
    for p in (a, b):
        sel = palm_mask & (np.hypot(P[:, 0] - p[0], P[:, 1] - p[1]) < 6)
        z = P[sel, 2]; cs.append((np.array([p[0], p[1], (z.max() + z.min()) / 2]), (z.max() - z.min()) / 2))
    bones.append((cs[0][0], cs[1][0], min(cs[0][1], 9.0) * 0.85, min(cs[1][1], 9.0) * 0.85))
fade = (-82.0, float(P[:, 1].min() + 2.0))
print('fade', fade)

# ---- normal map + micro relief from the photo, in uv space
alb = np.asarray(Image.open('../libhand/hand_texture.png').convert('RGB')).astype(np.float32) / 255
TA = alb.shape[0]
TN = 1024


def raster_uv(T, vals_fn, nch):
    """Rasterises every face into a TxT uv map; vals_fn(face, bary) -> (n, nch)."""
    img = np.zeros((T, T, nch), np.float32); cov = np.zeros((T, T), bool)
    uv = WUV * T - 0.5
    for fi in range(len(F)):
        t = uv[fi]
        x0, y0 = np.floor(t.min(0)).astype(int); x1, y1 = np.ceil(t.max(0)).astype(int)
        x0 = max(x0, 0); y0 = max(y0, 0); x1 = min(x1, T - 1); y1 = min(y1, T - 1)
        if x1 < x0 or y1 < y0: continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        p = np.stack([xs.ravel(), ys.ravel()], 1).astype(np.float64)
        a, b, c = t
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-12: continue
        w0 = ((b[1] - c[1]) * (p[:, 0] - c[0]) + (c[0] - b[0]) * (p[:, 1] - c[1])) / den
        w1 = ((c[1] - a[1]) * (p[:, 0] - c[0]) + (a[0] - c[0]) * (p[:, 1] - c[1])) / den
        w2 = 1 - w0 - w1
        m = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        if not m.any(): continue
        bary = np.stack([w0[m], w1[m], w2[m]], 1)
        img[p[m, 1].astype(int), p[m, 0].astype(int)] = vals_fn(fi, bary)
        cov[p[m, 1].astype(int), p[m, 0].astype(int)] = True
    return img, cov


def dilate(img, cov):
    idx = ndimage.distance_transform_edt(~cov, return_distances=False, return_indices=True)
    return img[idx[0], idx[1]]


e1 = P[F[:, 1]] - P[F[:, 0]]; e2 = P[F[:, 2]] - P[F[:, 0]]
d1 = WUV[:, 1] - WUV[:, 0]; d2 = WUV[:, 2] - WUV[:, 0]
r = d1[:, 0] * d2[:, 1] - d2[:, 0] * d1[:, 1]
r = np.where(np.abs(r) < 1e-12, 1e-12, r)
Tg = (e1 * d2[:, 1:2] - e2 * d1[:, 1:2]) / r[:, None]
Bg = (e2 * d1[:, 0:1] - e1 * d2[:, 0:1]) / r[:, None]
Nf = N[F]


def nvals(fi, bary):
    n = bary @ Nf[fi]
    k = len(n)
    return np.concatenate([n, np.repeat(Tg[fi][None], k, 0), np.repeat(Bg[fi][None], k, 0)], 1)


print('rasterising normal map...')
nm, ncov = raster_uv(TN, nvals, 9)
nm = dilate(nm, ncov)
n = nm[..., :3]; n /= np.maximum(np.linalg.norm(n, axis=2, keepdims=True), 1e-9)
Tm = nm[..., 3:6]; Bm = nm[..., 6:9]
lum = alb @ np.array([0.3, 0.55, 0.15], np.float32)
lumN = np.asarray(Image.fromarray((lum * 255).astype(np.uint8)).resize((TN, TN), Image.LANCZOS)).astype(np.float32) / 255
hp = ndimage.gaussian_filter(lumN, 0.6) - ndimage.gaussian_filter(lumN, 4.0)
gy, gx = np.gradient(hp)
H = float(os.environ.get('HAND_RELIEF', 0.9))
du = gx * TN * H; dv = gy * TN * H


def unit(v): return v / np.maximum(np.linalg.norm(v, axis=2, keepdims=True), 1e-9)


Tn = Tm - n * (Tm * n).sum(2, keepdims=True); Bn = Bm - n * (Bm * n).sum(2, keepdims=True)
tl2 = np.maximum((Tn * Tn).sum(2, keepdims=True), 1e-9); bl2 = np.maximum((Bn * Bn).sum(2, keepdims=True), 1e-9)
grad = du[..., None] * Tn / tl2 + dv[..., None] * Bn / bl2
nb = unit(n - grad)
Image.fromarray(np.clip((nb * 0.5 + 0.5) * 255 + 0.5, 0, 255).astype(np.uint8)).save(os.path.join(OUT, 'hand_normal.png'), optimize=True)

print('albedo...')
_, acov = raster_uv(TA // 2, lambda fi, b: np.ones((len(b), 1), np.float32), 1)
acov = np.asarray(Image.fromarray(acov.astype(np.uint8) * 255).resize((TA, TA), Image.NEAREST)) > 0
acov = ndimage.binary_erosion(acov, iterations=2)
alb_d = dilate(alb, acov)
# a white patch nothing maps to: ring triangles sample it, so their vertex
# colours pass through unchanged in both G-buffer passes
far = ndimage.distance_transform_edt(~acov)
far[:64, :] = 0; far[-64:, :] = 0; far[:, :64] = 0; far[:, -64:] = 0
py_, px_ = np.unravel_index(far.argmax(), far.shape)
assert far[py_, px_] > 48, far.max()
PATCH = (float((px_ + 0.5) / TA), float((py_ + 0.5) / TA))
alb_d[py_ - 32:py_ + 32, px_ - 32:px_ + 32] = 1.0
nimg = np.asarray(Image.open(os.path.join(OUT, 'hand_normal.png'))).copy()
qy, qx = int(PATCH[1] * TN), int(PATCH[0] * TN)
nimg[qy - 16:qy + 16, qx - 16:qx + 16] = 255
Image.fromarray(nimg).save(os.path.join(OUT, 'hand_normal.png'), optimize=True)
print('patch uv', PATCH)
Image.fromarray((alb_d * 255 + 0.5).astype(np.uint8)).save(os.path.join(OUT, 'hand_albedo.jpg'), quality=90, subsampling=0, optimize=True)

# ---- ambient occlusion per welded vertex: rays against a voxel shell
print('ao...')
vox = 0.75
lo = P.min(0) - 35; dims = np.ceil((P.max(0) + 35 - lo) / vox).astype(int) + 1
grid = np.zeros(dims, bool)
for wts in [(1, 0, 0), (0, 1, 0), (0, 0, 1), (1/3, 1/3, 1/3), (.5, .5, 0), (0, .5, .5), (.5, 0, .5),
            (2/3, 1/6, 1/6), (1/6, 2/3, 1/6), (1/6, 1/6, 2/3)]:
    pts = P[F[:, 0]] * wts[0] + P[F[:, 1]] * wts[1] + P[F[:, 2]] * wts[2]
    ijk = np.floor((pts - lo) / vox).astype(int); grid[ijk[:, 0], ijk[:, 1], ijk[:, 2]] = True
grid = ndimage.binary_dilation(grid, iterations=1)
ND = 64
u1 = (np.arange(ND) + 0.5) / ND; u2 = (np.arange(ND) * 0.618034) % 1
dirs_l = np.stack([np.sqrt(u1) * np.cos(2 * np.pi * u2), np.sqrt(u1) * np.sin(2 * np.pi * u2), np.sqrt(1 - u1)], 1)
ao = np.zeros(len(P))
steps = np.arange(2.2, 30, vox * 0.9)
for c0 in range(0, len(P), 2000):
    p = P[c0:c0 + 2000]; nn = N[c0:c0 + 2000]
    t1 = np.cross(nn, np.where(np.abs(nn[:, :1]) < 0.9, [[1, 0, 0]], [[0, 1, 0]]))
    t1 /= np.linalg.norm(t1, axis=1, keepdims=True); t2 = np.cross(nn, t1)
    D = dirs_l[None, :, 0:1] * t1[:, None] + dirs_l[None, :, 1:2] * t2[:, None] + dirs_l[None, :, 2:3] * nn[:, None]
    hit = np.zeros(D.shape[:2])
    for s in steps:
        q = p[:, None] + D * s
        ijk = np.clip(np.floor((q - lo) / vox).astype(int), 0, dims - 1)
        occ = grid[ijk[..., 0], ijk[..., 1], ijk[..., 2]]
        hit = np.maximum(hit, occ * (1 - (s / 30) ** 2))
    ao[c0:c0 + 2000] = 1 - hit.mean(1)
for _ in range(2):
    acc = np.zeros(len(P)); cnt = np.zeros(len(P))
    for k in range(3):
        for k2 in range(3):
            np.add.at(acc, F[:, k], ao[F[:, k2]]); np.add.at(cnt, F[:, k], 1)
    ao = acc / cnt
print('ao range %.3f mean %.3f' % (ao.min(), ao.mean()))

# ---- decimate with texture-aware quadrics
import pymeshlab
TARGET = int(os.environ.get('HAND_FACES', 24000))
ms = pymeshlab.MeshSet()
objp = os.path.abspath(os.path.join(OUT, '_dec.obj'))
with open(objp, 'w') as fh:
    NL = chr(10)
    fh.write('mtllib _dec.mtl' + NL + 'usemtl skin' + NL)
    fh.write(''.join(('v %.5f %.5f %.5f' % tuple(p)) + NL for p in P))
    wu = WUV.reshape(-1, 2)
    fh.write(''.join(('vt %.6f %.6f' % (u, 1 - v)) + NL for u, v in wu))
    fh.write(''.join(('f %d/%d %d/%d %d/%d' % (a + 1, 3 * i + 1, b + 1, 3 * i + 2, c + 1, 3 * i + 3)) + NL for i, (a, b, c) in enumerate(F)))
open(os.path.join(OUT, '_dec.mtl'), 'w').write('newmtl skin' + chr(10) + 'map_Kd _dec.png' + chr(10))
Image.new('RGB', (4, 4)).save(os.path.join(OUT, '_dec.png'))
ms.load_new_mesh(objp)
ms.meshing_decimation_quadric_edge_collapse_with_texture(targetfacenum=TARGET, qualitythr=0.6, extratcoordw=2.0,
    preserveboundary=True, boundaryweight=2.0, optimalplacement=True, preservenormal=True, planarquadric=True)
m = ms.current_mesh()
Pd = m.vertex_matrix(); Fd = m.face_matrix(); Wd = m.wedge_tex_coord_matrix().reshape(-1, 3, 2).copy(); Wd[..., 1] = 1 - Wd[..., 1]
print('decimated', len(Pd), len(Fd))
_, nn_i = cKDTree(P).query(Pd)
aod = ao[nn_i]
keys = np.concatenate([Fd.reshape(-1, 1).astype(np.float64), np.round(Wd.reshape(-1, 2) * 8192)], 1)
uk, first2, inv2 = np.unique(keys, axis=0, return_index=True, return_inverse=True)
inv2 = inv2.ravel()
vid = Fd.reshape(-1)[first2]
outP = Pd[vid].astype(np.float32); outUV = Wd.reshape(-1, 2)[first2].astype(np.float32)
outAO = np.clip(aod[vid] * 255 + 0.5, 0, 255).astype(np.uint8)
outF = inv2.reshape(-1, 3).astype(np.uint16)
assert len(outP) < 65536
print('output verts', len(outP), 'tris', len(outF))
with open(os.path.join(OUT, 'hand.bin'), 'wb') as fh:
    fh.write(b'HND1'); fh.write(struct.pack('<II', len(outP), len(outF)))
    fh.write(outP.tobytes()); fh.write(outUV.tobytes()); fh.write(outF.tobytes()); fh.write(outAO.tobytes())
above = np.where(outP[:, 1] > fade[0] + 8)[0]
outline = outP[above[np.linspace(0, len(above) - 1, 360).astype(int)]]
fing = W[:, [names['finger%djoint%d' % (f, k)] for f in (1, 2, 3, 4) for k in (1, 2, 3)]].sum(1)
fi = np.where(fing > 0.6)[0]
focus = P[fi[np.linspace(0, len(fi) - 1, 300).astype(int)]]
np.save(os.path.join(OUT, 'preview_data.npy'), dict(P=outP, UV=outUV, F=outF, AO=outAO), allow_pickle=True)
json.dump(dict(
    seats={str(f): {k: np.asarray(v).tolist() for k, v in s.items()} for f, s in seats.items()},
    seat_bone={str(k): v for k, v in seat_bone.items()},
    bones=[[a.tolist(), b.tolist(), float(r0), float(r1)] for a, b, r0, r1 in bones],
    outline=outline.tolist(), focus=focus.tolist(), fade=list(fade), patch=list(PATCH)), open(os.path.join(OUT, 'hand_meta.json'), 'w'))
print('done')
