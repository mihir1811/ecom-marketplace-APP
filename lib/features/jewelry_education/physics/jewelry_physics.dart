import 'dart:math' as math;
import 'dart:typed_data';

import '../geometry/jmath.dart';

/// Something drawn that moves as one. Physics writes its world
/// transform ([xf], 3×4 row-major) every step; the renderer reads it.
class JNode {
  final Float64List xf = M34.identity();
}

/// Standard gravity in mm/s².
const jGravity = 9810.0;

// ---- Colliders ---------------------------------------------------------

/// A solid that particles cannot enter: the display velvet.
abstract class JCollider {
  /// Signed distance from (x, y, z) to the surface (negative inside),
  /// with the outward normal written to [n].
  double distance(double x, double y, double z, Float64List n);
}

/// A rounded box: [half] sizes less [radius], then grown by [radius].
class JBoxCollider implements JCollider {
  JBoxCollider(this.centre, this.half, this.radius);

  final V3 centre, half;
  final double radius;

  @override
  double distance(double x, double y, double z, Float64List n) {
    final px = x - centre.x, py = y - centre.y, pz = z - centre.z;
    final qx = px.abs() - (half.x - radius);
    final qy = py.abs() - (half.y - radius);
    final qz = pz.abs() - (half.z - radius);
    final mx = math.max(qx, 0.0),
        my = math.max(qy, 0.0),
        mz = math.max(qz, 0.0);
    final outside = math.sqrt(mx * mx + my * my + mz * mz);
    final inside = math.min(math.max(qx, math.max(qy, qz)), 0.0);
    if (outside > 1e-9) {
      n[0] = mx / outside * px.sign;
      n[1] = my / outside * py.sign;
      n[2] = mz / outside * pz.sign;
    } else {
      // Deepest axis decides the way out.
      n[0] = n[1] = n[2] = 0;
      if (qx >= qy && qx >= qz) {
        n[0] = px.sign;
      } else if (qy >= qz) {
        n[1] = py.sign;
      } else {
        n[2] = pz.sign;
      }
    }
    return outside + inside - radius;
  }
}

/// A round bar along z (a bracelet display rod), [radius] around (cx, cy).
class JRodCollider implements JCollider {
  JRodCollider(this.cx, this.cy, this.radius);

  final double cx, cy, radius;

  @override
  double distance(double x, double y, double z, Float64List n) {
    final dx = x - cx, dy = y - cy;
    final l = math.sqrt(dx * dx + dy * dy);
    if (l < 1e-9) {
      n[0] = 0;
      n[1] = 1;
    } else {
      n[0] = dx / l;
      n[1] = dy / l;
    }
    n[2] = 0;
    return l - radius;
  }
}

/// Any solid given by a distance function.
class JFieldCollider implements JCollider {
  JFieldCollider(this.field);

  final double Function(double x, double y, double z, Float64List n) field;

  @override
  double distance(double x, double y, double z, Float64List n) =>
      field(x, y, z, n);
}

// ---- Rigid body on a pivot ---------------------------------------------

/// A rigid piece held at one point: a ring in its display slot, a stud
/// through the earring bar, a hoop or bangle hanging from it.
///
/// Newton–Euler about the pivot: gravity acts at the centre of mass, the
/// holder acts as a torsion spring and damper per body axis (stiffness
/// zero for a free swing), and the gyroscopic term keeps tumbling
/// honest. Integrated with semi-implicit Euler at the world's substep.
///
/// Body frame: the piece as built (its meshes' coordinates), so the rest
/// pose is the identity and the node transform is a rotation about
/// [pivot].
class JRigid {
  JRigid({
    required this.node,
    required this.pivot,
    required this.mass,
    required this.com,
    required Float64List inertia,
    required this.stiffness,
    required this.damping,
    this.touchPoints = const [],
  }) : _inertia = inertia,
       _inertiaInv = _invert3(inertia);

