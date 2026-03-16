extends Node
class_name SkillTreeData
## Skill tree database — each class has 3 branches with tiered skills.
## Skills can be leveled up (1-5) and have prerequisites.
## Players earn 1 skill point per level.

## Skill tree branches per class
## WARRIOR: Offense (Berserker) / Defense (Guardian) / Utility (Warlord)
## MAGE: Fire / Ice / Lightning
## RANGER: Marksmanship / Survival / Trapping

const MAX_SKILL_LEVEL := 5
const SKILL_POINTS_PER_LEVEL := 1

## Per-level scaling multipliers for upgraded skills
## Level 1 = base, each level improves the skill
const LEVEL_SCALING := {
	"damage_multiplier": 0.15,   # +15% damage per skill level
	"mana_cost_reduction": 0.05, # -5% mana cost per skill level
	"cooldown_reduction": 0.05,  # -5% cooldown per skill level
	"aoe_radius_bonus": 0.10,    # +10% AoE radius per skill level
	"hits_bonus_per_2_levels": 1, # +1 hit target every 2 levels
}

## Skill tree definitions per class
## Each skill has: branch, tier (1-3), prerequisites, unlock_level, and upgrade bonuses
const SKILL_TREES := {
	# ========================
	# WARRIOR SKILL TREE
	# ========================
	ClassData.ClassType.WARRIOR: {
		"branches": {
			"berserker": {
				"name": "Berserker",
				"description": "Offensive power and raw damage.",
				"color": Color(0.9, 0.2, 0.1),
			},
			"guardian": {
				"name": "Guardian",
				"description": "Defensive skills and survivability.",
				"color": Color(0.3, 0.5, 0.9),
			},
			"warlord": {
				"name": "Warlord",
				"description": "AoE control and battlefield dominance.",
				"color": Color(0.8, 0.6, 0.1),
			},
		},
		"skills": {
			# --- Berserker Branch ---
			"slash": {
				"branch": "berserker",
				"tier": 1,
				"unlock_level": 1,
				"prerequisites": [],
				"upgrade_bonuses": {
					"damage_multiplier": [1.5, 1.7, 1.9, 2.2, 2.5],
					"mana_cost": [5, 5, 4, 4, 3],
					"cooldown": [0.8, 0.75, 0.7, 0.65, 0.6],
				},
			},
			"frenzy_strike": {
				"branch": "berserker",
				"tier": 2,
				"unlock_level": 8,
				"prerequisites": ["slash"],
				"skill_data": {
					"name": "Frenzy Strike",
					"description": "A flurry of rapid slashes. Hits increase with level.",
					"class": ClassData.ClassType.WARRIOR,
					"damage_multiplier": 1.0,
					"mana_cost": 18,
					"cooldown": 6.0,
					"range": 45.0,
					"aoe_radius": 35.0,
					"hits": 3,
					"hotkey": "",
					"icon_color": Color(1, 0.3, 0.15),
				},
				"upgrade_bonuses": {
					"damage_multiplier": [1.0, 1.15, 1.3, 1.5, 1.7],
					"mana_cost": [18, 17, 16, 15, 14],
					"cooldown": [6.0, 5.5, 5.0, 4.5, 4.0],
					"hits": [3, 3, 4, 4, 5],
				},
			},
			"berserker_rage": {
				"branch": "berserker",
				"tier": 3,
				"unlock_level": 20,
				"prerequisites": ["frenzy_strike"],
				"skill_data": {
					"name": "Berserker Rage",
					"description": "Enter a rage, boosting attack by 30% for 10s. Higher levels increase bonus.",
					"class": ClassData.ClassType.WARRIOR,
					"damage_multiplier": 0.0,
					"mana_cost": 40,
					"cooldown": 30.0,
					"range": 0.0,
					"aoe_radius": 0.0,
					"hits": 0,
					"hotkey": "",
					"icon_color": Color(0.8, 0.1, 0.0),
					"buff_type": "attack_boost",
					"buff_duration": 10.0,
					"buff_value": 0.3,
				},
				"upgrade_bonuses": {
					"mana_cost": [40, 38, 35, 32, 30],
					"cooldown": [30.0, 28.0, 26.0, 24.0, 20.0],
					"buff_value": [0.3, 0.35, 0.4, 0.5, 0.6],
					"buff_duration": [10.0, 11.0, 12.0, 13.0, 15.0],
				},
			},
			# --- Guardian Branch ---
			"shield_charge": {
				"branch": "guardian",
				"tier": 1,
				"unlock_level": 1,
				"prerequisites": [],
				"upgrade_bonuses": {
					"damage_multiplier": [2.0, 2.3, 2.6, 3.0, 3.5],
					"mana_cost": [20, 19, 18, 17, 15],
					"cooldown": [8.0, 7.5, 7.0, 6.5, 6.0],
				},
			},
			"fortify": {
				"branch": "guardian",
				"tier": 2,
				"unlock_level": 10,
				"prerequisites": ["shield_charge"],
				"skill_data": {
					"name": "Fortify",
					"description": "Increase defense by 40% for 8s. Scales with level.",
					"class": ClassData.ClassType.WARRIOR,
					"damage_multiplier": 0.0,
					"mana_cost": 25,
					"cooldown": 20.0,
					"range": 0.0,
					"aoe_radius": 0.0,
					"hits": 0,
					"hotkey": "",
					"icon_color": Color(0.3, 0.5, 0.95),
					"buff_type": "defense_boost",
					"buff_duration": 8.0,
					"buff_value": 0.4,
				},
				"upgrade_bonuses": {
					"mana_cost": [25, 23, 21, 19, 17],
					"cooldown": [20.0, 18.0, 16.0, 14.0, 12.0],
					"buff_value": [0.4, 0.5, 0.6, 0.7, 0.8],
					"buff_duration": [8.0, 9.0, 10.0, 11.0, 12.0],
				},
			},
			"iron_will": {
				"branch": "guardian",
				"tier": 3,
				"unlock_level": 25,
				"prerequisites": ["fortify"],
				"skill_data": {
					"name": "Iron Will",
					"description": "Passive: Permanently increase max HP by 5% per level.",
					"class": ClassData.ClassType.WARRIOR,
					"damage_multiplier": 0.0,
					"mana_cost": 0,
					"cooldown": 0.0,
					"range": 0.0,
					"aoe_radius": 0.0,
					"hits": 0,
					"hotkey": "",
					"icon_color": Color(0.5, 0.6, 0.9),
					"passive": true,
					"passive_type": "max_hp_percent",
				},
				"upgrade_bonuses": {
					"passive_value": [0.05, 0.10, 0.15, 0.20, 0.25],
				},
			},
			# --- Warlord Branch ---
			"whirlwind": {
				"branch": "warlord",
				"tier": 1,
				"unlock_level": 1,
				"prerequisites": [],
				"upgrade_bonuses": {
					"damage_multiplier": [1.2, 1.4, 1.6, 1.8, 2.1],
					"mana_cost": [15, 14, 13, 12, 10],
					"cooldown": [4.0, 3.7, 3.4, 3.1, 2.8],
					"hits": [3, 3, 4, 4, 5],
					"aoe_radius": [60.0, 65.0, 70.0, 75.0, 85.0],
				},
			},
			"ground_slam": {
				"branch": "warlord",
				"tier": 2,
				"unlock_level": 12,
				"prerequisites": ["whirlwind"],
				"upgrade_bonuses": {
					"damage_multiplier": [3.0, 3.4, 3.8, 4.3, 5.0],
					"mana_cost": [35, 33, 31, 28, 25],
					"cooldown": [15.0, 14.0, 13.0, 12.0, 10.0],
					"aoe_radius": [80.0, 85.0, 90.0, 100.0, 110.0],
				},
			},
			"warcry": {
				"branch": "warlord",
				"tier": 3,
				"unlock_level": 22,
				"prerequisites": ["ground_slam"],
				"skill_data": {
					"name": "War Cry",
					"description": "Boosts attack and speed for 12s. AoE taunt on nearby enemies.",
					"class": ClassData.ClassType.WARRIOR,
					"damage_multiplier": 0.0,
					"mana_cost": 30,
					"cooldown": 25.0,
					"range": 100.0,
					"aoe_radius": 100.0,
					"hits": 0,
					"hotkey": "",
					"icon_color": Color(0.9, 0.7, 0.1),
					"buff_type": "attack_speed_boost",
					"buff_duration": 12.0,
					"buff_value": 0.2,
				},
				"upgrade_bonuses": {
					"mana_cost": [30, 28, 26, 24, 20],
					"cooldown": [25.0, 23.0, 21.0, 19.0, 16.0],
					"buff_value": [0.2, 0.25, 0.3, 0.35, 0.4],
					"buff_duration": [12.0, 13.0, 14.0, 15.0, 18.0],
				},
			},
		},
	},
	# ========================
	# MAGE SKILL TREE
	# ========================
	ClassData.ClassType.MAGE: {
		"branches": {
			"fire": {
				"name": "Fire",
				"description": "High single-target and burst damage.",
				"color": Color(1.0, 0.4, 0.0),
			},
			"ice": {
				"name": "Ice",
				"description": "AoE control and sustained damage.",
				"color": Color(0.4, 0.7, 1.0),
			},
			"lightning": {
				"name": "Lightning",
				"description": "Chain damage and multi-target hits.",
				"color": Color(0.9, 0.9, 0.3),
			},
		},
		"skills": {
			# --- Fire Branch ---
			"fireball": {
				"branch": "fire",
				"tier": 1,
				"unlock_level": 1,
				"prerequisites": [],
				"upgrade_bonuses": {
					"damage_multiplier": [1.8, 2.1, 2.4, 2.8, 3.2],
					"mana_cost": [10, 10, 9, 9, 8],
					"cooldown": [1.0, 0.95, 0.9, 0.85, 0.8],
					"aoe_radius": [30.0, 33.0, 36.0, 40.0, 45.0],
				},
			},
			"flame_wave": {
				"branch": "fire",
				"tier": 2,
				"unlock_level": 8,
				"prerequisites": ["fireball"],
				"skill_data": {
					"name": "Flame Wave",
					"description": "A cone of fire that scorches all enemies ahead.",
					"class": ClassData.ClassType.MAGE,
					"damage_multiplier": 2.0,
					"mana_cost": 22,
					"cooldown": 5.0,
					"range": 100.0,
					"aoe_radius": 60.0,
					"hits": 4,
					"hotkey": "",
					"icon_color": Color(1, 0.5, 0.1),
				},
				"upgrade_bonuses": {
					"damage_multiplier": [2.0, 2.3, 2.6, 3.0, 3.5],
					"mana_cost": [22, 21, 20, 18, 16],
					"cooldown": [5.0, 4.7, 4.4, 4.0, 3.5],
					"hits": [4, 4, 5, 5, 6],
				},
			},
			"meteor": {
				"branch": "fire",
				"tier": 3,
				"unlock_level": 20,
				"prerequisites": ["flame_wave"],
				"upgrade_bonuses": {
					"damage_multiplier": [4.0, 4.6, 5.2, 6.0, 7.0],
					"mana_cost": [45, 43, 40, 37, 35],
					"cooldown": [20.0, 18.0, 16.0, 14.0, 12.0],
					"aoe_radius": [120.0, 125.0, 130.0, 140.0, 150.0],
				},
			},
			# --- Ice Branch ---
			"blizzard": {
				"branch": "ice",
				"tier": 1,
				"unlock_level": 1,
				"prerequisites": [],
				"upgrade_bonuses": {
					"damage_multiplier": [1.3, 1.5, 1.7, 2.0, 2.3],
					"mana_cost": [25, 24, 23, 21, 19],
					"cooldown": [6.0, 5.5, 5.0, 4.5, 4.0],
					"hits": [4, 4, 5, 5, 6],
					"aoe_radius": [100.0, 105.0, 110.0, 120.0, 130.0],
				},
			},
			"frost_armor": {
				"branch": "ice",
				"tier": 2,
				"unlock_level": 10,
				"prerequisites": ["blizzard"],
				"skill_data": {
					"name": "Frost Armor",
					"description": "Coat yourself in ice, boosting defense and slowing attackers.",
					"class": ClassData.ClassType.MAGE,
					"damage_multiplier": 0.0,
					"mana_cost": 30,
					"cooldown": 25.0,
					"range": 0.0,
					"aoe_radius": 0.0,
					"hits": 0,
					"hotkey": "",
					"icon_color": Color(0.5, 0.8, 1.0),
					"buff_type": "defense_boost",
					"buff_duration": 10.0,
					"buff_value": 0.5,
				},
				"upgrade_bonuses": {
					"mana_cost": [30, 28, 26, 24, 20],
					"cooldown": [25.0, 23.0, 21.0, 18.0, 15.0],
					"buff_value": [0.5, 0.6, 0.7, 0.8, 1.0],
					"buff_duration": [10.0, 11.0, 12.0, 14.0, 16.0],
				},
			},
			"absolute_zero": {
				"branch": "ice",
				"tier": 3,
				"unlock_level": 22,
				"prerequisites": ["frost_armor"],
				"skill_data": {
					"name": "Absolute Zero",
					"description": "Freeze all enemies in a massive area. Frozen enemies take 2x damage.",
					"class": ClassData.ClassType.MAGE,
					"damage_multiplier": 2.5,
					"mana_cost": 50,
					"cooldown": 30.0,
					"range": 120.0,
					"aoe_radius": 150.0,
					"hits": 8,
					"hotkey": "",
					"icon_color": Color(0.3, 0.6, 1.0),
				},
				"upgrade_bonuses": {
					"damage_multiplier": [2.5, 3.0, 3.5, 4.0, 5.0],
					"mana_cost": [50, 47, 44, 40, 35],
					"cooldown": [30.0, 28.0, 25.0, 22.0, 18.0],
					"hits": [8, 8, 10, 10, 12],
				},
			},
			# --- Lightning Branch ---
			"lightning_chain": {
				"branch": "lightning",
				"tier": 1,
				"unlock_level": 1,
				"prerequisites": [],
				"upgrade_bonuses": {
					"damage_multiplier": [1.5, 1.7, 2.0, 2.3, 2.7],
					"mana_cost": [20, 19, 18, 17, 15],
					"cooldown": [5.0, 4.7, 4.4, 4.0, 3.5],
					"hits": [5, 5, 6, 7, 8],
				},
			},
			"thunderstorm": {
				"branch": "lightning",
				"tier": 2,
				"unlock_level": 12,
				"prerequisites": ["lightning_chain"],
				"skill_data": {
					"name": "Thunderstorm",
					"description": "Call down lightning bolts across a large area repeatedly.",
					"class": ClassData.ClassType.MAGE,
					"damage_multiplier": 2.2,
					"mana_cost": 35,
					"cooldown": 10.0,
					"range": 130.0,
					"aoe_radius": 100.0,
					"hits": 6,
					"hotkey": "",
					"icon_color": Color(1.0, 1.0, 0.4),
				},
				"upgrade_bonuses": {
					"damage_multiplier": [2.2, 2.5, 2.9, 3.3, 3.8],
					"mana_cost": [35, 33, 31, 28, 25],
					"cooldown": [10.0, 9.0, 8.0, 7.0, 6.0],
					"hits": [6, 6, 7, 8, 10],
				},
			},
			"arcane_mastery": {
				"branch": "lightning",
				"tier": 3,
				"unlock_level": 25,
				"prerequisites": ["thunderstorm"],
				"skill_data": {
					"name": "Arcane Mastery",
					"description": "Passive: Increase all spell damage by 5% per level and mana regen by 2/s per level.",
					"class": ClassData.ClassType.MAGE,
					"damage_multiplier": 0.0,
					"mana_cost": 0,
					"cooldown": 0.0,
					"range": 0.0,
					"aoe_radius": 0.0,
					"hits": 0,
					"hotkey": "",
					"icon_color": Color(0.7, 0.5, 1.0),
					"passive": true,
					"passive_type": "spell_damage_and_mana_regen",
				},
				"upgrade_bonuses": {
					"passive_spell_damage": [0.05, 0.10, 0.15, 0.20, 0.30],
					"passive_mana_regen": [2, 4, 6, 8, 12],
				},
			},
		},
	},
	# ========================
	# RANGER SKILL TREE
	# ========================
	ClassData.ClassType.RANGER: {
		"branches": {
			"marksmanship": {
				"name": "Marksmanship",
				"description": "Precision damage and critical strikes.",
				"color": Color(0.2, 0.8, 0.3),
			},
			"survival": {
				"name": "Survival",
				"description": "Evasion, mobility, and sustain.",
				"color": Color(0.6, 0.5, 0.2),
			},
			"trapping": {
				"name": "Trapping",
				"description": "AoE damage and crowd control.",
				"color": Color(0.5, 0.3, 0.1),
			},
		},
		"skills": {
			# --- Marksmanship Branch ---
			"arrow_shot": {
				"branch": "marksmanship",
				"tier": 1,
				"unlock_level": 1,
				"prerequisites": [],
				"upgrade_bonuses": {
					"damage_multiplier": [1.4, 1.6, 1.9, 2.2, 2.6],
					"mana_cost": [5, 5, 4, 4, 3],
					"cooldown": [0.6, 0.55, 0.5, 0.45, 0.4],
				},
			},
			"piercing_shot": {
				"branch": "marksmanship",
				"tier": 2,
				"unlock_level": 8,
				"prerequisites": ["arrow_shot"],
				"skill_data": {
					"name": "Piercing Shot",
					"description": "A powerful shot that pierces through enemies in a line.",
					"class": ClassData.ClassType.RANGER,
					"damage_multiplier": 2.2,
					"mana_cost": 18,
					"cooldown": 5.0,
					"range": 200.0,
					"aoe_radius": 20.0,
					"hits": 4,
					"hotkey": "",
					"icon_color": Color(0.1, 0.9, 0.4),
				},
				"upgrade_bonuses": {
					"damage_multiplier": [2.2, 2.5, 2.9, 3.4, 4.0],
					"mana_cost": [18, 17, 16, 14, 12],
					"cooldown": [5.0, 4.5, 4.0, 3.5, 3.0],
					"hits": [4, 4, 5, 5, 6],
				},
			},
			"eagle_eye": {
				"branch": "marksmanship",
				"tier": 3,
				"unlock_level": 20,
				"prerequisites": ["piercing_shot"],
				"skill_data": {
					"name": "Eagle Eye",
					"description": "Passive: Increase crit chance by 4% and crit damage by 15% per level.",
					"class": ClassData.ClassType.RANGER,
					"damage_multiplier": 0.0,
					"mana_cost": 0,
					"cooldown": 0.0,
					"range": 0.0,
					"aoe_radius": 0.0,
					"hits": 0,
					"hotkey": "",
					"icon_color": Color(0.9, 0.9, 0.2),
					"passive": true,
					"passive_type": "crit_boost",
				},
				"upgrade_bonuses": {
					"passive_crit_chance": [0.04, 0.08, 0.12, 0.16, 0.22],
					"passive_crit_damage": [0.15, 0.30, 0.45, 0.65, 0.90],
				},
			},
			# --- Survival Branch ---
			"evasive_shot": {
				"branch": "survival",
				"tier": 1,
				"unlock_level": 1,
				"prerequisites": [],
				"upgrade_bonuses": {
					"damage_multiplier": [1.6, 1.8, 2.1, 2.4, 2.8],
					"mana_cost": [20, 19, 18, 16, 14],
					"cooldown": [7.0, 6.5, 6.0, 5.5, 5.0],
				},
			},
			"natures_blessing": {
				"branch": "survival",
				"tier": 2,
				"unlock_level": 10,
				"prerequisites": ["evasive_shot"],
				"skill_data": {
					"name": "Nature's Blessing",
					"description": "Heal over time: Restore HP every second for 8s.",
					"class": ClassData.ClassType.RANGER,
					"damage_multiplier": 0.0,
					"mana_cost": 25,
					"cooldown": 18.0,
					"range": 0.0,
					"aoe_radius": 0.0,
					"hits": 0,
					"hotkey": "",
					"icon_color": Color(0.3, 0.9, 0.5),
					"buff_type": "heal_over_time",
					"buff_duration": 8.0,
					"buff_value": 0.0,
				},
				"upgrade_bonuses": {
					"mana_cost": [25, 23, 21, 19, 16],
					"cooldown": [18.0, 16.0, 14.0, 12.0, 10.0],
					"heal_per_tick": [8, 12, 18, 25, 35],
					"buff_duration": [8.0, 9.0, 10.0, 11.0, 12.0],
				},
			},
			"wind_walker": {
				"branch": "survival",
				"tier": 3,
				"unlock_level": 22,
				"prerequisites": ["natures_blessing"],
				"skill_data": {
					"name": "Wind Walker",
					"description": "Passive: Increase movement speed by 5% per level and dodge chance by 3% per level.",
					"class": ClassData.ClassType.RANGER,
					"damage_multiplier": 0.0,
					"mana_cost": 0,
					"cooldown": 0.0,
					"range": 0.0,
					"aoe_radius": 0.0,
					"hits": 0,
					"hotkey": "",
					"icon_color": Color(0.6, 0.9, 0.8),
					"passive": true,
					"passive_type": "speed_and_dodge",
				},
				"upgrade_bonuses": {
					"passive_speed": [0.05, 0.10, 0.15, 0.20, 0.28],
					"passive_dodge": [0.03, 0.06, 0.09, 0.12, 0.16],
				},
			},
			# --- Trapping Branch ---
			"multishot": {
				"branch": "trapping",
				"tier": 1,
				"unlock_level": 1,
				"prerequisites": [],
				"upgrade_bonuses": {
					"damage_multiplier": [1.0, 1.2, 1.4, 1.6, 1.9],
					"mana_cost": [15, 14, 13, 12, 10],
					"cooldown": [3.0, 2.8, 2.6, 2.4, 2.0],
					"hits": [5, 5, 6, 7, 8],
				},
			},
			"rain_of_arrows": {
				"branch": "trapping",
				"tier": 2,
				"unlock_level": 12,
				"prerequisites": ["multishot"],
				"upgrade_bonuses": {
					"damage_multiplier": [2.5, 2.9, 3.3, 3.8, 4.5],
					"mana_cost": [35, 33, 30, 27, 24],
					"cooldown": [14.0, 13.0, 12.0, 10.0, 8.0],
					"hits": [6, 6, 7, 8, 10],
					"aoe_radius": [110.0, 115.0, 120.0, 130.0, 140.0],
				},
			},
			"explosive_trap": {
				"branch": "trapping",
				"tier": 3,
				"unlock_level": 25,
				"prerequisites": ["rain_of_arrows"],
				"skill_data": {
					"name": "Explosive Trap",
					"description": "Place a trap that detonates when enemies walk over it. Massive AoE.",
					"class": ClassData.ClassType.RANGER,
					"damage_multiplier": 3.5,
					"mana_cost": 30,
					"cooldown": 15.0,
					"range": 80.0,
					"aoe_radius": 100.0,
					"hits": 8,
					"hotkey": "",
					"icon_color": Color(0.8, 0.4, 0.1),
				},
				"upgrade_bonuses": {
					"damage_multiplier": [3.5, 4.0, 4.6, 5.3, 6.5],
					"mana_cost": [30, 28, 26, 23, 20],
					"cooldown": [15.0, 14.0, 12.0, 10.0, 8.0],
					"hits": [8, 8, 10, 10, 12],
					"aoe_radius": [100.0, 105.0, 115.0, 125.0, 140.0],
				},
			},
		},
	},
}


