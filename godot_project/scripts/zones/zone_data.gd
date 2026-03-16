extends Node
class_name ZoneData
## Defines grinding zones with BDO-inspired difficulty tiers and mob density.

enum ZoneTier { SAFE, EASY, MEDIUM, HARD, NIGHTMARE }

const ZONE_COLORS := {
	ZoneTier.SAFE: Color(0.2, 0.5, 0.2),
	ZoneTier.EASY: Color(0.25, 0.4, 0.15),
	ZoneTier.MEDIUM: Color(0.35, 0.3, 0.1),
	ZoneTier.HARD: Color(0.3, 0.15, 0.1),
	ZoneTier.NIGHTMARE: Color(0.15, 0.05, 0.15),
}

const ZONE_TIER_NAMES := {
	ZoneTier.SAFE: "Safe Zone",
	ZoneTier.EASY: "Easy",
	ZoneTier.MEDIUM: "Medium",
	ZoneTier.HARD: "Hard",
	ZoneTier.NIGHTMARE: "Nightmare",
}

const ZONES := {
	"starter_village": {
		"name": "Starter Village",
		"tier": ZoneTier.SAFE,
		"recommended_level": 1,
		"bounds": Rect2(0, 0, 600, 600),
		"mobs": [],
		"mob_count": 0,
		"respawn_time": 0.0,
	},
	"slime_fields": {
		"name": "Slime Fields",
		"tier": ZoneTier.EASY,
		"recommended_level": 1,
		"bounds": Rect2(600, 0, 600, 600),
		"mobs": [
			{"id": "slime", "name": "Slime", "weight": 70},
			{"id": "big_slime", "name": "Big Slime", "weight": 30},
		],
		"mob_count": 12,
		"respawn_time": 8.0,
		"silver_per_mob": 50,
	},
	"wolf_forest": {
		"name": "Wolf Forest",
		"tier": ZoneTier.EASY,
		"recommended_level": 5,
		"bounds": Rect2(0, 600, 600, 600),
		"mobs": [
			{"id": "wolf", "name": "Wolf", "weight": 60},
			{"id": "alpha_wolf", "name": "Alpha Wolf", "weight": 25},
			{"id": "forest_spirit", "name": "Forest Spirit", "weight": 15},
		],
		"mob_count": 10,
		"respawn_time": 10.0,
		"silver_per_mob": 120,
	},
	"bandit_camp": {
		"name": "Bandit Camp",
		"tier": ZoneTier.MEDIUM,
		"recommended_level": 10,
		"bounds": Rect2(600, 600, 600, 600),
		"mobs": [
			{"id": "bandit", "name": "Bandit", "weight": 50},
			{"id": "bandit_archer", "name": "Bandit Archer", "weight": 30},
			{"id": "bandit_chief", "name": "Bandit Chief", "weight": 20},
		],
		"mob_count": 15,
		"respawn_time": 10.0,
		"silver_per_mob": 250,
	},
	"cursed_ruins": {
		"name": "Cursed Ruins",
		"tier": ZoneTier.HARD,
		"recommended_level": 20,
		"bounds": Rect2(1200, 0, 800, 600),
		"mobs": [
			{"id": "skeleton", "name": "Skeleton Warrior", "weight": 40},
			{"id": "skeleton_mage", "name": "Skeleton Mage", "weight": 30},
			{"id": "bone_golem", "name": "Bone Golem", "weight": 20},
			{"id": "lich", "name": "Lich", "weight": 10},
		],
		"mob_count": 18,
		"respawn_time": 12.0,
		"silver_per_mob": 600,
	},
	"demon_rift": {
		"name": "Demon Rift",
		"tier": ZoneTier.NIGHTMARE,
		"recommended_level": 35,
		"bounds": Rect2(1200, 600, 800, 600),
		"mobs": [
			{"id": "imp", "name": "Imp", "weight": 35},
			{"id": "demon_soldier", "name": "Demon Soldier", "weight": 30},
			{"id": "hellhound", "name": "Hellhound", "weight": 20},
			{"id": "demon_lord", "name": "Demon Lord", "weight": 15},
		],
		"mob_count": 20,
		"respawn_time": 15.0,
		"silver_per_mob": 1500,
	},
}

