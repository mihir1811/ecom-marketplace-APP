#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// Deferred shading for the jewelry simulator
// (lib/features/jewelry_education/render/jewelry_renderer.dart).
//
// The CPU rasterises the piece into a G-buffer: per pixel the surface's
// view-space normal (red, green; blue is rebuilt facing the camera) and
// a material tag (blue) packing what it is with one shading detail:
//
//   0.00 – 0.19   the setting's metal (two-tone), ambient occlusion
//   0.21 – 0.40   metal, ambient occlusion
//   0.45 – 0.65   display velvet, ambient occlusion
//   0.70 – 1.00   small diamond facet, a per-facet seed
//
// This pass shades every pixel with interpolated normals, so highlights
// are crisp however coarse the mesh.
//
// Metal: physically based mirror reflection. Its colour is all in the
// Fresnel reflectance at normal incidence (F0, Schlick's approximation
// toward white at grazing angles), there is no diffuse term. Polish sets
// how sharply it mirrors a studio of soft boxes; rougher finishes blur
// the boxes and lean the reflection toward the surface normal.
//
// Small diamonds: too small to trace here, so each facet returns the
// light a pavilion would send back from its own direction in the studio
// (a fixed scramble per facet seed), split slightly into red, green and
// blue for fire, darkened where it would see the viewer's own head, plus
// the Fresnel surface reflection. As the piece turns, facets flash in
// turn just as melee does.
//
// Velvet: matte with a soft sheen at grazing angles.
//
// The studio is fixed in the world, so reflections slide over the metal
// as the camera orbits or the piece swings.

uniform vec4 uRect;    // G-buffer origin (local px), 1 / its size (local px)
uniform vec4 uCam;     // principal point x, y (local px), focal length (px), exposure
uniform vec4 uRot0;    // view → world rotation rows
uniform vec4 uRot1;
uniform vec4 uRot2;
uniform vec4 uMetal;   // F0 rgb (linear), roughness
uniform vec4 uGem;     // body tint rgb, sparkle strength
uniform vec4 uVelvet;  // base rgb (linear), sheen
uniform vec4 uMetal2;  // the setting's F0 rgb (linear), roughness
uniform sampler2D uG;

out vec4 fragColor;

float softBox(vec3 d, vec3 c, vec3 right, vec3 up, vec2 halfSize, float soft) {
  float t = dot(d, c);
  if (t <= 0.05) return 0.0;
  vec2 q = abs(vec2(dot(d, right), dot(d, up)) / t) - halfSize;
  return (1.0 - smoothstep(-soft, soft, q.x)) *
         (1.0 - smoothstep(-soft, soft, q.y)) *
         smoothstep(0.05, 0.3, t);
}

vec3 boxAt(vec3 d, vec3 c, vec2 halfSize, float soft) {
  vec3 r = normalize(cross(vec3(0.0, 1.0, 0.0), c));
  vec3 u = cross(c, r);
  return vec3(softBox(d, c, r, u, halfSize, soft));
}

// The jeweller's studio, world directions: a dim room, a big overhead
// box, a warm key strip at the left, a cool fill at the right, a rim
// strip behind and a low white card in front.
vec3 studio(vec3 d, float rough) {
  float soft = 0.02 + rough * 0.85;
  // A slightly warm room, as studios light gold.
  vec3 col = mix(vec3(0.010, 0.009, 0.009), vec3(0.09, 0.083, 0.075),
                 smoothstep(-0.6, 0.05, d.y));
  col = mix(col, vec3(0.28, 0.265, 0.25), smoothstep(0.05, 0.9, d.y));
  float spread = 1.0 / (1.0 + rough * 1.5);
  // Overhead: a wide box tipped toward the viewer.
  vec3 oc = normalize(vec3(0.0, 1.0, 0.32));
  col += vec3(4.2) * spread * softBox(d, oc, vec3(1.0, 0.0, 0.0),
                                      normalize(cross(oc, vec3(1.0, 0.0, 0.0))),
                                      vec2(0.8, 0.42), soft);
  col += vec3(3.3, 3.15, 2.95) * spread *
         boxAt(d, normalize(vec3(-0.82, 0.32, 0.48)), vec2(0.24, 0.8), soft);
  col += vec3(1.7, 1.8, 1.95) * spread *
         boxAt(d, normalize(vec3(0.85, 0.22, 0.42)), vec2(0.2, 0.7), soft);
  col += vec3(1.4) * spread *
         boxAt(d, normalize(vec3(0.15, 0.25, -1.0)), vec2(0.9, 0.1), soft);
  col += vec3(0.9) * spread *
         boxAt(d, normalize(vec3(0.0, -0.15, 1.0)), vec2(0.75, 0.12), soft);
  return col;
}

