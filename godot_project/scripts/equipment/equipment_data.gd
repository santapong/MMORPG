extends Node
class_name EquipmentData
## Equipment database — defines all gear with grades, level requirements, stats, and set bonuses.
## BDO-inspired with grade tiers: Common -> Uncommon -> Rare -> Epic -> Legendary

enum Grade { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const GRADE_NAMES := {
	Grade.COMMON: "Common",
	Grade.UNCOMMON: "Uncommon",
	Grade.RARE: "Rare",
	Grade.EPIC: "Epic",
	Grade.LEGENDARY: "Legendary",
}

const GRADE_COLORS := {
	Grade.COMMON: Color(0.7, 0.7, 0.7),       # Gray
	Grade.UNCOMMON: Color(0.3, 0.8, 0.3),      # Green
	Grade.RARE: Color(0.3, 0.5, 1.0),          # Blue
	Grade.EPIC: Color(0.7, 0.3, 0.9),          # Purple
	Grade.LEGENDARY: Color(1.0, 0.65, 0.0),    # Orange
}

## Grade stat multipliers — higher grade = better stats
const GRADE_MULTIPLIER := {
	Grade.COMMON: 1.0,
	Grade.UNCOMMON: 1.3,
	Grade.RARE: 1.6,
	Grade.EPIC: 2.0,
	Grade.LEGENDARY: 2.5,
}

## Grade enhancement bonus multiplier — better gear gains more per enhance
const GRADE_ENHANCE_MULTIPLIER := {
	Grade.COMMON: 1.0,
	Grade.UNCOMMON: 1.2,
	Grade.RARE: 1.4,
	Grade.EPIC: 1.7,
	Grade.LEGENDARY: 2.0,
}

## === FULL EQUIPMENT DATABASE ===
## Stats: attack, defense, max_hp, max_mp, crit_chance, speed
## All equipment has: id, name, slot, grade, level_req, stats, description
const EQUIPMENT := {
	# ============================
	# WEAPONS (attack-focused)
	# ============================
	"wooden_sword": {
		"name": "Wooden Sword",
		"slot": "weapon",
		"grade": Grade.COMMON,
		"level_req": 1,
		"stats": {"attack": 5, "defense": 0, "crit_chance": 0.0},
		"description": "A basic training sword.",
		"class_req": [], # Empty = any class
	},
	"iron_sword": {
		"name": "Iron Sword",
		"slot": "weapon",
		"grade": Grade.COMMON,
		"level_req": 5,
		"stats": {"attack": 12, "defense": 0, "crit_chance": 0.01},
		"description": "A sturdy iron blade.",
		"class_req": [],
	},
	"steel_longsword": {
		"name": "Steel Longsword",
		"slot": "weapon",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"attack": 20, "defense": 2, "crit_chance": 0.02},
		"description": "Well-forged steel with a keen edge.",
		"class_req": [ClassData.ClassType.WARRIOR],
	},
	"hunters_bow": {
		"name": "Hunter's Bow",
		"slot": "weapon",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"attack": 18, "defense": 0, "crit_chance": 0.04},
		"description": "A longbow favored by veteran hunters.",
		"class_req": [ClassData.ClassType.RANGER],
	},
	"apprentice_staff": {
		"name": "Apprentice Staff",
		"slot": "weapon",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"attack": 22, "defense": 0, "max_mp": 15, "crit_chance": 0.02},
		"description": "A staff imbued with minor arcane energy.",
		"class_req": [ClassData.ClassType.MAGE],
	},
	"bandit_cutlass": {
		"name": "Bandit Cutlass",
		"slot": "weapon",
		"grade": Grade.RARE,
		"level_req": 15,
		"stats": {"attack": 30, "defense": 3, "crit_chance": 0.03, "speed": 5.0},
		"description": "A curved blade taken from a bandit captain.",
		"class_req": [],
	},
	"lich_staff": {
		"name": "Lich Staff",
		"slot": "weapon",
		"grade": Grade.RARE,
		"level_req": 20,
		"stats": {"attack": 35, "defense": 0, "max_mp": 30, "crit_chance": 0.03},
		"description": "A staff crackling with undead energy.",
		"class_req": [ClassData.ClassType.MAGE],
	},
	"warlord_greatsword": {
		"name": "Warlord's Greatsword",
		"slot": "weapon",
		"grade": Grade.EPIC,
		"level_req": 25,
		"stats": {"attack": 50, "defense": 8, "crit_chance": 0.05, "max_hp": 30},
		"description": "A massive two-handed sword that commands respect.",
		"class_req": [ClassData.ClassType.WARRIOR],
	},
	"gale_bow": {
		"name": "Gale Bow",
		"slot": "weapon",
		"grade": Grade.EPIC,
		"level_req": 25,
		"stats": {"attack": 42, "defense": 0, "crit_chance": 0.08, "speed": 15.0},
		"description": "A bow imbued with wind magic for rapid firing.",
		"class_req": [ClassData.ClassType.RANGER],
	},
	"archmage_scepter": {
		"name": "Archmage Scepter",
		"slot": "weapon",
		"grade": Grade.EPIC,
		"level_req": 25,
		"stats": {"attack": 55, "defense": 0, "max_mp": 50, "crit_chance": 0.05},
		"description": "A scepter wielded by the most powerful mages.",
		"class_req": [ClassData.ClassType.MAGE],
	},
	"demonic_blade": {
		"name": "Demonic Blade",
		"slot": "weapon",
		"grade": Grade.LEGENDARY,
		"level_req": 35,
		"stats": {"attack": 75, "defense": 5, "crit_chance": 0.07, "max_hp": -20},
		"description": "A cursed blade of immense power. Drains the wielder's vitality.",
		"class_req": [],
	},
	"celestial_staff": {
		"name": "Celestial Staff",
		"slot": "weapon",
		"grade": Grade.LEGENDARY,
		"level_req": 35,
		"stats": {"attack": 70, "defense": 5, "max_mp": 80, "crit_chance": 0.06},
		"description": "A staff forged from starlight. Channels cosmic power.",
		"class_req": [ClassData.ClassType.MAGE],
	},
	"verdant_longbow": {
		"name": "Verdant Longbow",
		"slot": "weapon",
		"grade": Grade.LEGENDARY,
		"level_req": 35,
		"stats": {"attack": 65, "defense": 0, "crit_chance": 0.12, "speed": 20.0},
		"description": "A living bow grown from the World Tree itself.",
		"class_req": [ClassData.ClassType.RANGER],
	},

	# ============================
	# BODY ARMOR (defense-focused)
	# ============================
	"cloth_tunic": {
		"name": "Cloth Tunic",
		"slot": "body",
		"grade": Grade.COMMON,
		"level_req": 1,
		"stats": {"defense": 3, "max_hp": 10},
		"description": "Simple cloth offering minimal protection.",
		"class_req": [],
	},
	"leather_armor": {
		"name": "Leather Armor",
		"slot": "body",
		"grade": Grade.COMMON,
		"level_req": 5,
		"stats": {"defense": 6, "max_hp": 20},
		"description": "Tanned leather armor. Light and flexible.",
		"class_req": [],
	},
	"chainmail": {
		"name": "Chainmail",
		"slot": "body",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"defense": 12, "max_hp": 35, "speed": -5.0},
		"description": "Interlocking metal rings. Good protection but heavier.",
		"class_req": [ClassData.ClassType.WARRIOR],
	},
	"ranger_vest": {
		"name": "Ranger's Vest",
		"slot": "body",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"defense": 8, "max_hp": 25, "speed": 5.0, "crit_chance": 0.02},
		"description": "A lightweight vest designed for swift movement.",
		"class_req": [ClassData.ClassType.RANGER],
	},
	"mage_robe": {
		"name": "Mage's Robe",
		"slot": "body",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"defense": 5, "max_hp": 15, "max_mp": 25, "attack": 3},
		"description": "Enchanted robes that amplify magical power.",
		"class_req": [ClassData.ClassType.MAGE],
	},
	"heavy_plate_armor": {
		"name": "Heavy Plate Armor",
		"slot": "body",
		"grade": Grade.RARE,
		"level_req": 20,
		"stats": {"defense": 22, "max_hp": 60, "speed": -10.0},
		"description": "Full plate armor. Exceptional protection at the cost of mobility.",
		"class_req": [ClassData.ClassType.WARRIOR],
	},
	"shadow_leather": {
		"name": "Shadow Leather",
		"slot": "body",
		"grade": Grade.RARE,
		"level_req": 20,
		"stats": {"defense": 14, "max_hp": 40, "speed": 8.0, "crit_chance": 0.03},
		"description": "Dark leather armor infused with shadow essence.",
		"class_req": [ClassData.ClassType.RANGER],
	},
	"arcane_vestments": {
		"name": "Arcane Vestments",
		"slot": "body",
		"grade": Grade.RARE,
		"level_req": 20,
		"stats": {"defense": 10, "max_hp": 25, "max_mp": 45, "attack": 6},
		"description": "Robes woven with pure arcane thread.",
		"class_req": [ClassData.ClassType.MAGE],
	},
	"titan_armor": {
		"name": "Titan Armor",
		"slot": "body",
		"grade": Grade.EPIC,
		"level_req": 30,
		"stats": {"defense": 35, "max_hp": 100, "attack": 5, "speed": -15.0},
		"description": "Forged from titan bones. Nearly impenetrable.",
		"class_req": [ClassData.ClassType.WARRIOR],
	},
	"demon_hide": {
		"name": "Demon Hide Armor",
		"slot": "body",
		"grade": Grade.LEGENDARY,
		"level_req": 35,
		"stats": {"defense": 30, "max_hp": 80, "attack": 10, "crit_chance": 0.04},
		"description": "Armor crafted from a Demon Lord's hide. Radiates dark power.",
		"class_req": [],
	},

	# ============================
	# HELMETS
	# ============================
	"leather_cap": {
		"name": "Leather Cap",
		"slot": "helmet",
		"grade": Grade.COMMON,
		"level_req": 1,
		"stats": {"defense": 2, "max_hp": 5},
		"description": "A basic leather cap.",
		"class_req": [],
	},
	"iron_helm": {
		"name": "Iron Helm",
		"slot": "helmet",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"defense": 6, "max_hp": 15},
		"description": "A solid iron helmet.",
		"class_req": [],
	},
	"mage_circlet": {
		"name": "Mage's Circlet",
		"slot": "helmet",
		"grade": Grade.RARE,
		"level_req": 15,
		"stats": {"defense": 3, "max_mp": 20, "attack": 4},
		"description": "A circlet that enhances magical focus.",
		"class_req": [ClassData.ClassType.MAGE],
	},
	"horned_greathelm": {
		"name": "Horned Greathelm",
		"slot": "helmet",
		"grade": Grade.EPIC,
		"level_req": 25,
		"stats": {"defense": 12, "max_hp": 40, "attack": 3},
		"description": "A fearsome helm worn by veteran warriors.",
		"class_req": [ClassData.ClassType.WARRIOR],
	},
	"crown_of_shadows": {
		"name": "Crown of Shadows",
		"slot": "helmet",
		"grade": Grade.LEGENDARY,
		"level_req": 35,
		"stats": {"defense": 10, "max_hp": 30, "attack": 8, "crit_chance": 0.05},
		"description": "A crown that bends light around the wearer.",
		"class_req": [],
	},

	# ============================
	# GLOVES
	# ============================
	"cloth_gloves": {
		"name": "Cloth Gloves",
		"slot": "gloves",
		"grade": Grade.COMMON,
		"level_req": 1,
		"stats": {"attack": 1, "defense": 1},
		"description": "Simple cloth gloves.",
		"class_req": [],
	},
	"leather_bracers": {
		"name": "Leather Bracers",
		"slot": "gloves",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"attack": 3, "defense": 3, "crit_chance": 0.01},
		"description": "Reinforced leather bracers.",
		"class_req": [],
	},
	"gauntlets_of_might": {
		"name": "Gauntlets of Might",
		"slot": "gloves",
		"grade": Grade.RARE,
		"level_req": 20,
		"stats": {"attack": 8, "defense": 5, "crit_chance": 0.02},
		"description": "Heavy gauntlets that amplify striking power.",
		"class_req": [],
	},
	"demon_grips": {
		"name": "Demon Grips",
		"slot": "gloves",
		"grade": Grade.EPIC,
		"level_req": 30,
		"stats": {"attack": 12, "defense": 6, "crit_chance": 0.04},
		"description": "Gloves forged in hellfire. Burns on contact.",
		"class_req": [],
	},

	# ============================
	# BOOTS
	# ============================
	"sandals": {
		"name": "Sandals",
		"slot": "boots",
		"grade": Grade.COMMON,
		"level_req": 1,
		"stats": {"defense": 1, "speed": 5.0},
		"description": "Basic footwear.",
		"class_req": [],
	},
	"leather_boots": {
		"name": "Leather Boots",
		"slot": "boots",
		"grade": Grade.COMMON,
		"level_req": 5,
		"stats": {"defense": 3, "speed": 8.0},
		"description": "Comfortable leather boots.",
		"class_req": [],
	},
	"iron_greaves": {
		"name": "Iron Greaves",
		"slot": "boots",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"defense": 6, "speed": 3.0, "max_hp": 10},
		"description": "Heavy iron boots. Sturdy but slow.",
		"class_req": [],
	},
	"swift_boots": {
		"name": "Swift Boots",
		"slot": "boots",
		"grade": Grade.RARE,
		"level_req": 18,
		"stats": {"defense": 5, "speed": 18.0, "crit_chance": 0.01},
		"description": "Enchanted boots that enhance agility.",
		"class_req": [],
	},
	"windstrider_boots": {
		"name": "Windstrider Boots",
		"slot": "boots",
		"grade": Grade.EPIC,
		"level_req": 28,
		"stats": {"defense": 8, "speed": 25.0, "max_hp": 20},
		"description": "Boots blessed by the wind spirit.",
		"class_req": [],
	},

	# ============================
	# RINGS (offense/utility)
	# ============================
	"copper_ring": {
		"name": "Copper Ring",
		"slot": "ring",
		"grade": Grade.COMMON,
		"level_req": 1,
		"stats": {"attack": 2},
		"description": "A simple copper band.",
		"class_req": [],
	},
	"chief_ring": {
		"name": "Bandit Chief's Ring",
		"slot": "ring",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"attack": 5, "defense": 2, "crit_chance": 0.02},
		"description": "A ring stolen from many victims.",
		"class_req": [],
	},
	"ring_of_arcana": {
		"name": "Ring of Arcana",
		"slot": "ring",
		"grade": Grade.RARE,
		"level_req": 18,
		"stats": {"attack": 8, "max_mp": 20, "crit_chance": 0.02},
		"description": "A ring that channels arcane power.",
		"class_req": [ClassData.ClassType.MAGE],
	},
	"berserker_band": {
		"name": "Berserker Band",
		"slot": "ring",
		"grade": Grade.RARE,
		"level_req": 18,
		"stats": {"attack": 10, "crit_chance": 0.03, "max_hp": -10},
		"description": "A blood-red band. Power at a price.",
		"class_req": [],
	},
	"ring_of_the_demon_lord": {
		"name": "Ring of the Demon Lord",
		"slot": "ring",
		"grade": Grade.LEGENDARY,
		"level_req": 35,
		"stats": {"attack": 18, "defense": 5, "crit_chance": 0.06, "max_hp": 25},
		"description": "A ring pulsing with demonic energy.",
		"class_req": [],
	},

	# ============================
	# NECKLACES (balanced/utility)
	# ============================
	"wooden_pendant": {
		"name": "Wooden Pendant",
		"slot": "necklace",
		"grade": Grade.COMMON,
		"level_req": 1,
		"stats": {"attack": 1, "defense": 1, "max_hp": 5},
		"description": "A carved wooden charm.",
		"class_req": [],
	},
	"silver_necklace": {
		"name": "Silver Necklace",
		"slot": "necklace",
		"grade": Grade.UNCOMMON,
		"level_req": 10,
		"stats": {"attack": 3, "defense": 3, "max_hp": 15},
		"description": "A fine silver chain with a small gem.",
		"class_req": [],
	},
	"amulet_of_vitality": {
		"name": "Amulet of Vitality",
		"slot": "necklace",
		"grade": Grade.RARE,
		"level_req": 20,
		"stats": {"defense": 5, "max_hp": 50, "max_mp": 15},
		"description": "An amulet that pulses with life energy.",
		"class_req": [],
	},
	"choker_of_precision": {
		"name": "Choker of Precision",
		"slot": "necklace",
		"grade": Grade.EPIC,
		"level_req": 28,
		"stats": {"attack": 10, "crit_chance": 0.05, "speed": 5.0},
		"description": "Sharpens the wearer's reflexes to a razor's edge.",
		"class_req": [],
	},
	"heart_of_the_abyss": {
		"name": "Heart of the Abyss",
		"slot": "necklace",
		"grade": Grade.LEGENDARY,
		"level_req": 35,
		"stats": {"attack": 15, "defense": 8, "max_hp": 40, "max_mp": 30, "crit_chance": 0.04},
		"description": "A necklace containing a fragment of the Abyss itself.",
		"class_req": [],
	},
}


