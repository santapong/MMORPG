# Content Authoring Guide — Mobs, Zones, Abilities

This guide is for **using an AI assistant (Claude, etc.) to add new mobs, zones,
abilities, and biomes** to Pixel Grinder. The game's content layer is fully
data-driven — no new scenes or scripts are needed for typical content.

> Paste the section you need into your AI chat along with your design brief.
> The AI will read the schema, copy the structure, balance against the existing
> tables, and edit the right files.

---

## TL;DR — what to ask the AI

```
"Design a new <THEME> zone for level <LEVEL>, tier <TIER>,
with <N> mob types (<roles>). Drops should include <ITEMS>.
Read scripts/zones/zone_data.gd to match the existing balance,
then edit ZONES, MOB_STATS, MOB_DROPS, MOB_COLORS, and ZONE_BIOMES.
If any mob needs a signature ability, add it to enemy_abilities.gd."
```

That's enough. The AI will pick numbers consistent with neighboring zones.

---

## Files the AI edits

| File | What lives there |
|---|---|
| `scripts/zones/zone_data.gd` | `ZONES`, `MOB_STATS`, `MOB_DROPS`, `ZONE_BIOMES` |
| `scripts/enemies/enemy_abilities.gd` | `ABILITIES`, `MINI_MOB_STATS` |
| `scripts/enemies/enemy.gd` | `MOB_COLORS` (per-mob tint) |

**Nothing else needs touching** for a normal mob/zone. The world scene reads
all of the above at runtime in `scripts/maps/world.gd`.

---

## Schema cheatsheets

### Zone entry — `ZONES`

```gdscript
"frozen_pass": {
    "name": "Frozen Pass",
    "tier": ZoneTier.HARD,              # SAFE / EASY / MEDIUM / HARD / NIGHTMARE
    "recommended_level": 25,
    "bounds": Rect2(2000, 0, 800, 600), # x, y, width, height in pixel units
    "mobs": [
        {"id": "frost_wolf",     "name": "Frost Wolf",     "weight": 60},
        {"id": "ice_elemental",  "name": "Ice Elemental",  "weight": 40},
    ],
    "mob_count": 16,
    "respawn_time": 11.0,               # seconds
    "silver_per_mob": 800,
},
```

**`bounds` placement:** pick an empty Rect2 region. Existing zones span
`x: 0..2000, y: 0..1200`. New zones can extend beyond — the global ground is
200 m × 200 m (≈ 6000 × 6000 in pixel units after the `1/30` scale).

**`weight`** is relative; `60 + 40 = 100` means 60 % frost wolves, 40 %
elementals among `mob_count` spawns.

### Zone biome — `ZONE_BIOMES`

```gdscript
"frozen_pass": {
    "ground_color":  Color(0.85, 0.92, 0.95),   # icy white-blue
    "prop_type":     "tree",                    # see prop type catalog below
    "prop_count":    10,
    "prop_color":    Color(0.70, 0.85, 0.95),   # frosty branches
},
```

**Prop type catalog** (`scripts/maps/world.gd::_make_prop`):

| `prop_type` | Visual | Good for |
|---|---|---|
| `village` | wooden hut + cone roof | towns, safe zones |
| `slime_pool` | flat translucent disc | poison, swamp, slime |
| `tree` | trunk + foliage sphere | forest, meadow, frozen |
| `camp` | tent or crate (50/50) | bandit, encampment |
| `ruin` | tilted stone pillar | ruins, ancient, undead |
| `lava` | emissive disc + spike | demon, volcanic, hell |

**To add a new prop type:** extend `_make_prop` in `scripts/maps/world.gd` with
a new `match` arm building primitive meshes.

### Mob stats — `MOB_STATS`

```gdscript
"frost_wolf": {
    "hp": 180, "atk": 24, "def": 9,
    "speed": 95.0,        # px/s (1 px ≈ 1/30 m, so 95 px/s ≈ 3.17 m/s)
    "exp": 130,
    "detect": 240.0,      # aggro radius, px
},
```

**Balance reference (current tiers):**