vec3 hash3(float s) {
  return fract(sin(vec3(s * 127.1, s * 311.7, s * 74.7)) * 43758.5453);
}

vec3 shadeMetal(vec3 n, vec3 v, float ao, vec4 metal) {
  float rough = metal.w;
  vec3 r = reflect(-v, n);
  float nv = clamp(dot(n, v), 0.0, 1.0);
  vec3 f0 = metal.rgb;
  vec3 fres = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
  vec3 sharp = studio(r, rough);
  vec3 broad = studio(normalize(mix(r, n, 0.55)), 1.0);
  vec3 c = fres * mix(sharp, broad, rough * 0.7);
  return c * mix(0.3, 1.0, ao);
}

vec3 shadeGem(vec3 n, vec3 v, float seed) {
  vec3 h = hash3(seed * 97.0 + 1.0) * 2.0 - 1.0;
  float nv = clamp(dot(n, v), 0.0, 1.0);
  vec3 r = reflect(-v, n);
  float fres = 0.17 + 0.83 * pow(1.0 - nv, 5.0);
  vec3 m = normalize(n + h * 0.9);
  vec3 di = reflect(-v, m);
  // A well cut stone returns light mostly from above.
  di = normalize(vec3(di.x, abs(di.y) * 0.75 + 0.25, di.z));
  vec3 disp = normalize(cross(di, n + vec3(1e-3))) * 0.07;
  vec3 col = vec3(studio(normalize(di - disp), 0.0).r,
                  studio(di, 0.0).g,
                  studio(normalize(di + disp), 0.0).b);
  col *= mix(0.2, 1.0, smoothstep(0.93, 0.75, dot(di, v)));
  return col * uGem.rgb * uGem.w + studio(r, 0.0) * fres;
}

vec3 shadeVelvet(vec3 n, vec3 v, float ao) {
  vec3 base = uVelvet.rgb;
  float key = max(dot(n, normalize(vec3(-0.45, 0.75, 0.5))), 0.0);
  float fill = n.y * 0.5 + 0.5;
  float nv = clamp(dot(n, v), 0.0, 1.0);
  float sheen = pow(1.0 - nv, 2.5);
  vec3 c = base * (0.2 + 0.8 * key + 0.25 * fill) +
           base * 2.4 * uVelvet.w * sheen * (0.35 + 0.65 * fill);
  return c * mix(0.25, 1.0, ao);
}

vec3 tone(vec3 x) {
  // ACES filmic fit, display gamma and a little S-curve, as the diamond
  // tracer uses, so the centre stone and its setting grade together.
  x *= uCam.w;
  vec3 y = clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
  vec3 g = pow(y, vec3(1.0 / 2.2));
  return g + 0.3 * (g * g * (3.0 - 2.0 * g) - g);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec4 g = texture(uG, (frag - uRect.xy) * uRect.zw);
  if (g.a < 0.004) {
    fragColor = vec4(0.0);
    return;
  }
  vec3 e = g.rgb / g.a;
  vec2 nxy = e.rg * 2.0 - 1.0;
  vec3 nv = normalize(vec3(nxy, sqrt(max(0.0, 1.0 - dot(nxy, nxy)))));
  vec3 vv = -normalize(vec3((frag.x - uCam.x) / uCam.z, -(frag.y - uCam.y) / uCam.z, -1.0));
  vec3 n = normalize(vec3(dot(uRot0.xyz, nv), dot(uRot1.xyz, nv), dot(uRot2.xyz, nv)));
  vec3 v = normalize(vec3(dot(uRot0.xyz, vv), dot(uRot1.xyz, vv), dot(uRot2.xyz, vv)));
  float tag = e.b;
  vec3 c;
  if (tag < 0.20) {
    c = shadeMetal(n, v, tag / 0.19, uMetal2);
  } else if (tag < 0.425) {
    c = shadeMetal(n, v, clamp((tag - 0.21) / 0.19, 0.0, 1.0), uMetal);
  } else if (tag < 0.675) {
    c = shadeVelvet(n, v, clamp((tag - 0.45) / 0.20, 0.0, 1.0));
  } else {
    c = shadeGem(n, v, (tag - 0.70) / 0.30);
  }
  fragColor = vec4(tone(c) * g.a, g.a);
}
