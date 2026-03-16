extends Node
class_name EquipmentSystem
## BDO-inspired equipment and enhancement system (+1 to +20).
## Supports grades, materials, Cron stones, forced enhancement (PRI-PEN),
## weapon/armor stat differentiation, and visual feedback.

signal equipment_changed(slot: String)
signal enhancement_success(slot: String, new_level: int)
signal enhancement_failed(slot: String, level: int)
signal enhancement_downgraded(slot: String, old_level: int, new_level: int)

## Equipment slots
const SLOTS := ["weapon", "body", "helmet", "gloves", "boots", "ring", "necklace"]

## Enhancement success rates (BDO-style declining rates)
const ENHANCEMENT_RATES := {
	1: 0.95, 2: 0.90, 3: 0.85, 4: 0.80, 5: 0.75,
	6: 0.65, 7: 0.55, 8: 0.45, 9: 0.35, 10: 0.30,
	11: 0.25, 12: 0.20, 13: 0.15, 14: 0.10, 15: 0.075,
	16: 0.05, 17: 0.04, 18: 0.03, 19: 0.02, 20: 0.01,
}

## Forced enhancement tier names (BDO-style)
const FORCED_ENHANCE_NAMES := {
	16: "PRI", 17: "DUO", 18: "TRI", 19: "TET", 20: "PEN",
}

## Expanded enhancement stat bonuses per level per slot (Section 6: Weapon vs Armor Differentiation)
const ENHANCE_BONUS_PER_LEVEL := {
	"weapon": {"attack": 3, "defense": 0, "crit_chance": 0.005, "max_hp": 0, "speed": 0.0},
	"body": {"attack": 0, "defense": 3, "crit_chance": 0.0, "max_hp": 5, "speed": 0.0},
	"helmet": {"attack": 0, "defense": 2, "crit_chance": 0.0, "max_hp": 3, "speed": 0.0},
	"gloves": {"attack": 1, "defense": 1, "crit_chance": 0.003, "max_hp": 0, "speed": 0.0},
	"boots": {"attack": 0, "defense": 2, "crit_chance": 0.0, "max_hp": 0, "speed": 2.0},
	"ring": {"attack": 2, "defense": 0, "crit_chance": 0.002, "max_hp": 0, "speed": 0.0},
	"necklace": {"attack": 1, "defense": 1, "crit_chance": 0.001, "max_hp": 2, "speed": 0.0},
}

## Silver cost per enhancement level
const ENHANCE_COST := {
	1: 1000, 2: 2000, 3: 3000, 4: 5000, 5: 8000,
	6: 12000, 7: 18000, 8: 25000, 9: 35000, 10: 50000,
	11: 80000, 12: 120000, 13: 180000, 14: 250000, 15: 400000,
	16: 600000, 17: 900000, 18: 1500000, 19: 2500000, 20: 5000000,
}

## Material requirements per enhancement level range
## 1 stone for +1-10, 2 for +11-15, 3 for +16-20
const MATERIAL_COST := {
	1: 1, 2: 1, 3: 1, 4: 1, 5: 1,
	6: 1, 7: 1, 8: 1, 9: 1, 10: 1,
	11: 2, 12: 2, 13: 2, 14: 2, 15: 2,
	16: 3, 17: 3, 18: 3, 19: 3, 20: 3,
}

## Material IDs
const MAT_WEAPON_STONE := "enchant_stone"
const MAT_ARMOR_STONE := "enchant_armor_stone"
const MAT_CONCENTRATED_WEAPON := "concentrated_weapon_stone"
const MAT_CONCENTRATED_ARMOR := "concentrated_armor_stone"
const MAT_CRON_STONE := "cron_stone"

## Cron stone cost by enhancement level and grade (base cost, scaled by grade)
const CRON_COST_BASE := {
	16: 10, 17: 20, 18: 40, 19: 80, 20: 150,
}
const CRON_GRADE_MULTIPLIER := {
	EquipmentData.Grade.COMMON: 1, EquipmentData.Grade.UNCOMMON: 2,
	EquipmentData.Grade.RARE: 3, EquipmentData.Grade.EPIC: 5,
	EquipmentData.Grade.LEGENDARY: 8,
}

