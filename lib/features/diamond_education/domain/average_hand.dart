import 'dart:math' as math;

/// Fingers a stone can sit on in the hand view, left to right as the back
/// of a left hand shows them.
enum HandFinger { little, ring, middle, forefinger }

/// A point on the reference hand, millimetres: x to the right, y down.
typedef HandPoint = ({double x, double y});

/// Reference artwork pixels to millimetres. Horizontal scale sets the
/// ring finger to 16.5 mm across where a ring sits (US size 6, the size
/// trade size charts compare stones on); vertical scale gives a 17.4 cm
/// hand.
const double _sx = 0.1745, _sy = 0.225;

HandPoint _p(double x, double y) => (x: x * _sx, y: y * _sy);

/// One digit, traced from the reference artwork: its two edges from base
/// to tip and the cap of points across its fingertip. The centreline runs
/// midway between the edges, so a stone placed on it sits mid-finger.
class HandDigit {
  HandDigit._(this.left, this.right, this.cap, this.seat) {
    final l = _Line(left.followedBy([tip]).toList());
    final r = _Line(right.followedBy([tip]).toList());
    const n = 80;
    for (var i = 0; i <= n; i++) {
      final a = l.at(i / n), b = r.at(i / n);
      _lefts.add(a);
      _rights.add(b);
      _axis.add((x: (a.x + b.x) / 2, y: (a.y + b.y) / 2));
    }
    _len.add(0);
    for (var i = 1; i < _axis.length; i++) {
      _len.add(_len.last + _dist(_axis[i - 1], _axis[i]));
    }
  }

  /// Edges base to tip, and the fingertip cap left to right.
  final List<HandPoint> left, right, cap;

  /// Distance along the digit from its base to where a ring sits.
  final double seat;

  final List<HandPoint> _lefts = [], _rights = [], _axis = [];
  final List<double> _len = [];

  HandPoint get tip => cap[cap.length ~/ 2];

  double get length => _len.last;

  /// Sample index nearest [d] mm along the centreline.
  int _index(double d) {
    for (var i = 1; i < _len.length; i++) {
      if (_len[i] >= d) return i;
    }
    return _len.length - 1;
  }

  /// Unit direction toward the tip at [d] mm along.
  HandPoint _dir(double d) {
    final i = _index(d.clamp(0.0, length));
    final a = _axis[math.max(0, i - 3)];
    final b = _axis[math.min(_axis.length - 1, i + 3)];
    final k = _dist(a, b);
    return (x: (b.x - a.x) / k, y: (b.y - a.y) / k);
  }

  /// Point [d] mm along the centreline from the base; negative runs on
  /// into the hand.
  HandPoint at(double d) {
    if (d <= 0) {
      final u = _dir(0);
      return (x: _axis[0].x + u.x * d, y: _axis[0].y + u.y * d);
    }
    final i = _index(d);
    final seg = _len[i] - _len[i - 1];
    final k = seg == 0 ? 0.0 : ((d - _len[i - 1]) / seg).clamp(0.0, 1.0);
    final a = _axis[i - 1], b = _axis[i];
    return (x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k);
  }

  HandPoint get seatPoint => at(seat);

  /// Radians from straight up at the seat; positive leans the tip right.
  double get lean {
    final u = _dir(seat);
    return math.atan2(u.x, -u.y);
  }

  /// Width across the digit at [d] mm along, square to its direction.
  double widthAt(double d) {
    final i = _index(d.clamp(0.0, length));
    final u = _dir(d);
    final dx = _rights[i].x - _lefts[i].x, dy = _rights[i].y - _lefts[i].y;
    return (dx * u.y - dy * u.x).abs();
  }

  /// Width where a ring sits: about the finger's diameter there.
  double get seatWidth => widthAt(seat);

  /// US ring size that fits [seatWidth] (circumference 36.5 mm at size 0,
  /// 2.55 mm per size).
  double get usRingSize => (seatWidth * math.pi - 36.5) / 2.55;

