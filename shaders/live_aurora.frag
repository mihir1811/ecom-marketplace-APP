#version 460 core

#include <flutter/runtime_effect.glsl>

// Live backdrop: near-black velvet with a slow champagne aurora drifting
// behind a soft ruby "on air" glow, fine light dust, vignette and grain.
// uEnergy (0..1) lifts the aurora while something is happening.

uniform vec2 uSize;
uniform float uTime;
uniform float uEnergy;

out vec4 fragColor;

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
    p = p * 2.03 + vec2(13.0, 5.0);
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float aspect = uSize.x / uSize.y;
  float t = uTime;

  vec3 col = mix(vec3(0.020, 0.019, 0.022), vec3(0.008, 0.008, 0.010), uv.y);

  // Aurora ribbons, strongest in the upper third.
  vec2 q = vec2(uv.x * aspect * 1.6, uv.y * 2.2);
  float w = fbm(q * 0.9 + vec2(t * 0.020, t * 0.012));
  float band = fbm(vec2(q.x + w * 1.8 - t * 0.03, q.y * 0.6 + w));
  float ribbon = smoothstep(0.42, 0.78, band) * smoothstep(0.85, 0.05, uv.y);
  vec3 champagne = vec3(0.86, 0.70, 0.44);
  vec3 bronze = vec3(0.36, 0.22, 0.12);
  col += mix(bronze, champagne, w) * ribbon * (0.16 + 0.10 * uEnergy);

  // Soft ruby glow top-left: "on air".
  vec2 r = vec2((uv.x - 0.12) * aspect, uv.y - 0.04);
  col += vec3(0.55, 0.06, 0.12) * exp(-dot(r, r) * 9.0) * 0.18;

  // Warm key light behind the content.
  vec2 k = vec2((uv.x - 0.6) * aspect, (uv.y - 0.28) * 1.3);
  col += vec3(0.90, 0.72, 0.48) * exp(-dot(k, k) * 3.5) * 0.05;

  // Light dust.
  float unit = uSize.y / 900.0;
  vec2 cell = frag / (22.0 * unit) + vec2(0.0, t * 0.15);
  vec2 g = floor(cell);
  float h = hash(g);
  if (h > 0.965) {
    vec2 f = fract(cell) - 0.5;
    float d = length(f - (vec2(hash(g + 1.3), hash(g + 2.9)) - 0.5) * 0.6);
    float tw = 0.5 + 0.5 * sin(t * (1.0 + h * 2.0) + h * 30.0);
    col += vec3(1.0, 0.92, 0.78) * smoothstep(0.08, 0.0, d) * tw * 0.35;
  }

  vec2 v = uv - 0.5;
  col *= 1.0 - dot(v, v) * 0.9;

  float grain = hash(floor(frag) + fract(t * 0.5) * 91.0) - 0.5;
  col += grain * 0.014;

  fragColor = vec4(max(col, vec3(0.0)), 1.0);
}
