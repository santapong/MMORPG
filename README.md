# Pixel Grinder

A 3D action MMORPG built with Godot 4 — **BDO** combat density meets
**Frieren** painterly aesthetic. Originally a 2D top-down pixel game,
currently being migrated to 3D on the
`claude/convert-2d-to-3d-game-Dt0C9` branch.

- See **[INSTALL.md](./INSTALL.md)** for installing Godot and running the project.
- See **[3D_CONVERSION_PLAN.md](./3D_CONVERSION_PLAN.md)** for the 2D→3D migration plan and art direction.

## Quick Start

```bash
git clone https://github.com/santapong/MMORPG.git
godot --path MMORPG/godot_project/
```

Or open `godot_project/project.godot` in the Godot 4 editor and press **F5**.

## Controls

| Key | Action |
|-----|--------|
| `W` `A` `S` `D` | Move |
| `Left Click` | Attack |
| `E` | Interact with NPCs |
| `I` | Toggle Inventory |
| `P` | Toggle Enhancement Panel |
| `G` | Toggle Grind Tracker |
| `M` | Toggle World Map |
| `1` `2` `3` `4` | Activate Skills |
| `Enter` | Focus Chat |

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