## Get equipment entry by ID
static func get_equipment(equip_id: String) -> Dictionary:
	var equip := EQUIPMENT.get(equip_id, {})
	if equip.is_empty():
		return {}
	var result := equip.duplicate(true)
	result["id"] = equip_id
	return result


## Get all equipment for a slot
static func get_equipment_for_slot(slot: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for equip_id in EQUIPMENT:
		if EQUIPMENT[equip_id]["slot"] == slot:
			var entry := EQUIPMENT[equip_id].duplicate(true)
			entry["id"] = equip_id
			result.append(entry)
	result.sort_custom(func(a, b): return a["level_req"] < b["level_req"])
	return result


## Get all equipment a player can use (level + class check)
static func get_available_equipment(player_level: int, class_type: ClassData.ClassType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for equip_id in EQUIPMENT:
		var equip: Dictionary = EQUIPMENT[equip_id]
		if player_level < equip.get("level_req", 1):
			continue
		var class_req: Array = equip.get("class_req", [])
		if class_req.size() > 0 and class_type not in class_req:
			continue
		var entry := equip.duplicate(true)
		entry["id"] = equip_id
		result.append(entry)
	return result


## Check if a player can equip an item
static func can_equip(equip_id: String, player_level: int, class_type: ClassData.ClassType) -> Dictionary:
	var equip := EQUIPMENT.get(equip_id, {})
	if equip.is_empty():
		return {"can_equip": false, "reason": "Equipment not found"}

	if player_level < equip.get("level_req", 1):
		return {"can_equip": false, "reason": "Requires level " + str(equip["level_req"])}

	var class_req: Array = equip.get("class_req", [])
	if class_req.size() > 0 and class_type not in class_req:
		var class_names := []
		for ct in class_req:
			class_names.append(ClassData.get_class_name_str(ct))
		return {"can_equip": false, "reason": "Requires: " + ", ".join(class_names)}

	return {"can_equip": true, "reason": ""}


## Get the effective stats of equipment considering grade multiplier
static func get_effective_stats(equip_id: String) -> Dictionary:
	var equip := EQUIPMENT.get(equip_id, {})
	if equip.is_empty():
		return {}
	var grade: Grade = equip.get("grade", Grade.COMMON)
	var multiplier: float = GRADE_MULTIPLIER.get(grade, 1.0)
	var base_stats: Dictionary = equip.get("stats", {})
	var result := {}
	for stat in base_stats:
		# Negative stats (penalties) don't get multiplied
		if base_stats[stat] < 0:
			result[stat] = base_stats[stat]
		else:
			result[stat] = base_stats[stat] # Stats are already balanced per grade in the database
	return result


## Get grade display name
static func get_grade_name(grade: Grade) -> String:
	return GRADE_NAMES.get(grade, "Unknown")


## Get grade color
static func get_grade_color(grade: Grade) -> Color:
	return GRADE_COLORS.get(grade, Color.WHITE)
