#version 460 core
// Shades the scanned hand from its G-buffer: HandRenderer rasterises the
// mesh twice side by side into one image, the photographed skin (times
// baked occlusion, alpha = coverage × forearm fade) on the left and the
// hand-space normal map on the right. This pass lights it as skin under a
// soft studio key, fill and rim: wrapped, red-shifted diffuse for light
// scattered under the skin, two-lobe GGX for its oil layer.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec4 uSize;   // half width (px), height (px), gap (px), exposure
uniform vec4 uR0;     // hand → camera rotation rows
uniform vec4 uR1;
uniform vec4 uR2;
uniform vec4 uLook;   // ultraviolet 0/1, ring metal F0 (linear rgb)
uniform sampler2D uG;

out vec4 fragColor;

const float PI = 3.14159265;

vec3 toCamera(vec3 v) {
  return vec3(dot(uR0.xyz, v), dot(uR1.xyz, v), dot(uR2.xyz, v));
}

vec3 wrap(float x, vec3 w) {
  vec3 d = clamp((vec3(x) + w) / (1.0 + w), 0.0, 1.0);
  return d * d * (3.0 - 2.0 * d) * (1.0 + w * 0.35) / (1.0 + w);
}

float ggx(float nh, float a) {
  float a2 = a * a;
  float d = nh * nh * (a2 - 1.0) + 1.0;
  return a2 / (PI * d * d);
}

float specular(vec3 n, vec3 v, vec3 l, float f0) {
  vec3 h = normalize(v + l);
  float nl = max(dot(n, l), 0.0);
  float nv = max(dot(n, v), 0.08);
  float nh = max(dot(n, h), 0.0);
  float vh = max(dot(v, h), 0.0);
  float d = 0.62 * ggx(nh, 0.36 * 0.36) + 0.38 * ggx(nh, 0.62 * 0.62);
  float f = f0 + (1.0 - f0) * pow(1.0 - vh, 5.0);
  float k = 0.25;
  float g = nl / (nl * (1.0 - k) + k) * nv / (nv * (1.0 - k) + k);
  return d * f * g / (4.0 * nv + 1e-4);
}