| Tier (zone) | HP range | ATK range | DEF range | EXP | Silver/Mob |
|---|---|---|---|---|---|
| EASY (Slime Fields) | 40–90 | 4–8 | 1–3 | 20–45 | 50 |
| EASY (Wolf Forest) | 60–140 | 10–18 | 2–6 | 40–90 | 120 |
| MEDIUM (Bandit Camp) | 80–250 | 15–28 | 4–14 | 80–200 | 250 |
| HARD (Cursed Ruins) | 130–500 | 30–55 | 8–30 | 180–600 | 600 |
| NIGHTMARE (Demon Rift) | 250–1200 | 45–90 | 12–50 | 500–2000 | 1500 |

A "Hard" tier mob should land roughly inside the Cursed Ruins range; the AI
will interpolate.

### Mob drops — `MOB_DROPS`

```gdscript
"frost_wolf": [
    # Trash loot — auto-sold for silver on kill.
    {"id":"frost_pelt","name":"Frost Pelt","type":"trash_loot",
     "silver_value":300,"stackable":true,"quantity":1,"chance":0.7},

    # Rare drop — auto-sold but tracked in session stats.
    {"id":"alpha_frost_pelt","name":"Alpha Frost Pelt","type":"rare_drop",
     "silver_value":2500,"stackable":true,"quantity":1,"chance":0.05},

    # Equipment — goes into inventory if there's room.
    {"id":"frost_dagger","name":"Frost Dagger","type":"equipment",
     "slot":"weapon","attack":18,"defense":0,
     "stackable":false,"quantity":1,"chance":0.02},

    # Enhancement material — Black Stones, Cron, Concentrated.
    {"id":"enchant_armor_stone","name":"Black Stone (Armor)",
     "type":"enhancement_mat","stackable":true,"quantity":1,"chance":0.06},

    # Consumable — potions go into inventory.
    {"id":"mana_potion_l","name":"Large Mana Potion","type":"consumable",
     "effect":"mana","value":80,"stackable":true,"quantity":1,"chance":0.15},
],
```

**`type` is one of:** `trash_loot`, `rare_drop`, `equipment`, `enhancement_mat`,
`consumable`. The drop handler in `enemy.gd::_die` branches on this — picking
the wrong type makes the drop silently disappear.

**Drop rate guidance:**

| What | Chance |
|---|---|
| Common trash loot | 0.6 – 0.9 |
| Rare trash / minor consumable | 0.2 – 0.4 |
| Enhancement material (Black Stone) | 0.04 – 0.08 |
| Concentrated Black Stone / Cron | 0.02 – 0.05 |
| Equipment piece | 0.02 – 0.05 |
| Rare drop (Alpha Fang etc.) | 0.03 – 0.10 |
| Legendary boss drop | 0.01 – 0.02 |

### Mob color — `MOB_COLORS` (in `scripts/enemies/enemy.gd`)

```gdscript
"frost_wolf": Color(0.80, 0.90, 0.95),
```

Used to tint the placeholder sphere mesh and re-applied after flashes / buffs.
Any RGB is fine; alpha is ignored for non-spirit mobs.

### Special ability — `ABILITIES` (in `scripts/enemies/enemy_abilities.gd`)

```gdscript
"frost_wolf": {
    "name": "Frost Lunge",
    "type": "lunge_bite",
    "cooldown": 4.0,
    "dash_speed": 340.0,
    "dash_duration": 0.25,
    "damage_mult": 2.0,
},
```

**Ability types currently implemented:**

| `type` | Effect | Key fields |
|---|---|---|
| `lunge_bite` | Dash toward target, hit on arrival | `dash_speed`, `dash_duration`, `damage_mult`, `cooldown` |
| `ranged` | Hit target from distance, no projectile mesh yet | `range`, `damage_mult`, `projectile_count`, `cooldown` |
| `aoe` | Damage all players in radius | `aoe_radius`, `damage_mult`, `cooldown` |
| `drain` | Damage + heal self for % of damage | `range`, `damage_mult`, `heal_percent`, `cooldown` |
| `teleport` | Blink toward target | `teleport_range`, `cooldown` |
| `knockback` | Damage + push target | `damage_mult`, `knockback_force`, `cooldown` |
| `buff_allies` | Buff nearby mobs (speed + atk) | `buff_radius`, `buff_speed_mult`, `buff_atk_mult`, `buff_duration`, `cooldown` |
| `split` | Spawn mini-mobs (on death or on cast) | `split_count`, `split_mob`, `split_lifetime`, `trigger: "on_death"` or `"on_ability"`, `cooldown` |

