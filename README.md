# Pixel Grinder

A 2D top-down pixel grinding MMORPG inspired by Black Desert Online, built with Godot 4.

## How to Run

### Prerequisites

- **Godot Engine 4.2+** — Download from [godotengine.org](https://godotengine.org/download)
  - Use the **Standard** version (not .NET) since the project uses GDScript
  - Any platform (Windows, macOS, Linux) works

### Running from the Editor

1. Clone the repository:
   ```
   git clone https://github.com/santapong/MMORPG.git
   cd MMORPG
   ```

2. Open Godot Engine

3. Click **Import** and navigate to the `godot_project/` folder

4. Select `project.godot` and click **Import & Edit**

5. Press **F5** (or the Play button) to run the game

### Running from Command Line

```bash
# Run with Godot from the command line
godot --path godot_project/

# Or if Godot is not in your PATH, use the full path:
/path/to/Godot_v4.2 --path godot_project/
```

### Exporting a Standalone Build

1. In the Godot editor, go to **Project > Export**
2. Add an export preset for your target platform (Windows, Linux, macOS, Web)
3. Click **Export Project** and choose an output location
4. Run the exported executable — no Godot installation needed

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