## Get the skill tree for a class
static func get_class_tree(class_type: ClassData.ClassType) -> Dictionary:
	return SKILL_TREES.get(class_type, {})


## Get a specific skill's tree entry
static func get_skill_tree_entry(class_type: ClassData.ClassType, skill_id: String) -> Dictionary:
	var tree := get_class_tree(class_type)
	return tree.get("skills", {}).get(skill_id, {})


## Get the effective stats of a skill at a given skill level (1-5)
static func get_skill_at_level(class_type: ClassData.ClassType, skill_id: String, skill_level: int) -> Dictionary:
	var tree_entry := get_skill_tree_entry(class_type, skill_id)
	if tree_entry.is_empty():
		return {}

	# Start with the base skill data (from SkillData or from tree entry's skill_data)
	var base_skill := SkillData.get_skill(skill_id)
	if base_skill.is_empty() and tree_entry.has("skill_data"):
		base_skill = tree_entry["skill_data"].duplicate()
	elif base_skill.is_empty():
		return {}
	else:
		base_skill = base_skill.duplicate()

	# Apply level-specific bonuses
	var level_index := clampi(skill_level - 1, 0, MAX_SKILL_LEVEL - 1)
	var bonuses: Dictionary = tree_entry.get("upgrade_bonuses", {})

	for key in bonuses:
		var values: Array = bonuses[key]
		if level_index < values.size():
			base_skill[key] = values[level_index]

	base_skill["skill_level"] = skill_level
	return base_skill