  HandDigit _shift(double dx, double dy) {
    List<HandPoint> s(List<HandPoint> p) => [
      for (final q in p) (x: q.x + dx, y: q.y + dy),
    ];
    return HandDigit._(s(left), s(right), s(cap), seat);
  }
}

/// Builds a digit from artwork pixels, widened by [widen] px a side so
/// its seat matches an average finger of that kind.
HandDigit _digit(
  List<(double, double)> left,
  List<(double, double)> cap,
  List<(double, double)> right, {
  required double widen,
  required double seat,
}) {
  final cx = (cap.first.$1 + cap.last.$1) / 2;
  final half = (cap.last.$1 - cap.first.$1) / 2;
  final k = half == 0 ? 1.0 : (half + widen) / half;
  return HandDigit._(
    [for (final (x, y) in left) _p(x - widen, y)],
    [for (final (x, y) in right) _p(x + widen, y)],
    [for (final (x, y) in cap) _p(cx + (x - cx) * k, y)],
    seat,
  );
}

/// An average adult hand, back view of a left hand, for judging how a
/// stone's size reads on a finger. Origin is the ring finger's ring seat.
///
/// Fingers follow average ring sizes where a ring sits: ring finger US 6
/// (16.5 mm across, the finger trade charts compare stones on), middle
/// finger US 7, index US 6½, little finger US 4. On the ring finger a
/// 1 ct round (6.5 mm) covers about 39% of the width, 2 ct about 49%,
/// 3 ct 57% and 5 ct 67%, as those charts give.
abstract final class AverageHand {
  /// Pixels added to each side of a finger in the artwork.
  static const _widen = (little: 8.8, ring: 0.0, middle: 5.3, index: 1.5);

  // Artwork, before centring on the ring seat.
  static final _little = _digit(
    const [
      (508, 430),
      (495, 380),
      (486, 330),
      (481, 280),
      (480, 230),
      (483, 200),
    ],
    const [(492, 184), (507, 178), (522, 182)],
    const [
      (585, 418),
      (572, 395),
      (560, 365),
      (552, 335),
      (545, 290),
      (538, 240),
      (532, 195),
    ],
    widen: _widen.little,
    seat: 11,
  );
  static final _ring = _digit(
    const [
      (600, 400),
      (598, 350),
      (597, 300),
      (598, 265),
      (603, 220),
      (610, 150),
      (615, 110),
      (622, 85),
    ],
    const [(633, 72), (648, 68), (663, 72)],
    const [
      (697, 378),
      (693, 350),
      (690, 300),
      (688, 240),
      (687, 180),
      (682, 120),
      (675, 85),
    ],
    widen: _widen.ring,
    seat: 12,
  );
  static final _middle = _digit(
    const [
      (709, 370),
      (711, 320),
      (713, 260),
      (716, 200),
      (720, 130),
      (724, 60),
      (729, 35),
    ],
    const [(740, 20), (757, 15), (774, 20)],
    const [
      (803, 365),
      (800, 320),
      (798, 260),
      (797, 200),
      (794, 130),
      (790, 60),
      (785, 35),
    ],
    widen: _widen.middle,
    seat: 12,
  );
  static final _index = _digit(
    const [
      (818, 370),
      (822, 320),
      (828, 260),
      (835, 200),
      (843, 140),
      (850, 98),
    ],
    const [(860, 78), (878, 70), (896, 75)],
    const [
      (916, 400),
      (915, 320),
      (915, 250),
      (914, 180),
      (912, 120),
      (908, 90),
    ],
    widen: _widen.index,
    seat: 12,
  );
  static final _thumb = _digit(
    const [(955, 540), (980, 505), (1005, 470), (1030, 440), (1048, 418)],
    const [(1062, 407), (1080, 404), (1093, 412), (1097, 428)],
    const [
      (965, 640),
      (995, 590),
      (1020, 550),
      (1045, 510),
      (1070, 475),
      (1090, 450),
    ],
    widen: 0,
    seat: 12,
  );

  static final HandPoint _origin = _ring.seatPoint;

