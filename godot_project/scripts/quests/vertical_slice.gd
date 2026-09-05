extends PanelContainer
class_name VerticalSlice
## A complete offline demo loop: accept, hunt, loot, equip, enhance, defeat
## the Slime King, and return to Elder Gorn.

const CombatProfiles := preload("res://scripts/combat/combat_profile.gd")

const QUEST_ID: int = 1
const SLIME_TARGET: int = 5

var world: Node3D = null
var title_label := Label.new()
var objective_label := Label.new()
var progress_label := Label.new()

func _ready() -> void:
	_build_ui()
	EventBus.npc_interacted.connect(_on_npc_interacted)
	EventBus.mob_defeated.connect(_on_mob_defeated)
	EventBus.equipment_equipped.connect(_on_equipment_equipped)
	EventBus.enhancement_result.connect(_on_enhancement_result)
	_refresh()

func setup(world_node: Node3D) -> void:
	world = world_node
	if _stage() == "boss":
		world.call_deferred("spawn_slice_boss")

func _build_ui() -> void:
	name = "VerticalSlice"
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -390.0
	offset_right = -24.0
	offset_top = 24.0
	offset_bottom = 142.0
	custom_minimum_size = Vector2(330, 118)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	margin.add_child(content)

	title_label.text = "THE SLIME CROWN"
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.35))
	content.add_child(title_label)

	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 12)
	content.add_child(objective_label)

	progress_label.add_theme_font_size_override("font_size", 10)
	progress_label.add_theme_color_override("font_color", Color(0.72, 0.75, 0.78))
	content.add_child(progress_label)

func _stage() -> String:
	return str(GameManager.slice_state.get("stage", "offer"))

func _set_stage(next_stage: String) -> void:
	GameManager.slice_state["stage"] = next_stage
	_refresh()
	_checkpoint()

func _refresh() -> void:
	match _stage():
		"offer":
			objective_label.text = "Talk to Elder Gorn in Starter Village [E]."
			progress_label.text = "Accept his first hunt."
		"hunt":
			var defeated := int(GameManager.slice_state.get("slimes_defeated", 0))
			objective_label.text = "Hunt slimes east of the village."
			progress_label.text = "%d / %d slimes defeated" % [defeated, SLIME_TARGET]
		"equip":
			var weapon := EquipmentData.get_equipment(CombatProfiles.quest_weapon_id(GameManager.player_class))
			objective_label.text = "Open Inventory [I] and equip the %s." % weapon.get("name", "quest weapon")
			progress_label.text = "Equip your quest loot."
		"enhance":
			objective_label.text = "Open Enhancement [P] and improve the weapon."
			progress_label.text = "Black Stones and silver were supplied."
		"boss":
			objective_label.text = "Defeat the Slime King in the glowing field arena."
			progress_label.text = "The crown awaits east of the village."
		"return":
			objective_label.text = "Return to Elder Gorn [E]."
			progress_label.text = "Report your victory."
		"complete":
			objective_label.text = "Quest complete — the village is safe."
			progress_label.text = "Vertical slice complete. Progress saved."

func _on_npc_interacted(npc_name: String) -> void:
	if npc_name != "Elder Gorn":
		return
	if _stage() == "offer":
		GameManager.slice_state["slimes_defeated"] = 0
		EventBus.quest_accepted.emit(QUEST_ID)
		_set_stage("hunt")
	elif _stage() == "return":
		SilverManager.add_silver(2500, "quest_complete")
		EventBus.quest_completed.emit(QUEST_ID)
		_set_stage("complete")

func _on_mob_defeated(mob_id: String, _entity_id: int) -> void:
	if _stage() == "hunt" and mob_id in ["slime", "big_slime"]:
		var defeated := mini(SLIME_TARGET, int(GameManager.slice_state.get("slimes_defeated", 0)) + 1)
		GameManager.slice_state["slimes_defeated"] = defeated
		if defeated >= SLIME_TARGET:
			_grant_hunt_reward()
		else:
			_refresh()
			_checkpoint()
	elif _stage() == "boss" and mob_id == "slime_king":
		_set_stage("return")

func _grant_hunt_reward() -> void:
	var inventory := _inventory()
	if inventory == null:
		return
	var weapon := EquipmentData.get_equipment(CombatProfiles.quest_weapon_id(GameManager.player_class))
	weapon = CombatProfiles.apply_loot_trait(weapon, _class_loot_trait())
	weapon["type"] = "equipment"
	weapon["stackable"] = false
	inventory.add_item(weapon)
	inventory.add_item({
		"id": EquipmentSystem.MAT_WEAPON_STONE,
		"name": "Black Stone (Weapon)",
		"type": "enhancement_mat",
		"stackable": true,
		"quantity": 3,
	})
	SilverManager.add_silver(3500, "quest_supply")
	_set_stage("equip")

func _class_loot_trait() -> String:
	match GameManager.player_class:
		ClassData.ClassType.WARRIOR: return "defense"
		ClassData.ClassType.MAGE: return "offense"
		ClassData.ClassType.RANGER: return "mobility"
	return "offense"

func _on_equipment_equipped(slot: String, _item: Dictionary) -> void:
	if _stage() == "equip" and slot == "weapon":
		_set_stage("enhance")

func _on_enhancement_result(slot: String, level: int, success: bool) -> void:
	if _stage() != "enhance" or slot != "weapon" or not success or level < 1:
		return
	_set_stage("boss")
	if world:
		world.spawn_slice_boss()

func _inventory() -> Inventory:
	if world == null or not world.has_method("_find_inventory_panel"):
		return null
	var panel = world._find_inventory_panel()
	return panel.inventory if panel else null

func _checkpoint() -> void:
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