  /// Builds the body from point [masses] (position, grams), tuning each
  /// axis's holder to swing at [hz] with damping ratio [zeta]; 0 Hz is a
  /// free swing under gravity alone.
  factory JRigid.tuned({
    required JNode node,
    required V3 pivot,
    required List<(V3, double)> masses,
    required V3 hz,
    required V3 zeta,
    List<V3> touchPoints = const [],
  }) {
    var m = 0.0;
    var c = V3.zero;
    for (final (p, w) in masses) {
      m += w;
      c = c + (p - pivot) * w;
    }
    c = c * (1 / m);
    final inertia = Float64List(9);
    for (final (p, w) in masses) {
      final r = p - pivot;
      final rr = r.dot(r);
      inertia[0] += w * (rr - r.x * r.x);
      inertia[4] += w * (rr - r.y * r.y);
      inertia[8] += w * (rr - r.z * r.z);
      inertia[1] -= w * r.x * r.y;
      inertia[2] -= w * r.x * r.z;
      inertia[5] -= w * r.y * r.z;
    }
    inertia[3] = inertia[1];
    inertia[6] = inertia[2];
    inertia[7] = inertia[5];
    // A floor so a near-point mass still has some rotational inertia.
    for (final i in const [0, 4, 8]) {
      inertia[i] = math.max(inertia[i], m * 0.5);
    }
    final k = Float64List(3), d = Float64List(3);
    final f = [hz.x, hz.y, hz.z], z = [zeta.x, zeta.y, zeta.z];
    for (var a = 0; a < 3; a++) {
      final ia = inertia[a * 4];
      final w = 2 * math.pi * f[a];
      // Gravity's own stiffness for a tip about a horizontal axis: it
      // restores a hanging piece and topples a standing one. The holder
      // makes up the difference to the asked frequency.
      final g = a == 1 ? 0.0 : -m * jGravity * c.y;
      if (f[a] > 0) {
        k[a] = math.max(0.0, ia * w * w - g);
        d[a] = 2 * z[a] * math.sqrt(ia * ia * w * w);
      } else {
        k[a] = 0;
        d[a] = 2 * z[a] * math.sqrt(ia * math.max(g, m * jGravity * 0.5));
      }
    }
    return JRigid(
      node: node,
      pivot: pivot,
      mass: m,
      com: c,
      inertia: inertia,
      stiffness: k,
      damping: d,
      touchPoints: [for (final p in touchPoints) p - pivot],
    );
  }

  final JNode node;
  final V3 pivot;
  final double mass;

  /// Centre of mass relative to the pivot, body frame.
  final V3 com;
  final Float64List _inertia, _inertiaInv;
  final Float64List stiffness, damping;

  /// Points on the piece (relative to the pivot) a finger can find.
  final List<V3> touchPoints;

