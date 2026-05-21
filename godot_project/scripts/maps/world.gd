extends Node3D
## Main game world (3D) — spawns the local player, enemies, NPCs, and HUD.
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
	_spawn_zone_biomes()
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

func _spawn_zone_biomes() -> void:
	## Build one biome tile + prop set per zone defined in ZoneData.ZONES.
	## Sits 2 cm above the global ground plane (which acts as the world void).
	for zone_id in ZoneData.ZONES:
		var zone: Dictionary = ZoneData.ZONES[zone_id]
		var biome: Dictionary = ZoneData.get_zone_biome(zone_id)
		if biome.is_empty():
			continue
		var bounds: Rect2 = zone.get("bounds", Rect2())
		if bounds.size == Vector2.ZERO:
			continue
		_spawn_biome_tile(bounds, biome.get("ground_color", Color.GRAY))
		_spawn_biome_props(
			bounds,
			biome.get("prop_type", "none"),
			biome.get("prop_count", 0),
			biome.get("prop_color", Color.WHITE),
		)

func _spawn_biome_tile(bounds: Rect2, color: Color) -> void:
	var tile := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(bounds.size.x * WORLD_SCALE, bounds.size.y * WORLD_SCALE)
	tile.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	tile.material_override = mat
	var center := bounds.position + bounds.size * 0.5
	var pos := _pixel_to_world(center)
	pos.y = 0.02
	tile.position = pos
	ground.add_child(tile)

func _spawn_biome_props(bounds: Rect2, prop_type: String, count: int, color: Color) -> void:
	if prop_type == "none" or count <= 0:
		return
	var margin := 35.0
	for i in count:
		var px := Vector2(
			randf_range(bounds.position.x + margin, bounds.end.x - margin),
			randf_range(bounds.position.y + margin, bounds.end.y - margin)
		)
		var prop := _make_prop(prop_type, color)
		if prop == null:
			continue
		var pos := _pixel_to_world(px)
		pos.y = 0.05
		prop.position = pos
		prop.rotation.y = randf() * TAU
		ground.add_child(prop)

func _make_prop(prop_type: String, color: Color) -> Node3D:
	## Build a primitive-mesh prop. No collision — decoration only.
	## Sizes are in metres; visual-only, mobs and players can walk through.
	var root := Node3D.new()
	match prop_type:
		"village":
			# Tiny wooden hut: box body + cone roof.
			var body := _mesh_child(BoxMesh.new(), color, Vector3(0, 0.5, 0))
			(body.mesh as BoxMesh).size = Vector3(1.4, 1.0, 1.4)
			root.add_child(body)
			var roof := _mesh_child(CylinderMesh.new(), color.darkened(0.25), Vector3(0, 1.25, 0))
			var rm := roof.mesh as CylinderMesh
			rm.top_radius = 0.0
			rm.bottom_radius = 1.1
			rm.height = 0.6
			root.add_child(roof)
		"slime_pool":
			# Flat translucent disc.
			var disc := _mesh_child(CylinderMesh.new(), color, Vector3.ZERO)
			var cm := disc.mesh as CylinderMesh
			cm.top_radius = randf_range(0.6, 1.4)
			cm.bottom_radius = cm.top_radius
			cm.height = 0.08
			(disc.material_override as StandardMaterial3D).transparency = (
				BaseMaterial3D.TRANSPARENCY_ALPHA
			)
			var pc: Color = color
			pc.a = 0.7
			(disc.material_override as StandardMaterial3D).albedo_color = pc
			root.add_child(disc)
		"tree":
			# Trunk + foliage sphere.
			var trunk_h := randf_range(1.8, 2.6)
			var trunk := _mesh_child(
				CylinderMesh.new(), Color(0.30, 0.20, 0.12), Vector3(0, trunk_h * 0.5, 0)
			)
			var trm := trunk.mesh as CylinderMesh
			trm.top_radius = 0.15
			trm.bottom_radius = 0.18
			trm.height = trunk_h
			root.add_child(trunk)
			var foliage := _mesh_child(
				SphereMesh.new(), color, Vector3(0, trunk_h + 0.4, 0)
			)
			var sm := foliage.mesh as SphereMesh
			sm.radius = randf_range(0.9, 1.3)
			sm.height = sm.radius * 2.0
			root.add_child(foliage)
		"camp":
			# Tent (cone) or crate (box), 50/50.
			if randf() < 0.5:
				var tent := _mesh_child(CylinderMesh.new(), color, Vector3(0, 0.6, 0))
				var tm := tent.mesh as CylinderMesh
				tm.top_radius = 0.0
				tm.bottom_radius = 0.9
				tm.height = 1.2
				root.add_child(tent)
			else:
				var crate := _mesh_child(BoxMesh.new(), color, Vector3(0, 0.35, 0))
				(crate.mesh as BoxMesh).size = Vector3(0.7, 0.7, 0.7)
				root.add_child(crate)
		"ruin":
			# Broken pillar — tall thin box, randomly tilted.
			var h := randf_range(1.8, 3.2)
			var pillar := _mesh_child(BoxMesh.new(), color, Vector3(0, h * 0.5, 0))
			(pillar.mesh as BoxMesh).size = Vector3(0.5, h, 0.5)
			pillar.rotation = Vector3(
				randf_range(-0.25, 0.25), 0.0, randf_range(-0.25, 0.25)
			)
			root.add_child(pillar)
		"lava":
			# Glowing lava patch — emissive disc with a jagged spike.
			var patch := _mesh_child(CylinderMesh.new(), color, Vector3(0, 0.02, 0))
			var lm := patch.mesh as CylinderMesh
			lm.top_radius = randf_range(0.7, 1.4)
			lm.bottom_radius = lm.top_radius
			lm.height = 0.04
			var pmat := patch.material_override as StandardMaterial3D
			pmat.emission_enabled = true
			pmat.emission = color
			pmat.emission_energy_multiplier = 1.4
			root.add_child(patch)
			if randf() < 0.6:
				var spike := _mesh_child(
					CylinderMesh.new(), Color(0.18, 0.08, 0.08), Vector3(0, 0.45, 0)
				)
				var spm := spike.mesh as CylinderMesh
				spm.top_radius = 0.0
				spm.bottom_radius = 0.35
				spm.height = 0.9
				root.add_child(spike)
		_:
			return null
	return root

func _mesh_child(mesh: Mesh, color: Color, local_pos: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = local_pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	node.material_override = mat
	return node

func _spawn_local_player() -> void:
	local_player = PlayerScene.instantiate() as Player
	local_player.is_local = true
	local_player.player_peer_id = GameManager.player_id
	local_player.global_position = _pixel_to_world(Vector2(300, 300))
	entities.add_child(local_player)

func _spawn_zone_enemies() -> void:
	## Spawn enemies based on zone data — BDO-style mob density per zone.
	for zone_id in ZoneData.ZONES:
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
		npc.global_position = _pixel_to_world(data["pos"])
		npc.dialog_lines = data["dialog"]
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
			local_player.get_equipment_system().setup_inventory(inv_panel.inventory)
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