## Enemy stat templates by mob ID
const MOB_STATS := {
	"slime": {"hp": 40, "atk": 4, "def": 1, "speed": 40.0, "exp": 20, "detect": 150.0},
	"big_slime": {"hp": 90, "atk": 8, "def": 3, "speed": 30.0, "exp": 45, "detect": 160.0},
	"wolf": {"hp": 70, "atk": 10, "def": 3, "speed": 80.0, "exp": 40, "detect": 220.0},
	"alpha_wolf": {"hp": 140, "atk": 18, "def": 6, "speed": 90.0, "exp": 90, "detect": 250.0},
	"forest_spirit": {"hp": 60, "atk": 14, "def": 2, "speed": 50.0, "exp": 55, "detect": 180.0},
	"bandit": {"hp": 120, "atk": 15, "def": 8, "speed": 65.0, "exp": 80, "detect": 200.0},
	"bandit_archer": {"hp": 80, "atk": 22, "def": 4, "speed": 55.0, "exp": 85, "detect": 280.0},
	"bandit_chief": {"hp": 250, "atk": 28, "def": 14, "speed": 60.0, "exp": 200, "detect": 220.0},
	"skeleton": {"hp": 200, "atk": 30, "def": 18, "speed": 50.0, "exp": 180, "detect": 200.0},
	"skeleton_mage": {"hp": 130, "atk": 40, "def": 8, "speed": 40.0, "exp": 210, "detect": 250.0},
	"bone_golem": {"hp": 500, "atk": 35, "def": 30, "speed": 30.0, "exp": 400, "detect": 180.0},
	"lich": {"hp": 350, "atk": 55, "def": 15, "speed": 35.0, "exp": 600, "detect": 300.0},
	"imp": {"hp": 250, "atk": 45, "def": 12, "speed": 90.0, "exp": 500, "detect": 250.0},
	"demon_soldier": {"hp": 600, "atk": 60, "def": 35, "speed": 55.0, "exp": 800, "detect": 230.0},
	"hellhound": {"hp": 400, "atk": 70, "def": 20, "speed": 100.0, "exp": 700, "detect": 280.0},
	"demon_lord": {"hp": 1200, "atk": 90, "def": 50, "speed": 45.0, "exp": 2000, "detect": 300.0},
}

