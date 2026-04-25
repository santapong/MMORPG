# 3D Conversion Plan — BDO × Frieren

This document is the design and execution plan for converting **Pixel Grinder**
from a 2D top-down pixel game into a 3D action MMORPG with the gameplay feel
of **Black Desert Online (BDO)** and the visual identity of **Frieren: Beyond
Journey's End**.

The contrast is the identity, not a clash:

> **BDO combat density and enhancement drama, dressed in Frieren's painterly,
> contemplative palette.**

---

## 1. Vision

| Layer | Direction |
|---|---|
| Combat / systems | BDO — action combat, dodge i-frames, soft auto-target, +0→+20 enhancement, failstacks, Cron Stones, AP/DP gating, grind rotations |
| Visuals / world | Frieren — cel-shaded, soft pastel palette, painterly fog, peaceful villages, ancient forests, demon-era ruins |
| Camera | 3rd-person over-the-shoulder (`SpringArm3D`) — BDO action MMO standard |
| Tone | Combat zones noisy and saturated; towns slow, sheathed weapons, contemplative dialog camera |

### Cut list (out of scope for v1)

Life skills, sailing, horse breeding/taming, mounted combat, node wars,
housing, costume crafting, lifeskill XP. Keep the enhancement drama, grind
rotations, AP/DP gating, action combat, and over-shoulder camera.

---

## 2. Art Direction (Frieren palette)

| Biome | Notes | Palette |
|---|---|---|
| Forest | dappled light, broken obelisks, abandoned mage towers | sage `#8FA47A`, deep moss `#4F6B4A`, dusty teal shadow `#5C7A78` |
| Sky / golden hour | warm directional sun, low bloom | peach `#F4C9A0`, gold `#E8B872`, lavender dusk `#B8A7C9` |
| North / pilgrimage | aurora skybox, frozen passes | off-white `#EDEEF0`, pale blue `#C7D4DC`, distance pink `#E4D2D6` |
| Stone / ruins | weathered limestone, mossed grey | `#C9BFA8`, `#8C8A78` |
| Magic accents | Frieren-coded violets and cyans | `#C9B6E0`, `#A9D6D4` |

Avoid saturated reds/oranges except for combat VFX flashes — they should
spike during fights and fade back to muted baseline afterward.

### Cel-shading approach (Godot 4)

- **Material**: `ShaderMaterial` with 2–3 step ramp on `dot(N, L)`, sample a
  gradient texture for art-directable bands.
- **Outlines**: inverted-hull pass (back-face cull, scaled along normal, flat
  black) per character; for world geometry, use a `CanvasLayer` post-process
  edge-detection shader reading the depth + normal-roughness buffers
  (Godot 4.2+).
- **Lighting**: flat shadow zones, no specular except a soft Fresnel rim light
  in cyan or peach.
- **Addons** worth evaluating: Godot 4 Toon Shader (StayAtHomeDev), Cellule.

### Lighting (`WorldEnvironment`)

- `DirectionalLight3D` sun with day/night cycle (~20-min real time). Warm
  sunrise (`#FFB070`) → cool moonlight (`#6080A0`).
- Tonemap: `filmic`. Glow blend: `softlight`. Bloom intensity ~0.4. SSR on
  metallic armor for the BDO-trim look.
- **SDFGI** on Forward+ for soft global illumination. Low-radius, low-intensity
  SSAO for painterly contact shadows.
- Volumetric fog density 0.01–0.03 with high light scattering — produces the
  haze and god-rays through trees.

---

## 3. Combat & Camera

- `CharacterBody3D` for player + enemies; gravity applied manually:
  `velocity.y -= gravity * delta`.
- **Dodge**: 0.4 s, i-frames on frames 5–15, locked velocity vector during
  the roll.
- **Skills**: root-motion driven via `AnimationTree` state machine. Each skill
  is 2–4 animation chunks with cancel windows at 60–80% of the chunk.
- **Soft auto-target**: 30°/8 m raycast cone; on attack input, snap player
  rotation to nearest enemy. No hard tab-target.
- **Camera**: `Camera3D` child of `SpringArm3D` parented to the player pivot.
  Spring length 3.5 m, 0.8 m right-shoulder offset, FOV 65 idle / 75 in
  combat. Screen shake (0.15 s, 4 px) on heavy hits.

---

## 4. Codebase Audit — Punch List

Detailed audit of every 2D-specific dependency in
`/home/user/MMORPG/godot_project/`. Group by category, work top-down.

### 4.1 Project config

- `project.godot` lines 106–112: rename all `2d_physics/layer_*` →
  `3d_physics/layer_*` (Player, Enemies, NPCs, Walls, Projectiles).
- `rendering/renderer/rendering_method`: `gl_compatibility` →
  `forward_plus` (mobile fallback unchanged).

### 4.2 Gameplay scripts (CharacterBody2D → CharacterBody3D)

| File | Notes |
|---|---|
| `scripts/player/player.gd` | `extends CharacterBody2D`; uses `Vector2` velocity, `facing_direction`, 4-dir anim names, `Camera2D`, `move_and_slide()`. |
| `scripts/player/other_player.gd` | `Vector2` position interpolation, `global_position.lerp()`. |
| `scripts/enemies/enemy.gd` | `CharacterBody2D`, `Vector2` everywhere, `move_and_slide()` in 20+ places, `distance_to()` range checks, `spawn_position`, `wander_direction`. |
| `scripts/enemies/mini_enemy.gd` | `CharacterBody2D`, `Vector2` velocity, facing-direction TAU/angle math. |
| `scripts/npcs/npc.gd` | `CharacterBody2D`; lightweight, no physics, but still needs port. |
| `scripts/maps/world.gd` | `Node2D` parent; `Vector2(300, 300)` spawns; `Rect2` zone bounds; `ColorRect` ground. |

