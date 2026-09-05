extends Node3D
## Main 2.5D voxel-pixel world — spawns the hero, mobs, NPCs, props, and HUD.
## Pixel-space zone bounds from ZoneData are scaled by WORLD_SCALE into meters.
## World-position UIs (minimap / world map / waypoint / zone indicator) remain
## gated; they consume Vector2 pixel coords and project from the player's X/Z.

const WORLD_SCALE: float = 1.0 / 30.0

const PlayerScene := preload("res://scenes/player/player.tscn")
const OtherPlayerScene := preload("res://scenes/player/other_player.tscn")
const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const NPCScene := preload("res://scenes/npcs/npc.tscn")

const SPAWN_ENEMIES: bool = true
const SPAWN_NPCS: bool = true
const ENABLE_DAMAGE_NUMBERS: bool = true
const ENABLE_WORLD_POSITION_UI: bool = false
const VERTICAL_SLICE_MODE: bool = true

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
var vertical_slice_node: PanelContainer = null
var _pixel_materials: Dictionary = {}

func _ready() -> void:
	_build_pixel_world()
	_spawn_local_player()
	if SPAWN_ENEMIES:
		_spawn_zone_enemies()
	if SPAWN_NPCS:
		_spawn_npcs()
	_setup_grinding_ui()
	_setup_vertical_slice()
	_apply_pixel_ui_theme()

	EventBus.player_joined.connect(_on_player_joined)
	EventBus.player_left.connect(_on_player_left)

	call_deferred("_apply_saved_state")

func _build_pixel_world() -> void:
	var art := Node3D.new()
	art.name = "PixelWorldArt"
	art.add_to_group("pixel_world_art")
	ground.add_child(art)

	# A chunky village establishes the safe hub at a glance.
	_pixel_house(art, Vector3(-26.5, 0.0, -16.0), Color("b96555"), Color("633d52"))
	_pixel_house(art, Vector3(-19.5, 0.0, -15.5), Color("d18b55"), Color("694353"))
	_pixel_house(art, Vector3(-27.0, 0.0, -5.0), Color("638c72"), Color("3e4f52"))
	for tree_pos in [
		Vector3(-31, 0, -18), Vector3(-30, 0, -10), Vector3(-29, 0, -1),
		Vector3(-16, 0, -18), Vector3(-15, 0, -4), Vector3(-8, 0, -22),
		Vector3(2, 0, -22), Vector3(8, 0, -17), Vector3(8, 0, -5),
		Vector3(1, 0, 2), Vector3(-10, 0, 2)
	]:
		_pixel_tree(art, tree_pos)

	# Gold crumbs point from the quest giver toward the Slime Fields.
	for x in range(-22, -11, 2):
		_cube(art, Vector3(float(x), 0.08, -10.0), Vector3(0.32, 0.12, 0.32), Color("f6c85f"), true)

	# A block gate and banners make the combat zone boundary unmistakable.
	for side in [-1.0, 1.0]:
		_cube(art, Vector3(-13.3, 1.2, -10.0 + side * 2.0), Vector3(0.6, 2.4, 0.6), Color("543b3d"))
		_cube(art, Vector3(-13.0, 1.85, -10.0 + side * 2.0), Vector3(0.18, 0.85, 1.2), Color("79d173"))
	_cube(art, Vector3(-13.3, 2.45, -10.0), Vector3(0.6, 0.38, 4.6), Color("6f4b3e"))

	# Rocks and bright tufts break up the field using only hard-edged blocks.
	for rock_pos in [Vector3(-8, 0, -16), Vector3(-3, 0, -5), Vector3(3, 0, -14), Vector3(5, 0, -3)]:
		_cube(art, rock_pos + Vector3(0, 0.25, 0), Vector3(0.8, 0.5, 0.65), Color("60716d"))
		_cube(art, rock_pos + Vector3(0.32, 0.48, 0), Vector3(0.38, 0.35, 0.42), Color("82907d"))

	_pixel_zone_label(art, Vector3(-23.0, 3.3, -18.5), "STARTER VILLAGE  •  SAFE HUB", Color("fff1d2"))
	_pixel_zone_label(art, Vector3(-3.0, 3.5, -21.0), "SLIME FIELDS  •  COMBAT ZONE", Color("9bdd62"))

