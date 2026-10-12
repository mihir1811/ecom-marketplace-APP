#version 460 core

#include <flutter/runtime_effect.glsl>

// Auth backdrop: slow-moving silk folds lit by a warm key light behind the
// gem, a faint drift of light dust (dark only), vignette and film grain.
// uDark blends between the ivory (0) and noir (1) moods.

uniform vec2 uSize;
uniform float uTime;
uniform float uDark;
uniform vec2 uFocus;
uniform vec2 uPointer;

out vec4 fragColor;

// Sin-free hash: stable on mediump mobile GPUs.
float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
             u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 3; i++) {
    v += a * noise(p);
    p = p * 2.02 + vec2(11.0, 7.0);
    a *= 0.5;
  }
  return v;
}

float dust(vec2 pos, float cell, float t) {
  vec2 g = floor(pos / cell);
  vec2 f = fract(pos / cell) - 0.5;
  float h = hash(g);
  if (h < 0.965) {
    return 0.0;
  }
  vec2 off = vec2(hash(g + 1.7), hash(g + 3.1)) - 0.5;
  float d = length(f - off * 0.7);
  float tw = 0.5 + 0.5 * sin(t * (0.6 + h * 1.8) + h * 50.0);
  return smoothstep(0.08, 0.0, d) * tw;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float aspect = uSize.x / uSize.y;
  float t = uTime;
  float unit = uSize.y / 900.0;

  vec2 par = (uPointer - 0.5) * 0.06;
  vec2 p = vec2(uv.x * aspect, uv.y) + par;

  // Silk: domain-warped diagonal folds.
  float w = fbm(p * 1.4 + vec2(t * 0.025, -t * 0.018));
  float phase = p.x * 2.1 + p.y * 3.3 + w * 3.6 + t * 0.09;
  float folds = sin(phase);
  float body = 0.5 + 0.5 * folds;
  float sheen = pow(body, 7.0);
  float shade = pow(1.0 - body, 3.0);

  // Warm key light behind the focal point.
  vec2 k = vec2((uv.x - uFocus.x) * aspect, (uv.y - uFocus.y) * 1.15);
  float key = exp(-dot(k, k) * 4.5);

  vec3 warm = vec3(0.86, 0.71, 0.49);

  vec3 noir = mix(vec3(0.016, 0.015, 0.018), vec3(0.040, 0.036, 0.033), body * 0.7);
  noir += warm * (sheen * 0.055 + key * 0.15);
  float d = dust(frag + vec2(t * 4.0, -t * 9.0) * unit, 26.0 * unit, t);
  noir += vec3(0.95, 0.86, 0.70) * d * 0.55 * (0.35 + key);

  vec3 ivory = mix(vec3(0.930, 0.905, 0.862), vec3(0.975, 0.960, 0.932), body);
  ivory -= vec3(0.040, 0.044, 0.050) * shade;
  ivory += vec3(1.0, 0.95, 0.86) * (sheen * 0.035 + key * 0.06);

  vec3 col = mix(ivory, noir, uDark);

  vec2 v = uv - 0.5;
  col *= 1.0 - dot(v, v) * mix(0.28, 0.85, uDark);

  float g = hash(floor(frag) + fract(t * 0.5) * 97.0) - 0.5;
  col += g * mix(0.010, 0.014, uDark);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
