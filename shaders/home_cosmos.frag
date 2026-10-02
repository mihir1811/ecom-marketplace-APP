#version 460 core

#include <flutter/runtime_effect.glsl>

// Home hero deep space: domain-warped nebula, two parallax layers of
// twinkling far stars, a warm light behind the focal point, film grain.

uniform vec2 uSize;
uniform float uTime;
uniform float uFocusY;
uniform float uScroll;

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
    p = p * 2.03 + vec2(17.0, 9.0);
    a *= 0.5;
  }
  return v;
}

float starLayer(vec2 pos, float cell, float density, float t) {
  vec2 g = floor(pos / cell);
  vec2 f = fract(pos / cell) - 0.5;
  float h = hash(g);
  if (h < density) {
    return 0.0;
  }
  vec2 off = vec2(hash(g + 1.7), hash(g + 3.1)) - 0.5;
  float d = length(f - off * 0.7);
  float tw = 0.55 + 0.45 * sin(t * (0.8 + h * 2.5) + h * 40.0);
  return smoothstep(0.09, 0.0, d) * tw * (h - density) / (1.0 - density);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float aspect = uSize.x / uSize.y;
  float t = uTime;
  float unit = uSize.y / 900.0;

  vec3 col = mix(vec3(0.010, 0.014, 0.024), vec3(0.018, 0.024, 0.038), uv.y);

  vec2 q = vec2(uv.x * aspect, uv.y) * 2.4 + vec2(t * 0.010, -t * 0.006);
  float warp = fbm(q * 0.8 + vec2(t * 0.008, 0.0));
  float n = fbm(q + warp * 1.6);
  vec3 teal = vec3(0.035, 0.11, 0.16);
  vec3 violet = vec3(0.10, 0.055, 0.16);
  vec3 nebula = mix(teal, violet, smoothstep(0.35, 0.75, warp));
  col += nebula * pow(n, 2.2) * 0.95;

  vec2 k = vec2((uv.x - 0.5) * aspect, (uv.y - uFocusY) * 1.1);
  float key = exp(-dot(k, k) * 4.2);
  col += vec3(0.85, 0.66, 0.42) * key * 0.085;

  vec2 drift = vec2(0.0, uScroll * 60.0 * unit);
  float s = starLayer(frag + drift * 0.5, 15.0 * unit, 0.955, t);
  s += starLayer(frag + drift + vec2(31.0, 7.0), 31.0 * unit, 0.93, t * 0.7) * 1.4;
  col += vec3(0.80, 0.86, 1.0) * s * 0.75;

  vec2 v = uv - 0.5;
  col *= 1.0 - dot(v, v) * 0.75;

  float g = hash(floor(frag) + fract(t * 0.5) * 97.0) - 0.5;
  col += g * 0.012;

  col *= 1.0 - uScroll * 0.45;
  fragColor = vec4(max(col, vec3(0.0)), 1.0);
}
