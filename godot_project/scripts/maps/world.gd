extends Node3D
## Main game world (3D scaffold) — spawns the local player and HUD UI.
## Enemies, NPCs, zone backgrounds, minimap, world-map and waypoint arrow
## land in later migration steps (4, 5, 6, 8); see 3D_CONVERSION_PLAN.md.

const PlayerScene := preload("res://scenes/player/player.tscn")
const OtherPlayerScene := preload("res://scenes/player/other_player.tscn")
const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const NPCScene := preload("res://scenes/npcs/npc.tscn")

# Toggle on after enemy/NPC/UI ports complete.
const SPAWN_ENEMIES: bool = false
const SPAWN_NPCS: bool = false
const ENABLE_WORLD_POSITION_UI: bool = false

@onready var entities: Node3D = $Entities
@onready var ui_layer: CanvasLayer = $UILayer
@onready var ground: Node3D = $Ground

var local_player: Player = null
var other_players: Dictionary = {} # peer_id -> OtherPlayer node

var skill_bar_node: PanelContainer = null
var grind_tracker_node: PanelContainer = null
var enhancement_panel_node: PanelContainer = null
var comparison_panel_node: PanelContainer = null
var zone_indicator_node: PanelContainer = null
var damage_numbers_node: Node3D = null
var minimap_node: PanelContainer = null
var world_map_node: CanvasLayer = null
var waypoint_arrow_node: Control = null

func _ready() -> void:
	_spawn_local_player()
	if SPAWN_ENEMIES:
		_spawn_zone_enemies()
	if SPAWN_NPCS:
		_spawn_npcs()
	_setup_grinding_ui()

	EventBus.player_joined.connect(_on_player_joined)
	EventBus.player_left.connect(_on_player_left)

	call_deferred("_apply_saved_state")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_grind_tracker") and grind_tracker_node:
		grind_tracker_node.toggle_visible()

	if Input.is_action_just_pressed("toggle_enhancement") and enhancement_panel_node:
		enhancement_panel_node.visible = not enhancement_panel_node.visible

	if ENABLE_WORLD_POSITION_UI:
		_update_world_position_ui()

func _update_world_position_ui() -> void:
	# Stub for the post-step-4 fan-out. Will read local_player.global_position.x/.z
	# and feed Vector2 into ZoneData / minimap / waypoint as needed.
	pass

func _spawn_local_player() -> void:
	local_player = PlayerScene.instantiate() as Player
	local_player.is_local = true
	local_player.player_peer_id = GameManager.player_id
	local_player.global_position = Vector3(0, 1, 0)
	entities.add_child(local_player)

func _spawn_zone_enemies() -> void:
	# Re-enabled in step 4 once Enemy ports to CharacterBody3D.
	pass

func _spawn_npcs() -> void:
	# Re-enabled in step 6 once NPC ports to CharacterBody3D.
	pass

func _setup_grinding_ui() -> void:
	var SkillBarScript := preload("res://scripts/ui/skill_bar.gd")
	skill_bar_node = PanelContainer.new()
	skill_bar_node.set_script(SkillBarScript)
	ui_layer.add_child(skill_bar_node)
	if local_player and local_player.get_skill_system():
		skill_bar_node.setup(local_player.get_skill_system())

	var GrindTrackerScript := preload("res://scripts/ui/grind_tracker.gd")
	grind_tracker_node = PanelContainer.new()
	grind_tracker_node.set_script(GrindTrackerScript)
	ui_layer.add_child(grind_tracker_node)

	var EnhancementScript := preload("res://scripts/ui/enhancement_panel.gd")
	enhancement_panel_node = PanelContainer.new()
	enhancement_panel_node.set_script(EnhancementScript)
	ui_layer.add_child(enhancement_panel_node)
	if local_player and local_player.get_equipment_system():
		var inv_panel := _find_inventory_panel()
		if inv_panel and inv_panel.inventory:
			local_player.get_equipment_system().setup_inventory(inv_panel.inventory)
		enhancement_panel_node.setup(local_player.get_equipment_system())

	var ComparisonScript := preload("res://scripts/ui/equipment_comparison_panel.gd")
	comparison_panel_node = PanelContainer.new()
	comparison_panel_node.set_script(ComparisonScript)
	ui_layer.add_child(comparison_panel_node)
	if local_player and local_player.get_equipment_system():
		comparison_panel_node.setup(local_player.get_equipment_system())

	# World-position-aware UI is re-wired in steps 6/8/9.
	if not ENABLE_WORLD_POSITION_UI:
		return

	var ZoneIndicatorScript := preload("res://scripts/ui/zone_indicator.gd")
	zone_indicator_node = PanelContainer.new()
	zone_indicator_node.set_script(ZoneIndicatorScript)
	ui_layer.add_child(zone_indicator_node)

	var DamageNumbersScript := preload("res://scripts/ui/damage_numbers.gd")
	damage_numbers_node = Node3D.new()
	damage_numbers_node.set_script(DamageNumbersScript)
	entities.add_child(damage_numbers_node)

	var MinimapScript := preload("res://scripts/ui/minimap.gd")
	minimap_node = PanelContainer.new()
	minimap_node.set_script(MinimapScript)
	ui_layer.add_child(minimap_node)
	minimap_node.setup(local_player)

	var WorldMapScript := preload("res://scripts/ui/world_map.gd")
	world_map_node = CanvasLayer.new()
	world_map_node.set_script(WorldMapScript)
	add_child(world_map_node)
	world_map_node.setup(local_player)

	var WaypointArrowScript := preload("res://scripts/ui/waypoint_arrow.gd")
	waypoint_arrow_node = Control.new()
	waypoint_arrow_node.set_script(WaypointArrowScript)
	waypoint_arrow_node.anchor_right = 1.0
	waypoint_arrow_node.anchor_bottom = 1.0
	ui_layer.add_child(waypoint_arrow_node)
	waypoint_arrow_node.setup(local_player)

func _on_player_joined(peer_id: int, player_name: String) -> void:
	if peer_id == GameManager.player_id:
		return
	var other := OtherPlayerScene.instantiate() as OtherPlayer
	other.peer_id = peer_id
	other.player_name = player_name
	entities.add_child(other)
	other_players[peer_id] = other

func _on_player_left(peer_id: int) -> void:
	if peer_id in other_players:
		other_players[peer_id].queue_free()
		other_players.erase(peer_id)

func _find_inventory_panel() -> InventoryPanel:
	for child in ui_layer.get_children():
		if child is InventoryPanel:
			return child
	return null

func get_comparison_panel() -> PanelContainer:
	return comparison_panel_node

func _apply_saved_state() -> void:
	SaveManager.apply_pending_state()
	SaveManager.start_playtime_tracking()