**Network sync** (`scripts/autoload/network_manager.gd`): position RPCs use
`Vector2`. Switch payloads to `Vector3` and audit all signal connections.

### 4.3 Math / type swaps

- `Vector2(x, y)` → `Vector3(x, 0, z)` for ground positions (Godot 3D is
  Y-up, ground = X/Z plane).
- `Transform2D` → `Transform3D`; rotation `float` → `Vector3` Euler or
  `Basis`/`Quaternion`.
- `look_at(target)`: 3D version is `look_at(target: Vector3, up = Vector3.UP)`
  — errors if target is collinear with `up`. Use `look_at_from_position()` for
  explicit origin. For ground heading: `atan2(z, x)`.
- `distance_to()` API is identical on `Vector3`.

### 4.4 Scenes (Sprite2D → Sprite3D billboard or `MeshInstance3D`)

| Scene | Action |
|---|---|
| `scenes/player/player.tscn` | Replace `Sprite2D` + `Camera2D` with skinned GLTF mesh (Mixamo-rigged) + `SpringArm3D` + `Camera3D`. Capsule `CollisionShape3D`. |
| `scenes/player/other_player.tscn` | Same model, network-driven transform. |
| `scenes/enemies/enemy.tscn` | All 16 mob types: Sprite3D billboard for v1 (cheap), upgrade to GLTF later. |
| `scenes/enemies/mini_enemy.tscn` | Sprite3D billboard, half scale. |
| `scenes/npcs/npc.tscn` | 3 NPCs (Elder Gorn, Merchant Lyra, Grind Guide Rex) — Sprite3D billboards or simple GLTF. |
| `scenes/maps/world.tscn` | Replace `ColorRect` ground with `MeshInstance3D` + `StaticBody3D`, or `Terrain3D` plugin. |

### 4.5 Collision shapes

- Bodies: `RectangleShape2D` (16×16) → `CapsuleShape3D` (height ~1.8 m,
  radius ~0.4 m) for humanoids, `BoxShape3D` for crates/walls.
- Attack `Area2D` + `CollisionShape2D` → `Area3D` + `CollisionShape3D`.
- NPC detection `CircleShape2D` (r=48) → `Area3D` + `SphereShape3D`
  (radius scaled — 1 unit ≈ 1 m).

### 4.6 UI (mostly stays — only one world-space file)

| File | Status |
|---|---|
| `scripts/ui/hud.gd`, `skill_bar.gd`, `inventory_panel.gd`, `chat_box.gd`, `dialog_box.gd`, `enhancement_panel.gd`, `waypoint_arrow.gd`, `minimap.gd`, `world_map.gd`, `zone_indicator.gd`, `grind_tracker.gd`, `equipment_comparison_panel.gd` | **KEEP AS-IS** — screen-space `CanvasLayer`, only reads `global_position`. |
| `scripts/ui/damage_numbers.gd` | **CONVERT** — spawns `Label` at `entity.global_position`; rework to `Label3D` or `Sprite3D` text on a `Marker3D`. |

Minimap and world-map continue to work — they consume world coordinates and
draw a 2D representation; just read the X/Z components of `Vector3`.

### 4.7 Animation

- `AnimationPlayer` API is unchanged; tracks now drive `Vector3`/`Quaternion`.
- Locomotion: `AnimationTree` with `AnimationNodeStateMachine` +
  `AnimationNodeBlendSpace2D` (idle / walk / run blended on velocity x/z).
- **Root motion**: set `AnimationTree.root_motion_track` to the skeleton root;
  per frame call `get_root_motion_position()` /
  `get_root_motion_rotation()` and feed into `CharacterBody3D.velocity`.

---

## 5. Execution Order

Work top-to-bottom — each step keeps the project runnable.

1. **Project settings** — flip renderer to `forward_plus`, rename physics
   layers to `3d_physics/*`.
2. **World scaffold** — replace `world.tscn` ground with a flat
   `MeshInstance3D` + `StaticBody3D`, add `WorldEnvironment` +
   `DirectionalLight3D`.
3. **Player** — port `player.gd` / `player.tscn` to `CharacterBody3D` +
   `SpringArm3D` camera. Use placeholder capsule mesh until the GLTF lands.
4. **Enemies** — port `enemy.gd` and one mob scene; verify combat /
   move_and_slide loop. Then duplicate to the remaining 15 mobs.
5. **NPCs** — port `npc.gd`; reuse Sprite3D billboards.
6. **Network sync** — switch RPC payloads from `Vector2` to `Vector3`; audit
   `network_manager.gd` and `other_player.gd`.
7. **Damage numbers** — convert to `Label3D` billboards.
8. **Cel-shader pass** — add toon `ShaderMaterial` to player + first mob.
9. **Frieren palette pass** — author `WorldEnvironment` colors, fog, sun.
10. **Skill anim chunks + cancel windows** — first skill end-to-end, then fan
    out.

**Total scope**: ~18 files (12 scripts + 6 scenes) plus `project.godot` and
new shaders. Realistic timeline: ~6 months for a 2-dev team if character
assets are bought or Mixamo-rigged.

---

## 6. References

- Godot 4 docs — Migrating from Godot 3 / 2D-to-3D conversion conventions
- BDO combat & enhancement systems — already partially implemented (see
  `scripts/equipment/equipment_system.gd`)
- *Frieren: Beyond Journey's End* — palette, lighting, character proportions
