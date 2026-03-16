extends Node
class_name EquipmentSystem
## BDO-inspired equipment and enhancement system (+1 to +20).
## Now supports grades, level requirements, and expanded stats.

signal equipment_changed(slot: String)
signal enhancement_success(slot: String, new_level: int)
signal enhancement_failed(slot: String, level: int)

## Equipment slots
const SLOTS := ["weapon", "body", "helmet", "gloves", "boots", "ring", "necklace"]

## Enhancement success rates (BDO-style declining rates)
const ENHANCEMENT_RATES := {
	1: 0.95, 2: 0.90, 3: 0.85, 4: 0.80, 5: 0.75,
	6: 0.65, 7: 0.55, 8: 0.45, 9: 0.35, 10: 0.30,
	11: 0.25, 12: 0.20, 13: 0.15, 14: 0.10, 15: 0.075,
	16: 0.05, 17: 0.04, 18: 0.03, 19: 0.02, 20: 0.01,
}

## Base enhancement stat bonus per level per slot
const ENHANCE_BONUS_PER_LEVEL := {
	"weapon": {"attack": 3, "defense": 0},
	"body": {"attack": 0, "defense": 3},
	"helmet": {"attack": 0, "defense": 2},
	"gloves": {"attack": 1, "defense": 1},
	"boots": {"attack": 0, "defense": 2},
	"ring": {"attack": 2, "defense": 0},
	"necklace": {"attack": 1, "defense": 1},
}

## Silver cost per enhancement level
const ENHANCE_COST := {
	1: 1000, 2: 2000, 3: 3000, 4: 5000, 5: 8000,
	6: 12000, 7: 18000, 8: 25000, 9: 35000, 10: 50000,
	11: 80000, 12: 120000, 13: 180000, 14: 250000, 15: 400000,
	16: 600000, 17: 900000, 18: 1500000, 19: 2500000, 20: 5000000,
}

## Currently equipped items: slot -> item_data
var equipped: Dictionary = {}

## Failstack system (BDO-style: failed attempts increase next success rate)
var failstacks: int = 0

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

func enhance_item(slot: String) -> bool:
	## Try to enhance equipped item. BDO-style with failstacks.
	## Grade affects enhancement bonus multiplier.
	if not equipped.has(slot):
		return false

	var item: Dictionary = equipped[slot]
	var current_level: int = item.get("enhance_level", 0)
	var next_level := current_level + 1

	if next_level > 20:
		return false

	# Check cost
	var cost: int = ENHANCE_COST.get(next_level, 999999999)
	if not SilverManager.remove_silver(cost):
		return false

	# Calculate success rate with failstacks
	var base_rate: float = ENHANCEMENT_RATES.get(next_level, 0.01)
	var failstack_bonus: float = failstacks * 0.01 # +1% per failstack
	var final_rate: float = min(0.95, base_rate + failstack_bonus)

	if randf() < final_rate:
		# Success
		item["enhance_level"] = next_level
		failstacks = 0
		_recalculate_stats()
		enhancement_success.emit(slot, next_level)
		EventBus.enhancement_result.emit(slot, next_level, true)
		return true
	else:
		# Fail - BDO style: level can drop on high enhance
		failstacks += 1
		if next_level > 15 and current_level > 15:
			item["enhance_level"] = current_level - 1
		enhancement_failed.emit(slot, current_level)
		EventBus.enhancement_result.emit(slot, current_level, false)
		return false

func get_total_equipment_stats() -> Dictionary:
	## Calculate total stats from all equipped items including enhancement bonuses.
	## Expanded to support: attack, defense, max_hp, max_mp, crit_chance, speed
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

		# Add enhancement bonuses (scaled by grade)
		var bonus: Dictionary = ENHANCE_BONUS_PER_LEVEL.get(slot, {"attack": 0, "defense": 0})
		total["attack"] += int(bonus["attack"] * enhance_level * enhance_mult)
		total["defense"] += int(bonus["defense"] * enhance_level * enhance_mult)

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
	return "[" + grade_name + "] +" + str(level) + " " + name

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
