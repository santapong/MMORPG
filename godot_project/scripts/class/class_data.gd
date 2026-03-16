extends Node
class_name ClassData
## Defines player classes with BDO-inspired stats and skill sets.

enum ClassType { WARRIOR, MAGE, RANGER }

const CLASS_INFO := {
	ClassType.WARRIOR: {
		"name": "Warrior",
		"description": "Melee bruiser with high HP and defense. Excels at close-range grinding.",
		"base_hp": 120,
		"base_mp": 30,
		"base_attack": 14,
		"base_defense": 8,
		"base_speed": 140.0,
		"hp_per_level": 15,
		"mp_per_level": 3,
		"atk_per_level": 3,
		"def_per_level": 2,
		"crit_chance": 0.08,
		"skills": ["slash", "whirlwind", "shield_charge", "ground_slam"],
		"color": Color(0.9, 0.3, 0.2),
	},
	ClassType.MAGE: {
		"name": "Mage",
		"description": "Ranged AoE specialist. High damage, low defense. Best for mob packs.",
		"base_hp": 70,
		"base_mp": 80,
		"base_attack": 16,
		"base_defense": 3,
		"base_speed": 130.0,
		"hp_per_level": 8,
		"mp_per_level": 8,
		"atk_per_level": 4,
		"def_per_level": 1,
		"crit_chance": 0.12,
		"skills": ["fireball", "blizzard", "lightning_chain", "meteor"],
		"color": Color(0.3, 0.4, 0.95),
	},
	ClassType.RANGER: {
		"name": "Ranger",
		"description": "Fast ranged attacker. Balanced stats with high crit. Great mobility.",
		"base_hp": 90,
		"base_mp": 50,
		"base_attack": 12,
		"base_defense": 5,
		"base_speed": 170.0,
		"hp_per_level": 10,
		"mp_per_level": 5,
		"atk_per_level": 3,
		"def_per_level": 1,
		"crit_chance": 0.18,
		"skills": ["arrow_shot", "multishot", "evasive_shot", "rain_of_arrows"],
		"color": Color(0.2, 0.85, 0.3),
	},
}

static func get_class_info(class_type: ClassType) -> Dictionary:
	return CLASS_INFO.get(class_type, {})

static func get_class_name_str(class_type: ClassType) -> String:
	return CLASS_INFO.get(class_type, {}).get("name", "Unknown")

static func get_all_classes() -> Array:
	return [ClassType.WARRIOR, ClassType.MAGE, ClassType.RANGER]