  /// Orientation quaternion (w, x, y, z) and world angular velocity.
  final Float64List q = Float64List.fromList([1, 0, 0, 0]);
  final Float64List w = Float64List(3);
  final Float64List _r = Float64List.fromList([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  // Grab: a body point dragged toward a world target.
  V3? _grabLocal, _grabTarget;

  double get kinetic => w[0] * w[0] + w[1] * w[1] + w[2] * w[2];

  void _syncR() {
    final qw = q[0], qx = q[1], qy = q[2], qz = q[3];
    _r[0] = 1 - 2 * (qy * qy + qz * qz);
    _r[1] = 2 * (qx * qy - qz * qw);
    _r[2] = 2 * (qx * qz + qy * qw);
    _r[3] = 2 * (qx * qy + qz * qw);
    _r[4] = 1 - 2 * (qx * qx + qz * qz);
    _r[5] = 2 * (qy * qz - qx * qw);
    _r[6] = 2 * (qx * qz - qy * qw);
    _r[7] = 2 * (qy * qz + qx * qw);
    _r[8] = 1 - 2 * (qx * qx + qy * qy);
  }

  V3 _rot(V3 v) => V3(
    _r[0] * v.x + _r[1] * v.y + _r[2] * v.z,
    _r[3] * v.x + _r[4] * v.y + _r[5] * v.z,
    _r[6] * v.x + _r[7] * v.y + _r[8] * v.z,
  );

  V3 _rotT(V3 v) => V3(
    _r[0] * v.x + _r[3] * v.y + _r[6] * v.z,
    _r[1] * v.x + _r[4] * v.y + _r[7] * v.z,
    _r[2] * v.x + _r[5] * v.y + _r[8] * v.z,
  );

  static V3 _mul(Float64List m, V3 v) => V3(
    m[0] * v.x + m[1] * v.y + m[2] * v.z,
    m[3] * v.x + m[4] * v.y + m[5] * v.z,
    m[6] * v.x + m[7] * v.y + m[8] * v.z,
  );

  /// World inverse inertia applied to a world vector.
  V3 _invI(V3 v) => _rot(_mul(_inertiaInv, _rotT(v)));

  V3 get _omega => V3(w[0], w[1], w[2]);

  /// World position of body point [local] (relative to the pivot).
  V3 worldPoint(V3 local) => pivot + _rot(local);

  void step(double h) {
    _syncR();
    final om = _omega;
    // Gravity at the centre of mass.
    var tau = _rot(com).cross(V3(0, -mass * jGravity, 0));
    // The holder: a torsion spring toward rest and a damper, per body
    // axis. A rotation's axis is fixed by it, so the body-frame rotation
    // vector equals the world one.
    final s = math.sqrt(q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);
    var phi = V3.zero;
    if (s > 1e-12) {
      final angle = 2 * math.atan2(s, q[0]);
      phi = V3(q[1], q[2], q[3]) * (angle / s);
    }
    final wb = _rotT(om);
    tau =
        tau -
        _rot(
          V3(
            stiffness[0] * phi.x + damping[0] * wb.x,
            stiffness[1] * phi.y + damping[1] * wb.y,
            stiffness[2] * phi.z + damping[2] * wb.z,
          ),
        );
    final gl = _grabLocal, gt = _grabTarget;
    if (gl != null && gt != null) {
      // A stiff, well damped spring between finger and piece.
      final r = _rot(gl);
      final vel = om.cross(r);
      final kf = mass * 900.0, cf = mass * 50.0;
      final f = (gt - (pivot + r)) * kf - vel * cf;
      tau = tau + r.cross(f);
    }
    // Euler's equations in the world frame: I·ω̇ = τ − ω × (I·ω).
    final iw = _rot(_mul(_inertia, wb));
    final a = _invI(tau - om.cross(iw));
    w[0] += a.x * h;
    w[1] += a.y * h;
    w[2] += a.z * h;
    // q̇ = ½ ω ⊗ q.
    final qw = q[0], qx = q[1], qy = q[2], qz = q[3];
    final hx = 0.5 * h * w[0], hy = 0.5 * h * w[1], hz = 0.5 * h * w[2];
    q[0] = qw - hx * qx - hy * qy - hz * qz;
    q[1] = qx + hx * qw + hy * qz - hz * qy;
    q[2] = qy - hx * qz + hy * qw + hz * qx;
    q[3] = qz + hx * qy - hy * qx + hz * qw;
    final l = math.sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);
    if (!l.isFinite || l < 1e-9) {
      reset();
      return;
    }
    for (var i = 0; i < 4; i++) {
      q[i] /= l;
    }
  }

  void writeNode() {
    _syncR();
    final m = node.xf;
    final t = pivot - _rot(pivot);
    m[0] = _r[0];
    m[1] = _r[1];
    m[2] = _r[2];
    m[3] = t.x;
    m[4] = _r[3];
    m[5] = _r[4];
    m[6] = _r[5];
    m[7] = t.y;
    m[8] = _r[6];
    m[9] = _r[7];
    m[10] = _r[8];
    m[11] = t.z;
  }

  /// A finger pushes body point [local] so that it moves at [speed]
  /// along [dir]: the finger is far heavier than the piece, so the
  /// contact point takes the finger's speed, and the piece's mass and
  /// inertia decide how it turns.
  void poke(V3 local, V3 dir, double speed) {
    _syncR();
    final r = _rot(local);
    final n = dir.normalized;
    final rn = r.cross(n);
    final k = n.dot(_invI(rn).cross(r));
    if (k < 1e-12) return;
    final current = _omega.cross(r).dot(n);
    final j = (speed - current) / k;
    if (j <= 0) return;
    var dw = _invI(rn * j);
    // Near the pivot a fingertip's speed would mean a wild spin; a
    // fingertip slips long before that.
    final l = dw.length;
    if (l > maxSpin) dw = dw * (maxSpin / l);
    w[0] += dw.x;
    w[1] += dw.y;
    w[2] += dw.z;
  }

  /// Fastest spin a tap can give, rad/s.
  static const maxSpin = 5.0;

  void grab(V3 local, V3 target) {
    _grabLocal = local;
    _grabTarget = target;
  }

  void moveGrab(V3 target) => _grabTarget = target;

  void release() {
    _grabLocal = null;
    _grabTarget = null;
  }

  void reset() {
    q
      ..[0] = 1
      ..[1] = 0
      ..[2] = 0
      ..[3] = 0;
    w.fillRange(0, 3, 0);
  }

  static Float64List _invert3(Float64List m) {
    final a = m[0], b = m[1], c = m[2], d = m[3], e = m[4], f = m[5];
    final g = m[6], h = m[7], i = m[8];
    final A = e * i - f * h, B = -(d * i - f * g), C = d * h - e * g;
    final det = a * A + b * B + c * C;
    final s = det.abs() < 1e-18 ? 0.0 : 1 / det;
    return Float64List.fromList([
      A * s,
      -(b * i - c * h) * s,
      (b * f - c * e) * s,
      B * s,
      (a * i - c * g) * s,
      -(a * f - c * d) * s,
      C * s,
      -(a * h - b * g) * s,
      (a * e - b * d) * s,
    ]);
  }
}

// ---- Particle rope (XPBD) ----------------------------------------------

/// A chain, a pendant on it, or a hanging drop, as point masses joined by
/// inextensible links: extended position-based dynamics (Macklin et al.,
/// "Small Steps in Physics Simulation", 2019), one constraint pass per
/// small substep, which keeps a pendulum's period and energy true.
///
/// Particles are pinned (zero inverse mass), free, or grabbed by a
/// finger. They collide with the display velvet, with friction.
class JRope {
  JRope(int count, {this.friction = 0.5, this.passes = 2}) : n = count {
    x = Float64List(count * 3);
    prev = Float64List(count * 3);
    v = Float64List(count * 3);
    invMass = Float64List(count);
    radius = Float64List(count);
    drag = Float64List(count);
  }

