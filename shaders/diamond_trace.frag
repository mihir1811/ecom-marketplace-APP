#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// Per-pixel diamond ray tracer for the education simulator. Mirrors
// SimTracer and SimStudio (lib/features/diamond_education/simulation):
// every pixel follows its own light path through the cut stone, so facet
// patterns are exact and crisp, with no interpolation between samples.
//
// Physics: Fresnel reflection at the surface, refraction in (Snell), total
// internal reflection past diamond's 24.4° critical angle, partial escape
// elsewhere, Beer–Lambert body colour, fluorescence and cloud scatter, and
// dispersion: every escape splits into red, green and blue at their own
// refractive index, which is where fire comes from.
//
// Lighting: a camera-fixed jeweller's studio. A light tent around the
// viewer, the viewer's own head straight behind the camera (the dark
// contrast pattern every real stone shows face up), rectangular soft
// boxes, and small intense spots that make the flashes and fire as the
// stone moves. Or a hearts & arrows scope: a dark viewing hole, a white
// disc around it and a red filter cone beyond, which turns the light
// returned by a precisely cut round into eight arrows face up and eight
// hearts face down.
//
// Clarity: inclusions are solid objects inside the stone that the light
// meets on its way, so the facets mirror and refract them just as they
// do in a real stone. Feathers are thin fractures that reflect like a
// mirror past the critical angle and show faint interference colours
// where they thin out, crystals are small octahedra (dark ones absorb,
// clear ones bend the light), clouds are hazy drifts of tiny points,
// needles thin bright rods and pinpoints single sparkling specks.
//
// Inclusion focus (uFocus): while a viewer studies the inclusions, the
// stone's own surface is toned down, its reflections dimmed and its facet
// pattern pulled toward an even glow, so what lies inside reads clearly
// through it. The inclusions themselves keep their full contrast.

const int MAX_PLANES = 140;
const int MAX_BOXES = 6;
const int MAX_SPOTS = 16;
const int MAX_BOUNCES = 12;
const int MAX_INCL = 12;
// Facet bounces plus inclusion hits along one path.
const int MAX_STEPS = 24;

const float IOR_R = 2.407;
const float IOR_G = 2.418;
const float IOR_B = 2.451;

uniform vec4 uView;    // centre x, centre y, px per model unit, eye distance
uniform vec4 uR0;      // model → world rotation rows
uniform vec4 uR1;
uniform vec4 uR2;
uniform vec4 uCounts;  // solid planes, all planes, bounces, exposure
uniform vec4 uRim;     // 1/a², 1/b², girdle threshold, room ambient
uniform vec4 uAbsorb;  // absorption rgb (with haze), scatter
uniform vec4 uEmit;    // emission rgb, ultraviolet flag
uniform vec4 uMisc;    // bounding radius, model units per traced px, traced px, lowest light
uniform vec4 uPlanes[MAX_PLANES];      // outward normal, offset
uniform vec4 uBoxes[MAX_BOXES * 3];  // centre; right axis + tan half width; rgb + tan half height
uniform vec4 uSpots[MAX_SPOTS * 2];  // dir + cos outer; rgb + 1/(cos inner − cos outer)
uniform vec4 uScope;   // hearts & arrows scope flag, inclusion count, scope hole, fold
uniform vec4 uIncl[MAX_INCL * 2];  // centre + size; axis + kind (whole part) and seed (fraction)
uniform vec4 uFocus;   // inclusion focus 0..1, the even level facets fade to
// Solid planes come down-facing first, then up-facing: x is where the
// up-facing ones start, y and z the largest horizontal part of any normal
// in each group (down, up). A ray steeper than that can leave through no
// plane of the group, so the group is skipped: the same picture, fewer
// tests.
uniform vec4 uSplit;

out vec4 fragColor;

vec3 toModel(vec3 w) {
  return w.x * uR0.xyz + w.y * uR1.xyz + w.z * uR2.xyz;
}

vec3 toWorld(vec3 m) {
  return vec3(dot(uR0.xyz, m), dot(uR1.xyz, m), dot(uR2.xyz, m));
}