func _pixel_house(parent: Node3D, at: Vector3, wall_color: Color, roof_color: Color) -> void:
	_cube(parent, at + Vector3(0, 1.0, 0), Vector3(4.0, 2.0, 3.2), wall_color)
	_cube(parent, at + Vector3(0, 2.15, 0), Vector3(4.6, 0.45, 3.8), roof_color)
	_cube(parent, at + Vector3(0, 0.72, 1.63), Vector3(0.85, 1.44, 0.15), Color("2b2334"))
	_cube(parent, at + Vector3(-1.15, 1.25, 1.64), Vector3(0.55, 0.55, 0.12), Color("7ed6da"), true)

func _pixel_tree(parent: Node3D, at: Vector3) -> void:
	_cube(parent, at + Vector3(0, 1.0, 0), Vector3(0.65, 2.0, 0.65), Color("694936"))
	_cube(parent, at + Vector3(0, 2.25, 0), Vector3(2.3, 1.25, 2.0), Color("286049"))
	_cube(parent, at + Vector3(-0.35, 3.0, 0.1), Vector3(1.45, 0.75, 1.45), Color("347858"))

func _pixel_zone_label(parent: Node3D, at: Vector3, copy: String, color: Color) -> void:
	var label := Label3D.new()
	label.position = at
	label.text = copy
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	label.font_size = 12
	label.outline_size = 3
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)

func _cube(parent: Node3D, at: Vector3, size: Vector3, color: Color, glow := false) -> MeshInstance3D:
	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _pixel_material(color, glow)
	cube.mesh = box
	cube.position = at
	parent.add_child(cube)
	return cube

func _pixel_material(color: Color, glow := false) -> StandardMaterial3D:
	var key := color.to_html() + ("_glow" if glow else "")
	if _pixel_materials.has(key):
		return _pixel_materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if glow:
		material.emission_enabled = true
		material.emission = color.darkened(0.2)
		material.emission_energy_multiplier = 0.8
	_pixel_materials[key] = material
	return material

func _apply_pixel_ui_theme() -> void:
	for child in ui_layer.get_children():
		_apply_theme_to_branch(child)

func _apply_theme_to_branch(node: Node) -> void:
	if node is Control:
		(node as Control).theme = PixelTheme.build()
	for child in node.get_children():
		_apply_theme_to_branch(child)

func _process(_delta: float) -> void:
	# Sync remote player positions (Vector3 in network state).
	for peer_id in NetworkManager.players:
		if peer_id == GameManager.player_id:
			continue
		if peer_id in other_players:
			var pos: Vector3 = NetworkManager.players[peer_id].get("position", Vector3.ZERO)
			other_players[peer_id].update_position(pos)

	if Input.is_action_just_pressed("toggle_grind_tracker") and grind_tracker_node:
		grind_tracker_node.toggle_visible()

	if Input.is_action_just_pressed("toggle_enhancement") and enhancement_panel_node:
		enhancement_panel_node.visible = not enhancement_panel_node.visible

func _pixel_to_world(p: Vector2) -> Vector3:
	# Treat ZoneData pixel coords as world coords scaled into meters,
	# centered on the world origin.
	var center := Vector2(1000, 600)  # ZoneData spans roughly 0..2000, 0..1200
	var local := p - center
	return Vector3(local.x * WORLD_SCALE, 1.0, local.y * WORLD_SCALE)

func _spawn_local_player() -> void:
	local_player = PlayerScene.instantiate() as Player
	local_player.is_local = true
	local_player.player_peer_id = GameManager.player_id
	local_player.position = _pixel_to_world(Vector2(300, 300))
	entities.add_child(local_player)

