extends Node
## Headless integration smoke test for the bounded offline quest loop.

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("VERTICAL SLICE SMOKE: " + message)

func _run() -> void:
	var game_manager = get_node("/root/GameManager")
	var silver_manager = get_node("/root/SilverManager")
	var save_manager = get_node("/root/SaveManager")
	var event_bus = get_node("/root/EventBus")
	game_manager.reset_state()
	var requested_class := int(OS.get_environment("PIXEL_TEST_CLASS") if OS.has_environment("PIXEL_TEST_CLASS") else "0")
	game_manager.select_class(requested_class as ClassData.ClassType)
	var expected_weapon := CombatProfile.quest_weapon_id(game_manager.player_class)
	silver_manager.silver = 0
	save_manager.delete_save(0)
	save_manager.current_slot = 0
	var packed_world := load("res://scenes/maps/world.tscn") as PackedScene
	var world = packed_world.instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame
	_require(world != null, "world scene is missing")
	_require(world.vertical_slice_node != null, "objective card is missing")
	_require(get_tree().get_nodes_in_group("enemies").size() == 12, "slice should start with twelve Slime Fields enemies")

	event_bus.npc_interacted.emit("Elder Gorn")
	_require(game_manager.slice_state["stage"] == "hunt", "Elder Gorn did not start the quest")

	for index in 5:
		event_bus.mob_defeated.emit("slime", 1000 + index)
	await get_tree().process_frame
	_require(game_manager.slice_state["stage"] == "equip", "five kills did not grant quest loot")

	var inventory: Inventory = world._find_inventory_panel().inventory
	_require(inventory.count_item(expected_weapon) == 1, "class quest weapon reward is missing")
	_require(inventory.count_item("enchant_stone") == 3, "Black Stone reward is missing")
	_require(silver_manager.silver >= 3500, "enhancement silver is missing")

	var weapon_slot := -1
	for index in inventory.items.size():
		if inventory.items[index].get("id", "") == expected_weapon:
			weapon_slot = index
			break
	_require(weapon_slot >= 0, "reward weapon has no inventory slot")
	inventory.use_item(weapon_slot)
	await get_tree().process_frame
	_require(game_manager.slice_state["stage"] == "enhance", "equipping did not advance the objective")
	_require(inventory.count_item(expected_weapon) == 0, "equipped weapon was duplicated")

	var equipment_system: EquipmentSystem = world.local_player.get_equipment_system()
	_require(equipment_system.can_enhance("weapon")["can"], "quest supplies do not satisfy +1 enhancement")
	seed(1)
	_require(equipment_system.enhance_item("weapon"), "seeded +1 enhancement did not succeed")
	await get_tree().process_frame
	_require(game_manager.slice_state["stage"] == "boss", "enhancement did not unlock the boss")
	_require(equipment_system.get_equipped("weapon").get("enhance_level", 0) == 1, "weapon did not reach +1")
	_require(inventory.count_item("enchant_stone") == 2, "enhancement did not consume one Black Stone")
	_require(get_tree().get_nodes_in_group("slice_boss").size() == 1, "exactly one Slime King should spawn")

	event_bus.mob_defeated.emit("slime_king", 2000)
	_require(game_manager.slice_state["stage"] == "return", "boss defeat did not advance the quest")
	event_bus.npc_interacted.emit("Elder Gorn")
	_require(game_manager.slice_state["stage"] == "complete", "returning to Elder Gorn did not complete the quest")
	_require(silver_manager.silver >= 5000, "completion reward is missing")

	_require(save_manager.save_game(0), "completion state did not save")
	game_manager.slice_state = {"stage": "offer", "slimes_defeated": 0}
	equipment_system.equipped.clear()
	for index in inventory.items.size():
		inventory.items[index] = {}
	_require(save_manager.load_game(0), "saved character did not reload")
	save_manager.apply_pending_state()
	_require(game_manager.slice_state["stage"] == "complete", "quest completion did not survive reload")
	_require(equipment_system.get_equipped("weapon").get("enhance_level", 0) == 1, "enhanced weapon did not survive reload")
	_require(inventory.count_item("enchant_stone") == 2, "remaining quest materials did not survive reload")

	if failed:
		get_tree().quit(1)
	else:
		print("VERTICAL_SLICE_SMOKE_OK")
		get_tree().quit(0)
