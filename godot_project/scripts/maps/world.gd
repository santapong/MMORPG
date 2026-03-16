extends Node2D
## Main game world — spawns player, zone-based enemies, NPCs, and UI.
## BDO-inspired grinding zones with mob density.

const PlayerScene := preload("res://scenes/player/player.tscn")
const OtherPlayerScene := preload("res://scenes/player/other_player.tscn")
const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const NPCScene := preload("res://scenes/npcs/npc.tscn")

@onready var entities: Node2D = $Entities
@onready var ui_layer: CanvasLayer = $UILayer
@onready var ground: Node2D = $Ground

var local_player: Player = null
var other_players: Dictionary = {} # peer_id -> OtherPlayer node

# UI components
var skill_bar_node: PanelContainer = null
var grind_tracker_node: PanelContainer = null
var enhancement_panel_node: PanelContainer = null
var comparison_panel_node: PanelContainer = null
var zone_indicator_node: PanelContainer = null
var damage_numbers_node: Node2D = null
var minimap_node: PanelContainer = null
var world_map_node: CanvasLayer = null
var waypoint_arrow_node: Control = null

func _ready() -> void:
	_create_zone_backgrounds()
	_spawn_local_player()
	_spawn_zone_enemies()
	_spawn_npcs()
	_setup_grinding_ui()

	# Listen for other players joining/leaving
	EventBus.player_joined.connect(_on_player_joined)
	EventBus.player_left.connect(_on_player_left)

func _process(_delta: float) -> void:
	# Sync remote player positions
	for peer_id in NetworkManager.players:
		if peer_id == GameManager.player_id:
			continue
		if peer_id in other_players:
			var pos: Vector2 = NetworkManager.players[peer_id].get("position", Vector2.ZERO)
			other_players[peer_id].update_position(pos)

	# Update zone indicator based on player position
	if local_player and zone_indicator_node:
		zone_indicator_node.update_zone(local_player.global_position)
		# Also update grind tracker with current zone name
		if grind_tracker_node:
			var zone_id := ZoneData.get_zone_at_position(local_player.global_position)
			var zone := ZoneData.get_zone(zone_id)
			grind_tracker_node.update_zone(zone.get("name", "Unknown"))

	# Toggle grind tracker with G
	if Input.is_action_just_pressed("toggle_grind_tracker") and grind_tracker_node:
		grind_tracker_node.toggle_visible()

	# Toggle enhancement panel with P
	if Input.is_action_just_pressed("toggle_enhancement") and enhancement_panel_node:
		enhancement_panel_node.visible = not enhancement_panel_node.visible

	# Toggle world map with M
	if Input.is_action_just_pressed("toggle_world_map") and world_map_node:
		world_map_node.visible = not world_map_node.visible

func _create_zone_backgrounds() -> void:
	## Create colored rectangles for each zone on the ground layer
	for zone_id in ZoneData.ZONES:
		var zone: Dictionary = ZoneData.ZONES[zone_id]
		var bounds: Rect2 = zone["bounds"]
		var tier: int = zone.get("tier", ZoneData.ZoneTier.SAFE)
		var color: Color = ZoneData.ZONE_COLORS.get(tier, Color(0.2, 0.35, 0.15))

		var rect := ColorRect.new()
		rect.position = bounds.position
		rect.size = bounds.size
		rect.color = color
		ground.add_child(rect)

		# Zone name label on the ground
		var label := Label.new()
		label.text = zone.get("name", "")
		label.position = bounds.position + Vector2(10, 10)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
		ground.add_child(label)

func _spawn_local_player() -> void:
	local_player = PlayerScene.instantiate() as Player
	local_player.is_local = true
	local_player.player_peer_id = GameManager.player_id
	local_player.global_position = Vector2(300, 300) # Starter village
	entities.add_child(local_player)

func _spawn_zone_enemies() -> void:
	## Spawn enemies based on zone data — BDO-style mob density per zone
	for zone_id in ZoneData.ZONES:
		var zone: Dictionary = ZoneData.ZONES[zone_id]
		var mobs: Array = zone.get("mobs", [])
		var mob_count: int = zone.get("mob_count", 0)
		var bounds: Rect2 = zone.get("bounds", Rect2())
		var zone_silver: int = zone.get("silver_per_mob", 0)
		var zone_respawn: float = zone.get("respawn_time", 10.0)

		if mobs.is_empty() or mob_count == 0:
			continue

		# Calculate total weight for weighted random
		var total_weight := 0
		for mob in mobs:
			total_weight += mob.get("weight", 1)

		for i in mob_count:
			# Pick a mob type based on weights
			var roll := randi() % total_weight
			var accumulated := 0
			var selected_mob: Dictionary = mobs[0]
			for mob in mobs:
				accumulated += mob.get("weight", 1)
				if roll < accumulated:
					selected_mob = mob
					break

			var enemy := EnemyScene.instantiate() as Enemy
			var mob_id: String = selected_mob.get("id", "slime")
			var mob_name: String = selected_mob.get("name", "Slime")
			enemy.enemy_name = mob_name
			enemy.setup_from_mob_id(mob_id, zone_silver)
			enemy.respawn_time = zone_respawn

			# Random position within zone bounds (with margin)
			var margin := 40.0
			var pos := Vector2(
				randf_range(bounds.position.x + margin, bounds.end.x - margin),
				randf_range(bounds.position.y + margin, bounds.end.y - margin)
			)
			enemy.global_position = pos
			enemy.spawn_position = pos
			enemy.nametag.text = mob_name
			entities.add_child(enemy)

