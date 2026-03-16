extends Node
## Save system with 5 character slots, auto-save, and full state serialization.

signal save_completed(slot: int)
signal load_completed(slot: int)
signal slot_deleted(slot: int)

const MAX_SLOTS := 5
const SAVE_DIR := "user://saves/"
const AUTO_SAVE_INTERVAL := 60.0 # Auto-save every 60 seconds

var current_slot: int = -1 # -1 means no slot loaded
var auto_save_timer: float = 0.0
var auto_save_enabled: bool = true

func _ready() -> void:
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _process(delta: float) -> void:
	if not auto_save_enabled or current_slot < 0 or not GameManager.is_in_game:
		return
	auto_save_timer += delta
	if auto_save_timer >= AUTO_SAVE_INTERVAL:
		auto_save_timer = 0.0
		save_game(current_slot)

## Get the file path for a slot
func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot

## Check if a slot has save data
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))

## Get summary info for a slot (for the character select screen)
func get_slot_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_get_save_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	var data: Dictionary = json.data
	return {
		"name": data.get("player_name", "Unknown"),
		"class": data.get("player_class", 0),
		"level": data.get("stats", {}).get("level", 1),
		"gear_score": data.get("gear_score", 0),
		"silver": data.get("silver", 0),
		"playtime": data.get("playtime", 0),
		"last_saved": data.get("last_saved", ""),
	}

## Get summary for all slots
func get_all_slot_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in MAX_SLOTS:
		result.append(get_slot_info(i))
	return result

## Save the current game state to a slot
func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false

	var data := _serialize_game_state()
	data["last_saved"] = Time.get_datetime_string_from_system()

	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(_get_save_path(slot), FileAccess.WRITE)
	if file == null:
		print("SaveManager: Failed to open save file for slot %d" % slot)
		return false
	file.store_string(json_string)
	file.close()

	current_slot = slot
	save_completed.emit(slot)
	print("SaveManager: Game saved to slot %d" % slot)
	return true

