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
| Design options (all customisation) | `domain/jewelry_design.dart` (`HeadSpec` for heads), `domain/jewelry_metal.dart` |
| Mesh primitives, G-buffer tags | `geometry/jmesh.dart` (`JTag`, `MeshBuilder`) |
| Centre stone from a `DiamondSpec` | `geometry/jewelry_stone.dart` |
| Prongs (3/4/6/8, compass, double claw; round/claw/tab/V tips), galleries, bezel / half bezel, halo, hidden halo, milgrain | `scene/setting_builder.dart` |
| Shanks (straight, tapered, reverse, split, bypass, twisted) and band stones (half/¾/eternity in pavé, channel, shared prong, bezel), also hoops and bangles | `scene/band_kit.dart` (`Shank`, `BandStones`) |
| Chain styles, figaro pattern, clasps, stations, charms | `scene/scene_kit.dart` |
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
- Two-tone: the setting is tagged `JTag.head` (B 0.00–0.19), everything
  else `JTag.metal` (0.21–0.40); the shader shades each with its own F0
  (`uMetal2`). Always tag head metal `JTag.head`, so two-tone is a restyle.
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
- A holder that grips an axis carries the weight (`preload`): the rest pose
  must be an equilibrium, or a stud flops when tapped.
- Velvet foam is lossy: held axes use ζ ≈ 0.35–0.5 and a small `stick` dead
  band (hysteresis), never ζ ≈ 0.1 (reads as jelly). Free axes rub at the
  pivot: `mu` × weight × `arm` (wire radius) as Coulomb friction, so swings
  stop dead after a few passes instead of fading forever. `slipAngle` lets a
  held axis slide to a new rest (ring twisted in its slot).
- Chains/drops/tennis lines (`JRope`): XPBD, small fixed substeps (1/480 s),
  forward+backward constraint sweeps (more `passes` for heavy ends or big
  mass ratios), Coulomb position-based friction against velvet colliders.
  Never add random motion.
- Damping comes from friction, not air: `joint`/`chainJoints` add link-on-link
  Coulomb friction (moment μ·r·tension, `arm` = μ·wire radius), solved as
  iterated sequential impulses with an accumulated clamp (one local pass
  cannot stop a long hanging part). Friction-corrected velocities are written
  back to positions (except particles in contact) so static friction holds
  without creep. Keep `drag` ≈ 0.05–0.15 (air is negligible).
- Bend limits are hard one-sided stops (`minOnly`), never springs: a two-sided
  compliant second-neighbour link stores energy and bounces forever.
- A loop draped over a rod rocks rigidly (no joint bends): `rocking` adds the
  twisting friction of the links resting on the rod on that rigid mode.
- A tap = a fingertip (ball, ~22 px on screen) moving along the view ray:
  inelastic along the contact normal (the rigid mesh's normal; for a round
  chain particle, from where the fingertip meets it), skin friction μ 0.6
  sideways, capped spin near pivots. Drag on the piece = grab spring.
- `JPhysics.settle()` before the first frame; viewport sleeps when `!moving`
  (rigid 0.02 rad/s, particles 2.5 mm/s).

## Verify

- `flutter test test/features/jewelry_education` (period of a pendulum,
  joint friction stops a swing, tension = weight, studs do not sag, a ring
  settles within two rocks, taps move and return, every option builds
  finite and under 60k triangles).
- Tune feel with a throwaway probe test: tap each piece, print the contact
  point's displacement every 0.1 s and count zero crossings.
- Visual check without a device: a throwaway `testWidgets` that, inside
  `tester.runAsync`, loads `JewelryRenderer.loadProgram()` and
  `SimRenderer.loadProgram()`, paints a scene into a `PictureRecorder` and
  writes a PNG under `test/_tmp/` (flutter_tester cannot write to the temp
  scratchpad). View it, then delete `test/_tmp/`.
- Shader compile check: `impellerc.exe` in the Flutter SDK's
  `bin/cache/artifacts/engine/windows-x64/` with `--include=<that>/shader_lib`.
- New copy goes in `lib/core/l10n/translations/jewelry_education_messages.dart`
  in English, Hindi and Gujarati.
