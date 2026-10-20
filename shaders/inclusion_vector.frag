#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// Clarity characteristics for the simulator's line drawing (vector view),
// drawn per pixel as the solid, lit objects they are rather than plot
// symbols. Each pixel casts its view ray through every inclusion's
// bounding sphere and shades what it meets in model space, so every one
// turns, foreshortens and catches the light with the stone.
//
// Lighting mimics darkfield illumination under a gemmological microscope,
// the way graders and photomicrographs show inclusions: the stone's body
// stays dark and inclusions glow where they scatter or mirror light from
// a ring of lamps around and above them.
//
// Looks, after GIA's clarity characteristic definitions and published
// photomicrographs:
// - pinpoint: a minute bright crystal; cloud: a hazy drift of countless
//   pinpoints; needle: thin, bright, often parallel rods.
// - crystal: a transparent mineral with relief at its faces (most
//   colourless, some garnet orange or chrome diopside green); carbon: a
//   black graphite platelet with a metallic sheen, or a sulphide crystal
//   with its rosette of tension cracks.
// - feather: a translucent white break, barbed like a plume, stepped
//   where it cleaves, mirror bright where light meets it past diamond's
//   critical angle and iridescent where the air film thins; open ones are
//   cut off at the facet they reach, with the break bright along it;
//   filled ones nearly vanish but flash orange, pink and blue.
// - knot: a diamond crystal polished through at the surface, with drag
//   lines; cavity: an angular, frosted hole; chip: a shallow shell-like
//   scoop at the girdle edge; bruise: a crushed point with root-like
//   cracks; bearding: hair-fine cracks in from the girdle; indented
//   natural: the rough's frosted skin with its triangular etch pits.
// - graining: faint reflective growth planes; twinning wisp: a twisted
//   ribbon of pinpoints; etch channel: a hollow, kinked, stained tunnel;
//   laser drill hole: a straight, even, frosted tunnel to a bleached
//   crystal.
//
// Inclusions arrive sorted far to near and are composited over each
// other in that order; output is premultiplied.

const int MAX_INCL = 20;

uniform vec4 uView;   // centre x, centre y, px per model unit, eye distance
uniform vec4 uR0;     // model → world rotation rows
uniform vec4 uR1;
uniform vec4 uR2;
uniform vec4 uMisc;   // count, time, opacity, model units per px
uniform vec4 uIncl[MAX_INCL * 3];  // centre + size; axis + kind.seed; surface plane (n, d), n = 0 when enclosed

out vec4 fragColor;

// Lamp directions, world space (unit length).
const vec3 KEY_W = vec3(-0.5499, 0.6198, 0.5599);
const vec3 FILL_W = vec3(0.7868, 0.1210, 0.6052);
const vec3 RIM_W = vec3(0.1506, -0.3515, -0.9240);

vec3 toModel(vec3 w) {
  return w.x * uR0.xyz + w.y * uR1.xyz + w.z * uR2.xyz;
}

vec3 toWorld(vec3 m) {
  return vec3(dot(uR0.xyz, m), dot(uR1.xyz, m), dot(uR2.xyz, m));
}

float hash13(vec3 p) {
  p = fract(p * 0.1031);
  p += dot(p, p.zyx + 31.32);
  return fract((p.x + p.y) * p.z);
}

vec3 hash33(vec3 p) {
  p = fract(p * vec3(0.1031, 0.1030, 0.0973));
  p += dot(p, p.yxz + 33.33);
  return fract((p.xxy + p.yxx) * p.zyx);
}