  final int n;
  late final Float64List x, prev, v, invMass, radius, drag;

  /// Coefficient of friction against the velvet.
  final double friction;

  /// Constraint sweeps per substep; short ropes with a heavy end need
  /// more to stay inextensible.
  final int passes;

  final List<int> _a = [], _b = [];
  final List<double> _rest = [], _compliance = [];

  /// Whether a link may only stretch to its rest length, never be
  /// pushed shorter (chains go slack; bending limits do not).
  final List<bool> _maxOnly = [];
  final List<JCollider> colliders = [];

  int? _grabbed;
  V3? _grabTarget;

  V3 at(int i) => V3(x[i * 3], x[i * 3 + 1], x[i * 3 + 2]);

  void place(
    int i,
    V3 p, {
    double mass = 0,
    double r = 0.5,
    double drag = 1.0,
  }) {
    x[i * 3] = prev[i * 3] = p.x;
    x[i * 3 + 1] = prev[i * 3 + 1] = p.y;
    x[i * 3 + 2] = prev[i * 3 + 2] = p.z;
    invMass[i] = mass > 0 ? 1 / mass : 0;
    radius[i] = r;
    this.drag[i] = drag;
  }

  /// Joins [a] and [b] at [rest] mm. [compliance] (mm/N) softens it;
  /// [maxOnly] lets it go slack like a chain.
  void link(
    int a,
    int b,
    double rest, {
    double compliance = 0,
    bool maxOnly = false,
  }) {
    _a.add(a);
    _b.add(b);
    _rest.add(rest);
    _compliance.add(compliance);
    _maxOnly.add(maxOnly);
  }

  /// Fastest particle's squared speed, (mm/s)².
  double get kinetic {
    var e = 0.0;
    for (var i = 0; i < n; i++) {
      if (invMass[i] == 0) continue;
      e = math.max(
        e,
        v[i * 3] * v[i * 3] +
            v[i * 3 + 1] * v[i * 3 + 1] +
            v[i * 3 + 2] * v[i * 3 + 2],
      );
    }
    return e;
  }

  final Float64List _nrm = Float64List(3);