func _spawn_npcs() -> void:
	var npc_data := [
		{
			"name": "Elder Gorn",
			"pos": Vector2(200, 200),
			"dialog": [
				"Welcome, adventurer! This is the starting village.",
				"Head east to the Slime Fields for your first grinding spot.",
				"The wolves to the south are tougher — be careful!",
				"When you get stronger, try the Bandit Camp to the southeast.",
				"Legends speak of cursed ruins and demon rifts far to the east..."
			],
		},
		{
			"name": "Merchant Lyra",
			"pos": Vector2(150, 400),
			"dialog": [
				"Looking to buy something?",
				"Sell your trash loot for silver, then enhance your gear!",
				"Black Stones drop from tough monsters. Use them to enhance equipment.",
				"Press P to open the Enhancement panel."
			],
			"is_shop": true,
		},
		{
			"name": "Grind Guide Rex",
			"pos": Vector2(400, 200),
			"dialog": [
				"Want to know the best grind spots?",
				"Slime Fields (Lv1+): Easy silver, good for beginners.",
				"Wolf Forest (Lv5+): Better exp, watch out for Alpha Wolves.",
				"Bandit Camp (Lv10+): Decent silver, Bandit Chiefs drop rings.",
				"Cursed Ruins (Lv20+): Great loot, Liches drop Black Stones!",
				"Demon Rift (Lv35+): Endgame. Demon Lords drop the best gear.",
				"Press G to toggle the Grind Tracker!"
			],
		},
	]

	for data in npc_data:
		var npc := NPCScene.instantiate() as NPC
		npc.npc_name = data["name"]
		npc.global_position = data["pos"]
		npc.dialog_lines = data["dialog"]
		npc.is_shopkeeper = data.get("is_shop", false)
		entities.add_child(npc)

func _setup_grinding_ui() -> void:
	# Skill bar
	var SkillBarScript := preload("res://scripts/ui/skill_bar.gd")
	skill_bar_node = PanelContainer.new()
	skill_bar_node.set_script(SkillBarScript)
	ui_layer.add_child(skill_bar_node)
	# Connect skill system after player is ready
	if local_player and local_player.get_skill_system():
		skill_bar_node.setup(local_player.get_skill_system())

	# Grind tracker
	var GrindTrackerScript := preload("res://scripts/ui/grind_tracker.gd")
	grind_tracker_node = PanelContainer.new()
	grind_tracker_node.set_script(GrindTrackerScript)
	ui_layer.add_child(grind_tracker_node)

	# Enhancement panel
	var EnhancementScript := preload("res://scripts/ui/enhancement_panel.gd")
	enhancement_panel_node = PanelContainer.new()
	enhancement_panel_node.set_script(EnhancementScript)
	ui_layer.add_child(enhancement_panel_node)
	if local_player and local_player.get_equipment_system():
		# Connect equipment system to inventory for material tracking
		var inv_panel := _find_inventory_panel()
		if inv_panel and inv_panel.inventory:
			local_player.get_equipment_system().setup_inventory(inv_panel.inventory)
		enhancement_panel_node.setup(local_player.get_equipment_system())

	# Equipment comparison panel
	var ComparisonScript := preload("res://scripts/ui/equipment_comparison_panel.gd")
	comparison_panel_node = PanelContainer.new()
	comparison_panel_node.set_script(ComparisonScript)
	ui_layer.add_child(comparison_panel_node)
	if local_player and local_player.get_equipment_system():
		comparison_panel_node.setup(local_player.get_equipment_system())

	# Zone indicator
	var ZoneIndicatorScript := preload("res://scripts/ui/zone_indicator.gd")
	zone_indicator_node = PanelContainer.new()
	zone_indicator_node.set_script(ZoneIndicatorScript)
	ui_layer.add_child(zone_indicator_node)

	# Damage numbers
	var DamageNumbersScript := preload("res://scripts/ui/damage_numbers.gd")
	damage_numbers_node = Node2D.new()
	damage_numbers_node.set_script(DamageNumbersScript)
	entities.add_child(damage_numbers_node)

	# Minimap
	var MinimapScript := preload("res://scripts/ui/minimap.gd")
	minimap_node = PanelContainer.new()
	minimap_node.set_script(MinimapScript)
	ui_layer.add_child(minimap_node)
	minimap_node.setup(local_player)

	# World map overlay
	var WorldMapScript := preload("res://scripts/ui/world_map.gd")
	world_map_node = CanvasLayer.new()
	world_map_node.set_script(WorldMapScript)
	add_child(world_map_node)
	world_map_node.setup(local_player)

	# Waypoint navigation arrow
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