float noise3(vec3 x) {
  vec3 i = floor(x);
  vec3 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);
  return mix(mix(mix(hash13(i), hash13(i + vec3(1.0, 0.0, 0.0)), f.x),
                 mix(hash13(i + vec3(0.0, 1.0, 0.0)),
                     hash13(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
             mix(mix(hash13(i + vec3(0.0, 0.0, 1.0)),
                     hash13(i + vec3(1.0, 0.0, 1.0)), f.x),
                 mix(hash13(i + vec3(0.0, 1.0, 1.0)),
                     hash13(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

float sq(float x) {
  return x * x;
}

float fbm(vec3 p) {
  float s = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    s += a * noise3(p);
    p = p * 2.03 + vec3(17.1, 9.2, 4.7);
    a *= 0.5;
  }
  return s / 0.9375;
}

// Two unit vectors square to n and each other, turned by angle a.
void frame(vec3 n, float a, out vec3 u, out vec3 v) {
  vec3 u0 = normalize(cross(n, abs(n.y) < 0.9 ? vec3(0.0, 1.0, 0.0)
                                              : vec3(1.0, 0.0, 0.0)));
  vec3 v0 = cross(n, u0);
  u = u0 * cos(a) + v0 * sin(a);
  v = v0 * cos(a) - u0 * sin(a);
}

// Darkfield lamps along world direction w: a dim, cool surround, a ring
// of lamps round the horizon and two brighter ones above.
vec3 env(vec3 w) {
  float up = clamp(w.y * 0.5 + 0.5, 0.0, 1.0);
  vec3 c = vec3(0.035, 0.04, 0.05) + vec3(0.22, 0.23, 0.26) * up * up;
  c += vec3(0.5, 0.5, 0.52) * exp(-sq(w.y / 0.22));
  c += vec3(1.9, 1.85, 1.7) * pow(max(dot(w, KEY_W), 0.0), 28.0);
  c += vec3(0.75, 0.85, 1.05) * pow(max(dot(w, FILL_W), 0.0), 14.0);
  return c;
}

// Light a rough (frosted) surface scatters toward the eye.
float frosty(vec3 n, vec3 lk, vec3 lf, vec3 lr) {
  float k = max(dot(n, lk), 0.0);
  float f = max(dot(n, lf), 0.0);
  float r = max(dot(n, lr), 0.0);
  return 0.1 + 0.85 * k + 0.35 * f + 0.25 * r;
}

// A sharp highlight of the lamps mirrored by normal n.
vec3 gloss(vec3 d, vec3 n, float rough) {
  vec3 r = reflect(d, n);
  return env(toWorld(r)) * rough;
}

vec4 over(vec4 front, vec4 back) {
  return front + back * (1.0 - front.a);
}

float reachOf(float kind) {
  float r = 1.8;
  if (kind < 18.5) r = 1.1;
  if (kind < 17.5) r = 1.25;
  if (kind < 16.5) r = 1.2;
  if (kind < 14.5) r = 1.35;
  if (kind < 13.5) r = 1.5;
  if (kind < 12.5) r = 1.6;
  if (kind < 11.5) r = 1.35;
  if (kind < 9.5) r = 1.8;
  if (kind < 8.5) r = 1.25;
  if (kind < 5.5) r = 2.5;
  if (kind < 4.5) r = 1.8;
  if (kind < 3.5) r = 1.15;
  if (kind < 2.5) r = 1.05;
  if (kind < 1.5) r = 4.0;
  return r;
}

// ---------------------------------------------------------------------
// Convex shapes. Each returns entry and exit distances (x > y on a miss),
// the outward normals there, and how far behind the entry the next face
// lies (small near an edge), for outlines.

// Octahedron with its corners cut by a cube, in a frame scaled by k.
vec2 octa(vec3 o, vec3 d, float cut, out vec3 nIn, out vec3 nOut,
          out float edge, out float edgeOut) {
  float tN = -1e9;
  float t2 = -1e9;
  float tF = 1e9;
  float tF2 = 1e9;
  nIn = vec3(0.0, 1.0, 0.0);
  nOut = nIn;
  edge = 0.0;
  edgeOut = 0.0;
  for (int k = 0; k < 7; k++) {
    vec3 m = k < 4
        ? vec3(k == 1 || k == 3 ? -1.0 : 1.0, k >= 2 ? -1.0 : 1.0, 1.0)
        : vec3(k == 4 ? 1.0 : 0.0, k == 5 ? 1.0 : 0.0, k == 6 ? 1.0 : 0.0);
    float w = k < 4 ? 1.0 : cut;
    float den = dot(d, m);
    float num = dot(o, m);
    if (abs(den) < 1e-9) {
      if (abs(num) > w) return vec2(1.0, -1.0);
      continue;
    }
    float sg = den > 0.0 ? 1.0 : -1.0;
    float t1 = (-sg * w - num) / den;
    float tb = (sg * w - num) / den;
    if (t1 > tN) {
      t2 = tN;
      tN = t1;
      nIn = -sg * m;
    } else if (t1 > t2) {
      t2 = t1;
    }
    if (tb < tF) {
      tF2 = tF;
      tF = tb;
      nOut = sg * m;
    } else if (tb < tF2) {
      tF2 = tb;
    }
  }
  edge = tN - t2;
  edgeOut = tF2 - tF;
  return vec2(tN, tF);
}

// Hexagonal plate: three slabs across, one through its thickness.
vec2 hexPlate(vec3 o, vec3 d, float thick, float seed, out vec3 nIn,
              out float edge) {
  float tN = -1e9;
  float t2 = -1e9;
  float tF = 1e9;
  nIn = vec3(0.0, 1.0, 0.0);
  edge = 0.0;
  for (int k = 0; k < 4; k++) {
    float a = float(k) * 1.0471976;
    vec3 m = k < 3 ? vec3(cos(a), 0.0, sin(a)) : vec3(0.0, 1.0, 0.0);
    float w = k < 3 ? 0.866 * (0.78 + 0.4 * hash13(vec3(float(k), seed * 29.0, 3.0)))
                    : thick;
    float den = dot(d, m);
    float num = dot(o, m);
    if (abs(den) < 1e-9) {
      if (abs(num) > w) return vec2(1.0, -1.0);
      continue;
    }
    float sg = den > 0.0 ? 1.0 : -1.0;
    float t1 = (-sg * w - num) / den;
    float tb = (sg * w - num) / den;
    if (t1 > tN) {
      t2 = tN;
      tN = t1;
      nIn = -sg * m;
    } else if (t1 > t2) {
      t2 = t1;
    }
    tF = min(tF, tb);
  }
  edge = tN - t2;
  return vec2(tN, tF);
}

// Cuts [span] to the stone's side of facet plane s (n · p <= d): sets
// `cut` when the entry moved onto the facet itself.
vec2 clipSurface(vec3 o, vec3 d, vec4 s, vec2 span, out bool cut) {
  cut = false;
  if (dot(s.xyz, s.xyz) < 0.5) return span;
  float den = dot(d, s.xyz);
  float num = s.w - dot(o, s.xyz);
  if (abs(den) < 1e-9) {
    if (num < 0.0) return vec2(1.0, -1.0);
    return span;
  }
  float t = num / den;
  if (den > 0.0) {
    span.y = min(span.y, t);
  } else if (t > span.x) {
    span.x = t;
    cut = true;
  }
  return span;
}

// Closest approach of the ray (o, d) to segment p..q: returns the ray
// distance, sets the segment parameter (0..1) and the gap.
float raySeg(vec3 o, vec3 d, vec3 p, vec3 q, out float u, out float gap) {
  vec3 e = q - p;
  vec3 w = o - p;
  float ee = dot(e, e);
  float de = dot(d, e);
  float dw = dot(d, w);
  float ew = dot(e, w);
  float den = max(ee - de * de, 1e-9);
  u = clamp((ew - de * dw) / den, 0.0, 1.0);
  float t = dot(p + e * u - o, d);
  gap = length(o + d * t - p - e * u);
  return t;
}

// A crystal's frame from its packed data: long axis b.xyz, turned about
// it, stretched along it and flattened across it by the seed.
void crystalFrame(vec4 a, vec4 b, out vec3 u, out vec3 ax, out vec3 v,
                  out vec3 k) {
  float seed = fract(b.w);
  ax = b.xyz;
  frame(ax, seed * 6.2832, u, v);
  k = a.w * vec3(1.0, 1.0 + 0.7 * seed, 0.65 + 0.3 * fract(seed * 7.13));
}

vec3 toLocal(vec3 w, vec3 u, vec3 ax, vec3 v, vec3 k) {
  return vec3(dot(w, u), dot(w, ax), dot(w, v)) / k;
}

vec3 normalOut(vec3 m, vec3 u, vec3 ax, vec3 v, vec3 k) {
  return normalize(u * (m.x / k.x) + ax * (m.y / k.y) + v * (m.z / k.z));
}

// ---------------------------------------------------------------------
// The characteristics. Each takes the view ray (o, d) in model space,
// the packed slots a, b, s, and model units per pixel px.

vec4 pinpoint(vec3 o, vec3 d, vec4 a, float seed, float px) {
  vec3 oc = a.xyz - o;
  float t = dot(oc, d);
  float r = length(oc - d * t);
  float rad = max(a.w, 0.9 * px);
  float core = exp(-sq(r / rad) * 2.4);
  float halo = exp(-r / (rad * 1.6)) * 0.12 *
               smoothstep(max(a.w * 3.6, 3.6 * px), rad, r);
  // Its tiny faces glint as the stone turns.
  float glint = 0.7 + 0.6 * pow(0.5 + 0.5 * sin(dot(d, vec3(19.1, 11.7, 7.3)) +
                                               seed * 40.0), 6.0);
  float dim = min(1.0, a.w / rad * 1.4 + 0.45);
  vec3 col = mix(vec3(0.88, 0.92, 1.0), vec3(1.0, 0.97, 0.9), seed);
  float al = clamp(core * 0.95 + halo * 0.4, 0.0, 1.0) * dim;
  return vec4(col * (core * 1.2 + halo) * glint * dim, al);
}

vec4 cloud(vec3 o, vec3 d, vec4 a, vec4 b, float seed, float px,
           vec3 lk, float jit) {
  vec3 u;
  vec3 v;
  frame(b.xyz, seed * 6.2832, u, v);
  vec3 rad = a.w * vec3(1.0, 0.42 + 0.15 * seed, 0.75);
  vec3 lo = vec3(dot(o - a.xyz, u), dot(o - a.xyz, b.xyz), dot(o - a.xyz, v)) / rad;
  vec3 ld = vec3(dot(d, u), dot(d, b.xyz), dot(d, v)) / rad;
  float qa = dot(ld, ld);
  float qb = dot(lo, ld);
  float qc = dot(lo, lo) - 1.0;
  float disc = qb * qb - qa * qc;
  if (disc <= 0.0) return vec4(0.0);
  float root = sqrt(disc);
  float t0 = (-qb - root) / qa;
  float t1 = (-qb + root) / qa;
  float dt = (t1 - t0) / 26.0;
  float freq = 1.0 / (a.w * 0.075);
  float sp = max(0.22 / freq, 0.65 * px);
  float T = 1.0;
  float e = 0.0;
  for (int i = 0; i < 26; i++) {
    float t = t0 + dt * (float(i) + jit);
    vec3 p = o + d * t;
    vec3 x = lo + ld * t;
    float rr = dot(x, x);
    // Patchy, densest at its heart.
    float body = smoothstep(1.0, 0.15, rr) *
                 (0.35 + 0.9 * fbm(x * 2.3 + seed * 19.0));
    float clump = max(0.0, fbm(x * 4.1 + seed * 7.0) - 0.42) * 2.2;
    float haze = body * (0.3 + clump);
    // Its pinpoints: one per cell of a fine lattice, where it is dense.
    vec3 c = floor(p * freq);
    vec3 h = hash33(c + seed * 13.0);
    vec3 at = (c + 0.2 + 0.6 * h) / freq;
    float speck = h.x < body * 1.1 ? exp(-sq(length(p - at) / sp)) : 0.0;
    float ds = dt * length(rad * ld) / a.w;
    e += T * (haze * 0.75 + speck * 3.2) * ds;
    T *= exp(-haze * ds * 1.5);
  }
  float lit = 0.75 + 0.45 * max(dot(-d, lk), 0.0);
  vec3 col = vec3(0.86, 0.88, 0.93) * e * lit;
  return vec4(col, clamp(1.0 - T + e * 0.15, 0.0, 1.0));
}

vec4 needles(vec3 o, vec3 d, vec4 a, vec4 b, float seed, float px,
             vec3 lk, vec3 lf) {
  vec3 u;
  vec3 v;
  frame(b.xyz, seed * 6.2832, u, v);
  vec4 acc = vec4(0.0);
  float nearest = 1e9;
  float count = 2.0 + floor(seed * 3.0);
  for (int i = 0; i < 4; i++) {
    if (float(i) >= count) break;
    vec3 h = hash33(vec3(seed * 91.0, float(i) * 7.0, 3.0));
    vec3 dir = normalize(b.xyz + (h - 0.5) * 0.14);
    vec3 off = (u * (h.x - 0.5) + v * (h.y - 0.5)) * a.w * 0.55 +
               b.xyz * (h.z - 0.5) * a.w * 0.3;
    float len = a.w * (0.5 + 0.45 * h.z);
    vec3 p = a.xyz + off - dir * len;
    vec3 q = a.xyz + off + dir * len;
    float s;
    float gap;
    float t = raySeg(o, d, p, q, s, gap);
    float along = abs(s * 2.0 - 1.0);
    float r = max(a.w * 0.026 * (0.7 + 0.6 * h.x), 0.5 * px) *
              (1.0 - 0.75 * pow(along, 4.0));
    float cover = smoothstep(r + px * 0.8, r - px * 0.2, gap);
    if (cover <= 0.001) continue;
    // A thin bright rod: diffuse across it, a line of sheen along it.
    vec3 hit = o + d * t;
    vec3 axisP = p + (q - p) * s;
    vec3 n = hit - axisP;
    n = length(n) > 1e-6 ? normalize(n) : normalize(cross(dir, d));
    n = normalize(n - d * 0.6);
    vec3 hv = normalize(lk - d);
    float th = dot(dir, hv);
    float sheen = pow(sqrt(max(1.0 - th * th, 0.0)), 70.0);
    float lum = 0.35 + 0.7 * max(dot(n, lk), 0.0) + 0.3 * max(dot(n, lf), 0.0) +
                1.3 * sheen;
    vec3 col = vec3(0.9, 0.93, 1.0) * lum;
    float al = cover * (0.8 + 0.2 * sheen);
    vec4 c = vec4(col * al, al);
    acc = t < nearest ? over(c, acc) : over(acc, c);
    nearest = min(nearest, t);
  }
  return acc;
}

// A transparent crystal. mode 0: an included mineral, tinted by seed;
// 1: a knot (diamond in diamond, cut by facet s); 2: a bleached crystal.
vec4 crystal(vec3 o, vec3 d, vec4 a, vec4 b, vec4 s, float seed, float px,
             vec3 lk, float mode) {
  vec3 u;
  vec3 ax;
  vec3 v;
  vec3 k;
  crystalFrame(a, b, u, ax, v, k);
  vec3 nIn;
  vec3 nOut;
  float edge;
  float edgeOut;
  float cutW = 0.62 + 0.25 * fract(seed * 3.7);
  vec3 lo = toLocal(o - a.xyz, u, ax, v, k);
  vec3 ldr = toLocal(d, u, ax, v, k);
  // Local distances are along an unnormalised direction: same t.
  vec2 hit = octa(lo, ldr, cutW, nIn, nOut, edge, edgeOut);
  bool cut = false;
  hit = clipSurface(o, d, s, hit, cut);
  if (hit.x >= hit.y) return vec4(0.0);
  float cover = smoothstep(0.0, px * 1.4, hit.y - hit.x);
  vec3 n = cut ? s.xyz : normalOut(nIn, u, ax, v, k);
  vec3 nb = normalOut(nOut, u, ax, v, k);
  float lw = px * 1.2 + a.w * 0.025;
  // Edges on the near side, and fainter, the far side's seen through it.
  float line = cut ? 0.0 : 1.0 - smoothstep(0.0, lw, edge);
  float lineBack = 1.0 - smoothstep(0.0, lw, edgeOut);
  float relief = 1.0 - smoothstep(0.0, a.w * 0.2, cut ? 1.0 : edge);

  float cosI = abs(dot(d, n));
  // Diamond is denser than the crystal: past about 46° its faces mirror.
  float tir = smoothstep(0.74, 0.62, cosI);
  float tirB = smoothstep(0.74, 0.62, abs(dot(d, nb)));
  vec3 tint = vec3(0.97, 0.98, 1.0);
  if (mode < 0.5) {
    tint = seed < 0.62 ? vec3(0.97, 0.98, 1.0)
         : seed < 0.84 ? vec3(1.0, 0.5, 0.28)
                       : vec3(0.42, 0.92, 0.52);
  }
  float key = max(dot(reflect(d, n), lk), 0.0);
  vec3 front = gloss(d, n, 1.0) * (0.06 + 0.8 * tir) +
               vec3(1.0) * pow(key, 50.0) * 1.6;
  vec3 back = gloss(d, -nb, 1.0) * (0.04 + 0.5 * tirB);
  vec3 body = tint * (0.1 + 0.12 * max(dot(n, lk), 0.0));
  vec3 col = front + tint * (back * 0.7 + body);
  col += tint * (line * 0.95 + lineBack * 0.35) * (0.65 + 0.5 * max(dot(n, lk), 0.0));
  // Relief: a crystal's rim reads a touch darker just inside its edges.
  col *= mix(1.0, 0.7, relief * (1.0 - tir));
  float al = 0.22 + 0.5 * tir + 0.12 * tirB + 0.6 * line + 0.25 * lineBack;
  if (mode > 1.5) {
    // Bleached: a pale, frosted ghost of the crystal, with dark residue.
    float fr = fbm((o + d * hit.x - a.xyz) / a.w * 4.0 + seed * 9.0);
    col = vec3(1.0, 0.98, 0.95) * (0.75 + 0.6 * fr) *
              (0.8 + 0.5 * max(dot(n, lk), 0.0)) +
          vec3(1.0) * (line * 0.8 + lineBack * 0.3);
    col *= 1.0 - 0.75 * smoothstep(0.68, 0.76, fr);
    al = 0.62 + 0.25 * fr + 0.3 * line;
  } else if (mode > 0.5) {
    // A knot: diamond in diamond, seen mostly by its outline and the
    // strain round it; polished flat where it meets the facet.
    col = front * 0.6 + vec3(0.95) * (line * 0.9 + lineBack * 0.4) +
          vec3(0.9) * 0.06;
    al = 0.08 + 0.3 * tir + 0.6 * line + 0.3 * lineBack;
    if (cut) {
      // Outline of the polished section: how far inside the crystal the
      // point on the facet lies.
      vec3 lp = abs(toLocal(o + d * hit.x - a.xyz, u, ax, v, k));
      float f = max(lp.x + lp.y + lp.z - 1.0, max(lp.x, max(lp.y, lp.z)) - cutW);
      float rim = 1.0 - smoothstep(0.0, (px * 2.0) / a.w + 0.03, -f);
      col = col * 0.6 + vec3(1.0) * rim * 0.95 + gloss(d, s.xyz, 0.1) +
            vec3(0.85) * lineBack * 0.4;
      al = max(al, 0.1 + 0.8 * rim);
    }
  }
  al = clamp(al, 0.0, 0.96) * cover;
  return vec4(col * al, al);
}

// Rosette of tension cracks round a sulphide: a translucent disc split by
// radial fractures.
vec4 rosette(vec3 o, vec3 d, vec4 a, vec4 b, float seed, float px, out float t) {
  t = 1e9;
  float den = dot(d, b.xyz);
  if (abs(den) < 1e-5) return vec4(0.0);
  t = dot(a.xyz - o, b.xyz) / den;
  vec3 q = o + d * t - a.xyz;
  vec3 u;
  vec3 v;
  frame(b.xyz, seed * 6.2832, u, v);
  vec2 x = vec2(dot(q, u), dot(q, v)) / a.w;
  float r = length(x);
  if (r < 0.75 || r > 2.5) return vec4(0.0);
  float ang = atan(x.y, x.x);
  float petals = 5.0 + floor(seed * 4.0);
  float lobe = pow(0.5 + 0.5 * cos(ang * petals + seed * 20.0), 3.0);
  float reach = 1.3 + 0.9 * lobe * (0.7 + 0.6 * noise3(vec3(ang * 3.0, seed * 30.0, 1.0)));
  float m = smoothstep(reach, reach - 0.25, r) * smoothstep(0.75, 0.95, r);
  float streak = 0.4 + 0.6 * noise3(vec3(ang * 22.0, r * 3.0, seed * 5.0));
  float cosV = abs(den);
  float flash = smoothstep(0.92, 0.85, cosV);
  float lum = (0.35 + 0.5 * streak) * (0.7 + 0.8 * flash);
  float al = m * (0.25 + 0.35 * streak) * smoothstep(0.02, 0.12, cosV + 0.05);
  return vec4(vec3(0.9, 0.92, 0.95) * lum * al, al);
}

vec4 darkCrystal(vec3 o, vec3 d, vec4 a, vec4 b, float seed, float px,
                 vec3 lk) {
  vec3 u;
  vec3 ax;
  vec3 v;
  vec3 k;
  crystalFrame(a, b, u, ax, v, k);
  vec3 nIn;
  vec3 nOut;
  float edge;
  vec3 lo = toLocal(o - a.xyz, u, ax, v, k);
  vec3 ldr = toLocal(d, u, ax, v, k);
  bool graphite = seed < 0.55;
  vec2 hit;
  if (graphite) {
    // A thin hexagonal plate of graphite.
    vec3 lo2 = vec3(lo.x, lo.y / (1.0 + 0.7 * seed), lo.z);
    vec3 ld2 = vec3(ldr.x, ldr.y / (1.0 + 0.7 * seed), ldr.z);
    hit = hexPlate(lo2, ld2, 0.22, seed, nIn, edge);
    nIn = normalOut(nIn * vec3(1.0, 1.0 / (1.0 + 0.7 * seed), 1.0), u, ax, v, k);
  } else {
    float eo;
    hit = octa(lo, ldr, 0.72, nIn, nOut, edge, eo);
    nIn = normalOut(nIn, u, ax, v, k);
  }
  vec4 col = vec4(0.0);
  float tc = 1e9;
  if (hit.x < hit.y) {
    tc = hit.x;
    float cover = smoothstep(0.0, px * 1.3, hit.y - hit.x);
    float line = 1.0 - smoothstep(0.0, px * 1.2 + a.w * 0.025, edge);
    // Black, with graphite's submetallic sheen and glints at its edges.
    vec3 sheen = gloss(d, nIn, graphite ? 0.28 : 0.16);
    vec3 spec = vec3(1.0) * pow(max(dot(reflect(d, nIn), lk), 0.0), graphite ? 40.0 : 22.0) *
                (graphite ? 1.4 : 0.8);
    vec3 p = o + d * hit.x;
    float grain = graphite ? noise3((p - a.xyz) / a.w * vec3(14.0, 3.0, 14.0) + seed * 9.0) : 0.5;
    vec3 c = vec3(0.018, 0.017, 0.016) + sheen * (0.6 + 0.6 * grain) + spec +
             vec3(0.55, 0.56, 0.6) * line;
    float al = cover * 0.97;
    col = vec4(c * al, al);
  }
  if (!graphite) {
    float tr;
    vec4 halo = rosette(o, d, a, b, seed, px, tr);
    col = tr < tc ? over(halo, col) : over(col, halo);
  }
  return col;
}

// A break: frosted, barbed, stepped, mirror bright past the critical
// angle and iridescent where it thins. mode 0 closed, 1 open (cut off at
// facet s, bright along it), 2 glass filled.
vec4 feather(vec3 o, vec3 d, vec4 a, vec4 b, vec4 s, float seed, float px,
             vec3 lk, vec3 lf, float mode) {
  vec3 n = b.xyz;
  float den = dot(d, n);
  if (abs(den) < 1e-5) return vec4(0.0);
  float t = dot(a.xyz - o, n) / den;
  vec3 p = o + d * t;
  vec3 q = p - a.xyz;
  vec3 u;
  vec3 v;
  frame(n, seed * 6.2832, u, v);
  vec2 x = vec2(dot(q, u), dot(q, v)) / a.w;
  float r = length(x);
  if (r > 1.25) return vec4(0.0);
  float pxn = px / a.w;

  // Lobed, broken outline.
  vec2 dir = x / max(r, 1e-5);
  float rim = 0.6 + 0.32 * noise3(vec3(dir * 1.7, seed * 37.0)) +
              0.14 * noise3(vec3(dir * 5.0, seed * 11.0));
  // Ragged, broken edge: torn in patches, not spiked.
  rim *= 0.8 + 0.32 * fbm(vec3(x * 3.5, seed * 5.0)) +
         0.08 * noise3(vec3(dir * 20.0, seed * 2.0 + r * 3.0));
  float outline = smoothstep(rim, rim - 1.6 * pxn - 0.02, r);
  if (outline <= 0.0) return vec4(0.0);

  bool isOpen = mode > 0.5 && dot(s.xyz, s.xyz) > 0.5;
  float sd = isOpen ? dot(p, s.xyz) - s.w : -1.0;
  if (isOpen && sd > px * 0.5) return vec4(0.0);

  // Plume: a curving main crack with barbs swept off it, warped so no
  // two run quite alike.
  vec2 xw = x + (vec2(fbm(vec3(x * 2.0, seed * 3.0)), fbm(vec3(x * 2.0, seed * 3.0 + 7.0))) -
                 0.5) * 0.35;
  float bend = 0.22 * sin(xw.x * 1.6 + seed * 6.0) + 0.1 * sin(xw.x * 4.3 + seed * 3.0);
  float dy = xw.y - bend;
  float barbs = abs(dy) * 1.0 - xw.x * 0.6;
  float stria = pow(0.5 + 0.5 * cos(barbs * 30.0 + fbm(vec3(xw * 4.0, seed)) * 6.0), 6.0) *
                (0.3 + 0.7 * noise3(vec3(xw * 6.0, seed * 3.0)));
  float spine = exp(-sq(dy / 0.035)) * smoothstep(rim, rim * 0.4, r);
  // Cleavage steps: crisp terraces where the break jumps planes.
  float lev = fbm(vec3(x * 1.8, seed * 13.0)) * 4.0;
  float stepEdge = smoothstep(0.86, 0.98, fract(lev)) * 0.9;
  // Healed patches leave holes in the break.
  float body = fbm(vec3(x * 4.5, seed * 23.0));
  float healed = smoothstep(0.18, 0.32, body - 0.12 * r);
  // Thinner toward its rim: the air film there makes thin-film colours.
  float thick = clamp((rim - r) / (0.55 * rim), 0.0, 1.0);
  if (isOpen) thick = max(thick, smoothstep(-0.4 * a.w, 0.0, sd));

  vec3 nf = den < 0.0 ? n : -n;
  float cosV = abs(den);
  // Past diamond's critical angle the crack mirrors almost everything.
  float mirror = mix(0.22, 1.0, smoothstep(0.93, 0.86, cosV));
  vec3 refl = gloss(d, nf, 1.0) * mirror;
  vec3 film = 0.5 + 0.5 * cos(6.2832 * (thick * 1.7 + seed + vec3(0.0, 0.33, 0.67)));
  // Interference only in patches where the film is thinnest.
  float filmPatch = smoothstep(0.55, 0.78, noise3(vec3(x * 2.6, seed * 41.0)));
  float frost = 0.18 + 0.45 * body + 0.95 * stria + 0.7 * stepEdge + 0.55 * spine;
  float lit = 0.5 + 0.3 * frosty(nf, lk, lf, toModel(RIM_W));
  vec3 col = vec3(0.93, 0.94, 0.96) * frost * lit * 0.5 +
             refl * (0.2 + 0.35 * body);
  col = mix(col, col * film * 1.6, (1.0 - thick) * filmPatch * 0.5);
  // Wisps thin out toward the rim instead of ending on a hard line.
  float wisp = pow(smoothstep(rim, rim * 0.45, r), 0.7);
  float al = clamp((0.1 + 0.28 * body + 0.5 * stria + 0.32 * stepEdge + 0.35 * spine) *
                   (0.45 + 0.55 * wisp) + 0.22 * mirror * wisp, 0.0, 0.92);

  if (mode > 1.5) {
    // Lead glass in the crack: the break nearly vanishes, but the glass
    // disperses colour unlike diamond, flashing orange to pink-purple and
    // electric blue as the angle changes.
    float ang = smoothstep(0.35, 0.95, cosV);
    vec3 flash = mix(vec3(1.0, 0.5, 0.12), vec3(0.9, 0.3, 0.95), ang);
    flash = mix(flash, vec3(0.2, 0.7, 1.0), smoothstep(0.55, 0.75, sin(ang * 9.0 + seed * 6.0)));
    float band = 0.45 + 0.55 * stria + 0.4 * stepEdge;
    col = col * 0.15 + flash * band * (0.9 + 0.6 * mirror) * (0.55 + 0.6 * stria);
    al = clamp((0.12 + 0.42 * band * (0.6 + 0.4 * mirror)) * (0.5 + 0.5 * wisp), 0.0, 0.75);
  }
  if (isOpen) {
    // Where the break meets the facet: a bright crack across the surface.
    float lineW = px * 0.9 + a.w * 0.006;
    float brk = exp(-sq(sd / lineW)) * smoothstep(rim, rim * 0.6, r);
    col += vec3(1.0) * brk * 0.9;
    al = max(al, brk * 0.85);
  }
  al *= outline * (mode > 1.5 ? 1.0 : healed * 0.85 + 0.15);
  // A crack seen edge on is a thin bright line; don't let it vanish.
  float edgeOn = smoothstep(0.08, 0.0, cosV);
  al = max(al, edgeOn * outline * 0.6);
  return vec4(col * al, al);
}

// Drag lines a polished-through knot leaves on its facet: faint comet
// tails behind it, along the polish direction.
vec4 dragLines(vec3 o, vec3 d, vec4 a, vec4 s, float seed, float px) {
  float den = dot(d, s.xyz);
  if (abs(den) < 1e-5) return vec4(0.0);
  float t = (s.w - dot(o, s.xyz)) / den;
  vec3 p = o + d * t - a.xyz;
  vec3 u;
  vec3 v;
  frame(s.xyz, seed * 6.2832, u, v);
  vec2 x = vec2(dot(p, u), dot(p, v)) / a.w;
  if (x.x < 0.4 || x.x > 2.6 || abs(x.y) > 0.9) return vec4(0.0);
  float lines = pow(0.5 + 0.5 * cos(x.y * 34.0 + noise3(vec3(x * 2.0, seed)) * 3.0), 10.0);
  float fade = smoothstep(2.6, 0.6, x.x) * smoothstep(0.9, 0.3, abs(x.y));
  float al = lines * fade * 0.28;
  return vec4(vec3(0.95) * al, al);
}

// Walls of an opening (cavity, chip, indented natural) seen from inside
// the stone: shade a frosted surface with normal n at p.
vec3 wall(vec3 d, vec3 n, vec3 p, vec4 a, float seed, vec3 lk, vec3 lf,
          float tone) {
  float fr = fbm((p - a.xyz) / a.w * 5.0 + seed * 11.0);
  vec3 nb = normalize(n + (vec3(fr, noise3(p / a.w * 9.0), fbm(p / a.w * 7.0)) - 0.5) * 0.6);
  float lit = frosty(nb, lk, lf, toModel(RIM_W));
  float tir = smoothstep(0.92, 0.85, abs(dot(d, n)));
  return vec3(0.9, 0.9, 0.92) * tone * (0.3 + 0.55 * fr) * lit + gloss(d, nb, 0.35 * tir);
}

vec4 cavity(vec3 o, vec3 d, vec4 a, vec4 b, vec4 s, float seed, float px,
            vec3 lk, vec3 lf) {
  // An angular hole: a convex block of random faces round a point just
  // below the facet, open where the facet cuts it.
  vec3 c = a.xyz + s.xyz * a.w * 0.25;
  float tN = -1e9;
  float t2 = -1e9;
  float tF = 1e9;
  vec3 nN = vec3(0.0, 1.0, 0.0);
  vec3 nF = nN;
  for (int i = 0; i < 13; i++) {
    vec3 m = normalize(hash33(vec3(seed * 53.0, float(i) * 3.1, 7.0)) - 0.5);
    float w = a.w * (0.5 + 0.3 * hash13(vec3(float(i), seed * 17.0, 2.0)));
    float den = dot(d, m);
    float num = dot(o - c, m);
    if (abs(den) < 1e-9) {
      if (num > w) return vec4(0.0);
      continue;
    }
    // One-sided faces: each bounds the hole on its own side only.
    if (den < 0.0) {
      float te = (w - num) / den;
      if (te > tN) {
        t2 = tN;
        tN = te;
        nN = m;
      } else if (te > t2) {
        t2 = te;
      }
    } else {
      float tx = (w - num) / den;
      if (tx < tF) {
        tF = tx;
        nF = m;
      }
    }
  }
  vec2 span = vec2(tN, tF);
  if (span.x >= span.y) return vec4(0.0);
  bool cut = false;
  vec2 inside = clipSurface(o, d, s, span, cut);
  if (inside.x >= inside.y) return vec4(0.0);
  float cover = smoothstep(0.0, px * 1.4, inside.y - inside.x);
  vec3 col;
  float al;
  vec3 p;
  if (!cut) {
    // The ray meets the hole's wall from inside the stone: diamond
    // against air mirrors it bright, frosted by the broken surface.
    p = o + d * inside.x;
    float depth = s.w - dot(p, s.xyz);
    float ao = 0.5 + 0.5 * smoothstep(0.0, a.w * 0.6, depth);
    col = wall(d, nN, p, a, seed, lk, lf, 1.0) * ao;
    float crease = 1.0 - smoothstep(0.0, px * 1.2 + a.w * 0.03, tN - t2);
    col = col * (1.0 - 0.55 * crease) + vec3(0.9) * crease * 0.25;
    al = 0.92;
  } else {
    // Into the opening from outside: its walls fall away into shadow,
    // frosted specks catching the light, dirt dark at the bottom.
    p = o + d * inside.y;
    float depth = s.w - dot(p, s.xyz);
    float deep = smoothstep(0.0, a.w * 0.9, depth);
    col = wall(d, -nF, p, a, seed, lk, lf, 0.8) * mix(0.55, 0.05, deep);
    float speck = smoothstep(0.72, 0.8, noise3((p - a.xyz) / a.w * 14.0 + seed));
    col += vec3(0.8) * speck * (1.0 - deep) * 0.6;
    al = 0.94;
  }
  // The opening's broken rim on the facet catches the light.
  float sd = abs(dot(p, s.xyz) - s.w);
  float rimW = (px * 1.4 + a.w * 0.03) *
               (0.6 + 0.8 * noise3((p - a.xyz) / a.w * 9.0 + seed * 4.0));
  float rim = exp(-sq(sd / rimW));
  col += vec3(1.0) * rim;
  al = max(al, rim) * cover;
  return vec4(col * al, al);
}

// A shallow scoop, a sphere just outside facet s cut into the stone.
// mode 0: a chip, with conchoidal ripples; 1: an indented natural, the
// rough's frosted skin with trigons.
vec4 scoop(vec3 o, vec3 d, vec4 a, vec4 b, vec4 s, float seed, float px,
           vec3 lk, vec3 lf, float mode) {
  vec3 ps = a.xyz - s.xyz * (dot(a.xyz, s.xyz) - s.w);
  vec3 tAx = b.xyz;
  vec3 wAx = normalize(cross(s.xyz, tAx));
  // Stretched along the girdle for a natural.
  vec3 sc = ps + s.xyz * a.w * (mode > 0.5 ? 0.62 : 0.5);
  vec3 rad = a.w * (mode > 0.5 ? vec3(1.15, 0.55, 0.78) : vec3(1.0, 0.8, 0.9));
  vec3 lo = vec3(dot(o - sc, tAx), dot(o - sc, wAx), dot(o - sc, s.xyz)) / rad;
  vec3 ld = vec3(dot(d, tAx), dot(d, wAx), dot(d, s.xyz)) / rad;
  float qa = dot(ld, ld);
  float qb = dot(lo, ld);
  float qc = dot(lo, lo) - 1.0;
  float disc = qb * qb - qa * qc;
  if (disc <= 0.0) return vec4(0.0);
  float root = sqrt(disc);
  vec2 span = vec2((-qb - root) / qa, (-qb + root) / qa);
  bool cut;
  vec2 inside = clipSurface(o, d, s, span, cut);
  if (inside.x >= inside.y) return vec4(0.0);
  float cover = smoothstep(0.0, px * 1.4, inside.y - inside.x);
  float tw = cut ? inside.y : inside.x;
  vec3 p = o + d * tw;
  vec3 lp = (lo + ld * tw);
  vec3 n = normalize(vec3(lp.x / rad.x, lp.y / rad.y, lp.z / rad.z));
  vec3 nW = normalize(tAx * n.x + wAx * n.y + s.xyz * n.z);
  // Facing the viewer: from inside the scoop (seen through its opening)
  // its wall faces in; from inside the stone, out.
  if (cut) nW = -nW;
  vec3 col;
  if (mode < 0.5) {
    // Shell-like ripples round the point of impact.
    float ring = length(lp.xy) * 11.0 + fbm(vec3(lp.xy * 3.0, seed * 5.0)) * 2.5;
    float rip = pow(0.5 + 0.5 * cos(ring * 3.1416), 3.0);
    float fine = pow(0.5 + 0.5 * cos(ring * 3.1416 * 4.0), 6.0);
    col = wall(d, nW, p, a, seed, lk, lf, 1.05) * (0.75 + 0.3 * rip + 0.15 * fine);
    col += gloss(d, nW, 0.35 * (rip + 0.5));
  } else {
    // The rough's skin: matte, faintly brown, with parallel growth lines
    // and triangular etch pits (trigons).
    vec2 g = vec2(dot(p - ps, tAx), dot(p - ps, wAx)) / a.w * 15.0;
    vec2 tri = vec2(g.x + g.y * 0.57735, g.y * 1.1547);
    vec2 cell = floor(tri);
    vec2 f = fract(tri);
    float pit = hash13(vec3(cell, seed * 31.0));
    float inTri = f.x + f.y < 1.0 ? 1.0 : 0.0;
    float tri3 = min(min(f.x, f.y), abs(1.0 - f.x - f.y));
    float trigon = pit > 0.7 && inTri > 0.5 ? smoothstep(0.03, 0.09, tri3) : 0.0;
    float lines = pow(0.5 + 0.5 * cos(g.y * 2.2 + noise3(vec3(g * 0.4, seed)) * 2.0), 6.0);
    // Granular, frosted, faintly brown: the crystal's own skin.
    float grain = noise3((p - a.xyz) / a.w * 38.0 + seed * 3.0);
    float grit = noise3((p - a.xyz) / a.w * 90.0 + seed * 7.0);
    col = wall(d, nW, p, a, seed, lk, lf, 1.2) * vec3(0.93, 0.87, 0.78) *
          (0.55 + 0.35 * grain + 0.3 * grit) * (0.8 + 0.25 * lines) *
          (1.0 - 0.55 * trigon);
    col += vec3(0.9) * (pit > 0.7 && inTri > 0.5 ? 1.0 - smoothstep(0.0, 0.05, tri3) : 0.0) * 0.4;
  }
  float sd = abs(dot(p, s.xyz) - s.w);
  float rim = exp(-sq(sd / (px * 1.3 + a.w * 0.02)));
  col += vec3(1.0) * rim * 0.8;
  float al = (cut ? 0.8 : 0.92);
  al = max(al, rim) * cover;
  return vec4(col * al, al);
}

// Thin cracks along segments: root-like for a bruise, hairs for bearding.
float crackLine(vec3 o, vec3 d, vec3 p, vec3 q, float r0, float r1, float px,
                out float t) {
  float u;
  float gap;
  t = raySeg(o, d, p, q, u, gap);
  float r = max(mix(r0, r1, u), 0.35 * px);
  float w = min(1.0, mix(r0, r1, u) / (0.35 * px));
  return smoothstep(r + px * 0.9, r * 0.3, gap) * w;
}

vec4 bruise(vec3 o, vec3 d, vec4 a, vec4 b, vec4 s, float seed, float px,
            vec3 lk) {
  vec3 c = a.xyz;
  vec3 inward = -s.xyz;
  vec3 u;
  vec3 v;
  frame(inward, seed * 6.2832, u, v);
  float m = 0.0;
  float tm = 1e9;
  for (int i = 0; i < 8; i++) {
    vec3 h = hash33(vec3(seed * 71.0, float(i) * 5.3, 11.0));
    float ang = float(i) * 0.785 + h.x * 0.6;
    vec3 side = u * cos(ang) + v * sin(ang);
    vec3 dir = normalize(inward * (0.45 + 0.5 * h.y) + side * (0.7 + 0.3 * h.z));
    float len = a.w * (0.55 + 0.6 * h.z);
    vec3 mid = c + dir * len * 0.5 + (u * (h.y - 0.5) + v * (h.x - 0.5)) * a.w * 0.18;
    vec3 tip = c + dir * len;
    float t1;
    float t2;
    float t3;
    float l1 = crackLine(o, d, c, mid, a.w * 0.022, a.w * 0.014, px, t1);
    float l2 = crackLine(o, d, mid, tip, a.w * 0.014, 0.0, px, t2);
    // A side root off each.
    vec3 twig = mid + (side * 0.6 + inward * 0.5) * len * 0.35;
    float l3 = crackLine(o, d, mid, twig, a.w * 0.01, 0.0, px, t3);
    float l = max(l1, max(l2, l3 * 0.8)) * 0.8;
    if (l > m) {
      m = l;
      tm = l == l1 ? t1 : (l == l2 ? t2 : t3);
    }
  }
  // The crushed point itself: a little frosted star at the junction.
  vec3 oc = c - o;
  float tc = dot(oc, d);
  float gc = length(oc - d * tc);
  float core = exp(-sq(gc / max(a.w * 0.12, px)));
  float spark = fbm((o + d * tc - c) / a.w * 12.0 + seed * 3.0);
  float al = clamp(max(m * 0.85, core * (0.6 + 0.4 * spark)), 0.0, 1.0);
  vec3 col = vec3(0.92, 0.93, 0.95) * (0.65 + 0.5 * max(dot(-d, lk), 0.0)) +
             vec3(0.4) * core * spark;
  // Only inside the stone.
  vec3 hp = o + d * (m > core ? tm : tc);
  if (dot(hp, s.xyz) - s.w > px) al = 0.0;
  return vec4(col * al, al);
}

vec4 bearding(vec3 o, vec3 d, vec4 a, vec4 b, vec4 s, float seed, float px,
              float jit) {
  // Frame on the girdle: along it (b), into the stone (-s), across it.
  vec3 tAx = b.xyz;
  vec3 nIn = -s.xyz;
  vec3 wAx = normalize(cross(nIn, tAx));
  vec3 c = a.xyz;
  // March the band the hairs fill.
  vec3 lo = vec3(dot(o - c, tAx), dot(o - c, wAx), dot(o - c, nIn));
  vec3 ld = vec3(dot(d, tAx), dot(d, wAx), dot(d, nIn));
  vec3 lo3 = vec3(-a.w, -a.w * 0.16, -0.01 * a.w);
  vec3 hi3 = vec3(a.w, a.w * 0.16, a.w * 0.42);
  vec3 inv = 1.0 / (abs(ld) + 1e-6) * sign(ld + 1e-9);
  vec3 ta = (lo3 - lo) * inv;
  vec3 tb = (hi3 - lo) * inv;
  vec3 tmin = min(ta, tb);
  vec3 tmax = max(ta, tb);
  float t0 = max(max(tmin.x, tmin.y), tmin.z);
  float t1 = min(min(tmax.x, tmax.y), tmax.z);
  if (t0 >= t1) return vec4(0.0);
  float spacing = a.w * 0.045;
  float hr = max(a.w * 0.007, 0.45 * px);
  float e = 0.0;
  float dt = (t1 - t0) / 28.0;
  for (int i = 0; i < 28; i++) {
    float t = t0 + dt * (float(i) + jit);
    vec3 x = lo + ld * t;
    float depth = x.z;
    if (depth < 0.0) continue;
    float cell = floor(x.x / spacing);
    float best = 0.0;
    for (int j = -1; j <= 1; j++) {
      float id = cell + float(j);
      vec3 h = hash33(vec3(id, seed * 19.0, 4.0));
      float len = a.w * (0.04 + 0.34 * h.z * h.z * h.z);
      if (depth > len) continue;
      float along = smoothstep(a.w, a.w * 0.6, abs(id * spacing));
      // Hairs lean and wave a little as they run in.
      float hx = (id + 0.2 + 0.6 * h.x) * spacing + depth * (h.y - 0.5) * 0.6;
      float hy = (h.y - 0.5) * a.w * 0.24 + sin(depth / a.w * 18.0 + h.x * 6.0) * a.w * 0.01;
      float gap = length(vec2(x.x - hx, x.y - hy));
      float taper = 1.0 - depth / len;
      best = max(best, exp(-sq(gap / (hr * (0.4 + 0.6 * taper)))) * taper * along);
    }
    e += best * dt / (hr * 3.0);
  }
  float al = clamp(e * 1.1, 0.0, 0.92);
  return vec4(vec3(0.93, 0.94, 0.96) * al * 1.25, al);
}

vec4 graining(vec3 o, vec3 d, vec4 a, vec4 b, float seed, float px, vec3 lk) {
  vec3 n = b.xyz;
  float den = dot(d, n);
  if (abs(den) < 1e-4) return vec4(0.0);
  vec3 u;
  vec3 v;
  frame(n, seed * 6.2832, u, v);
  float spacing = a.w * (0.16 + 0.06 * seed);
  vec4 acc = vec4(0.0);
  float cosV = abs(den);
  for (int j = 0; j < 6; j++) {
    int jj = den > 0.0 ? 5 - j : j;
    float off = (float(jj) - 2.5) * spacing +
                (hash13(vec3(float(jj), seed * 11.0, 5.0)) - 0.5) * spacing * 0.5;
    float t = (dot(a.xyz - o, n) + off) / den;
    vec3 q = o + d * t - a.xyz;
    vec2 x = vec2(dot(q, u), dot(q, v)) / a.w;
    float r = length(x * vec2(0.8, 1.15));
    if (r > 1.0) continue;
    // Long streaks across the growth plane.
    float streak = sq(noise3(vec3(x.x * 1.2, x.y * 16.0, seed * 9.0 + float(jj))));
    float lines = pow(0.5 + 0.5 * cos(x.y * 46.0 + noise3(vec3(x * 3.0, seed)) * 4.0), 8.0);
    float mask = smoothstep(1.0, 0.5, r) * (streak * 0.8 + lines * 0.5);
    float sheen = pow(max(dot(reflect(d, den < 0.0 ? n : -n), lk), 0.0), 10.0);
    float al = mask * (0.2 + 0.45 * sheen) * smoothstep(0.03, 0.15, cosV);
    vec3 col = vec3(0.86, 0.88, 0.92) * (0.6 + 1.4 * sheen);
    vec4 c = vec4(col * al, al);
    acc = over(acc, c);
  }
  return acc;
}

vec4 twinningWisp(vec3 o, vec3 d, vec4 a, vec4 b, float seed, float px,
                  float jit) {
  vec3 ax = b.xyz;
  vec3 u;
  vec3 v;
  frame(ax, seed * 6.2832, u, v);
  vec3 oc = o - a.xyz;
  float qb = dot(oc, d);
  float qc = dot(oc, oc) - a.w * a.w * 1.1;
  float disc = qb * qb - qc;
  if (disc <= 0.0) return vec4(0.0);
  float root = sqrt(disc);
  float t0 = -qb - root;
  float t1 = -qb + root;
  float dt = (t1 - t0) / 30.0;
  float freq = 1.0 / (a.w * 0.05);
  float sp = max(0.2 / freq, 0.6 * px);
  float e = 0.0;
  float T = 1.0;
  for (int i = 0; i < 30; i++) {
    float t = t0 + dt * (float(i) + jit);
    vec3 p = o + d * t;
    vec3 q = p - a.xyz;
    float s = dot(q, ax) / a.w;
    if (abs(s) > 1.0) continue;
    float th = s * 3.4 + seed * 6.0;
    vec2 lat = vec2(dot(q, u), dot(q, v)) / a.w;
    // The ribbon's centre wanders a little as it runs.
    lat -= vec2(sin(s * 2.3 + seed * 9.0), cos(s * 1.7 + seed * 4.0)) * 0.08;
    vec2 r = vec2(lat.x * cos(th) + lat.y * sin(th), -lat.x * sin(th) + lat.y * cos(th));
    float width = 0.17 * pow(max(1.0 - s * s, 0.0), 0.35);
    float streaks = 0.35 + 0.65 * pow(noise3(vec3(s * 2.0, r.x * 14.0, seed * 3.0)), 1.5);
    float ribbon = exp(-sq(r.y / 0.03)) * smoothstep(width, width * 0.4, abs(r.x)) *
                   streaks;
    if (ribbon < 0.01) continue;
    vec3 c = floor(p * freq);
    vec3 h = hash33(c + seed * 7.0);
    vec3 at = (c + 0.2 + 0.6 * h) / freq;
    float speck = h.x < 0.6 ? exp(-sq(length(p - at) / sp)) : 0.0;
    float haze = ribbon * (0.22 + 0.5 * fbm(vec3(s * 3.0, r * 6.0) + seed * 5.0));
    float ds = dt / a.w * 3.0;
    e += T * (haze * 0.7 + speck * ribbon * 5.0) * ds;
    T *= exp(-haze * ds * 0.8);
  }
  float al = clamp(1.0 - T + e * 0.1, 0.0, 0.95);
  return vec4(vec3(0.9, 0.91, 0.95) * e, al);
}

// A tunnel from the surface: mode 0 a natural etch channel (kinked,
// tapering, stained), 1 a laser drill hole (straight and even).
vec4 tunnel(vec3 o, vec3 d, vec4 a, vec4 b, vec4 s, float seed, float px,
            vec3 lk, float mode) {
  vec3 ax = b.xyz;
  vec3 u;
  vec3 v;
  frame(ax, seed * 6.2832, u, v);
  vec3 top = a.xyz + ax * a.w;
  vec3 bottom = a.xyz - ax * a.w;
  float r0 = mode > 0.5 ? max(0.0115, 0.8 * px) : a.w * 0.06;
  vec4 acc = vec4(0.0);
  float bestCover = 0.0;
  float bestT = 1e9;
  float bestGap = 0.0;
  float bestR = 1.0;
  float bestU = 0.0;
  // Etch channels follow kinks of the crystal; drill holes run true.
  for (int i = 0; i < 3; i++) {
    float f0 = float(i) / 3.0;
    float f1 = float(i + 1) / 3.0;
    vec3 k0 = vec3(0.0);
    vec3 k1 = vec3(0.0);
    if (mode < 0.5) {
      vec3 h0 = hash33(vec3(seed * 41.0, float(i), 1.0)) - 0.5;
      vec3 h1 = hash33(vec3(seed * 41.0, float(i + 1), 1.0)) - 0.5;
      k0 = i == 0 ? vec3(0.0) : (u * h0.x + v * h0.y) * a.w * 0.35;
      k1 = i == 2 ? (u * h1.x + v * h1.y) * a.w * 0.2 : (u * h1.x + v * h1.y) * a.w * 0.35;
    }
    vec3 p = mix(top, bottom, f0) + k0;
    vec3 q = mix(top, bottom, f1) + k1;
    float uu;
    float gap;
    float t = raySeg(o, d, p, q, uu, gap);
    float along = mix(f0, f1, uu);
    float r = mode > 0.5 ? r0 : r0 * (1.0 - 0.6 * along);
    float rr = max(r, 0.5 * px);
    float cover = smoothstep(rr + px * 0.9, rr - px * 0.3, gap) * min(1.0, r / (0.5 * px) + 0.25);
    if (cover > bestCover) {
      bestCover = cover;
      bestT = t;
      bestGap = gap;
      bestR = rr;
      bestU = along;
    }
  }
  if (bestCover > 0.001) {
    vec3 hp = o + d * bestT;
    if (dot(s.xyz, s.xyz) > 0.5 && dot(hp, s.xyz) - s.w > px) {
      bestCover = 0.0;
    } else {
      // Hollow: its walls, seen at a grazing angle, mirror bright; its
      // middle shows the tunnel's dim interior.
      float prof = clamp(bestGap / bestR, 0.0, 1.0);
      float walls = mix(0.35, 1.0, smoothstep(0.25, 0.9, prof));
      float fr = noise3(vec3(bestU * (mode > 0.5 ? 40.0 : 14.0), seed * 9.0, prof * 3.0));
      vec3 stain = mode > 0.5 ? vec3(0.95, 0.96, 1.0) : vec3(0.92, 0.8, 0.62);
      vec3 col = stain * walls * (0.55 + 0.45 * fr) * (0.75 + 0.5 * max(dot(-d, lk), 0.0));
      float al = bestCover * (0.75 + 0.2 * walls);
      acc = vec4(col * al, al);
    }
  }
  // The opening on the facet: a dark mouth inside a bright ring.
  if (dot(s.xyz, s.xyz) > 0.5) {
    float den = dot(d, s.xyz);
    if (abs(den) > 1e-4) {
      float t = (s.w - dot(o, s.xyz)) / den;
      float r = length(o + d * t - top);
      float rr = max(r0, 0.6 * px);
      float ring = exp(-sq((r - rr * 1.25) / (rr * 0.45 + px * 0.6)));
      float mouth = smoothstep(rr * 1.05, rr * 0.7, r);
      vec4 m = vec4(vec3(1.0) * ring * 0.85, max(ring * 0.85, mouth * 0.8));
      m.rgb += vec3(0.04) * mouth;
      acc = t < bestT ? over(m, acc) : over(acc, m);
    }
  }
  return acc;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float scale = uView.z;
  float d0 = uView.w;
  vec3 eye = toModel(vec3(0.0, 0.0, d0));
  vec3 dir = normalize(toModel(vec3((frag.x - uView.x) / scale,
                                    -(frag.y - uView.y) / scale, -d0)));
  float px = uMisc.w;
  vec3 lk = toModel(KEY_W);
  vec3 lf = toModel(FILL_W);
  // Per-pixel jitter for the marched kinds, so their steps never band.
  float jit = hash13(vec3(frag, 7.0));
  vec4 acc = vec4(0.0);
  for (int k = 0; k < MAX_INCL; k++) {
    if (float(k) >= uMisc.x) break;
    vec4 a = uIncl[k * 3];
    vec4 b = uIncl[k * 3 + 1];
    vec4 s = uIncl[k * 3 + 2];
    float kind = floor(b.w);
    float seed = fract(b.w);
    float reach = a.w * reachOf(kind);
    if (kind < 1.5) reach = max(reach, 4.0 * px);
    if (kind > 17.5 && kind < 18.5) reach += 0.02;
    reach += 2.0 * px;
    vec3 oc = eye - a.xyz;
    float bq = dot(oc, dir);
    float cq = dot(oc, oc) - reach * reach;
    if (bq * bq - cq <= 0.0) continue;
    // Flat tests, not an else-if chain: SkSL bounds nesting depth.
    int ki = int(kind + 0.5);
    vec4 c = vec4(0.0);
    if (ki == 1) c = pinpoint(eye, dir, a, seed, px);
    if (ki == 2) c = cloud(eye, dir, a, b, seed, px, lk, fract(jit + seed * 7.0));
    if (ki == 3) c = needles(eye, dir, a, b, seed, px, lk, lf);
    if (ki == 4) c = crystal(eye, dir, a, b, vec4(0.0), seed, px, lk, 0.0);
    if (ki == 5) c = darkCrystal(eye, dir, a, b, seed, px, lk);
    if (ki == 6) c = feather(eye, dir, a, b, s, seed, px, lk, lf, 0.0);
    if (ki == 7) c = feather(eye, dir, a, b, s, seed, px, lk, lf, 1.0);
    if (ki == 8) c = feather(eye, dir, a, b, s, seed, px, lk, lf, 2.0);
    if (ki == 9) {
      c = over(crystal(eye, dir, a, b, s, seed, px, lk, 1.0),
               dragLines(eye, dir, a, s, seed, px));
    }
    if (ki == 10) c = cavity(eye, dir, a, b, s, seed, px, lk, lf);
    if (ki == 11) c = scoop(eye, dir, a, b, s, seed, px, lk, lf, 0.0);
    if (ki == 12) c = bruise(eye, dir, a, b, s, seed, px, lk);
    if (ki == 13) c = bearding(eye, dir, a, b, s, seed, px, fract(jit + seed * 3.0));
    if (ki == 14) c = scoop(eye, dir, a, b, s, seed, px, lk, lf, 1.0);
    if (ki == 15) c = graining(eye, dir, a, b, seed, px, lk);
    if (ki == 16) c = twinningWisp(eye, dir, a, b, seed, px, fract(jit + seed * 5.0));
    if (ki == 17) c = tunnel(eye, dir, a, b, s, seed, px, lk, 0.0);
    if (ki == 18) c = tunnel(eye, dir, a, b, s, seed, px, lk, 1.0);
    if (ki == 19) c = crystal(eye, dir, a, b, vec4(0.0), seed, px, lk, 2.0);
    acc = over(c, acc);
  }
  // Tone: soft shoulder so bright glints stay white, never clip harshly.
  vec3 rgb = acc.rgb / (1.0 + max(acc.rgb - 0.8, 0.0) * 0.8);
  float alpha = clamp(acc.a, 0.0, 1.0);
  // Premultiplied; glints may glow a little past their own coverage.
  fragColor = vec4(min(rgb, vec3(alpha * 1.6 + 0.02)), alpha) * uMisc.z;
}
