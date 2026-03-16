extends Node
class_name Inventory
## Player inventory system — manages items, stacking, and usage.

signal inventory_changed()

const MAX_SLOTS: int = 20

var items: Array[Dictionary] = []

func _ready() -> void:
	# Initialize empty slots
	items.resize(MAX_SLOTS)
	for i in MAX_SLOTS:
		items[i] = {}

	EventBus.item_picked_up.connect(add_item)

func add_item(item_data: Dictionary) -> bool:
	if item_data.is_empty():
		return false

	# Try to stack with existing item
	if item_data.get("stackable", false):
		for i in items.size():
			if items[i].get("id", "") == item_data.get("id", ""):
				items[i]["quantity"] = items[i].get("quantity", 1) + item_data.get("quantity", 1)
				inventory_changed.emit()
				EventBus.inventory_updated.emit()
				return true

	# Find empty slot
	for i in items.size():
		if items[i].is_empty():
			items[i] = item_data.duplicate()
			if not items[i].has("quantity"):
				items[i]["quantity"] = 1
			inventory_changed.emit()
			EventBus.inventory_updated.emit()
			return true

	# Inventory full
	print("Inventory is full!")
	return false

func remove_item(slot_index: int, quantity: int = 1) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return {}
	if items[slot_index].is_empty():
		return {}

	var item := items[slot_index].duplicate()
	items[slot_index]["quantity"] = items[slot_index].get("quantity", 1) - quantity

	if items[slot_index]["quantity"] <= 0:
		items[slot_index] = {}

	inventory_changed.emit()
	EventBus.inventory_updated.emit()
	return item

func use_item(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	if items[slot_index].is_empty():
		return

	var item := items[slot_index]
	match item.get("type", ""):
		"consumable":
			_use_consumable(item)
			remove_item(slot_index)
		"equipment":
			_equip_item(item, slot_index)

func _use_consumable(item: Dictionary) -> void:
	match item.get("effect", ""):
		"heal":
			var heal_amount: int = item.get("value", 20)
			GameManager.player_stats["hp"] = min(
				GameManager.player_stats["hp"] + heal_amount,
				GameManager.player_stats["max_hp"]
			)
			EventBus.player_health_changed.emit(
				GameManager.player_id,
				GameManager.player_stats["hp"],
				GameManager.player_stats["max_hp"]
			)
		"mana":
			var mana_amount: int = item.get("value", 15)
			GameManager.player_stats["mp"] = min(
				GameManager.player_stats["mp"] + mana_amount,
				GameManager.player_stats["max_mp"]
			)
			EventBus.player_mana_changed.emit(
				GameManager.player_id,
				GameManager.player_stats["mp"],
				GameManager.player_stats["max_mp"]
			)
	EventBus.item_used.emit(item)

func _equip_item(_item: Dictionary, _slot_index: int) -> void:
	# Equipment system can be expanded
	pass

func get_item(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return {}
	return items[slot_index]

func get_all_items() -> Array[Dictionary]:
	return items