  void step(double h, {double extraDrag = 0}) {
    for (var i = 0; i < n; i++) {
      final k = i * 3;
      prev[k] = x[k];
      prev[k + 1] = x[k + 1];
      prev[k + 2] = x[k + 2];
      if (invMass[i] == 0) continue;
      v[k + 1] -= jGravity * h;
      final damp = math.exp(-(drag[i] + extraDrag) * h);
      v[k] *= damp;
      v[k + 1] *= damp;
      v[k + 2] *= damp;
      x[k] += v[k] * h;
      x[k + 1] += v[k + 1] * h;
      x[k + 2] += v[k + 2] * h;
    }
    final g = _grabbed, gt = _grabTarget;
    if (g != null && gt != null && invMass[g] > 0) {
      // The finger leads; the chain follows through its links.
      final k = g * 3;
      x[k] += (gt.x - x[k]) * 0.3;
      x[k + 1] += (gt.y - x[k + 1]) * 0.3;
      x[k + 2] += (gt.z - x[k + 2]) * 0.3;
    }
    // Two sweeps in opposite orders so a heavy pendant does not stretch
    // the light chain above it.
    final m = _a.length;
    final h2 = h * h;
    for (var pass = 0; pass < passes; pass++) {
      for (var j = 0; j < m; j++) {
        final c = pass.isEven ? j : m - 1 - j;
        final a = _a[c], b = _b[c];
        final wa = invMass[a], wb = invMass[b];
        final wsum = wa + wb + _compliance[c] / h2;
        if (wsum == 0) continue;
        final ka = a * 3, kb = b * 3;
        final dx = x[ka] - x[kb],
            dy = x[ka + 1] - x[kb + 1],
            dz = x[ka + 2] - x[kb + 2];
        final l = math.sqrt(dx * dx + dy * dy + dz * dz);
        if (l < 1e-9) continue;
        final err = l - _rest[c];
        if (_maxOnly[c] && err < 0) continue;
        final s = -err / wsum / l;
        x[ka] += wa * s * dx;
        x[ka + 1] += wa * s * dy;
        x[ka + 2] += wa * s * dz;
        x[kb] -= wb * s * dx;
        x[kb + 1] -= wb * s * dy;
        x[kb + 2] -= wb * s * dz;
      }
    }
    // Contacts: push out of the velvet, and let friction hold back the
    // slide along it.
    if (colliders.isNotEmpty) {
      final nrm = _nrm;
      for (var i = 0; i < n; i++) {
        if (invMass[i] == 0) continue;
        final k = i * 3;
        for (final col in colliders) {
          final d = col.distance(x[k], x[k + 1], x[k + 2], nrm);
          final pen = radius[i] - d;
          if (pen <= 0) continue;
          x[k] += nrm[0] * pen;
          x[k + 1] += nrm[1] * pen;
          x[k + 2] += nrm[2] * pen;
          final mx = x[k] - prev[k],
              my = x[k + 1] - prev[k + 1],
              mz = x[k + 2] - prev[k + 2];
          final along = mx * nrm[0] + my * nrm[1] + mz * nrm[2];
          final tx = mx - along * nrm[0],
              ty = my - along * nrm[1],
              tz = mz - along * nrm[2];
          // Coulomb friction, position-based (Müller et al. 2007): the
          // push out of the velvet measures the normal force, and the
          // slide it allows is μ times that; slower slides stick.
          final slide = math.sqrt(tx * tx + ty * ty + tz * tz);
          if (slide < 1e-12) continue;
          final limit = friction * pen;
          final cut = slide <= limit * 1.5 ? 1.0 : limit / slide;
          x[k] -= tx * cut;
          x[k + 1] -= ty * cut;
          x[k + 2] -= tz * cut;
        }
      }
    }
    final inv = 1 / h;
    for (var i = 0; i < n; i++) {
      final k = i * 3;
      if (invMass[i] == 0) {
        v[k] = v[k + 1] = v[k + 2] = 0;
        continue;
      }
      v[k] = (x[k] - prev[k]) * inv;
      v[k + 1] = (x[k + 1] - prev[k + 1]) * inv;
      v[k + 2] = (x[k + 2] - prev[k + 2]) * inv;
    }
  }

  /// A fingertip about [reach] mm wide meets particle [i] moving at
  /// [speed] along [dir]; its neighbours along the chain feel it less.
  void poke(int i, V3 dir, double speed, {double reach = 6}) {
    final n0 = dir.normalized;
    final c = at(i);
    for (var j = 0; j < n; j++) {
      if (invMass[j] == 0) continue;
      final d = (at(j) - c).length;
      final f = math.exp(-(d * d) / (reach * reach));
      if (f < 0.02) continue;
      final k = j * 3;
      final cur = v[k] * n0.x + v[k + 1] * n0.y + v[k + 2] * n0.z;
      final dv = math.max(0.0, speed - cur) * f;
      v[k] += n0.x * dv;
      v[k + 1] += n0.y * dv;
      v[k + 2] += n0.z * dv;
    }
  }