// Hearts & arrows scope along world direction d: the viewing hole
// straight back (cosine of its edge in uScope.z), the white reflector
// around it, brightest toward the hole, then the red filter cone, deep at
// the sides and glowing toward the reflector, lit unevenly by the ring of
// lamps behind it, over a dim stage. Kept below the tone curve's knee so
// its shading survives instead of flattening into poster colours. Must
// match SimStudio.sample.
vec3 scope(vec3 d) {
  float z = d.z;
  float ring = 1.0 + 0.14 * cos(6.0 * atan(d.y, d.x + 1e-5));
  vec3 red = (vec3(0.92, 0.075, 0.095) * (0.25 + 0.75 * z * z) * ring +
              vec3(0.05, 0.018, 0.026)) * (0.93 + 0.07 * d.y);
  vec3 c = mix(vec3(0.025, 0.012, 0.014), red, smoothstep(0.0, 0.35, z));
  vec3 white = vec3(1.05, 0.97, 0.97) *
               (0.7 + 0.45 * smoothstep(0.87, uScope.z, z));
  c = mix(c, white, smoothstep(0.86, 0.9, z));
  return mix(c, vec3(0.01, 0.006, 0.007),
             smoothstep(uScope.z - 0.002, uScope.z + 0.006, z));
}

// Radiance of the studio along world direction d (x right, y up, z toward
// the viewer), or of the hearts & arrows scope with a few faint glints.
// Must match SimStudio.sample.
vec3 studio(vec3 d) {
  float y = d.y;
  float z = d.z;
  vec3 c;
  bool inScope = uScope.x > 0.5;
  if (inScope) {
    c = scope(d);
  } else {
    float room = y < 0.0 ? 0.02 + 0.04 * (1.0 + y)
                         : 0.06 + 0.22 * y * (2.0 - y);
    float tent = 0.4 * smoothstep(0.15, 0.55, z) *
                 (0.5 + 0.5 * smoothstep(-0.5, 0.4, y));
    float head = smoothstep(0.968, 0.986, z);
    c = vec3((room + tent) * (1.0 - 0.9 * head) * uRim.w);
    c += uEmit.w * vec3(0.004, 0.001, 0.012);
  }
  // Below every light only the room remains.
  if (y < uMisc.w) return c;
  for (int i = 0; i < MAX_BOXES; i++) {
    if (inScope) break;
    vec4 a = uBoxes[i * 3];
    vec4 b = uBoxes[i * 3 + 1];
    vec4 e = uBoxes[i * 3 + 2];
    float k = dot(d, a.xyz);
    if (k <= 0.2) continue;
    vec2 q = vec2(dot(d, b.xyz) / b.w, dot(d, cross(a.xyz, b.xyz)) / e.w) / k;
    float w = (1.0 - smoothstep(0.82, 1.0, abs(q.x))) *
              (1.0 - smoothstep(0.82, 1.0, abs(q.y))) *
              (1.0 - 0.25 * dot(q, q));
    c += max(w, 0.0) * e.rgb;
  }
  for (int i = 0; i < MAX_SPOTS; i++) {
    vec4 a = uSpots[i * 2];
    vec4 b = uSpots[i * 2 + 1];
    float w = clamp((dot(d, a.xyz) - a.w) * b.w, 0.0, 1.0);
    c += w * w * (3.0 - 2.0 * w) * b.rgb;
  }
  return c;
}

// Light the facets return, toned down under inclusion focus.
vec3 soften(vec3 c) {
  vec3 even = vec3(uFocus.y) + 0.24 * c / (1.0 + c);
  return mix(c, even, uFocus.x * 0.85);
}

float fresnel(float cosI, float cosT, float n1, float n2) {
  float s = (n1 * cosI - n2 * cosT) / (n1 * cosI + n2 * cosT);
  float p = (n2 * cosI - n1 * cosT) / (n2 * cosI + n1 * cosT);
  return (s * s + p * p) * 0.5;
}

// A folded stone (uScope.w = k > 0, see SimMesh.fold) is traced as one
// part between mirrors: its +x half for k = 1 (a heart), the wedge
// 0 <= atan2(x, z) <= pi/k for k >= 2 (a star, a lily), like a
// kaleidoscope. These are the mirrors, as planes n . p <= 0.
vec3 mirrorA() {
  return vec3(-1.0, 0.0, 0.0);
}

vec3 mirrorB() {
  float a = 3.14159265 / max(uScope.w, 1.0);
  return vec3(cos(a), 0.0, -sin(a));
}

// The traced part's frame: G turns world (x, z) into it, and back.
vec3 toPart(mat2 g, vec3 p) {
  vec2 q = g * p.xz;
  return vec3(q.x, p.y, q.y);
}