## Load game state from a slot
func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	if not has_save(slot):
		return false

	var file := FileAccess.open(_get_save_path(slot), FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		print("SaveManager: Failed to parse save file for slot %d" % slot)
		return false

	var data: Dictionary = json.data
	_deserialize_game_state(data)

	current_slot = slot
	auto_save_timer = 0.0
	load_completed.emit(slot)
	print("SaveManager: Game loaded from slot %d" % slot)
	return true

## Delete a save slot
func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	var path := _get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if current_slot == slot:
		current_slot = -1
	slot_deleted.emit(slot)
	return true

## Create a new character in a slot
func create_character(slot: int, char_name: String, class_type: ClassData.ClassType) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	if has_save(slot):
		return false # Slot already occupied

	# Set up fresh character
	GameManager.select_class(class_type)
	GameManager.player_name = char_name
	SilverManager.silver = 0
	SilverManager.start_session()

	# Save initial state
	current_slot = slot
	return save_game(slot)

## Serialize full game state to a dictionary
func _serialize_game_state() -> Dictionary:
	var data := {}

	# Player identity
	data["player_name"] = GameManager.player_name
	data["player_class"] = GameManager.player_class

	# Stats (full copy)
	data["stats"] = GameManager.player_stats.duplicate(true)

	# Skill tree
	data["skill_points"] = GameManager.skill_points
	data["total_skill_points_earned"] = GameManager.total_skill_points_earned
	data["skill_levels"] = GameManager.skill_levels.duplicate(true)

	# Silver
	data["silver"] = SilverManager.silver

	# Inventory
	var inv_items := []
	var inv := _get_inventory()
	if inv:
		for item in inv.get_all_items():
			if item.is_empty():
				inv_items.append({})
			else:
				inv_items.append(item.duplicate(true))
	data["inventory"] = inv_items

	# Equipment
	var equip_sys := _get_equipment_system()
	var equipped := {}
	if equip_sys:
		for slot in equip_sys.equipped:
			equipped[slot] = equip_sys.equipped[slot].duplicate(true)
		data["failstacks"] = equip_sys.failstacks
		data["enhancement_history"] = equip_sys.enhancement_history.duplicate(true)
		data["gear_score"] = equip_sys.get_gear_score()
	data["equipped"] = equipped

	# Playtime tracking
	data["playtime"] = _get_total_playtime()

	# Position
	var player := _get_local_player()
	if player:
		data["position"] = {"x": player.global_position.x, "y": player.global_position.y}
	else:
		data["position"] = {"x": 300, "y": 300}

	return data

## Deserialize game state from a dictionary
func _deserialize_game_state(data: Dictionary) -> void:
	# Player identity
	GameManager.player_name = data.get("player_name", "Player")
	GameManager.player_class = data.get("player_class", ClassData.ClassType.WARRIOR)

	# Stats
	var saved_stats: Dictionary = data.get("stats", {})
	for key in saved_stats:
		GameManager.player_stats[key] = saved_stats[key]

	# Skill tree
	GameManager.skill_points = data.get("skill_points", 0)
	GameManager.total_skill_points_earned = data.get("total_skill_points_earned", 0)
	GameManager.skill_levels = data.get("skill_levels", {})
	GameManager._apply_all_passives()

	# Silver
	SilverManager.silver = data.get("silver", 0)
	SilverManager.silver_changed.emit(SilverManager.silver)
	SilverManager.start_session()

	# Failstacks (restored when equipment system is available)
	_pending_failstacks = data.get("failstacks", 0)
	_pending_equipped = data.get("equipped", {})
	_pending_inventory = data.get("inventory", [])
	_pending_history = data.get("enhancement_history", [])
	_pending_position = data.get("position", {"x": 300, "y": 300})

## Pending data to apply once the world is loaded
var _pending_failstacks: int = 0
var _pending_equipped: Dictionary = {}
var _pending_inventory: Array = []
var _pending_history: Array = []
var _pending_position: Dictionary = {"x": 300, "y": 300}

## Call this after world scene is loaded to restore equipment, inventory, and position
func apply_pending_state() -> void:
	# Restore inventory
	var inv := _get_inventory()
	if inv and _pending_inventory.size() > 0:
		for i in inv.items.size():
			if i < _pending_inventory.size() and not _pending_inventory[i].is_empty():
				inv.items[i] = _pending_inventory[i].duplicate(true)
			else:
				inv.items[i] = {}
		inv.inventory_changed.emit()
		_pending_inventory = []

	# Restore equipment
	var equip_sys := _get_equipment_system()
	if equip_sys:
		equip_sys.equipped = _pending_equipped.duplicate(true)
		equip_sys.failstacks = _pending_failstacks
		for entry in _pending_history:
			equip_sys.enhancement_history.append(entry)
		equip_sys._recalculate_stats()
		_pending_equipped = {}
		_pending_history = []

	# Restore position
	var player := _get_local_player()
	if player:
		player.global_position = Vector2(
			_pending_position.get("x", 300),
			_pending_position.get("y", 300)
		)

## Helper to find the local player node
func _get_local_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("players")
	for p in players:
		if p.get("is_local") == true:
			return p
	return null

## Helper to find the inventory
func _get_inventory() -> Inventory:
	var world := get_tree().current_scene
	if world and world.has_method("_find_inventory_panel"):
		var panel = world._find_inventory_panel()
		if panel and panel.inventory:
			return panel.inventory
	# Fallback: search UI layer
	for node in get_tree().get_nodes_in_group("inventory"):
		if node is Inventory:
			return node
	return null

## Helper to find the equipment system
func _get_equipment_system() -> EquipmentSystem:
	var player := _get_local_player()
	if player and player.has_method("get_equipment_system"):
		return player.get_equipment_system()
	return null

## Playtime tracking
var _session_start_time: float = 0.0
var _accumulated_playtime: float = 0.0

func start_playtime_tracking(accumulated: float = 0.0) -> void:
	_session_start_time = Time.get_unix_time_from_system()
	_accumulated_playtime = accumulated

func _get_total_playtime() -> float:
	if _session_start_time <= 0.0:
		return _accumulated_playtime
	return _accumulated_playtime + (Time.get_unix_time_from_system() - _session_start_time)

func format_playtime(seconds: float) -> String:
	var total := int(seconds)
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	return "%dm" % minutes