  void grab(int i, V3 target) {
    _grabbed = i;
    _grabTarget = target;
  }

  void moveGrab(V3 target) => _grabTarget = target;

  void release() {
    _grabbed = null;
    _grabTarget = null;
  }
}

/// A rigid piece hanging from a rope: a pendant or an earring drop. Its
/// bail rides on particle [bail], its centre of mass is particle [com]
/// (joined to the bail at the piece's own bail-to-centre distance), so
/// it swings and twists as a real pendulum; its face turns to [front].
class JRopeFrame {
  JRopeFrame({
    required this.node,
    required this.rope,
    required this.bail,
    required this.com,
    required this.front,
  });

  final JNode node;
  final JRope rope;
  final int bail, com;

  /// Which way the face looks at a point (the chest's normal, or
  /// forward off the earring bar).
  final V3 Function(V3 at) front;

  void writeNode() {
    final b = rope.at(bail), c = rope.at(com);
    final xf = Xf.lookUp(b - c, front(c), b);
    xf.writeTo(node.xf);
  }
}

/// How chain links turn along a rope.
enum JLinkTwist {
  /// Each link at right angles to the last (cable, box).
  alternate,

  /// Every link the same way up (curb lies flat, rope is a twisted cord).
  none,
}

/// Lays chain links (or bracelet segments) along a rope each step.
///
/// Links sit every [pitch] mm along the rope's polyline from particle
/// [from] to [to] (wrapping for a closed loop), local x along the chain
/// and local z toward [front]. With [segments] there is one node per
/// rope span instead, its local y pointing away from the loop's centre
/// (a tennis bracelet's stones face out).
class JChainSkin {
  JChainSkin({
    required this.rope,
    required this.nodes,
    required this.pitch,
    required this.from,
    required this.to,
    required this.front,
    this.twist = JLinkTwist.alternate,
    this.closed = false,
    this.segments = false,
  });

  final JRope rope;
  final List<JNode> nodes;
  final double pitch;
  final int from, to;
  final V3 Function(V3 at) front;
  final JLinkTwist twist;
  final bool closed, segments;

  late final Float64List _cum = Float64List((to - from + 2));

  /// How many links fit on a rope this long.
  static int linksFor(double length, double pitch) =>
      math.max(1, (length / pitch).floor());

  void writeNodes() {
    if (segments) {
      _writeSegments();
      return;
    }
    final count = to - from + 1;
    final spans = closed ? count : count - 1;
    _cum[0] = 0;
    for (var i = 0; i < spans; i++) {
      final a = rope.at(from + i), b = rope.at(from + (i + 1) % count);
      _cum[i + 1] = _cum[i] + (b - a).length;
    }
    final total = _cum[spans];
    final k = nodes.length;
    final start = closed ? 0.0 : (total - (k - 1) * pitch) / 2;
    var seg = 0;
    V3 pointAt(double s) {
      if (closed) s = (s % total + total) % total;
      s = s.clamp(0.0, total);
      while (seg > 0 && _cum[seg] > s) {
        seg--;
      }
      while (seg < spans - 1 && _cum[seg + 1] < s) {
        seg++;
      }
      final len = _cum[seg + 1] - _cum[seg];
      final f = len <= 0 ? 0.0 : (s - _cum[seg]) / len;
      return rope.at(from + seg).lerp(rope.at(from + (seg + 1) % count), f);
    }

    for (var i = 0; i < k; i++) {
      final s = start + i * pitch;
      final p = pointAt(s);
      final t =
          (pointAt(s + pitch * 0.5) - pointAt(s - pitch * 0.5)).normalized;
      final f = front(p);
      var zAxis = f - t * f.dot(t);
      zAxis = zAxis.length < 1e-6 ? t.anyPerpendicular : zAxis.normalized;
      if (twist == JLinkTwist.alternate && i.isOdd) zAxis = t.cross(zAxis);
      final yAxis = zAxis.cross(t);
      M34.setAxes(nodes[i].xf, t, yAxis, zAxis, p);
    }
  }