## Failstack recommendation ranges per enhancement level
const FAILSTACK_RECOMMENDATION := {
	1: [0, 0], 2: [0, 0], 3: [0, 2], 4: [0, 3], 5: [0, 5],
	6: [2, 8], 7: [5, 12], 8: [8, 18], 9: [12, 25], 10: [15, 30],
	11: [18, 35], 12: [22, 40], 13: [28, 44], 14: [32, 50], 15: [40, 60],
	16: [25, 50], 17: [35, 60], 18: [44, 70], 19: [55, 90], 20: [70, 120],
}

## Currently equipped items: slot -> item_data
var equipped: Dictionary = {}

## Failstack system (BDO-style: failed attempts increase next success rate)
var failstacks: int = 0

## Cron stone toggle
var use_cron_stones: bool = false

## Enhancement history log (last 10 attempts)
var enhancement_history: Array[Dictionary] = []
const MAX_HISTORY := 10

## Reference to player inventory (set via setup)
var inventory: Inventory = null

func setup_inventory(inv: Inventory) -> void:
	inventory = inv

func get_equipped(slot: String) -> Dictionary:
	return equipped.get(slot, {})

func equip_item(item: Dictionary) -> Dictionary:
	## Equip an item. Returns the previously equipped item (or empty dict).
	## Now checks level requirements and class restrictions.
	var slot: String = item.get("slot", "")
	if slot.is_empty() or slot not in SLOTS:
		return {}

	# Check level requirement
	var level_req: int = item.get("level_req", 1)
	if GameManager.player_stats["level"] < level_req:
		return {}

	# Check class requirement
	var class_req: Array = item.get("class_req", [])
	if class_req.size() > 0 and GameManager.player_class not in class_req:
		return {}

	var previous := equipped.get(slot, {})
	equipped[slot] = item.duplicate(true)
	if not equipped[slot].has("enhance_level"):
		equipped[slot]["enhance_level"] = 0
	if not equipped[slot].has("grade"):
		equipped[slot]["grade"] = EquipmentData.Grade.COMMON
	_recalculate_stats()
	equipment_changed.emit(slot)
	EventBus.equipment_equipped.emit(slot, equipped[slot])
	return previous

func unequip_item(slot: String) -> Dictionary:
	if not equipped.has(slot):
		return {}
	var item := equipped[slot]
	equipped.erase(slot)
	_recalculate_stats()
	equipment_changed.emit(slot)
	EventBus.equipment_unequipped.emit(slot, item)
	return item

## Determine which material is required for a given slot and enhancement level
func get_required_material(slot: String, next_level: int) -> String:
	var is_weapon_slot := slot in ["weapon", "ring", "necklace"]
	if next_level >= 16:
		return MAT_CONCENTRATED_WEAPON if is_weapon_slot else MAT_CONCENTRATED_ARMOR
	return MAT_WEAPON_STONE if is_weapon_slot else MAT_ARMOR_STONE

## Get the display name of a material
static func get_material_name(mat_id: String) -> String:
	match mat_id:
		"enchant_stone": return "Black Stone (Weapon)"
		"enchant_armor_stone": return "Black Stone (Armor)"
		"concentrated_weapon_stone": return "Concentrated Black Stone (Weapon)"
		"concentrated_armor_stone": return "Concentrated Black Stone (Armor)"
		"cron_stone": return "Cron Stone"
		"advice_of_valks": return "Advice of Valks"
	return mat_id

## Get Cron stone cost for current enhancement
func get_cron_cost(slot: String) -> int:
	if not equipped.has(slot):
		return 0
	var item: Dictionary = equipped[slot]
	var next_level: int = item.get("enhance_level", 0) + 1
	if next_level < 16:
		return 0
	var base: int = CRON_COST_BASE.get(next_level, 0)
	var grade = item.get("grade", EquipmentData.Grade.COMMON)
	var mult: int = CRON_GRADE_MULTIPLIER.get(grade, 1)
	return base * mult