vec3 fromPart(mat2 g, vec3 p) {
  return vec3(dot(g[0], p.xz), p.y, dot(g[1], p.xz));
}

// Where the view ray (o, v) enters the traced solid: returns the distance
// and sets the entry facet's normal and the chord through it (negative on
// a miss, by how far). A folded stone's part is closed by its mirrors.
float enterHalf(vec3 o, vec3 v, out vec3 n, out float chord) {
  float tIn = -1e9;
  float tOut = 1e9;
  n = vec3(0.0, 1.0, 0.0);
  for (int i = 0; i < MAX_PLANES; i++) {
    if (float(i) >= uCounts.x) break;
    vec4 p = uPlanes[i];
    float den = dot(p.xyz, v);
    float num = p.w - dot(p.xyz, o);
    if (abs(den) < 1e-7) {
      if (num < 0.0) tOut = -1e9;
      continue;
    }
    float t = num / den;
    if (den < 0.0) {
      if (t > tIn) {
        tIn = t;
        n = p.xyz;
      }
    } else {
      tOut = min(tOut, t);
    }
  }
  // The girdle can only shorten a chord that leaves its inner ring: when
  // both ends lie inside it, its planes change nothing. Same picture.
  vec3 ea = o + v * tIn;
  vec3 eb = o + v * tOut;
  // A folded stone's part is closed by mirrors, not the girdle alone.
  bool inRing = uScope.w < 0.5 && tOut > tIn &&
                dot(ea.xz * ea.xz, uRim.xy) < uRim.z &&
                dot(eb.xz * eb.xz, uRim.xy) < uRim.z;
  for (int i = 0; i < MAX_PLANES; i++) {
    if (inRing || float(i) >= uCounts.y) break;
    if (float(i) < uCounts.x) continue;
    vec4 p = uPlanes[i];
    float den = dot(p.xyz, v);
    float num = p.w - dot(p.xyz, o);
    if (abs(den) < 1e-7) {
      if (num < 0.0) tOut = -1e9;
      continue;
    }
    float t = num / den;
    if (den < 0.0) {
      if (t > tIn) {
        tIn = t;
        n = p.xyz;
      }
    } else {
      tOut = min(tOut, t);
    }
  }
  for (int m = 0; m < 2; m++) {
    if (float(m) >= min(uScope.w, 2.0)) break;
    vec3 pn = m == 0 ? mirrorA() : mirrorB();
    float den = dot(pn, v);
    float num = -dot(pn, o);
    if (abs(den) < 1e-7) {
      if (num < 0.0) tOut = -1e9;
      continue;
    }
    float t = num / den;
    if (den < 0.0) {
      if (t > tIn) {
        tIn = t;
        n = pn;
      }
    } else {
      tOut = min(tOut, t);
    }
  }
  chord = tOut - tIn;
  return tIn;
}

// Where the view ray enters the stone. A folded stone is its traced part
// and that part's images, turned by 2 pi/k and mirrored; g is the frame
// of the image the ray enters (see toPart).
float enter(vec3 o, vec3 v, out vec3 n, out float chord, out mat2 g) {
  float t = 1e9;
  chord = -1e9;
  n = vec3(0.0, 1.0, 0.0);
  g = mat2(1.0);
  float k = max(uScope.w, 1.0);
  for (int e = 0; e < 12; e++) {
    if (float(e) >= (uScope.w > 0.5 ? 2.0 * k : 1.0)) break;
    float a = 6.2831853 * floor(float(e) * 0.5) / k;
    float c = cos(a);
    float s = sin(a);
    // Undo the turn, then the mirror on odd images.
    mat2 ge = mat2(c, s, -s, c);
    if (mod(float(e), 2.0) > 0.5) ge = mat2(-1.0, 0.0, 0.0, 1.0) * ge;
    vec3 ne;
    float ce;
    float te = enterHalf(toPart(ge, o), toPart(ge, v), ne, ce);
    if (ce > 0.0 && (chord <= 0.0 || te < t)) {
      t = te;
      n = fromPart(ge, ne);
      chord = ce;
      g = ge;
    } else if (chord <= 0.0) {
      chord = max(chord, ce);
    }
  }
  return t;
}