vec3 aces(vec3 x) {
  return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void main() {
  vec2 px = FlutterFragCoord().xy;
  vec2 full = vec2(uSize.x * 2.0 + uSize.z, uSize.y);
  vec2 uvA = px / full;
  vec2 off = vec2(uSize.x + uSize.z, 0.0) / full;
  vec2 t = 0.5 / full;

  // A 2×2 box over the unsmoothed raster for soft silhouettes: coverage
  // from its average, colour and normal from its fullest tap.
  vec4 a = texture(uG, uvA);
  vec2 best = uvA;
  float bestA = a.a;
  vec4 sum = a;
  for (int i = 0; i < 4; i++) {
    vec2 o = vec2(i == 0 || i == 2 ? t.x : -t.x, i < 2 ? t.y : -t.y);
    vec4 s = texture(uG, uvA + o);
    sum += s;
    if (s.a > bestA) {
      bestA = s.a;
      best = uvA + o;
    }
  }
  sum *= 0.2;
  float cover = sum.a;
  if (cover <= 0.002) {
    fragColor = vec4(0.0);
    return;
  }
  vec4 bt = texture(uG, best);
  vec3 albedo = bt.rgb / max(bt.a, 1e-3);
  // Rings are drawn magenta in the albedo half: no skin is.
  bool metal = albedo.g < 0.1 && albedo.r > 0.8 && albedo.b > 0.8;
  vec3 nTex = texture(uG, best + off).rgb;
  vec3 n = normalize(toCamera(nTex * 2.0 - 1.0));
  vec3 v = vec3(0.0, 0.0, 1.0);

  // The photograph already holds some soft light; take most of it out of
  // the shadows so the studio light can shape the hand.
  vec3 lin = pow(albedo, vec3(2.2));
  float l = dot(lin, vec3(0.3, 0.55, 0.15));
  lin *= 0.92;

  bool uv = uLook.x > 0.5;
  vec3 lk = normalize(vec3(-0.45, 0.6, 0.66));
  vec3 lf = normalize(vec3(0.8, 0.05, 0.6));
  vec3 lr = normalize(vec3(0.4, 0.5, -0.77));
  vec3 cKey = uv ? vec3(0.32, 0.12, 0.95) * 0.9 : vec3(1.0, 0.955, 0.9) * 1.75;
  vec3 cFill = uv ? vec3(0.0) : vec3(0.78, 0.85, 1.0) * 0.32;
  vec3 cRim = uv ? vec3(0.1, 0.04, 0.3) : vec3(1.0, 0.93, 0.86) * 1.1;
  vec3 sky = uv ? vec3(0.03, 0.01, 0.08) : vec3(0.2, 0.21, 0.24);
  vec3 ground = uv ? vec3(0.0) : vec3(0.06, 0.05, 0.045);
  if (uv) lin *= 0.4;

  if (metal) {
    // Polished metal mirrors the studio: a dark floor, a bright ceiling,
    // the softboxes as broad highlights; Schlick-tinted by the alloy.
    vec3 r = reflect(-v, n);
    vec3 env = mix(vec3(0.025, 0.022, 0.02), vec3(1.15, 1.12, 1.08),
                   smoothstep(-0.25, 0.7, r.y));
    env *= 0.55 + 0.45 * smoothstep(-0.3, 0.9, r.z);
    env += cKey * 3.2 * smoothstep(0.82, 0.98, dot(r, lk));
    env += vec3(1.0, 0.97, 0.93) * 2.2 * smoothstep(0.8, 0.97, dot(r, lf));
    env += cRim * 2.6 * smoothstep(0.82, 0.97, dot(r, lr));
    env += vec3(0.9) * smoothstep(0.6, 0.97, dot(r, normalize(vec3(0.0, 0.2, 1.0))));
    // A dark card beside the key: polished metal needs something to
    // mirror besides light.
    env *= 1.0 - 0.7 * smoothstep(0.6, 0.9, dot(r, normalize(vec3(0.9, -0.1, 0.4))));
    float mv = max(dot(n, v), 0.0);
    vec3 f0 = uLook.yzw;
    vec3 f = f0 + (1.0 - f0) * pow(1.0 - mv, 5.0);
    vec3 m = f * env;
    if (uv) m = f * vec3(0.05, 0.03, 0.12) + vec3(0.02, 0.01, 0.06);
    m = aces(m * uSize.w);
    m = pow(m, vec3(1.0 / 2.2));
    fragColor = vec4(m * cover, cover);
    return;
  }

  vec3 wrapW = vec3(0.5, 0.22, 0.13);
  vec3 diff = cKey * wrap(dot(n, lk), wrapW) +
              cFill * wrap(dot(n, lf), wrapW) +
              cRim * wrap(dot(n, lr), wrapW) * 0.7;
  vec3 amb = mix(ground, sky, 0.5 + 0.5 * n.y);
  vec3 col = lin * (diff + amb);

  // Light through thin flesh at the silhouette: a warm glow from the rim.
  float nv = max(dot(n, v), 0.0);
  float edge = pow(1.0 - nv, 3.0);
  col += lin * vec3(1.0, 0.32, 0.16) * edge * (0.25 + 0.75 * max(dot(-n, lr), 0.0)) * cRim * 0.5;

  // The skin's oil layer, quieter where the photograph is dark (creases).
  float occ = clamp(l * 3.0, 0.35, 1.0);
  float spec = specular(n, v, lk, 0.028) + 0.5 * specular(n, v, lf, 0.028) +
               0.8 * specular(n, v, lr, 0.028);
  col += spec * occ * vec3(1.0, 0.97, 0.94) * (uv ? 0.1 : 0.55);
  float fr = 0.028 + 0.972 * pow(1.0 - nv, 5.0);
  col += fr * 0.3 * mix(ground, sky, 0.5 + 0.5 * reflect(-v, n).y) * occ;
  if (uv) col += lin * vec3(0.25, 0.32, 0.6) * 0.25;

  col = aces(col * uSize.w);
  col = pow(col, vec3(1.0 / 2.2));
  fragColor = vec4(col * cover, cover);
}