## Check if player has enough materials for enhancement
func can_enhance(slot: String) -> Dictionary:
	if not equipped.has(slot):
		return {"can": false, "reason": "No item equipped"}
	if inventory == null:
		return {"can": false, "reason": "No inventory"}

	var item: Dictionary = equipped[slot]
	var current_level: int = item.get("enhance_level", 0)
	var next_level := current_level + 1

	if next_level > 20:
		return {"can": false, "reason": "Already at max enhancement"}

	# Check silver
	var cost: int = ENHANCE_COST.get(next_level, 999999999)
	if SilverManager.silver < cost:
		return {"can": false, "reason": "Not enough silver"}

	# Check material
	var mat_id := get_required_material(slot, next_level)
	var mat_needed: int = MATERIAL_COST.get(next_level, 1)
	var mat_count := _count_material(mat_id)
	if mat_count < mat_needed:
		return {"can": false, "reason": "Need %d %s (have %d)" % [mat_needed, get_material_name(mat_id), mat_count]}

	# Check Cron stones if toggled on
	if use_cron_stones and next_level >= 16:
		var cron_cost := get_cron_cost(slot)
		var cron_count := _count_material(MAT_CRON_STONE)
		if cron_count < cron_cost:
			return {"can": false, "reason": "Need %d Cron Stones (have %d)" % [cron_cost, cron_count]}

	return {"can": true, "reason": ""}

func enhance_item(slot: String) -> bool:
	## Try to enhance equipped item. BDO-style with failstacks, materials, and Cron stones.
	var check := can_enhance(slot)
	if not check["can"]:
		return false

	var item: Dictionary = equipped[slot]
	var current_level: int = item.get("enhance_level", 0)
	var next_level := current_level + 1

	# Consume silver
	var cost: int = ENHANCE_COST.get(next_level, 999999999)
	if not SilverManager.remove_silver(cost):
		return false

	# Consume materials
	var mat_id := get_required_material(slot, next_level)
	var mat_needed: int = MATERIAL_COST.get(next_level, 1)
	_consume_material(mat_id, mat_needed)

	# Consume Cron stones if toggled
	var using_cron := use_cron_stones and next_level >= 16
	if using_cron:
		var cron_cost := get_cron_cost(slot)
		_consume_material(MAT_CRON_STONE, cron_cost)

	# Calculate success rate with failstacks
	var base_rate: float = ENHANCEMENT_RATES.get(next_level, 0.01)
	var failstack_bonus: float = failstacks * 0.01 # +1% per failstack
	var final_rate: float = min(0.95, base_rate + failstack_bonus)

	if randf() < final_rate:
		# Success
		item["enhance_level"] = next_level
		_add_history(slot, item.get("name", "Unknown"), current_level, next_level, true)
		failstacks = 0
		_recalculate_stats()
		enhancement_success.emit(slot, next_level)
		EventBus.enhancement_result.emit(slot, next_level, true)
		return true
	else:
		# Fail - BDO style: level drops on forced enhancement (+16 and above)
		failstacks += 1
		var downgraded := false
		if next_level > 15 and current_level > 15 and not using_cron:
			item["enhance_level"] = current_level - 1
			downgraded = true
			enhancement_downgraded.emit(slot, current_level, current_level - 1)
		_add_history(slot, item.get("name", "Unknown"), current_level, current_level if not downgraded else current_level - 1, false)
		_recalculate_stats()
		enhancement_failed.emit(slot, current_level)
		EventBus.enhancement_result.emit(slot, current_level, false)
		return false

## Set failstacks to a fixed value (Advice of Valks)
func use_advice_of_valks(valks_value: int) -> bool:
	if inventory == null:
		return false
	var idx := _find_material_index("advice_of_valks")
	if idx < 0:
		return false
	inventory.remove_item(idx)
	failstacks = valks_value
	return true

func get_total_equipment_stats() -> Dictionary:
	## Calculate total stats from all equipped items including enhancement bonuses.
	## Expanded to support differentiated bonuses per slot type.
	var total := {
		"attack": 0,
		"defense": 0,
		"max_hp": 0,
		"max_mp": 0,
		"crit_chance": 0.0,
		"speed": 0.0,
	}

	for slot in equipped:
		var item: Dictionary = equipped[slot]
		var stats: Dictionary = item.get("stats", {})
		var enhance_level: int = item.get("enhance_level", 0)
		var grade = item.get("grade", EquipmentData.Grade.COMMON)
		var enhance_mult: float = EquipmentData.GRADE_ENHANCE_MULTIPLIER.get(grade, 1.0)

		# Add base item stats
		for stat in stats:
			if total.has(stat):
				total[stat] += stats[stat]

		# Legacy support: direct attack/defense on item without stats dict
		if not stats.has("attack") and item.has("attack"):
			total["attack"] += item.get("attack", 0)
		if not stats.has("defense") and item.has("defense"):
			total["defense"] += item.get("defense", 0)

		# Add enhancement bonuses (scaled by grade) — differentiated per slot
		var bonus: Dictionary = ENHANCE_BONUS_PER_LEVEL.get(slot, {})
		for stat_key in bonus:
			if total.has(stat_key) and bonus[stat_key] != 0:
				if stat_key in ["crit_chance", "speed"]:
					total[stat_key] += bonus[stat_key] * enhance_level * enhance_mult
				else:
					total[stat_key] += int(bonus[stat_key] * enhance_level * enhance_mult)

	return total

