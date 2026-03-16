extends Node
class_name EnemyAbilities
## Defines special abilities for each enemy type.
## Bones split into mini skeletons, wolves lunge-bite, bosses have unique attacks.

## Ability data per mob_id. Each ability has:
##   name: Display name
##   cooldown: Seconds between uses
##   type: "split", "lunge_bite", "howl", "ranged", "aoe", "heal", "teleport", "drain"
##   damage_mult: Damage multiplier vs base attack
##   Extra fields depend on type.
const ABILITIES := {
	# --- Slime ---
	"big_slime": {
		"name": "Slime Split",
		"type": "split",
		"cooldown": 12.0,
		"split_count": 2,
		"split_mob": "mini_slime",
		"split_lifetime": 8.0,
		"trigger": "on_death",
	},

	# --- Wolves ---
	"wolf": {
		"name": "Lunge Bite",
		"type": "lunge_bite",
		"cooldown": 5.0,
		"dash_speed": 300.0,
		"dash_duration": 0.2,
		"damage_mult": 1.8,
	},
	"alpha_wolf": {
		"name": "Alpha Lunge",
		"type": "lunge_bite",
		"cooldown": 4.0,
		"dash_speed": 350.0,
		"dash_duration": 0.25,
		"damage_mult": 2.2,
	},

	# --- Bandits ---
	"bandit_archer": {
		"name": "Volley",
		"type": "ranged",
		"cooldown": 6.0,
		"range": 200.0,
		"damage_mult": 1.5,
		"projectile_count": 3,
	},
	"bandit_chief": {
		"name": "Rally Cry",
		"type": "buff_allies",
		"cooldown": 15.0,
		"buff_radius": 150.0,
		"buff_speed_mult": 1.4,
		"buff_atk_mult": 1.3,
		"buff_duration": 6.0,
	},

	# --- Skeletons / Bones ---
	"skeleton": {
		"name": "Bone Toss",
		"type": "ranged",
		"cooldown": 4.0,
		"range": 160.0,
		"damage_mult": 1.4,
		"projectile_count": 1,
	},
	"skeleton_mage": {
		"name": "Dark Bolt",
		"type": "ranged",
		"cooldown": 3.0,
		"range": 200.0,
		"damage_mult": 2.0,
		"projectile_count": 1,
	},
	"bone_golem": {
		"name": "Bone Split",
		"type": "split",
		"cooldown": 10.0,
		"split_count": 3,
		"split_mob": "mini_skeleton",
		"split_lifetime": 10.0,
		"trigger": "on_ability",
	},
	"lich": {
		"name": "Life Drain",
		"type": "drain",
		"cooldown": 8.0,
		"range": 120.0,
		"damage_mult": 2.5,
		"heal_percent": 0.5,
	},

	# --- Demons ---
	"imp": {
		"name": "Shadow Blink",
		"type": "teleport",
		"cooldown": 6.0,
		"teleport_range": 120.0,
	},
	"demon_soldier": {
		"name": "Shield Bash",
		"type": "knockback",
		"cooldown": 7.0,
		"damage_mult": 1.6,
		"knockback_force": 200.0,
	},
	"hellhound": {
		"name": "Fire Dash",
		"type": "lunge_bite",
		"cooldown": 3.5,
		"dash_speed": 400.0,
		"dash_duration": 0.2,
		"damage_mult": 2.5,
	},
	"demon_lord": {
		"name": "Hellfire",
		"type": "aoe",
		"cooldown": 10.0,
		"aoe_radius": 120.0,
		"damage_mult": 3.0,
	},
}

## Mini-mob stats for split abilities (weaker temporary versions)
const MINI_MOB_STATS := {
	"mini_slime": {
		"name": "Mini Slime",
		"hp": 15,
		"atk": 3,
		"def": 0,
		"speed": 55.0,
		"color": Color(0.3, 1.0, 0.3, 0.7),
		"scale": Vector2(0.5, 0.5),
	},
	"mini_skeleton": {
		"name": "Mini Skeleton",
		"hp": 60,
		"atk": 15,
		"def": 5,
		"speed": 65.0,
		"color": Color(0.9, 0.9, 0.8, 0.8),
		"scale": Vector2(0.6, 0.6),
	},
}

static func get_ability(mob_id: String) -> Dictionary:
	return ABILITIES.get(mob_id, {})

static func has_ability(mob_id: String) -> bool:
	return mob_id in ABILITIES

static func get_mini_mob(mini_id: String) -> Dictionary:
	return MINI_MOB_STATS.get(mini_id, {})
