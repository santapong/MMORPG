# Changelog

All notable changes to the Pixel Grinder MMORPG project.

---

## [0.5.0] - 2026-03-16

### Added — Save System & Multiple Characters
- **5 character slots**: Create up to 5 separate characters with independent progress
- **Character select screen**: Shows character name, class, level, gear score, silver, and playtime per slot
- **Character creation flow**: Name input (max 16 chars) + class selection before entering the game
- **Delete character**: Remove saved characters from slot select screen
- **Auto-save**: Game state saved automatically every 60 seconds while in-game
- **Save on exit**: Auto-saves when returning to main menu
- **Full state serialization**: Saves player stats, level, class, equipment, enhancement levels, failstacks, enhancement history, inventory (all items and stacks), silver, skill tree, and world position
- **Pending state restoration**: Equipment, inventory, and position restored after world scene loads
- **SaveManager autoload**: New global manager registered in project.godot
- **Playtime tracking**: Accumulated play time tracked across sessions per character

### Changed
- Main menu now starts on character select screen instead of going directly to class/network options
- GameManager gained `reset_state()` for clean character initialization
- GameManager auto-saves current slot before returning to menu
- World scene applies saved state via deferred call after all systems initialize

### New Files
- `scripts/autoload/save_manager.gd` — Save/load/delete with 5 slots, auto-save timer, full serialization

---

## [0.4.0] - 2026-03-16

### Added — Full Enhancement System Overhaul
- **Material Requirements**: Black Stone (Weapon) for weapon/ring/necklace, Black Stone (Armor) for body/helmet/gloves/boots
- **Concentrated Black Stones**: Required for +16 to +20 enhancement, rare drops from Demon Soldier and Demon Lord
- **Material cost scaling**: 1 stone for +1-10, 2 for +11-15, 3 for +16-20
- **Cron Stones**: New downgrade protection material, cost scales by enhance level and gear grade
- **Cron Stone UI toggle**: "Use Cron Stones" checkbox in enhancement panel
- **Forced Enhancement names**: PRI (+16), DUO (+17), TRI (+18), TET (+19), PEN (+20)
- **Forced Enhancement downgrade**: Failed PRI-PEN drops level by 1 unless Cron protected
- **Advice of Valks**: Consumable item that sets failstacks to a fixed value (drops from Demon Lord)

### Added — Enhancement UI Overhaul
- Stats before/after preview with delta indicators on each enhancement attempt
- Grade color and grade name displayed on item names and slot buttons
- Enhancement history log showing last 10 attempts (success/fail/level/downgrade)
- Failstack recommendation guide with optimal ranges per enhancement level
- Material inventory count shown inline with red/green color coding
- Screen shake on success (gentle), failure (strong), and downgrade (heavy)
- Panel color flash feedback (green on success, red on failure)
- Enhancement glow colors on slot buttons (+5 green, +10 blue, +15 purple, +20 orange)

### Added — Weapon vs Armor Stat Differentiation
- Weapons: primarily attack + crit_chance per enhance level
- Body/Helmet: primarily defense + max_hp per enhance level
- Gloves: attack + crit_chance per enhance level
- Boots: defense + speed per enhance level
- Rings: attack + crit_chance per enhance level
- Necklaces: mixed attack + defense + crit_chance + max_hp per enhance level
- Grade multiplier applies to all enhancement stat gains

### Added — Equipment Comparison Panel
- Side-by-side comparison when equipping new gear (current vs new)
- Green/red stat delta indicators ("+5 ATK", "-3 DEF")
- "Equip" / "Cancel" confirmation with full stat preview
- Displays grade colors and forced enhancement tier names

### Added — New Drop Table Entries
- Lich now drops Black Stone (Armor) and Cron Stones
- Bone Golem now drops Black Stone (Armor)
- Demon Soldier drops Concentrated Black Stone (Weapon/Armor) and Cron Stones
- Hellhound drops Black Stone (Weapon/Armor) and Cron Stones
- Demon Lord drops Concentrated Black Stones, Cron Stones, and Advice of Valks

### Changed
- Equipment system now requires materials in addition to silver for enhancement
- Enhancement panel expanded from 300x350 to 380x560 with scrollable layout
- Inventory system gained `count_item()` and `has_item()` helper methods
- World scene now wires inventory to equipment system for material tracking

### New Files
- `scripts/ui/equipment_comparison_panel.gd` — Side-by-side gear comparison with stat deltas

---

## [0.3.0] - 2026-03-16

### Added — Skill Tree System
- 3 skill branches per class with 3 tiers each (9 skills per class, 27 total)
  - **Warrior**: Berserker (burst damage), Guardian (defense/survival), Warlord (AoE control)
  - **Mage**: Fire (single-target burst), Ice (AoE + defense), Lightning (chain multi-target)
  - **Ranger**: Marksmanship (crit/precision), Survival (evasion/heal), Trapping (AoE crowd control)
- Skills level 1–5 with per-level scaling on damage, cooldown, mana cost, AoE radius, and hit count
- 1 skill point earned per level, prerequisite chain for tier unlocking
- Passive skills: Eagle Eye, Iron Will, Arcane Mastery, Wind Walker
- Active buff skills: Berserker Rage, Fortify, Frost Armor, War Cry, Nature's Blessing

### Added — Equipment Grade & Database System
- 5 equipment grades: Common (gray), Uncommon (green), Rare (blue), Epic (purple), Legendary (orange)
- 40+ equipment items across 7 slots with grade-appropriate stat scaling
- Level requirements (1–35) and class restrictions on specialized gear
- 6 equipment stats: attack, defense, max_hp, max_mp, crit_chance, speed
- Negative stat tradeoffs on powerful gear (Demonic Blade: -20 HP, Heavy Plate: -speed)
- Grade-scaled enhancement bonuses (Legendary = 2x enhance value vs Common)
- Gear Score system for measuring total equipment power

### Changed
- GameManager now tracks skill points, passive bonuses, active buffs, and full equipment stats
- Player uses computed total stats (dodge chance, crit damage, spell damage multiplier, total speed)
- SkillSystem resolves effective skill stats from skill tree level data
- Combat crit system now supports variable crit damage multiplier
- Mana regen includes passive bonus from skill tree
- Player dodge chance from Ranger passive (Wind Walker)

### New Files
- `scripts/skills/skill_tree_data.gd` — Skill tree database and upgrade logic
- `scripts/equipment/equipment_data.gd` — Full equipment database with grades and stats

---

## [0.2.0] - 2026-03-15

### Added
- Map system with zone navigation and waypoints
- World map with 6 grinding zones (Starter Village through Demon Rift)
- Minimap and zone indicator UI

---

## [0.1.0] - 2026-03-15

### Added
- Initial BDO-inspired pixel grinding game systems
- 3 classes: Warrior, Mage, Ranger with unique skill sets (4 skills each)
- Leveling system with XP scaling (100 * level^1.5)
- BDO-style enhancement system (+1 to +20) with failstacks
- 7 equipment slots with basic enhancement bonuses
- Inventory system (20 slots, stacking, consumables)
- 14 enemy types across 6 zones with drop tables
- Silver economy with session tracking
- Combat system with crit strikes and damage variance
- ENet multiplayer networking
- Full UI: HUD, skill bar, enhancement panel, grind tracker, chat
- Event bus with 62 signals for decoupled communication