## Get stats that an item would have at a specific enhancement level (for preview)
func get_enhanced_item_stats(item: Dictionary, slot: String, enhance_level: int) -> Dictionary:
	var total := {}
	var stats: Dictionary = item.get("stats", {})
	var grade = item.get("grade", EquipmentData.Grade.COMMON)
	var enhance_mult: float = EquipmentData.GRADE_ENHANCE_MULTIPLIER.get(grade, 1.0)

	# Base item stats
	for stat in stats:
		total[stat] = stats[stat]

	# Enhancement bonuses
	var bonus: Dictionary = ENHANCE_BONUS_PER_LEVEL.get(slot, {})
	for stat_key in bonus:
		if bonus[stat_key] != 0:
			var val = bonus[stat_key] * enhance_level * enhance_mult
			if stat_key in ["crit_chance", "speed"]:
				total[stat_key] = total.get(stat_key, 0.0) + val
			else:
				total[stat_key] = total.get(stat_key, 0) + int(val)

	return total

func _recalculate_stats() -> void:
	var equip_stats := get_total_equipment_stats()
	GameManager.player_stats["equip_attack"] = equip_stats["attack"]
	GameManager.player_stats["equip_defense"] = equip_stats["defense"]
	GameManager.player_stats["equip_max_hp"] = equip_stats["max_hp"]
	GameManager.player_stats["equip_max_mp"] = equip_stats["max_mp"]
	GameManager.player_stats["equip_crit_chance"] = equip_stats["crit_chance"]
	GameManager.player_stats["equip_speed"] = equip_stats["speed"]
	EventBus.equipment_stats_changed.emit(equip_stats)

func get_enhance_display_name(item: Dictionary) -> String:
	var level: int = item.get("enhance_level", 0)
	var name: String = item.get("name", "Unknown")
	var grade = item.get("grade", EquipmentData.Grade.COMMON)
	var grade_name := EquipmentData.get_grade_name(grade)
	if level == 0:
		return "[" + grade_name + "] " + name
	# Use forced enhancement names for +16 and above
	var level_str: String
	if level >= 16 and FORCED_ENHANCE_NAMES.has(level):
		level_str = FORCED_ENHANCE_NAMES[level]
	else:
		level_str = "+" + str(level)
	return "[" + grade_name + "] " + level_str + " " + name

func get_gear_score() -> int:
	## Calculate total gear score — a single number representing equipment power.
	var score := 0
	for slot in equipped:
		var item: Dictionary = equipped[slot]
		var grade = item.get("grade", EquipmentData.Grade.COMMON)
		var enhance_level: int = item.get("enhance_level", 0)
		var grade_value: int = [10, 20, 35, 55, 80][grade] # Points per grade
		score += grade_value + (enhance_level * 5)
	return score

## Enhancement history helpers
func _add_history(slot: String, item_name: String, from_level: int, to_level: int, success: bool) -> void:
	enhancement_history.push_front({
		"slot": slot,
		"item": item_name,
		"from": from_level,
		"to": to_level,
		"success": success,
		"failstacks": failstacks,
	})
	if enhancement_history.size() > MAX_HISTORY:
		enhancement_history.resize(MAX_HISTORY)

## Material helpers
func _count_material(mat_id: String) -> int:
	if inventory == null:
		return 0
	for item in inventory.get_all_items():
		if item.get("id", "") == mat_id:
			return item.get("quantity", 0)
	return 0

func _find_material_index(mat_id: String) -> int:
	if inventory == null:
		return -1
	var items := inventory.get_all_items()
	for i in items.size():
		if items[i].get("id", "") == mat_id:
			return i
	return -1

func _consume_material(mat_id: String, amount: int) -> bool:
	if inventory == null:
		return false
	var idx := _find_material_index(mat_id)
	if idx < 0:
		return false
	inventory.remove_item(idx, amount)
	return true