## Get all skills in a branch for a class
static func get_branch_skills(class_type: ClassData.ClassType, branch: String) -> Array[String]:
	var result: Array[String] = []
	var tree := get_class_tree(class_type)
	var skills: Dictionary = tree.get("skills", {})
	for skill_id in skills:
		if skills[skill_id].get("branch", "") == branch:
			result.append(skill_id)
	# Sort by tier
	result.sort_custom(func(a, b):
		return skills[a].get("tier", 1) < skills[b].get("tier", 1)
	)
	return result


## Check if a skill can be unlocked/upgraded
static func can_upgrade_skill(class_type: ClassData.ClassType, skill_id: String,
		current_skill_levels: Dictionary, player_level: int, available_points: int) -> Dictionary:
	var tree_entry := get_skill_tree_entry(class_type, skill_id)
	if tree_entry.is_empty():
		return {"can_upgrade": false, "reason": "Skill not found"}

	var current_level: int = current_skill_levels.get(skill_id, 0)

	if current_level >= MAX_SKILL_LEVEL:
		return {"can_upgrade": false, "reason": "Already max level"}

	if available_points <= 0:
		return {"can_upgrade": false, "reason": "No skill points available"}

	if player_level < tree_entry.get("unlock_level", 1):
		return {"can_upgrade": false, "reason": "Player level too low (need lv." + str(tree_entry["unlock_level"]) + ")"}

	# Check prerequisites
	for prereq in tree_entry.get("prerequisites", []):
		if current_skill_levels.get(prereq, 0) <= 0:
			return {"can_upgrade": false, "reason": "Requires " + prereq + " first"}

	return {"can_upgrade": true, "reason": ""}