## Drop tables by mob ID - BDO style with trash loot + rare drops
const MOB_DROPS := {
	"slime": [
		{"id": "slime_goo", "name": "Slime Goo", "type": "trash_loot", "silver_value": 50, "stackable": true, "quantity": 1, "chance": 0.8},
		{"id": "health_potion_s", "name": "Small Health Potion", "type": "consumable", "effect": "heal", "value": 20, "stackable": true, "quantity": 1, "chance": 0.3},
	],
	"big_slime": [
		{"id": "slime_goo", "name": "Slime Goo", "type": "trash_loot", "silver_value": 50, "stackable": true, "quantity": 2, "chance": 0.9},
		{"id": "condensed_slime", "name": "Condensed Slime Core", "type": "trash_loot", "silver_value": 200, "stackable": true, "quantity": 1, "chance": 0.4},
		{"id": "health_potion_m", "name": "Health Potion", "type": "consumable", "effect": "heal", "value": 50, "stackable": true, "quantity": 1, "chance": 0.2},
	],
	"wolf": [
		{"id": "wolf_hide", "name": "Wolf Hide", "type": "trash_loot", "silver_value": 120, "stackable": true, "quantity": 1, "chance": 0.7},
		{"id": "wolf_fang", "name": "Wolf Fang", "type": "trash_loot", "silver_value": 80, "stackable": true, "quantity": 1, "chance": 0.5},
	],
	"alpha_wolf": [
		{"id": "wolf_hide", "name": "Wolf Hide", "type": "trash_loot", "silver_value": 120, "stackable": true, "quantity": 2, "chance": 0.9},
		{"id": "alpha_fang", "name": "Alpha Fang", "type": "rare_drop", "silver_value": 1000, "stackable": true, "quantity": 1, "chance": 0.05},
		{"id": "leather_armor", "name": "Leather Armor", "type": "equipment", "slot": "body", "attack": 0, "defense": 5, "stackable": false, "quantity": 1, "chance": 0.03},
	],
	"forest_spirit": [
		{"id": "spirit_dust", "name": "Spirit Dust", "type": "trash_loot", "silver_value": 150, "stackable": true, "quantity": 1, "chance": 0.6},
		{"id": "mana_potion_s", "name": "Small Mana Potion", "type": "consumable", "effect": "mana", "value": 30, "stackable": true, "quantity": 1, "chance": 0.3},
	],
	"bandit": [
		{"id": "bandit_loot", "name": "Stolen Goods", "type": "trash_loot", "silver_value": 250, "stackable": true, "quantity": 1, "chance": 0.7},
		{"id": "health_potion_m", "name": "Health Potion", "type": "consumable", "effect": "heal", "value": 50, "stackable": true, "quantity": 1, "chance": 0.2},
	],
	"bandit_archer": [
		{"id": "bandit_loot", "name": "Stolen Goods", "type": "trash_loot", "silver_value": 250, "stackable": true, "quantity": 1, "chance": 0.7},
		{"id": "sharp_arrow", "name": "Sharp Arrow Bundle", "type": "trash_loot", "silver_value": 180, "stackable": true, "quantity": 1, "chance": 0.5},
	],
	"bandit_chief": [
		{"id": "bandit_loot", "name": "Stolen Goods", "type": "trash_loot", "silver_value": 250, "stackable": true, "quantity": 3, "chance": 0.9},
		{"id": "chief_ring", "name": "Bandit Chief's Ring", "type": "equipment", "slot": "ring", "attack": 5, "defense": 2, "stackable": false, "quantity": 1, "chance": 0.05},
		{"id": "iron_sword", "name": "Iron Sword", "type": "equipment", "slot": "weapon", "attack": 12, "defense": 0, "stackable": false, "quantity": 1, "chance": 0.04},
	],
	"skeleton": [
		{"id": "bone_fragment", "name": "Bone Fragment", "type": "trash_loot", "silver_value": 600, "stackable": true, "quantity": 1, "chance": 0.7},
		{"id": "ancient_coin", "name": "Ancient Coin", "type": "trash_loot", "silver_value": 400, "stackable": true, "quantity": 1, "chance": 0.4},
	],
	"skeleton_mage": [
		{"id": "bone_fragment", "name": "Bone Fragment", "type": "trash_loot", "silver_value": 600, "stackable": true, "quantity": 1, "chance": 0.7},
		{"id": "dark_crystal", "name": "Dark Crystal", "type": "rare_drop", "silver_value": 5000, "stackable": true, "quantity": 1, "chance": 0.03},
		{"id": "mana_potion_l", "name": "Large Mana Potion", "type": "consumable", "effect": "mana", "value": 80, "stackable": true, "quantity": 1, "chance": 0.15},
	],
	"bone_golem": [
		{"id": "bone_fragment", "name": "Bone Fragment", "type": "trash_loot", "silver_value": 600, "stackable": true, "quantity": 3, "chance": 0.9},
		{"id": "golem_core", "name": "Golem Core", "type": "rare_drop", "silver_value": 8000, "stackable": true, "quantity": 1, "chance": 0.04},
		{"id": "heavy_armor", "name": "Heavy Plate Armor", "type": "equipment", "slot": "body", "attack": 0, "defense": 18, "stackable": false, "quantity": 1, "chance": 0.02},
		{"id": "enchant_armor_stone", "name": "Black Stone (Armor)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.06},
	],
	"lich": [
		{"id": "dark_crystal", "name": "Dark Crystal", "type": "rare_drop", "silver_value": 5000, "stackable": true, "quantity": 1, "chance": 0.1},
		{"id": "lich_staff", "name": "Lich Staff", "type": "equipment", "slot": "weapon", "attack": 25, "defense": 0, "stackable": false, "quantity": 1, "chance": 0.02},
		{"id": "enchant_stone", "name": "Black Stone (Weapon)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.08},
		{"id": "enchant_armor_stone", "name": "Black Stone (Armor)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.06},
		{"id": "cron_stone", "name": "Cron Stone", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.03},
	],
	"imp": [
		{"id": "demon_blood", "name": "Demon Blood", "type": "trash_loot", "silver_value": 1500, "stackable": true, "quantity": 1, "chance": 0.7},
		{"id": "health_potion_l", "name": "Large Health Potion", "type": "consumable", "effect": "heal", "value": 150, "stackable": true, "quantity": 1, "chance": 0.15},
	],
	"demon_soldier": [
		{"id": "demon_blood", "name": "Demon Blood", "type": "trash_loot", "silver_value": 1500, "stackable": true, "quantity": 2, "chance": 0.8},
		{"id": "demon_armor_shard", "name": "Demon Armor Shard", "type": "rare_drop", "silver_value": 15000, "stackable": true, "quantity": 1, "chance": 0.03},
		{"id": "enchant_stone", "name": "Black Stone (Weapon)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.06},
		{"id": "enchant_armor_stone", "name": "Black Stone (Armor)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.06},
		{"id": "concentrated_weapon_stone", "name": "Concentrated Black Stone (Weapon)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.02},
		{"id": "concentrated_armor_stone", "name": "Concentrated Black Stone (Armor)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.02},
		{"id": "cron_stone", "name": "Cron Stone", "type": "enhancement_mat", "stackable": true, "quantity": 2, "chance": 0.04},
	],
	"hellhound": [
		{"id": "demon_blood", "name": "Demon Blood", "type": "trash_loot", "silver_value": 1500, "stackable": true, "quantity": 1, "chance": 0.8},
		{"id": "hellfire_fang", "name": "Hellfire Fang", "type": "rare_drop", "silver_value": 12000, "stackable": true, "quantity": 1, "chance": 0.04},
		{"id": "enchant_stone", "name": "Black Stone (Weapon)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.05},
		{"id": "enchant_armor_stone", "name": "Black Stone (Armor)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.05},
		{"id": "cron_stone", "name": "Cron Stone", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.03},
	],
	"demon_lord": [
		{"id": "demon_blood", "name": "Demon Blood", "type": "trash_loot", "silver_value": 1500, "stackable": true, "quantity": 5, "chance": 0.95},
		{"id": "demon_lord_token", "name": "Demon Lord Token", "type": "rare_drop", "silver_value": 50000, "stackable": true, "quantity": 1, "chance": 0.02},
		{"id": "demonic_blade", "name": "Demonic Blade", "type": "equipment", "slot": "weapon", "attack": 50, "defense": 0, "stackable": false, "quantity": 1, "chance": 0.01},
		{"id": "enchant_stone", "name": "Black Stone (Weapon)", "type": "enhancement_mat", "stackable": true, "quantity": 2, "chance": 0.1},
		{"id": "enchant_armor_stone", "name": "Black Stone (Armor)", "type": "enhancement_mat", "stackable": true, "quantity": 2, "chance": 0.08},
		{"id": "concentrated_weapon_stone", "name": "Concentrated Black Stone (Weapon)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.05},
		{"id": "concentrated_armor_stone", "name": "Concentrated Black Stone (Armor)", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.05},
		{"id": "cron_stone", "name": "Cron Stone", "type": "enhancement_mat", "stackable": true, "quantity": 3, "chance": 0.06},
		{"id": "advice_of_valks", "name": "Advice of Valks", "type": "enhancement_mat", "stackable": true, "quantity": 1, "chance": 0.02},
	],
}

static func get_mob_stats(mob_id: String) -> Dictionary:
	return MOB_STATS.get(mob_id, {})

static func get_mob_drops(mob_id: String) -> Array:
	var drops: Array = MOB_DROPS.get(mob_id, [])
	return drops

static func get_zone(zone_id: String) -> Dictionary:
	return ZONES.get(zone_id, {})

static func get_zone_at_position(pos: Vector2) -> String:
	for zone_id in ZONES:
		var zone: Dictionary = ZONES[zone_id]
		if zone["bounds"].has_point(pos):
			return zone_id
	return "starter_village"
