extends RefCounted
class_name CombatProfile
## Data-driven combat identity for each playable class.

const PROFILES := {
	ClassData.ClassType.WARRIOR: {
		"basic_range": 1.9,
		"basic_arc_cos": -0.2,
		"max_targets": 4,
		"combo": [1.0, 1.2, 1.55],
		"dodge_cost": 35.0,
		"dodge_duration": 0.28,
		"dodge_speed": 8.0,
		"invulnerable": 0.14,
		"damage_reduction": 0.5,
		"weapon_id": "wooden_sword",
	},
	ClassData.ClassType.MAGE: {
		"basic_range": 5.5,
		"basic_arc_cos": 0.25,
		"max_targets": 1,
		"combo": [0.9, 1.05, 1.35],
		"dodge_cost": 45.0,
		"dodge_duration": 0.18,
		"dodge_speed": 13.0,
		"invulnerable": 0.18,
		"damage_reduction": 0.0,
		"weapon_id": "training_staff",
	},
	ClassData.ClassType.RANGER: {
		"basic_range": 6.5,
		"basic_arc_cos": 0.45,
		"max_targets": 1,
		"combo": [0.85, 1.0, 1.25],
		"dodge_cost": 30.0,
		"dodge_duration": 0.34,
		"dodge_speed": 10.5,
		"invulnerable": 0.28,
		"damage_reduction": 0.0,
		"weapon_id": "training_bow",
	},
}

const LOOT_TRAITS := {
	"offense": {"name": "Fierce", "stats": {"attack": 3, "crit_chance": 0.02}},
	"defense": {"name": "Steadfast", "stats": {"defense": 3, "max_hp": 12}},
	"mobility": {"name": "Fleet", "stats": {"speed": 12.0, "crit_chance": 0.01}},
}

static func get_profile(class_type: ClassData.ClassType) -> Dictionary:
	return PROFILES.get(class_type, PROFILES[ClassData.ClassType.WARRIOR]).duplicate(true)

static func combo_multiplier(class_type: ClassData.ClassType, combo_index: int) -> float:
	var combo: Array = PROFILES.get(class_type, PROFILES[ClassData.ClassType.WARRIOR])["combo"]
	return float(combo[clampi(combo_index, 0, combo.size() - 1)])

static func quest_weapon_id(class_type: ClassData.ClassType) -> String:
	return str(PROFILES.get(class_type, PROFILES[ClassData.ClassType.WARRIOR])["weapon_id"])

static func apply_loot_trait(item: Dictionary, trait_id: String) -> Dictionary:
	var result := item.duplicate(true)
	var loot_trait: Dictionary = LOOT_TRAITS.get(trait_id, LOOT_TRAITS["offense"])
	result["trait"] = trait_id
	result["name"] = "%s %s" % [loot_trait["name"], result.get("name", "Item")]
	var stats: Dictionary = result.get("stats", {}).duplicate(true)
	for key in loot_trait["stats"]:
		stats[key] = stats.get(key, 0) + loot_trait["stats"][key]
	result["stats"] = stats
	return result