// One colour channel escaping at index ior; returns the light it carries
// out and leaves the reflected share in keep.
float escape(float ior, vec3 t, vec3 n, float c, float s1, float thr,
             vec3 mask, out float keep) {
  float s2 = ior * ior * s1;
  if (s2 >= 1.0) {
    keep = thr;
    return 0.0;
  }
  float cT = sqrt(1.0 - s2);
  float f = fresnel(c, cT, ior, 1.0);
  vec3 e = ior * t - (ior * c - cT) * n;
  keep = thr * f;
  return thr * (1.0 - f) * dot(soften(studio(toWorld(e))), mask);
}

float exitFresnel(float c, float s1, float ior) {
  float s2 = ior * ior * s1;
  if (s2 >= 1.0) return 1.0;
  return fresnel(c, sqrt(1.0 - s2), ior, 1.0);
}

float hash13(vec3 p) {
  p = fract(p * 0.1031);
  p += dot(p, p.zyx + 31.32);
  return fract((p.x + p.y) * p.z);
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

// Two unit vectors square to n and each other, turned by angle a.
void frame(vec3 n, float a, out vec3 u, out vec3 v) {
  vec3 u0 = normalize(cross(n, abs(n.y) < 0.9 ? vec3(0.0, 1.0, 0.0)
                                              : vec3(1.0, 0.0, 0.0)));
  vec3 v0 = cross(n, u0);
  u = u0 * cos(a) + v0 * sin(a);
  v = v0 * cos(a) - u0 * sin(a);
}

// Light an inclusion scatters back: the glow of the stone around it and
// a little of the room along d.
vec3 innerLight(vec3 d) {
  vec3 around = uScope.x > 0.5 ? vec3(0.42, 0.07, 0.08) : vec3(0.3 * uRim.w);
  return (around + uEmit.xyz * 4.0 + 0.1 * min(studio(toWorld(d)), vec3(3.0))) *
         (1.0 + 0.5 * uFocus.x);
}

// A crystal in its own frame: an octahedron with its corners cut by a
// cube (half width cut), the habit diamond's own inclusions grow in.
// Returns entry and exit distances along d and the outward normals there.
vec2 octa(vec3 o, vec3 d, float cut, out vec3 nIn, out vec3 nOut) {
  float tN = -1e9;
  float tF = 1e9;
  nIn = vec3(0.0, 1.0, 0.0);
  nOut = nIn;
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
    float t2 = (sg * w - num) / den;
    if (t1 > tN) {
      tN = t1;
      nIn = -sg * m;
    }
    if (t2 < tF) {
      tF = t2;
      nOut = sg * m;
    }
  }
  return vec2(tN, tF);
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

// How open a feather is at in-plane point q (units of its radius), 0
// where there is no crack: a lobed, broken outline with fine streaks
// along its edge and patches where it has healed.
float featherOpen(vec2 q, float seed) {
  float r = length(q);
  vec2 dir = q / max(r, 1e-5);
  float edge = 0.5 + 0.4 * noise3(vec3(dir * 1.7, seed * 37.0)) +
               0.15 * noise3(vec3(dir * 5.0, seed * 11.0));
  float rim = edge * (0.84 + 0.22 * noise3(vec3(dir * 24.0, seed * 5.0 + r * 2.0)));
  if (r > rim) return 0.0;
  float body = 0.6 * noise3(vec3(q * 4.0, seed * 23.0)) +
               0.4 * noise3(vec3(q * 13.0, seed * 3.0));
  if (body < 0.16 + 0.2 * r) return 0.0;
  return clamp((rim - r) / (0.45 * rim), 0.15, 1.0);
}

// Inside a small polished facet at in-plane point q (units of its
// radius): a hexagon, 1 inside and 0 beyond.
float facetOpen(vec2 q) {
  vec2 a = abs(q);
  return max(a.x * 0.866 + a.y * 0.5, a.y) < 0.9 ? 1.0 : 0.0;
}

vec3 shade(vec3 p, vec3 d, vec3 n, mat2 g) {
  float cosI = max(-dot(d, n), 1e-4);
  float cosT = sqrt(1.0 - (1.0 - cosI * cosI) / (IOR_G * IOR_G));
  float f0 = fresnel(cosI, cosT, 1.0, IOR_G);
  vec3 acc = f0 * (1.0 - 0.75 * uFocus.x) * studio(toWorld(reflect(d, n)));

  float eta = 1.0 / IOR_G;
  vec3 t = eta * d + (eta * cosI - cosT) * n;
  vec3 thr = vec3(1.0 - f0);

  int bounces = 0;
  int skip = -1;
  float px = uMisc.y;
  for (int it = 0; it < MAX_STEPS; it++) {
    if (float(bounces) >= uCounts.z) break;
    // Facet planes in the traced part's frame.
    vec3 q = toPart(g, p);
    vec3 tq = toPart(g, t);
    float tMin = 1e9;
    vec3 hn = vec3(0.0);
    // Heading up past every down-facing normal's tilt, or down past every
    // up-facing one's, the ray cannot leave through that group.
    bool noDown = tq.y > uSplit.y;
    float solidEnd = tq.y < -uSplit.z ? uSplit.x : uCounts.x;
    for (int i = 0; i < MAX_PLANES; i++) {
      if (float(i) >= solidEnd) break;
      if (noDown && float(i) < uSplit.x) continue;
      vec4 pl = uPlanes[i];
      float den = dot(tq, pl.xyz);
      if (den <= 1e-6) continue;
      float s = (pl.w - dot(q, pl.xyz)) / den;
      if (s < tMin) {
        tMin = s;
        hn = pl.xyz;
      }
    }
    // The girdle only matters where that point lies beyond its edge.
    vec3 h = q + tq * tMin;
    if (tMin > 1e8 || dot(h.xz * h.xz, uRim.xy) >= uRim.z) {
      for (int i = 0; i < MAX_PLANES; i++) {
        if (float(i) >= uCounts.y) break;
        if (float(i) < uCounts.x) continue;
        vec4 pl = uPlanes[i];
        float den = dot(tq, pl.xyz);
        if (den <= 1e-6) continue;
        float s = (pl.w - dot(q, pl.xyz)) / den;
        if (s < tMin) {
          tMin = s;
          hn = pl.xyz;
        }
      }
    }
    // Into the next image, if a mirror comes first.
    int crossing = -1;
    if (uScope.w > 0.5 && tq.x < -1e-6) {
      float s = -q.x / tq.x;
      if (s < tMin) {
        tMin = s;
        crossing = 0;
      }
    }
    if (uScope.w > 1.5) {
      vec3 mb = mirrorB();
      float den = dot(mb, tq);
      if (den > 1e-6) {
        float s = -dot(mb, q) / den;
        if (s < tMin) {
          tMin = s;
          crossing = 1;
        }
      }
    }
    if (tMin > 1e8) break;
    tMin = max(tMin, 0.0);
    hn = fromPart(g, hn);

    // The nearest inclusion this way, if it comes before the facet.
    float sEv = tMin;
    int ev = -1;
    float evW = 0.0;
    vec3 evN = vec3(0.0);
    // Its data; SkSL only indexes uniform arrays by loop counters.
    vec4 evA = vec4(0.0);
    vec4 evB = vec4(0.0);
    for (int k = 0; k < MAX_INCL; k++) {
      if (float(k) >= uScope.y) break;
      if (k == skip) continue;
      vec4 a = uIncl[k * 2];
      vec4 b = uIncl[k * 2 + 1];
      float kind = floor(b.w);
      if (kind > 4.5 && kind < 5.5) continue;  // clouds below
      vec3 oc = a.xyz - p;
      float along = dot(oc, t);
      float reach = a.w * (kind > 1.5 && kind < 3.5 ? 1.8 : 1.05) + 2.0 * px;
      vec3 perp = oc - t * along;
      if (dot(perp, perp) > reach * reach || along < -reach ||
          along > sEv + reach) continue;
      float seed = fract(b.w);
      if (kind < 1.5) {
        // Pinpoint: a speck, never thinner than a pixel.
        float s = clamp(along, 0.0, sEv);
        float rp = max(a.w, 0.7 * px);
        float w = (1.0 - smoothstep(0.35 * rp, rp, length(oc - t * s))) *
                  min(1.0, a.w * a.w / (rp * rp) * 1.6);
        if (w > 0.002 && s > 1e-4 && s < sEv) {
          sEv = s;
          ev = k;
          evW = w;
          evA = a;
          evB = b;
        }
      } else if (kind < 3.5) {
        vec3 u;
        vec3 ax;
        vec3 v;
        vec3 sc;
        crystalFrame(a, b, u, ax, v, sc);
        vec3 nIn;
        vec3 nOut;
        vec2 hit = octa(toLocal(-oc, u, ax, v, sc), toLocal(t, u, ax, v, sc),
                        0.62 + 0.25 * fract(seed * 3.7), nIn, nOut);
        if (hit.x < hit.y && hit.x > 1e-4 && hit.x < sEv) {
          sEv = hit.x;
          ev = k;
          evA = a;
          evB = b;
          evN = normalOut(nIn, u, ax, v, sc);
        }
      } else if (kind < 4.5 || kind > 6.5) {
        // Feather, open or glass-filled, or a small polished facet.
        float den = dot(t, b.xyz);
        if (abs(den) < 1e-5) continue;
        float s = dot(oc, b.xyz) / den;
        if (s < 1e-4 || s >= sEv) continue;
        vec3 u;
        vec3 v;
        frame(b.xyz, seed * 6.2832, u, v);
        vec3 q = p + t * s - a.xyz;
        vec2 fq = vec2(dot(q, u), dot(q, v)) / a.w;
        float open = kind > 7.5 ? facetOpen(fq) : featherOpen(fq, seed);
        if (open > 0.0) {
          sEv = s;
          ev = k;
          evW = open;
          evA = a;
          evB = b;
          evN = den < 0.0 ? b.xyz : -b.xyz;
        }
      } else {
        // Needle: a thin rod along b.xyz, a.w long either way.
        vec3 w0 = -oc;
        float bb = dot(t, b.xyz);
        float dd = dot(t, w0);
        float ee = dot(b.xyz, w0);
        float den = max(1.0 - bb * bb, 1e-5);
        float u = clamp((ee - bb * dd) / den, -a.w, a.w);
        float s = clamp(dot(a.xyz + b.xyz * u - p, t), 0.0, sEv);
        float dist = length(p + t * s - a.xyz - b.xyz * u);
        float rn = max(a.w * 0.04, 0.6 * px);
        float w = (1.0 - smoothstep(0.4 * rn, rn, dist)) *
                  min(1.0, a.w * 0.04 / rn * 1.4) *
                  (1.0 - smoothstep(0.6 * a.w, a.w, abs(u)));
        if (w > 0.002 && s > 1e-4 && s < sEv) {
          sEv = s;
          ev = k;
          evW = w;
          evA = a;
          evB = b;
        }
      }
    }

    // Clouds along the way: hazy drifts of points too small to resolve.
    for (int k = 0; k < MAX_INCL; k++) {
      if (float(k) >= uScope.y) break;
      vec4 b = uIncl[k * 2 + 1];
      if (floor(b.w) < 4.5 || floor(b.w) > 5.5) continue;
      vec4 a = uIncl[k * 2];
      float seed = fract(b.w);
      // Flattened across its axis.
      vec3 oc = (p - a.xyz) / a.w;
      vec3 o2 = oc + b.xyz * dot(oc, b.xyz) * 0.8;
      vec3 d2 = (t + b.xyz * dot(t, b.xyz) * 0.8) / a.w;
      float qa = dot(d2, d2);
      float qb = dot(o2, d2);
      float qc = dot(o2, o2) - 1.0;
      float disc = qb * qb - qa * qc;
      if (disc <= 0.0) continue;
      float root = sqrt(disc);
      float t0 = max((-qb - root) / qa, 0.0);
      float t1 = min((-qb + root) / qa, sEv);
      if (t1 <= t0) continue;
      float dens = 0.0;
      for (int j = 0; j < 3; j++) {
        vec3 x = (p + t * mix(t0, t1, (float(j) + 0.5) / 3.0) - a.xyz) / a.w;
        float ax = dot(x, b.xyz);
        float rr = dot(x, x) + 3.0 * ax * ax;
        float g = 0.55 * noise3(x * 3.5 + seed * 31.0) +
                  0.45 * noise3(x * 17.0 + seed * 7.0);
        dens += max(0.0, g - 0.25 - 0.5 * rr);
      }
      float tau = dens / 3.0 * (t1 - t0) / a.w * 4.5;
      acc += thr * (1.0 - exp(-tau)) * innerLight(t) * 1.3;
      thr *= exp(-0.6 * tau);
    }

    float seg = ev >= 0 ? sEv : tMin;
    p += t * seg;
    thr *= exp(-uAbsorb.xyz * seg);
    acc += uEmit.xyz * ((thr.r + thr.g + thr.b) / 3.0 * seg);
    acc += vec3(0.5, 0.5, 0.52) * (uAbsorb.w * seg * (thr.g + 0.2));

    if (ev >= 0) {
      vec4 a = evA;
      vec4 b = evB;
      float kind = floor(b.w);
      float seed = fract(b.w);
      skip = ev;
      if (kind < 1.5 || (kind > 5.5 && kind < 6.5)) {
        // Pinpoint or needle: light scattered back white, the rest on.
        acc += thr * evW * (innerLight(t) * 1.5 + vec3(0.15 * uRim.w));
        thr *= 1.0 - 0.8 * evW;
      } else if (kind < 2.5) {
        // Dark crystal (graphite, sulphide): absorbs, with a faint sheen.
        acc += thr * 0.02 * innerLight(t);
        t = reflect(t, evN);
        thr *= vec3(0.085, 0.08, 0.075);
        p += evN * 1e-4;
      } else if (kind < 3.5) {
        // Clear crystal (olivine, garnet, diamond's own kin): a lower
        // index than diamond, so its faces bend the light or mirror it.
        acc += thr * 0.04 * innerLight(t);
        float eta = IOR_G / 1.75;
        float c1 = -dot(t, evN);
        float k2 = 1.0 - eta * eta * (1.0 - c1 * c1);
        if (k2 < 0.0) {
          t = reflect(t, evN);
          p += evN * 1e-4;
        } else {
          vec3 tIn = eta * t + (eta * c1 - sqrt(k2)) * evN;
          thr *= 1.0 - fresnel(c1, sqrt(k2), IOR_G, 1.75);
          vec3 u;
          vec3 ax;
          vec3 v;
          vec3 sc;
          crystalFrame(a, b, u, ax, v, sc);
          vec3 nIn;
          vec3 nOut;
          vec3 o = p - evN * 1e-4;
          vec2 hit = octa(toLocal(o - a.xyz, u, ax, v, sc),
                          toLocal(tIn, u, ax, v, sc),
                          0.62 + 0.25 * fract(seed * 3.7), nIn, nOut);
          float len = max(hit.y, 0.0);
          vec3 no = normalOut(nOut, u, ax, v, sc);
          // Faint body colour: most colourless, some green or red.
          vec3 tint = seed < 0.7 ? vec3(0.4, 0.2, 0.5)
                    : seed < 0.88 ? vec3(1.5, 0.2, 1.6) : vec3(0.2, 2.2, 1.8);
          thr *= exp(-tint * len / a.w * 0.35);
          p = o + tIn * len + no * 1e-4;
          float eta2 = 1.75 / IOR_G;
          float c2 = dot(tIn, no);
          float k3 = 1.0 - eta2 * eta2 * (1.0 - c2 * c2);
          t = normalize(eta2 * tIn + (sqrt(max(k3, 0.0)) - eta2 * c2) * no);
        }
      } else {
        // Feather: a thin fracture. Past diamond's critical angle it
        // mirrors almost all the light; where it thins, light tunnels
        // through and thin-film colours show. Its broken faces frost it.
        float c1 = abs(dot(t, evN));
        float r = c1 < 0.906 ? 0.94 : 0.22;
        r *= mix(0.5, 1.0, evW);
        vec3 film = 0.5 + 0.5 * cos(6.2832 * (evW * 1.6 + seed +
                                                vec3(0.0, 0.33, 0.67)));
        vec3 tint = mix(film, vec3(1.0), 0.6 + 0.4 * evW);
        // Frosted, broken faces: a crack reads white against the stone.
        vec3 glow = vec3(0.8 + 1.1 * evW);
        if (kind > 7.5) {
          // A polished extra facet: a clean, flat mirror.
          r = 0.9;
          tint = vec3(1.0);
          glow = vec3(0.12);
        } else if (kind > 6.5) {
          // Glass-filled: the filling's index is close to diamond's, so
          // the crack mostly lets light through, but what it returns is
          // split into orange and electric blue flashes.
          float flash = c1 < 0.75 ? 1.0 : 0.35;
          vec3 hue = mix(vec3(1.0, 0.45, 0.08), vec3(0.15, 0.45, 1.0),
                         step(0.5, fract(seed * 5.0 + evW * 0.7)));
          r = 0.3;
          tint = mix(vec3(0.9), hue * 2.2, flash);
          glow = 1.3 * tint;
        }
        acc += thr * innerLight(t) * glow;
        if (r > 0.5) {
          thr *= r * tint;
          t = reflect(t, evN);
          p += evN * 1e-4;
        } else {
          acc += thr * r * tint * innerLight(reflect(t, evN));
          thr *= 1.0 - r;
        }
      }
      if (max(thr.r, max(thr.g, thr.b)) < 0.012) break;
      continue;
    }
    skip = -1;
    if (crossing >= 0) {
      // The ray carries on into the neighbouring image: the part's frame
      // there is this one mirrored in the mirror crossed.
      vec3 mn = crossing == 0 ? mirrorA() : mirrorB();
      g = mat2(1.0 - 2.0 * mn.x * mn.x, -2.0 * mn.x * mn.z,
               -2.0 * mn.x * mn.z, 1.0 - 2.0 * mn.z * mn.z) * g;
      continue;
    }
    bounces++;

    float c = dot(t, hn);
    float s1 = 1.0 - c * c;
    float s2G = IOR_G * IOR_G * s1;
    if (s2G < 0.5 || (uScope.x > 0.5 && s2G < 1.0)) {
      // Steep exit: the three colours leave almost together. In the
      // scope its diffuse light washes fire out, so they always do.
      float cG = sqrt(1.0 - s2G);
      vec3 e = IOR_G * t - (IOR_G * c - cG) * hn;
      vec3 env = soften(studio(toWorld(e)));
      vec3 f = vec3(exitFresnel(c, s1, IOR_R), fresnel(c, cG, IOR_G, 1.0),
                    exitFresnel(c, s1, IOR_B));
      acc += thr * (1.0 - f) * env;
      thr *= f;
    } else {
      float kR;
      float kG;
      float kB;
      acc.r += escape(IOR_R, t, hn, c, s1, thr.r, vec3(1.0, 0.0, 0.0), kR);
      acc.g += escape(IOR_G, t, hn, c, s1, thr.g, vec3(0.0, 1.0, 0.0), kG);
      acc.b += escape(IOR_B, t, hn, c, s1, thr.b, vec3(0.0, 0.0, 1.0), kB);
      thr = vec3(kR, kG, kB);
    }

    t -= 2.0 * c * hn;
    if (max(thr.r, max(thr.g, thr.b)) < 0.012) break;
  }
  // Whatever is still trapped returns as a faint average of the room.
  return acc + thr * 0.02;
}

vec3 rayAt(vec2 frag, vec3 eyeW) {
  vec2 u = (frag - uView.xy) / uView.z;
  return normalize(toModel(vec3(u.x, -u.y, 0.0) - eyeW));
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec3 eyeW = vec3(0.0, 0.0, uView.w);
  vec3 o = toModel(eyeW);
  vec3 v = rayAt(frag, eyeW);

  // Cheap reject outside the bounding sphere.
  float b = dot(o, v);
  float r = uMisc.x * 1.02;
  if (b * b - dot(o, o) + r * r < 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  vec3 n;
  float chord;
  mat2 g;
  float t = enter(o, v, n, chord, g);
  float cover = chord > 0.0 ? 1.0 : 0.0;

  // Along the silhouette, measure true pixel coverage with four
  // rotated-grid samples so the outline is smooth, never stair-stepped.
  if (abs(chord) < 6.0 * uMisc.y) {
    cover = 0.0;
    for (int k = 0; k < 4; k++) {
      float a = float(k) * 1.5707963 + 0.4636476;
      vec2 off = vec2(cos(a), sin(a)) * (0.395 * uMisc.z);
      vec3 vs = rayAt(frag + off, eyeW);
      vec3 ns;
      float cs;
      mat2 gs;
      float ts = enter(o, vs, ns, cs, gs);
      if (cs > 0.0) {
        cover += 0.25;
        if (chord <= 0.0) {
          v = vs;
          n = ns;
          t = ts;
          chord = cs;
          g = gs;
        }
      }
    }
  }
  if (cover <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  vec3 hdr = shade(o + v * t, v, n, g) * uCounts.w;
  // ACES filmic curve, display gamma, then a little S-curve: whites crisp,
  // contrast deep, as a stone looks in person rather than a flat grey.
  vec3 col = clamp((hdr * (2.51 * hdr + 0.03)) / (hdr * (2.43 * hdr + 0.59) + 0.14),
                   0.0, 1.0);
  col = pow(col, vec3(1.0 / 2.2));
  col = mix(col, col * col * (3.0 - 2.0 * col), 0.3);
  fragColor = vec4(col * cover, cover);
}
