---
name: jewelry-3d-simulation
description: Build, extend or debug the 3D jewelry simulator (lib/features/jewelry_education) and the diamond simulator handoff - procedural jewelry meshes, PBR metal shading, deferred G-buffer rendering in Flutter, traced centre stones, and real-physics touch interaction (XPBD chains, rigid pendulums). Use for any change to jewelry types, settings, metals, chains, physics feel or rendering quality.
---

# Jewelry 3D simulation

No 3D engine: Flutter `Canvas.drawVertices` + one fragment shader, with the
diamond simulator's own ray tracer for centre stones.

## Map

| Concern | File |
|---|---|
| Design options (all customisation) | `domain/jewelry_design.dart`, `domain/jewelry_metal.dart` |
| Mesh primitives, G-buffer tags | `geometry/jmesh.dart` (`JTag`, `MeshBuilder`) |
| Centre stone from a `DiamondSpec` | `geometry/jewelry_stone.dart` |
| Prongs / bezel / halo | `scene/setting_builder.dart` |
| One builder per piece | `scene/ring_scene.dart`, `earring_scene.dart`, `necklace_scene.dart`, `bracelet_scene.dart`, `pendant_builder.dart` |
| Physics | `physics/jewelry_physics.dart` |
| Renderer + camera | `render/jewelry_renderer.dart`, `render/jewelry_camera.dart`, `shaders/jewelry_shade.frag` |
| State, handoff from diamond sim | `application/jewelry_simulator_controller.dart` (`jewelryStoneHandoffProvider`) |
| UI | `presentation/` (simulator screen, education page, panels, viewport) |

Units: millimetres, grams, seconds; world y up, gravity 9810 mm/s².

## Rendering rules

- Per frame: transform → cull by screen winding (meshes wind CCW from outside;
  `MeshBuilder.tri` enforces it from normals) → radix-sort far to near →
  rasterise into a G-buffer image (RG = view normal, B = `JTag`, A = coverage)
  → `jewelry_shade.frag` shades metal / velvet / melee.
- Draw the whole piece in ONE G-buffer, then each traced stone, then re-draw
  only the triangles in front of that stone, clipped to its rect. Splitting the
  G-buffer by depth leaves seams.
- G-buffer `Paint.isAntiAlias = false` (AA mixes normals/tags across edges).
- Metal = Fresnel-Schlick on tinted F0 (no diffuse). Measured F0 (linear):
  gold (1.0, 0.77, 0.34), silver (0.97, 0.96, 0.92), platinum ≈ (0.67–0.71, …),
  copper (0.96, 0.64, 0.54); karat blends toward pale, rhodium ≈ 0.78 neutral.
  Roughness = finish (polished 0.06, satin 0.24, matte 0.42).
- Studio env is world-fixed so reflections slide when orbiting/swinging.
- Traced stones: `SimRenderer` takes tilt + spin; any orientation = those plus a
  canvas roll (`_paintStone`). Keep `SimRenderer.bounces` constant.
- Budget: keep scenes under ~50k triangles (link meshes are LOD'd; hidden back
  chain is a plain tube).

## Physics rules

- Rigid pieces held at a point (`JRigid`): Newton–Euler about the pivot, gravity
  at the centre of mass, per-axis torsion spring tuned by frequency + damping
  ratio (`JRigid.tuned`, gravity stiffness compensated). Free axes = pendulum.
- Chains/drops/tennis lines (`JRope`): XPBD, small fixed substeps (1/480 s),
  forward+backward constraint sweeps (more `passes` for heavy ends), Coulomb
  position-based friction against velvet colliders. Never add random motion.
- A tap = finger far heavier than the piece: contact point takes the finger's
  speed (`poke`), capped spin near pivots. Drag on the piece = grab spring.
- `JPhysics.settle()` before the first frame; viewport sleeps when `!moving`.

## Verify

- `flutter test test/features/jewelry_education` (period of a pendulum,
  settling, taps move and return, every variant builds finite).
- Visual check without a device: a throwaway `testWidgets` that, inside
  `tester.runAsync`, loads `JewelryRenderer.loadProgram()` and
  `SimRenderer.loadProgram()`, paints a scene into a `PictureRecorder` and
  writes a PNG under `test/_tmp/` (flutter_tester cannot write to the temp
  scratchpad). View it, then delete `test/_tmp/`.
- Shader compile check: `impellerc.exe` in the Flutter SDK's
  `bin/cache/artifacts/engine/windows-x64/` with `--include=<that>/shader_lib`.
- New copy goes in `lib/core/l10n/translations/jewelry_education_messages.dart`
  in English, Hindi and Gujarati.