**Adding a NEW ability type** requires code, not just data:
1. Add a `match` arm in `enemy.gd::_try_use_ability`.
2. Add a handler method (e.g. `_do_freeze()`).
3. Document it here.

### Mini-mob (for `split` abilities) — `MINI_MOB_STATS`

```gdscript
"mini_frost_wolf": {
    "name": "Frost Pup",
    "hp": 40, "atk": 12, "def": 3, "speed": 75.0,
    "color": Color(0.85, 0.95, 1.0, 0.8),
    "scale": Vector2(0.5, 0.5),  # used by mini_enemy.gd
},
```

---

## Drop-in AI prompts

Copy-paste these to Claude / Cursor / your agent of choice.

### Add a new mob to an existing zone

```
Add a new mob "<name>" to the <zone_id> zone in
scripts/zones/zone_data.gd. Theme: <theme>. Role: <tank/ranged/fast/buffer>.

Tier balance: match the rest of <zone_id> — read MOB_STATS for the existing
mobs in that zone to pick HP/ATK/DEF/EXP in range.

Drops: 1 themed trash_loot (silver value matches zone tier), 1 rare drop,
and a 4–8% chance for the zone's appropriate Black Stone material.

If the mob has a signature ability, add an entry to
scripts/enemies/enemy_abilities.gd. Otherwise leave abilities empty.

Add a color in MOB_COLORS in scripts/enemies/enemy.gd that fits the theme.

Finally, add it to the <zone_id> mobs array with an appropriate weight.
```

### Add a new zone

```
Add a new zone "<zone_id>" to scripts/zones/zone_data.gd:
- Name: <name>
- Tier: <SAFE / EASY / MEDIUM / HARD / NIGHTMARE>
- Recommended level: <N>
- Theme: <theme — frost, sky, undertow, sky temple, etc.>
- 3–4 new mob types (mix of roles)
- bounds: pick an empty Rect2 (existing zones occupy x:0..2000, y:0..1200)

Also:
- Add MOB_STATS, MOB_DROPS, and MOB_COLORS entries for each new mob.
- Add an entry to ZONE_BIOMES with ground_color, prop_type (from the
  catalog), prop_count (6–14), and prop_color.
- Give 1 of the mobs a signature ability if the theme calls for it.

Balance against existing tiers — read the table at the top of
docs/CONTENT_AUTHORING.md for HP/ATK/DEF/EXP ranges per tier.
```

### Add a new biome prop type

```
Add a new prop_type "<name>" to scripts/maps/world.gd::_make_prop.
Theme: <theme>. Should be primitive-mesh-only (no asset imports).

Use BoxMesh, CylinderMesh, SphereMesh, and StandardMaterial3D.
Follow the existing arms (village, tree, ruin, lava) as a template.

Then document the new prop_type in the table in
docs/CONTENT_AUTHORING.md.
```

### Add a new ability type

```
Add a new ability type "<name>" in scripts/enemies/enemy_abilities.gd
and wire it up in scripts/enemies/enemy.gd::_try_use_ability:

Behavior: <description>
Key fields: <list>

Follow the existing patterns (lunge_bite, ranged, aoe, drain).
Update the ability table in docs/CONTENT_AUTHORING.md.

Then assign the new ability to one or two existing mobs that fit the theme.
```

---

## Sanity-check after AI edits

After the AI edits, before launching, eyeball:

1. **All `mob_ids` referenced in `ZONES.mobs` exist in `MOB_STATS`** —
   missing IDs spawn a default slime.
2. **All `mob_ids` in `MOB_STATS` have a `MOB_COLORS` entry** in
   `enemy.gd` — missing colors fall back to red.
3. **All drop `type` values are one of:** `trash_loot`, `rare_drop`,
   `equipment`, `enhancement_mat`, `consumable`. Typos are silent.
4. **`bounds` Rect2 doesn't overlap an existing zone** unless intentional
   (overlapping zones means mobs from both zones spawn in the overlap).
5. **`weight` values in `mobs` arrays sum to anything > 0** — used as
   relative probability.

A quick way: run `godot --headless --path godot_project/ --quit` after the
edits — Godot reports any parse errors without launching the game.
