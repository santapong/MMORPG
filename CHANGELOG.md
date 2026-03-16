# Changelog

All notable changes to the Pixel Grinder MMORPG project.

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
