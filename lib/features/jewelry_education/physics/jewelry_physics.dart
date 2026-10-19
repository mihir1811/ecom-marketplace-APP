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
/// holder acts as a viscoelastic torsion spring per body axis (stiffness
/// zero for a free swing) that also carries the piece's weight at rest,
/// and the gyroscopic term keeps tumbling honest. Dry (Coulomb) friction
/// where the piece bears on its holder takes a fixed bite out of the
/// motion every swing, so it stops dead after a few swings instead of
/// fading forever like a spring. Integrated with semi-implicit Euler at
/// the world's substep.
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
    Float64List? friction,
    Float64List? slip,
    this.preload = V3.zero,
    this.touchPoints = const [],
    this.touchNormals = const [],
  }) : _inertia = inertia,
       _inertiaInv = _invert3(inertia),
       friction = friction ?? Float64List(3),
       slip = slip ?? Float64List(3);

  /// Builds the body from point [masses] (position, grams), tuning each
  /// axis's holder to swing at [hz] with damping ratio [zeta]; 0 Hz is a
  /// free swing under gravity alone.
  ///
  /// A held axis is a viscoelastic holder (velvet foam): its hysteresis
  /// is a small dead band of [stick] radians inside which it holds still.
  /// A free axis rubs where the piece bears on its pivot, with friction
  /// coefficient [mu] at lever arm [arm] (mm: the wire's radius in a
  /// hole), under the piece's own weight. A held axis whose spring torque
  /// passes the holder's grip at [slipAngle] (rad; 0 never) slides round
  /// to a new rest, as a ring twisted hard in its slot stays turned.
  factory JRigid.tuned({
    required JNode node,
    required V3 pivot,
    required List<(V3, double)> masses,
    required V3 hz,
    required V3 zeta,
    V3 stick = V3.zero,
    double mu = 0,
    V3 arm = V3.zero,
    V3 slipAngle = V3.zero,
    List<V3> touchPoints = const [],
    List<V3> touchNormals = const [],
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
    final fr = Float64List(3), sl = Float64List(3);
    final f = [hz.x, hz.y, hz.z], z = [zeta.x, zeta.y, zeta.z];
    final arms = [arm.x, arm.y, arm.z];
    final sticks = [stick.x, stick.y, stick.z];
    final slips = [slipAngle.x, slipAngle.y, slipAngle.z];
    // Gravity's torque about the pivot at rest; a holder that grips an
    // axis carries it, so the rest pose is a true equilibrium.
    final weight = m * jGravity;
    final rest = [weight * c.z, 0.0, -weight * c.x];
    final pre = Float64List(3);
    for (var a = 0; a < 3; a++) {
      final ia = inertia[a * 4];
      final w = 2 * math.pi * f[a];
      // Gravity's own stiffness for a tip about a horizontal axis: it
      // restores a hanging piece and topples a standing one. The holder
      // makes up the difference to the asked frequency.
      final g = a == 1 ? 0.0 : -weight * c.y;
      if (f[a] > 0) {
        k[a] = math.max(0.0, ia * w * w - g);
        d[a] = 2 * z[a] * ia * w;
        pre[a] = -rest[a];
      } else {
        k[a] = 0;
        d[a] = 2 * z[a] * math.sqrt(ia * math.max(g, weight * 0.5));
      }
      fr[a] = k[a] > 0 ? k[a] * sticks[a] : mu * weight * arms[a];
      sl[a] = k[a] * slips[a];
    }
    return JRigid(
      node: node,
      pivot: pivot,
      mass: m,
      com: c,
      inertia: inertia,
      stiffness: k,
      damping: d,
      friction: fr,
      slip: sl,
      preload: V3(pre[0], pre[1], pre[2]),
      touchPoints: [for (final p in touchPoints) p - pivot],
      touchNormals: touchNormals,
    );
  }

  final JNode node;
  final V3 pivot;
  final double mass;

  /// Centre of mass relative to the pivot, body frame.
  final V3 com;
  final Float64List _inertia, _inertiaInv;
  final Float64List stiffness, damping;

  /// Dry friction torque per body axis, g·mm²/s².
  final Float64List friction;

  /// Torque per body axis past which the holder slips (0: never).
  final Float64List slip;

  /// The holder's constant torque (world) that bears the weight at rest.
  final V3 preload;

  /// Where the holder's spring is relaxed, per body axis (rad); it moves
  /// when the piece slips in its holder.
  final Float64List _rest = Float64List(3);

  /// Points on the piece (relative to the pivot) a finger can find, and
  /// the surface's outward normal there (body frame).
  final List<V3> touchPoints;
  final List<V3> touchNormals;

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
    final ph = [phi.x, phi.y, phi.z];
    for (var a = 0; a < 3; a++) {
      // The holder gives way past its grip: its spring re-seats there.
      if (slip[a] <= 0) continue;
      final over = stiffness[a] * (ph[a] - _rest[a]);
      if (over.abs() > slip[a]) {
        _rest[a] = ph[a] - over.sign * slip[a] / stiffness[a];
      }
    }
    tau =
        tau +
        preload -
        _rot(
          V3(
            stiffness[0] * (ph[0] - _rest[0]) + damping[0] * wb.x,
            stiffness[1] * (ph[1] - _rest[1]) + damping[1] * wb.y,
            stiffness[2] * (ph[2] - _rest[2]) + damping[2] * wb.z,
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
    _dryFriction(h);
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

  /// Coulomb friction at the holder: per body axis, a torque of fixed
  /// size against the spin, applied as an impulse that can stop the spin
  /// but never reverse it. Slow enough, and the piece sticks.
  void _dryFriction(double h) {
    if (friction[0] <= 0 && friction[1] <= 0 && friction[2] <= 0) return;
    _syncR();
    final wb = _rotT(_omega);
    final c = [wb.x, wb.y, wb.z];
    for (var a = 0; a < 3; a++) {
      if (friction[a] <= 0) continue;
      final dw = friction[a] * h / _inertia[a * 4];
      c[a] = c[a].abs() <= dw ? 0 : c[a] - c[a].sign * dw;
    }
    final out = _rot(V3(c[0], c[1], c[2]));
    w[0] = out.x;
    w[1] = out.y;
    w[2] = out.z;
  }

  /// World velocity of body point [local] (relative to the pivot).
  V3 velocityAt(V3 local) {
    _syncR();
    return _omega.cross(_rot(local));
  }

  /// World normal of the surface at body normal [n].
  V3 worldNormal(V3 n) {
    _syncR();
    return _rot(n);
  }

  /// Impulse [j] (g·mm/s) along world direction [dir] at world offset
  /// [r] from the pivot.
  void _impulse(V3 r, V3 dir, double j) {
    final dw = _invI(r.cross(dir) * j);
    w[0] += dw.x;
    w[1] += dw.y;
    w[2] += dw.z;
  }

  /// Impulse per unit of velocity change at offset [r] along [dir]:
  /// the inverse of the point's effective mass.
  double _response(V3 r, V3 dir) => dir.dot(_invI(r.cross(dir)).cross(r));

  /// A fingertip moving at world velocity [finger] meets body point
  /// [local], where the surface's outward world normal is [normal].
  ///
  /// The finger is far heavier than the piece, so the contact is
  /// perfectly inelastic along the normal (the point leaves at the
  /// finger's own speed into the surface), and skin friction ([mu])
  /// drags the point along with the finger's sideways motion, up to the
  /// Coulomb limit. The piece's mass and inertia tensor decide how all
  /// of that turns it.
  void touch(V3 local, V3 normal, V3 finger, {double mu = 0.6}) {
    _syncR();
    final r = _rot(local);
    var n = normal.normalized;
    // A finger cannot pull: touching a face that looks away from it, it
    // meets the edge head-on.
    if (finger.dot(n) >= -1e-9) n = -finger.normalized;
    final into = -n;
    final target = finger.dot(into);
    final kn = _response(r, into);
    if (kn < 1e-12) return;
    final jn = (target - _omega.cross(r).dot(into)) / kn;
    if (jn <= 0) return;
    final before = V3(w[0], w[1], w[2]);
    _impulse(r, into, jn);
    // Skin friction toward the finger's sideways motion.
    final slide = (finger - n * finger.dot(n)) - _tangential(r, n);
    final sl = slide.length;
    if (sl > 1e-9) {
      final t = slide * (1 / sl);
      final kt = _response(r, t);
      if (kt > 1e-12) _impulse(r, t, math.min(sl / kt, mu * jn));
    }
    // Near the pivot a fingertip's speed would mean a wild spin; a
    // fingertip slips long before that.
    final dw = V3(w[0], w[1], w[2]) - before;
    final l = dw.length;
    if (l > maxSpin) {
      final keep = before + dw * (maxSpin / l);
      w[0] = keep.x;
      w[1] = keep.y;
      w[2] = keep.z;
    }
  }

  V3 _tangential(V3 r, V3 n) {
    final v = _omega.cross(r);
    return v - n * v.dot(n);
  }

  /// A finger pushes body point [local] along [dir] at [speed], meeting
  /// the surface head-on.
  void poke(V3 local, V3 dir, double speed) {
    final d = dir.normalized;
    touch(local, -d, d * speed);
  }

  /// Fastest spin a tap can give, rad/s.
  static const maxSpin = 4.0;

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
    _rest.fillRange(0, 3, 0);
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
  JRope(
    int count, {
    this.friction = 0.5,
    this.passes = 2,
    this.pile = 25,
    this.roll = 0.4,
    this.rocking = 0,
  }) : n = count {
    _touching = Uint8List(count);
    _press = Float64List(count);
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

  /// Velvet pile's own loss, 1/s: a particle resting in it moves through
  /// soft fibres that soak up its motion, as a viscous contact.
  final double pile;

  /// Rolling resistance of the velvet, mm: a chain lying on it resists
  /// rocking about where it touches with a moment of [roll] times the
  /// force pressing it down, as the pile deforms under it.
  final double roll;
  late final Uint8List _touching;
  late final Float64List _press;

  /// For a rope that rocks as one piece on what it rests on (a bracelet
  /// draped over a rod): the share of its resting joints' friction that
  /// resists the rocking (the links over the rod only twist a little as
  /// it tilts); 0 for none. See [_rockFriction].
  final double rocking;

  final List<int> _a = [], _b = [];
  final List<double> _rest = [], _compliance = [];

  /// Whether a link may only stretch to its rest length, never be
  /// pushed shorter (chains go slack; bending limits do not).
  final List<bool> _maxOnly = [], _minOnly = [];
  final List<JCollider> colliders = [];

  /// Solids only one particle meets: the bar face a hook's wire rests
  /// against, which the parts hanging below it pass under.
  final Map<int, JCollider> own = {};

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
  /// [maxOnly] lets it go slack like a chain; [minOnly] only stops them
  /// coming closer (a bend stop: two box links meeting edge to edge,
  /// which is a hard, inelastic stop, not a spring). Returns the link's
  /// index.
  int link(
    int a,
    int b,
    double rest, {
    double compliance = 0,
    bool maxOnly = false,
    bool minOnly = false,
  }) {
    _a.add(a);
    _b.add(b);
    _rest.add(rest);
    _compliance.add(compliance);
    _maxOnly.add(maxOnly);
    _minOnly.add(minOnly);
    _lambda.add(0);
    return _a.length - 1;
  }

  // Each link's accumulated multiplier over a substep: its tension.
  final List<double> _lambda = [];
  double _h = JPhysics.substep;

  /// Link [c]'s tension over the last substep, g·mm/s² (µN).
  double tension(int c) => _lambda[c].abs() / (_h * _h);

  int get jointCount => _jj.length;

  // Joints: the bend at particle _jj between segments (_ji, _jj) and
  // (_jj, _jk), the links carrying its load, and its friction arm.
  final List<int> _ji = [], _jj = [], _jk = [], _jl1 = [], _jl2 = [];
  final List<double> _jArm = [], _jLen = [];

  int _linkOf(int a, int b) {
    for (var c = 0; c < _a.length; c++) {
      if ((_a[c] == a && _b[c] == b) || (_a[c] == b && _b[c] == a)) return c;
    }
    return -1;
  }

  /// Dry friction where segments (i, j) and (j, k) meet at j: wire rubbing
  /// on wire in a chain link, a jump ring in a bail, a hinge pin. Pass
  /// i == j for a pivot at j: a hook in its hole (j pinned), or a charm's
  /// jump ring on the link it hangs from.
  ///
  /// The links press on each other with the chain's tension T, so the
  /// joint resists bending with a friction moment μ·T·r, [arm] being
  /// μ·r: friction coefficient times the pin's (wire's) radius, mm.
  /// Unlike air drag this takes a fixed bite of every swing, so a chain
  /// settles in a few swings and stops dead, as real ones do.
  void joint(int i, int j, int k, {required double arm}) {
    final l2 = _linkOf(j, k);
    if (l2 < 0) return;
    final l1 = i == j ? l2 : _linkOf(i, j);
    if (l1 < 0) return;
    _ji.add(i);
    _jj.add(j);
    _jk.add(k);
    _jl1.add(l1);
    _jl2.add(l2);
    _jArm.add(arm);
    _jLen.add(i == j ? _rest[l2] : (_rest[l1] + _rest[l2]) / 2);
  }

  /// Joints all along particles [from]..[to] (wrapping when [closed]),
  /// with a pivot joint at a pinned end.
  void chainJoints(int from, int to, double arm, {bool closed = false}) {
    final count = to - from + 1;
    for (var s = 0; s < count; s++) {
      final j = from + s;
      final hasPrev = closed || s > 0, hasNext = closed || s < count - 1;
      final i = from + (s - 1 + count) % count;
      final k = from + (s + 1) % count;
      if (hasPrev && hasNext) {
        joint(i, j, k, arm: arm);
      } else if (invMass[j] == 0) {
        joint(j, j, hasNext ? k : i, arm: arm);
      }
    }
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
    _lambda.fillRange(0, m, 0);
    _h = h;
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
        if (_minOnly[c] && err > 0) continue;
        _lambda[c] -= err / wsum;
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
    _touching.fillRange(0, n, 0);
    _press.fillRange(0, n, 0);
    if (colliders.isNotEmpty || own.isNotEmpty) {
      for (var i = 0; i < n; i++) {
        if (invMass[i] == 0) continue;
        for (final col in colliders) {
          _contact(i, col);
        }
        final mine = own[i];
        if (mine != null) _contact(i, mine);
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
    _jointFriction(h);
    if (roll > 0) _rolling(h);
    if (rocking > 0) _rockFriction(h);
    if (pile > 0) {
      final keep = math.exp(-pile * h);
      for (var i = 0; i < n; i++) {
        if (_touching[i] == 0) continue;
        v[i * 3] *= keep;
        v[i * 3 + 1] *= keep;
        v[i * 3 + 2] *= keep;
      }
    }
    // Friction works on this substep's motion itself, not only on what
    // carries into the next: where it sticks, the step's own sag under
    // gravity is undone too, so static friction holds a piece still
    // instead of letting it creep. (Particles resting on the velvet keep
    // where their contact put them: moving them now would leave them
    // inside it.)
    for (var i = 0; i < n; i++) {
      if (invMass[i] == 0 || _touching[i] != 0) continue;
      final k = i * 3;
      x[k] = prev[k] + v[k] * h;
      x[k + 1] = prev[k + 1] + v[k + 1] * h;
      x[k + 2] = prev[k + 2] + v[k + 2] * h;
    }
  }

  /// Pushes particle [i] out of [col], and lets friction hold back the
  /// slide along it.
  void _contact(int i, JCollider col) {
    final nrm = _nrm;
    final k = i * 3;
    final d = col.distance(x[k], x[k + 1], x[k + 2], nrm);
    final pen = radius[i] - d;
    if (pen <= 0) return;
    _touching[i] = 1;
    // The push out measures the contact force over the substep.
    _press[i] += pen / (invMass[i] * _h * _h);
    x[k] += nrm[0] * pen;
    x[k + 1] += nrm[1] * pen;
    x[k + 2] += nrm[2] * pen;
    final mx = x[k] - prev[k], my = x[k + 1] - prev[k + 1];
    final mz = x[k + 2] - prev[k + 2];
    final along = mx * nrm[0] + my * nrm[1] + mz * nrm[2];
    final tx = mx - along * nrm[0],
        ty = my - along * nrm[1],
        tz = mz - along * nrm[2];
    // Coulomb friction, position-based (Müller et al. 2007): the push out
    // of the velvet measures the normal force, and the slide it allows is
    // μ times that; slower slides stick.
    final slide = math.sqrt(tx * tx + ty * ty + tz * tz);
    if (slide < 1e-12) return;
    final limit = friction * pen;
    final cut = slide <= limit * 1.5 ? 1.0 : limit / slide;
    x[k] -= tx * cut;
    x[k + 1] -= ty * cut;
    x[k + 2] -= tz * cut;
  }

  /// Coulomb friction at the joints, on velocities (the velocity pass of
  /// position-based dynamics). The bend rate at j is the second
  /// difference of the velocities, v_i + v_k − 2·v_j, less its part along
  /// the chain; whole-chain swinging and turning have none, so only
  /// bending is resisted. A momentum-conserving impulse triple (+2P at j,
  /// −P at i and k) cancels it.
  ///
  /// Solved as sequential impulses (as rigid-body engines solve contact
  /// friction): several sweeps, alternating direction, each joint's total
  /// impulse over the substep clamped to its friction moment's limit.
  /// One local pass is not enough: a joint between the support and a
  /// long hanging part must stop the whole part's swing, which only
  /// reaches it through its neighbours.
  void _jointFriction(double h) {
    final jn = _jj.length;
    if (jn == 0) return;
    if (_acc.length < jn * 3) _acc = Float64List(jn * 3);
    _acc.fillRange(0, jn * 3, 0);
    final h2 = h * h;
    if (_cap.length < jn) _cap = Float64List(jn);
    for (var c = 0; c < jn; c++) {
      final tension =
          (_lambda[_jl1[c]].abs() + _lambda[_jl2[c]].abs()) / (2 * h2);
      _cap[c] = _jArm[c] * tension / _jLen[c] * h;
    }
    for (var sweep = 0; sweep < frictionSweeps; sweep++) {
      for (var t = 0; t < jn; t++) {
        final c = sweep.isEven ? t : jn - 1 - t;
        final cap = _cap[c];
        if (cap <= 0) continue;
        final i = _ji[c], j = _jj[c], k = _jk[c];
        final wi = i == j ? 0.0 : invMass[i], wj = invMass[j], wk = invMass[k];
        // A pivot's bend is the far end's swing about j: +2P at j, −P at k.
        final denom = i == j ? wk + 2 * wj : wi + wk + 4 * wj;
        if (denom == 0) continue;
        final ii = i * 3, jj = j * 3, kk = k * 3;
        var bx = v[ii] + v[kk] - 2 * v[jj],
            by = v[ii + 1] + v[kk + 1] - 2 * v[jj + 1],
            bz = v[ii + 2] + v[kk + 2] - 2 * v[jj + 2];
        if (i == j) {
          // A pivot: the bend is the far end's own swing.
          bx = v[kk] - v[jj];
          by = v[kk + 1] - v[jj + 1];
          bz = v[kk + 2] - v[jj + 2];
        }
        var tx = x[kk] - x[ii],
            ty = x[kk + 1] - x[ii + 1],
            tz = x[kk + 2] - x[ii + 2];
        final tl = math.sqrt(tx * tx + ty * ty + tz * tz);
        if (tl > 1e-9) {
          tx /= tl;
          ty /= tl;
          tz /= tl;
          final along = bx * tx + by * ty + bz * tz;
          bx -= along * tx;
          by -= along * ty;
          bz -= along * tz;
        }
        // Total impulse so far plus what would stop the bend, clamped.
        final a = c * 3;
        var qx = _acc[a] + bx / denom,
            qy = _acc[a + 1] + by / denom,
            qz = _acc[a + 2] + bz / denom;
        final ql = math.sqrt(qx * qx + qy * qy + qz * qz);
        if (ql > cap) {
          final f = cap / ql;
          qx *= f;
          qy *= f;
          qz *= f;
        }
        final px = qx - _acc[a], py = qy - _acc[a + 1], pz = qz - _acc[a + 2];
        _acc[a] = qx;
        _acc[a + 1] = qy;
        _acc[a + 2] = qz;
        v[jj] += 2 * px * wj;
        v[jj + 1] += 2 * py * wj;
        v[jj + 2] += 2 * pz * wj;
        v[ii] -= px * wi;
        v[ii + 1] -= py * wi;
        v[ii + 2] -= pz * wi;
        v[kk] -= px * wk;
        v[kk + 1] -= py * wk;
        v[kk + 2] -= pz * wk;
      }
    }
  }

  /// Sweeps of the joint friction solve per substep.
  static const frictionSweeps = 8;
  Float64List _acc = Float64List(0), _cap = Float64List(0);

  /// Rolling resistance where the chain rests on the velvet: each segment
  /// leaving a touching particle turns about it against a moment of
  /// [roll] × the contact force, capped over the substep; slower turns
  /// stop. Without it a draped loop rocks on its contact line forever,
  /// since point masses cannot feel a pivot's friction.
  void _rolling(double h) {
    for (var c = 0; c < _jj.length; c++) {
      final j = _jj[c];
      if (_touching[j] == 0 || _press[j] <= 0) continue;
      final jj = j * 3;
      for (final nb in [_ji[c], _jk[c]]) {
        if (nb == j || invMass[nb] == 0) continue;
        final kk = nb * 3;
        var rx = v[kk] - v[jj], ry = v[kk + 1] - v[jj + 1];
        var rz = v[kk + 2] - v[jj + 2];
        var tx = x[kk] - x[jj], ty = x[kk + 1] - x[jj + 1];
        var tz = x[kk + 2] - x[jj + 2];
        final l = math.sqrt(tx * tx + ty * ty + tz * tz);
        if (l < 1e-9) continue;
        tx /= l;
        ty /= l;
        tz /= l;
        final along = rx * tx + ry * ty + rz * tz;
        rx -= along * tx;
        ry -= along * ty;
        rz -= along * tz;
        final rl = math.sqrt(rx * rx + ry * ry + rz * rz);
        if (rl < 1e-12) continue;
        final cap = roll * _press[j] / l * h * invMass[nb];
        final cut = math.min(rl, cap) / rl;
        v[kk] -= rx * cut;
        v[kk + 1] -= ry * cut;
        v[kk + 2] -= rz * cut;
      }
    }
  }

  /// A loop draped over a rod rocks on it as one rigid piece: no joint
  /// bends, so joint friction cannot see it. What stops it in reality is
  /// the links over the rod twisting against each other as the loop
  /// tilts: a friction moment, summed over the joints resting on the rod,
  /// of each joint's μ·r times its tension. This finds the rope's rigid
  /// spin about the contact patch (angular momentum over inertia) and
  /// takes that moment's worth out of it each substep, never reversing
  /// it.
  void _rockFriction(double h) {
    var cx = 0.0, cy = 0.0, cz = 0.0, total = 0.0;
    for (var i = 0; i < n; i++) {
      if (_touching[i] == 0) continue;
      final p = _press[i];
      cx += x[i * 3] * p;
      cy += x[i * 3 + 1] * p;
      cz += x[i * 3 + 2] * p;
      total += p;
    }
    if (total <= 0) return;
    cx /= total;
    cy /= total;
    cz /= total;
    var moment = 0.0;
    final h2 = h * h;
    for (var c = 0; c < _jj.length; c++) {
      if (_touching[_jj[c]] == 0) continue;
      moment +=
          _jArm[c] *
          (_lambda[_jl1[c]].abs() + _lambda[_jl2[c]].abs()) /
          (2 * h2);
    }
    moment *= rocking;
    if (moment <= 0) return;
    // Angular momentum and inertia about the contact.
    var lx = 0.0, ly = 0.0, lz = 0.0;
    final inertia = Float64List(9);
    for (var i = 0; i < n; i++) {
      if (invMass[i] == 0) continue;
      final m = 1 / invMass[i];
      final rx = x[i * 3] - cx, ry = x[i * 3 + 1] - cy, rz = x[i * 3 + 2] - cz;
      final vx = v[i * 3], vy = v[i * 3 + 1], vz = v[i * 3 + 2];
      lx += m * (ry * vz - rz * vy);
      ly += m * (rz * vx - rx * vz);
      lz += m * (rx * vy - ry * vx);
      final rr = rx * rx + ry * ry + rz * rz;
      inertia[0] += m * (rr - rx * rx);
      inertia[4] += m * (rr - ry * ry);
      inertia[8] += m * (rr - rz * rz);
      inertia[1] -= m * rx * ry;
      inertia[2] -= m * rx * rz;
      inertia[5] -= m * ry * rz;
    }
    inertia[3] = inertia[1];
    inertia[6] = inertia[2];
    inertia[7] = inertia[5];
    final inv = JRigid._invert3(inertia);
    final wx = inv[0] * lx + inv[1] * ly + inv[2] * lz;
    final wy = inv[3] * lx + inv[4] * ly + inv[5] * lz;
    final wz = inv[6] * lx + inv[7] * ly + inv[8] * lz;
    final wl = math.sqrt(wx * wx + wy * wy + wz * wz);
    if (wl < 1e-9) return;
    final ux = wx / wl, uy = wy / wl, uz = wz / wl;
    final ieff =
        ux * (inertia[0] * ux + inertia[1] * uy + inertia[2] * uz) +
        uy * (inertia[3] * ux + inertia[4] * uy + inertia[5] * uz) +
        uz * (inertia[6] * ux + inertia[7] * uy + inertia[8] * uz);
    if (ieff <= 0) return;
    final dw = math.min(wl, moment * h / ieff);
    final ax = -ux * dw, ay = -uy * dw, az = -uz * dw;
    for (var i = 0; i < n; i++) {
      if (invMass[i] == 0) continue;
      final rx = x[i * 3] - cx, ry = x[i * 3 + 1] - cy, rz = x[i * 3 + 2] - cz;
      v[i * 3] += ay * rz - az * ry;
      v[i * 3 + 1] += az * rx - ax * rz;
      v[i * 3 + 2] += ax * ry - ay * rx;
    }
  }

  /// A fingertip about [reach] mm wide, moving at world velocity
  /// [finger], meets particle [i] where its outward normal is [normal]:
  /// the contact is inelastic along the normal and skin friction ([mu])
  /// drags sideways, up to the Coulomb limit. Neighbours along the chain
  /// under the same fingertip feel it less.
  void touch(int i, V3 normal, V3 finger, {double reach = 6, double mu = 0.6}) {
    var nn = normal.normalized;
    if (finger.dot(nn) >= -1e-9) nn = -finger.normalized;
    final into = -nn;
    final target = finger.dot(into);
    final side = finger - nn * finger.dot(nn);
    final c = at(i);
    for (var j = 0; j < n; j++) {
      if (invMass[j] == 0) continue;
      final d = (at(j) - c).length;
      final f = math.exp(-(d * d) / (reach * reach));
      if (f < 0.02) continue;
      final k = j * 3;
      final vel = V3(v[k], v[k + 1], v[k + 2]);
      final dn = math.max(0.0, target - vel.dot(into)) * f;
      if (dn <= 0) continue;
      var dv = into * dn;
      final slide = side - (vel - nn * vel.dot(nn));
      final sl = slide.length;
      if (sl > 1e-9) dv = dv + slide * (math.min(sl, mu * dn) / sl);
      v[k] += dv.x;
      v[k + 1] += dv.y;
      v[k + 2] += dv.z;
    }
  }

  /// A finger pushes particle [i] along [dir] at [speed], head-on.
  void poke(int i, V3 dir, double speed, {double reach = 6}) {
    final d = dir.normalized;
    touch(i, -d, d * speed, reach: reach);
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
/// [from] to [to] (wrapping for a closed loop), or at [offsets] (mm from
/// the first link) for a patterned chain such as a figaro, local x along
/// the chain and local z toward [front]. With [segments] there is one
/// node per rope span instead, its local y pointing away from the loop's
/// centre (a tennis bracelet's stones face out).
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
    this.offsets,
    this.path,
  });

  final JRope rope;
  final List<JNode> nodes;
  final double pitch;
  final int from, to;
  final V3 Function(V3 at) front;
  final JLinkTwist twist;
  final bool closed, segments;
  final List<double>? offsets;

  /// The particles the chain runs through, when they are not simply
  /// [from]..[to] (a Y drop leaving the necklace's middle).
  final List<int>? path;

  V3 _at(int i) => rope.at(path?[i] ?? from + i);

  late final Float64List _cum = Float64List(
    (path?.length ?? to - from + 1) + 1,
  );

  /// How many links fit on a rope this long.
  static int linksFor(double length, double pitch) =>
      math.max(1, (length / pitch).floor());

  void writeNodes() {
    if (segments) {
      _writeSegments();
      return;
    }
    final count = path?.length ?? to - from + 1;
    final spans = closed ? count : count - 1;
    _cum[0] = 0;
    for (var i = 0; i < spans; i++) {
      final a = _at(i), b = _at((i + 1) % count);
      _cum[i + 1] = _cum[i] + (b - a).length;
    }
    final total = _cum[spans];
    final k = nodes.length;
    final off = offsets;
    final used = off == null ? (k - 1) * pitch : off.last;
    final start = closed ? 0.0 : (total - used) / 2;
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
      return _at(seg).lerp(_at((seg + 1) % count), f);
    }

    for (var i = 0; i < k; i++) {
      final s = start + (off == null ? i * pitch : off[i]);
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
  const JTouch.rigid(this.body, this.local, [this.localNormal])
    : rope = null,
      particle = -1;
  const JTouch.particle(this.rope, this.particle)
    : body = null,
      local = V3.zero,
      localNormal = null;

  final JRigid? body;
  final V3 local;

  /// The surface's outward normal at [local], body frame, when known.
  final V3? localNormal;
  final JRope? rope;
  final int particle;

  V3 get world => body != null ? body!.worldPoint(local) : rope!.at(particle);

  /// Outward surface normal (world), or null for a chain particle, which
  /// is round: its normal depends on where the finger meets it.
  V3? get normal {
    final n = localNormal;
    return body != null && n != null ? body!.worldNormal(n) : null;
  }

  /// Radius of what was touched: a chain particle's, or 0 for a point on
  /// a rigid piece's surface.
  double get radius => rope != null ? rope!.radius[particle] : 0;
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

  /// Whether anything still visibly moves: a rigid piece turning faster
  /// than 0.02 rad/s, a chain particle faster than 2.5 mm/s (a twentieth
  /// of a millimetre a frame). Slower than that, the viewport sleeps.
  bool get moving {
    for (final b in rigids) {
      if (b.kinetic > 4e-4) return true;
    }
    for (final r in ropes) {
      if (r.kinetic > 6.25) return true;
    }
    return false;
  }

  /// Every point a finger can find, with what it belongs to.
  Iterable<JTouch> touchables() sync* {
    for (final b in rigids) {
      final ns = b.touchNormals;
      for (var i = 0; i < b.touchPoints.length; i++) {
        yield JTouch.rigid(b, b.touchPoints[i], i < ns.length ? ns[i] : null);
      }
    }
    for (final r in ropes) {
      for (var i = 0; i < r.n; i++) {
        if (r.invMass[i] > 0) yield JTouch.particle(r, i);
      }
    }
  }

  /// A fingertip moving at world velocity [finger] meets [t], where the
  /// outward surface normal is [normal] (the touched part's own, if
  /// null): see [JRigid.touch] and [JRope.touch].
  void touch(JTouch t, V3 finger, {V3? normal}) {
    final n = normal ?? t.normal ?? -finger;
    if (t.body != null) {
      t.body!.touch(t.local, n, finger);
    } else {
      t.rope!.touch(t.particle, n, finger);
    }
  }

  /// A finger pushes [t] head-on along [dir] at [speed].
  void poke(JTouch t, V3 dir, double speed) {
    final d = dir.normalized;
    touch(t, d * speed, normal: -d);
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