  void _writeSegments() {
    final count = to - from + 1;
    var c = V3.zero;
    for (var i = 0; i < count; i++) {
      c = c + rope.at(from + i);
    }
    c = c * (1 / count);
    for (var i = 0; i < nodes.length; i++) {
      final a = rope.at(from + i), b = rope.at(from + (i + 1) % count);
      final t = (b - a).normalized;
      final mid = (a + b) * 0.5;
      var out = mid - c;
      out = out - t * out.dot(t);
      out = out.length < 1e-6 ? t.anyPerpendicular : out.normalized;
      M34.setAxes(nodes[i].xf, t, out, t.cross(out), mid);
    }
  }
}

// ---- World -------------------------------------------------------------

/// What a finger found: a rigid body point or a rope particle.
class JTouch {
  const JTouch.rigid(this.body, this.local) : rope = null, particle = -1;
  const JTouch.particle(this.rope, this.particle)
    : body = null,
      local = V3.zero;

  final JRigid? body;
  final V3 local;
  final JRope? rope;
  final int particle;

  V3 get world => body != null ? body!.worldPoint(local) : rope!.at(particle);
}

/// Steps every body at a fixed small substep, so motion is the same at
/// any frame rate, and writes the nodes the renderer draws.
class JPhysics {
  JPhysics({
    this.rigids = const [],
    this.ropes = const [],
    this.frames = const [],
    this.skins = const [],
  });

  final List<JRigid> rigids;
  final List<JRope> ropes;
  final List<JRopeFrame> frames;
  final List<JChainSkin> skins;

  static const substep = 1 / 480;
  double _carry = 0;

  bool get isStatic => rigids.isEmpty && ropes.isEmpty;

  /// Advances by [dt] seconds (at most a twentieth, so a stalled frame
  /// does not explode the simulation).
  void advance(double dt) {
    _carry += dt.clamp(0.0, 0.05);
    var steps = 0;
    while (_carry >= substep && steps < 32) {
      _step(substep);
      _carry -= substep;
      steps++;
    }
    if (steps == 32) _carry = 0;
    writeNodes();
  }

  void _step(double h, {double extraDrag = 0}) {
    for (final b in rigids) {
      b.step(h);
    }
    for (final r in ropes) {
      r.step(h, extraDrag: extraDrag);
    }
  }

  /// Lets everything hang at rest before the first frame.
  void settle({double seconds = 2.5}) {
    final n = (seconds / substep).round();
    for (var i = 0; i < n; i++) {
      // Thick air early on, normal air for the last half second.
      _step(substep, extraDrag: i < n - 240 ? 6 : 0);
    }
    for (final b in rigids) {
      b.reset();
    }
    writeNodes();
  }

  void writeNodes() {
    for (final b in rigids) {
      b.writeNode();
    }
    for (final f in frames) {
      f.writeNode();
    }
    for (final s in skins) {
      s.writeNodes();
    }
  }

  /// Whether anything still visibly moves.
  bool get moving {
    for (final b in rigids) {
      if (b.kinetic > 4e-4) return true;
    }
    for (final r in ropes) {
      if (r.kinetic > 2.0) return true;
    }
    return false;
  }

  /// Every point a finger can find, with what it belongs to.
  Iterable<JTouch> touchables() sync* {
    for (final b in rigids) {
      for (final p in b.touchPoints) {
        yield JTouch.rigid(b, p);
      }
    }
    for (final r in ropes) {
      for (var i = 0; i < r.n; i++) {
        if (r.invMass[i] > 0) yield JTouch.particle(r, i);
      }
    }
  }

  void poke(JTouch t, V3 dir, double speed) {
    if (t.body != null) {
      t.body!.poke(t.local, dir, speed);
    } else {
      t.rope!.poke(t.particle, dir, speed);
    }
  }

  void grab(JTouch t, V3 target) {
    if (t.body != null) {
      t.body!.grab(t.local, target);
    } else {
      t.rope!.grab(t.particle, target);
    }
  }

  void moveGrab(JTouch t, V3 target) {
    if (t.body != null) {
      t.body!.moveGrab(target);
    } else {
      t.rope!.moveGrab(target);
    }
  }

  void release() {
    for (final b in rigids) {
      b.release();
    }
    for (final r in ropes) {
      r.release();
    }
  }
}
