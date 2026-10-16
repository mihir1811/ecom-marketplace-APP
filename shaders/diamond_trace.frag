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
// stone moves.

const int MAX_PLANES = 140;
const int MAX_BOXES = 6;
const int MAX_SPOTS = 16;
const int MAX_BOUNCES = 12;

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

out vec4 fragColor;

vec3 toModel(vec3 w) {
  return w.x * uR0.xyz + w.y * uR1.xyz + w.z * uR2.xyz;
}

vec3 toWorld(vec3 m) {
  return vec3(dot(uR0.xyz, m), dot(uR1.xyz, m), dot(uR2.xyz, m));
}

// Radiance of the studio along world direction d (x right, y up, z toward
// the viewer). Must match SimStudio.sample.
vec3 studio(vec3 d) {
  float y = d.y;
  float z = d.z;
  float room = y < 0.0 ? 0.02 + 0.04 * (1.0 + y) : 0.06 + 0.22 * y * (2.0 - y);
  float tent = 0.4 * smoothstep(0.15, 0.55, z) *
               (0.5 + 0.5 * smoothstep(-0.5, 0.4, y));
  float head = smoothstep(0.968, 0.986, z);
  vec3 c = vec3((room + tent) * (1.0 - 0.9 * head) * uRim.w);
  c += uEmit.w * vec3(0.004, 0.001, 0.012);
  // Below every light only the room remains.
  if (y < uMisc.w) return c;
  for (int i = 0; i < MAX_BOXES; i++) {
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

float fresnel(float cosI, float cosT, float n1, float n2) {
  float s = (n1 * cosI - n2 * cosT) / (n1 * cosI + n2 * cosT);
  float p = (n2 * cosI - n1 * cosT) / (n2 * cosI + n1 * cosT);
  return (s * s + p * p) * 0.5;
}

// Where the view ray (o, v) enters the stone: returns the distance and
// sets the entry facet's normal and the chord through the stone (negative
// on a miss, by how far).
float enter(vec3 o, vec3 v, out vec3 n, out float chord) {
  float tIn = -1e9;
  float tOut = 1e9;
  n = vec3(0.0, 1.0, 0.0);
  for (int i = 0; i < MAX_PLANES; i++) {
    if (float(i) >= uCounts.y) break;
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
  chord = tOut - tIn;
  return tIn;
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
  return thr * (1.0 - f) * dot(studio(toWorld(e)), mask);
}

float exitFresnel(float c, float s1, float ior) {
  float s2 = ior * ior * s1;
  if (s2 >= 1.0) return 1.0;
  return fresnel(c, sqrt(1.0 - s2), ior, 1.0);
}

vec3 shade(vec3 p, vec3 d, vec3 n) {
  float cosI = max(-dot(d, n), 1e-4);
  float cosT = sqrt(1.0 - (1.0 - cosI * cosI) / (IOR_G * IOR_G));
  float f0 = fresnel(cosI, cosT, 1.0, IOR_G);
  vec3 acc = f0 * studio(toWorld(reflect(d, n)));

  float eta = 1.0 / IOR_G;
  vec3 t = eta * d + (eta * cosI - cosT) * n;
  vec3 thr = vec3(1.0 - f0);

  for (int b = 0; b < MAX_BOUNCES; b++) {
    if (float(b) >= uCounts.z) break;
    float tMin = 1e9;
    vec3 hn = vec3(0.0);
    for (int i = 0; i < MAX_PLANES; i++) {
      if (float(i) >= uCounts.x) break;
      vec4 pl = uPlanes[i];
      float den = dot(t, pl.xyz);
      if (den <= 1e-6) continue;
      float s = (pl.w - dot(p, pl.xyz)) / den;
      if (s < tMin) {
        tMin = s;
        hn = pl.xyz;
      }
    }
    // The girdle only matters where that point lies beyond its edge.
    vec3 h = p + t * tMin;
    if (tMin > 1e8 || dot(h.xz * h.xz, uRim.xy) >= uRim.z) {
      for (int i = 0; i < MAX_PLANES; i++) {
        if (float(i) >= uCounts.y) break;
        if (float(i) < uCounts.x) continue;
        vec4 pl = uPlanes[i];
        float den = dot(t, pl.xyz);
        if (den <= 1e-6) continue;
        float s = (pl.w - dot(p, pl.xyz)) / den;
        if (s < tMin) {
          tMin = s;
          hn = pl.xyz;
        }
      }
    }
    if (tMin > 1e8) break;
    tMin = max(tMin, 0.0);
    p += t * tMin;

    thr *= exp(-uAbsorb.xyz * tMin);
    acc += uEmit.xyz * ((thr.r + thr.g + thr.b) / 3.0 * tMin);
    acc += vec3(0.5, 0.5, 0.52) * (uAbsorb.w * tMin * (thr.g + 0.2));

    float c = dot(t, hn);
    float s1 = 1.0 - c * c;
    float s2G = IOR_G * IOR_G * s1;
    if (s2G < 0.5) {
      // Steep exit: the three colours leave almost together.
      float cG = sqrt(1.0 - s2G);
      vec3 e = IOR_G * t - (IOR_G * c - cG) * hn;
      vec3 env = studio(toWorld(e));
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
  float t = enter(o, v, n, chord);
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
      float ts = enter(o, vs, ns, cs);
      if (cs > 0.0) {
        cover += 0.25;
        if (chord <= 0.0) {
          v = vs;
          n = ns;
          t = ts;
          chord = cs;
        }
      }
    }
  }
  if (cover <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  vec3 hdr = shade(o + v * t, v, n) * uCounts.w;
  // ACES filmic curve, display gamma, then a little S-curve: whites crisp,
  // contrast deep, as a stone looks in person rather than a flat grey.
  vec3 col = clamp((hdr * (2.51 * hdr + 0.03)) / (hdr * (2.43 * hdr + 0.59) + 0.14),
                   0.0, 1.0);
  col = pow(col, vec3(1.0 / 2.2));
  col = mix(col, col * col * (3.0 - 2.0 * col), 0.3);
  fragColor = vec4(col * cover, cover);
}