func _spawn_zone_enemies() -> void:
	## Spawn enemies based on zone data — BDO-style mob density per zone.
	for zone_id in ZoneData.ZONES:
		if VERTICAL_SLICE_MODE and zone_id != "slime_fields":
			continue
		var zone: Dictionary = ZoneData.ZONES[zone_id]
		var mobs: Array = zone.get("mobs", [])
		var mob_count: int = zone.get("mob_count", 0)
		var bounds: Rect2 = zone.get("bounds", Rect2())
		var zone_silver: int = zone.get("silver_per_mob", 0)
		var zone_respawn: float = zone.get("respawn_time", 10.0)

		if mobs.is_empty() or mob_count == 0:
			continue

		var total_weight := 0
		for mob in mobs:
			total_weight += mob.get("weight", 1)

		for i in mob_count:
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

			var margin := 40.0
			var px := Vector2(
				randf_range(bounds.position.x + margin, bounds.end.x - margin),
				randf_range(bounds.position.y + margin, bounds.end.y - margin)
			)
			var pos := _pixel_to_world(px)
			enemy.position = pos
			enemy.spawn_position = pos
			entities.add_child(enemy)
			if i == 0:
				enemy.call_deferred("make_elite")

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
		npc.position = _pixel_to_world(data["pos"])
		var dialog: Array[String] = []
		dialog.assign(data["dialog"])
		npc.dialog_lines = dialog
		npc.is_shopkeeper = data.get("is_shop", false)
		entities.add_child(npc)

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
			var equipment_system := local_player.get_equipment_system()
			equipment_system.setup_inventory(inv_panel.inventory)
			inv_panel.inventory.set_equipment_system(equipment_system)
		enhancement_panel_node.setup(local_player.get_equipment_system())

	var ComparisonScript := preload("res://scripts/ui/equipment_comparison_panel.gd")
	comparison_panel_node = PanelContainer.new()
	comparison_panel_node.set_script(ComparisonScript)
	ui_layer.add_child(comparison_panel_node)
	if local_player and local_player.get_equipment_system():
		comparison_panel_node.setup(local_player.get_equipment_system())

	if ENABLE_DAMAGE_NUMBERS:
		var DamageNumbersScript := preload("res://scripts/ui/damage_numbers.gd")
		damage_numbers_node = Node3D.new()
		damage_numbers_node.set_script(DamageNumbersScript)
		entities.add_child(damage_numbers_node)

	if not ENABLE_WORLD_POSITION_UI:
		return

	var ZoneIndicatorScript := preload("res://scripts/ui/zone_indicator.gd")
	zone_indicator_node = PanelContainer.new()
	zone_indicator_node.set_script(ZoneIndicatorScript)
	ui_layer.add_child(zone_indicator_node)

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

func _setup_vertical_slice() -> void:
	var SliceScript := preload("res://scripts/quests/vertical_slice.gd")
	vertical_slice_node = PanelContainer.new()
	vertical_slice_node.set_script(SliceScript)
	ui_layer.add_child(vertical_slice_node)
	vertical_slice_node.setup(self)

func spawn_slice_boss() -> void:
	if not get_tree().get_nodes_in_group("slice_boss").is_empty():
		return

	var arena := Node3D.new()
	arena.name = "SlimeKingArena"
	arena.position = _pixel_to_world(Vector2(900, 300))
	ground.add_child(arena)
	for index in 20:
		var angle := TAU * float(index) / 20.0
		var block_pos := Vector3(cos(angle) * 4.5, 0.08, sin(angle) * 4.5)
		_cube(arena, block_pos, Vector3(1.15, 0.14, 1.15), Color("9bdd62"), true)

	var boss := EnemyScene.instantiate() as Enemy
	boss.enemy_name = "Slime King"
	boss.mob_id = "slime_king"
	boss.max_hp = 260
	boss.attack_power = 9
	boss.defense = 2
	boss.move_speed = 32.0
	boss.detection_range = 260.0
	boss.attack_range = 40.0
	boss.exp_reward = 160
	boss.silver_per_kill = 800
	boss.respawns = false
	boss.position = _pixel_to_world(Vector2(900, 300))
	boss.spawn_position = boss.position
	boss.scale = Vector3.ONE * 1.8
	entities.add_child(boss)
	boss.add_to_group("slice_boss")

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