  static final HandDigit little = _centred(_little);
  static final HandDigit ring = _centred(_ring);
  static final HandDigit middle = _centred(_middle);
  static final HandDigit index = _centred(_index);
  static final HandDigit thumb = _centred(_thumb);

  static HandDigit _centred(HandDigit d) => d._shift(-_origin.x, -_origin.y);

  static HandDigit of(HandFinger f) => switch (f) {
    HandFinger.little => little,
    HandFinger.ring => ring,
    HandFinger.middle => middle,
    HandFinger.forefinger => index,
  };

  /// The hand's outline, closed, wrist at the bottom.
  static final List<HandPoint> outline = () {
    List<HandPoint> art(List<(double, double)> p, [double dx = 0]) => [
      for (final (x, y) in p) _p(x + dx, y),
    ];
    const w = _widen;
    final raw = <HandPoint>[
      ...art(const [
        (505, 1080),
        (512, 1024),
        (530, 950),
        (548, 880),
        (550, 820),
        (540, 760),
        (527, 700),
        (518, 640),
        (515, 580),
        (518, 520),
        (520, 480),
      ]),
      ..._little.left,
      ..._little.cap,
      ..._little.right.reversed,
      ...art(const [
        (592, 425),
        (597, 427),
        (601, 421),
      ], (w.little - w.ring) / 2),
      ..._ring.left,
      ..._ring.cap,
      ..._ring.right.reversed,
      ...art(const [
        (701, 389),
        (705, 391),
        (708, 384),
      ], (w.ring - w.middle) / 2),
      ..._middle.left,
      ..._middle.cap,
      ..._middle.right.reversed,
      ...art(const [
        (806, 384),
        (811, 389),
        (815, 385),
      ], (w.middle - w.index) / 2),
      ..._index.left,
      ..._index.cap,
      ..._index.right.reversed,
      ...art(const [(920, 470), (926, 530), (933, 570)]),
      ..._thumb.left,
      ..._thumb.cap,
      ...art(const [
        (1090, 450),
        (1070, 475),
        (1045, 510),
        (1020, 550),
        (995, 590),
        (970, 630),
        (948, 665),
        (930, 700),
        (912, 740),
        (895, 790),
        (885, 850),
        (890, 920),
        (900, 1024),
        (903, 1080),
      ]),
    ];
    return [for (final q in raw) (x: q.x - _origin.x, y: q.y - _origin.y)];
  }();

  /// Middle fingertip to the wrist crease, and across the knuckles.
  static const double lengthCm = (790 - 15) * _sy / 10;
  static final double palmCm =
      (_index.right.first.x - _little.left.first.x) / 10;

  /// The whole hand's left and right edges, thumb included.
  static final double spanLeft = outline.map((p) => p.x).reduce(math.min);
  static final double spanRight = outline.map((p) => p.x).reduce(math.max);

  /// Extents of the four fingers around the origin, for framing.
  static final double left = little.left.map((p) => p.x).reduce(math.min) - 1;
  static final double right = index.right.map((p) => p.x).reduce(math.max) + 1;
  static final double top =
      [little, ring, middle, index].map((d) => d.tip.y).reduce(math.min) - 1;
}

double _dist(HandPoint a, HandPoint b) =>
    math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));

/// A polyline sampled by arc length, 0..1.
class _Line {
  _Line(this.points) {
    _len.add(0);
    for (var i = 1; i < points.length; i++) {
      _len.add(_len.last + _dist(points[i - 1], points[i]));
    }
  }

  final List<HandPoint> points;
  final List<double> _len = [];

  HandPoint at(double t) {
    final d = t.clamp(0.0, 1.0) * _len.last;
    for (var i = 1; i < points.length; i++) {
      if (_len[i] >= d) {
        final seg = _len[i] - _len[i - 1];
        final k = seg == 0 ? 0.0 : (d - _len[i - 1]) / seg;
        final a = points[i - 1], b = points[i];
        return (x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k);
      }
    }
    return points.last;
  }
}
