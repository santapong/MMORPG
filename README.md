# Pixel Grinder

**A 2.5D voxel-pixel action RPG about hunting monsters, collecting gear, and
making that gear stronger.** The playable Godot 4 demo is one complete arcade
RPG loop: follow the gold pixel trail, clear the Slime Fields, claim a class
weapon, enhance it, and defeat the crowned Slime King.

> **Game loop:** HUNT SLIMES → LOOT GEAR → ENHANCE → DEFEAT THE BOSS

The presentation is intentionally pixel-first: block-built heroes, NPCs and
slimes; a fixed isometric-style action camera; checkerboard terrain; voxel
village props; a limited dusk palette; and hard-edged UI panels.

- See **[INSTALL.md](./INSTALL.md)** for installing Godot and running the project.
- See **[3D_CONVERSION_PLAN.md](./3D_CONVERSION_PLAN.md)** for the 2D→3D migration plan and art direction.
- See **[VERTICAL_SLICE_PLAN.md](./VERTICAL_SLICE_PLAN.md)** for the current finish line and acceptance checks.

## Playable slice: The Slime Crown

Create a Warrior, Mage, or Ranger, start the offline quest, and follow the
objective card:

1. Talk to Elder Gorn in Starter Village.
2. Defeat five slimes in Slime Fields.
3. Open the inventory and equip the rewarded Wooden Sword.
4. Enhance it to +1 with the supplied Black Stones and silver.
5. Defeat the Slime King in the glowing arena and return to Elder Gorn.

Quest state, inventory, equipment, enhancement, and completion persist with the
character save. This slice intentionally keeps networking and the broader MMO
roadmap out of the critical path.

## Quick Start

```bash
git clone https://github.com/santapong/MMORPG.git
godot --path MMORPG/godot_project/
```

Or open `godot_project/project.godot` in the Godot 4 editor and press **F5**.

Validate the full quest state machine without touching real saves:

```bash
mkdir -p /tmp/pixel-grinder-smoke-data
XDG_DATA_HOME=/tmp/pixel-grinder-smoke-data godot --headless \
  --path godot_project res://tests/vertical_slice_smoke.tscn
```

## Controls

| Key | Action |
|-----|--------|
| `W` `A` `S` `D` | Move |
| `Left Click` | Attack |
| `Space` | Class dodge / blink |
| `E` | Interact with NPCs |
| `I` | Toggle Inventory |
| `P` | Toggle Enhancement Panel |
| `G` | Toggle Grind Tracker |
| `M` | Toggle World Map |
| `1` `2` `3` `4` | Activate Skills |
| `Enter` | Focus Chat |

The objective card in the upper-right always shows the next slice action.

## What kind of game is it?

- **Genre:** short-form 2.5D pixel action RPG.
- **Goal:** complete the Slime Crown story quest and beat its boss.
- **Combat:** real-time attacks, three-hit class combos, four skills, and dodge.
- **Progression:** monster drops, class weapons, equipment, and enhancement.
- **Scope:** a complete offline vertical slice, not a live MMO service.

## Combat progression

- **Warrior:** short-range cleave combo and a guarded combat step.
- **Mage:** ranged arcane attacks and a fast blink.
- **Ranger:** the longest basic range and a generous evasive roll.
- Every class has four skills; fire, ice, lightning, and multishot skills now
  apply combat effects, while Shield Charge and Evasive Shot move the player.
- One Crowned Slime elite anchors the field encounter. Class quest rewards are
  enhancement-ready and carry a defensive, offensive, or mobility trait.

## Game Overview

### Classes
- **Warrior** — High HP/defense, melee combat, tanky builds
- **Mage** — High MP/spell damage, ranged magic, glass cannon
- **Ranger** — Balanced with high crit, fast movement, evasion

### Grinding Zones
| Zone | Level | Difficulty |
|------|-------|------------|
| Starter Village | 1 | Safe |
| Slime Fields | 1+ | Easy |
| Wolf Forest | 5+ | Easy |
| Bandit Camp | 10+ | Medium |
| Cursed Ruins | 20+ | Hard |
| Demon Rift | 35+ | Nightmare |

### Enhancement System
BDO-style gear enhancement from +0 to +20:
- **+1 to +15**: Standard enhancement using Black Stones
- **+16 to +20**: Forced enhancement (PRI/DUO/TRI/TET/PEN) with downgrade risk
- **Failstacks**: Failed attempts increase your next success rate
- **Cron Stones**: Prevent level downgrade on forced enhancement failure
- **Materials**: Black Stone (Weapon/Armor) for +1-15, Concentrated Black Stone for +16-20

### Equipment
- 7 slots: Weapon, Body, Helmet, Gloves, Boots, Ring, Necklace
- 5 grades: Common (gray), Uncommon (green), Rare (blue), Epic (purple), Legendary (orange)
- 40+ unique items with class restrictions and level requirements

### Save System
- **5 character slots** — Create up to 5 different characters with separate progress
- **Auto-save** — Game automatically saves every 60 seconds while playing
- **Save on exit** — Progress is saved when returning to the main menu
- **Character select screen** — Shows name, class, level, gear score, silver, and playtime per slot
- Save files stored in Godot's `user://saves/` directory as JSON

## Project Structure

```
godot_project/
  scripts/
    autoload/       Global managers (EventBus, GameManager, NetworkManager, SaveManager)
    combat/         Damage calculation and crit system
    class/          Class definitions and stats
    economy/        Silver currency manager
    equipment/      Enhancement system and equipment database
    enemies/        Enemy AI and behavior
    inventory/      Item management and stacking
    maps/           World and zone management
    npcs/           NPC interaction and dialog
    player/         Player controller
    skills/         Skill tree system and skill data
    ui/             All UI panels (HUD, inventory, enhancement, etc.)
    zones/          Zone data, mob stats, and drop tables
  scenes/           Godot scene files (.tscn)
```
