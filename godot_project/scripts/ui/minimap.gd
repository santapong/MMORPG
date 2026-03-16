extends PanelContainer
## Minimap — shows player position, nearby enemies, NPCs, and zone outlines.
## Draws in real-time using _draw() on an inner Control node.

const MINIMAP_SIZE := Vector2(180, 180)
const MINIMAP_SCALE := 0.08 # World units to minimap pixels
const PLAYER_DOT_SIZE := 4.0
const ENEMY_DOT_SIZE := 2.5
const NPC_DOT_SIZE := 3.0
const WAYPOINT_DOT_SIZE := 5.0
const RENDER_RADIUS := 1200.0 # How far around the player to show

var draw_surface: Control = null
var player_ref: Node2D = null
var compass_label := Label.new()
var coords_label := Label.new()

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	custom_minimum_size = MINIMAP_SIZE + Vector2(10, 30)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -(MINIMAP_SIZE.x + 20)
	offset_right = -10
	offset_top = -(MINIMAP_SIZE.y + 40)
	offset_bottom = -10

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	# Title bar
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "MAP"
	title.add_theme_font_size_override("font_size", 10)
	title_row.add_child(title)

	compass_label.text = ""
	compass_label.add_theme_font_size_override("font_size", 10)
	compass_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	title_row.add_child(compass_label)

	# Drawing surface
	draw_surface = Control.new()
	draw_surface.custom_minimum_size = MINIMAP_SIZE
	draw_surface.clip_contents = true
	draw_surface.draw.connect(_on_draw)
	vbox.add_child(draw_surface)

	# Coordinates
	coords_label.text = "0, 0"
	coords_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coords_label.add_theme_font_size_override("font_size", 9)
	coords_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(coords_label)

func setup(player: Node2D) -> void:
	player_ref = player

func _process(_delta: float) -> void:
	if draw_surface and player_ref and is_instance_valid(player_ref):
		draw_surface.queue_redraw()
		coords_label.text = "%d, %d" % [int(player_ref.global_position.x), int(player_ref.global_position.y)]

func _on_draw() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return

	var center := MINIMAP_SIZE / 2.0
	var player_pos := player_ref.global_position

	# Draw background
	draw_surface.draw_rect(Rect2(Vector2.ZERO, MINIMAP_SIZE), Color(0.05, 0.05, 0.1, 0.85))

	# Draw zone boundaries
	_draw_zones(center, player_pos)

	# Draw waypoint
	_draw_waypoint(center, player_pos)

	# Draw NPCs (cyan dots)
	var npcs := draw_surface.get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		var offset := (npc.global_position - player_pos) * MINIMAP_SCALE
		if offset.length() < center.x:
			var dot_pos := center + offset
			draw_surface.draw_circle(dot_pos, NPC_DOT_SIZE, Color(0.2, 0.9, 0.9))

	# Draw enemies (red dots)
	var enemies := draw_surface.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.visible:
			continue
		var offset := (enemy.global_position - player_pos) * MINIMAP_SCALE
		if offset.length() < center.x:
			var dot_pos := center + offset
			draw_surface.draw_circle(dot_pos, ENEMY_DOT_SIZE, Color(1, 0.3, 0.3, 0.7))

	# Draw other players (blue dots)
	var players := draw_surface.get_tree().get_nodes_in_group("players")
	for p in players:
		if not is_instance_valid(p) or p == player_ref:
			continue
		var offset := (p.global_position - player_pos) * MINIMAP_SCALE
		if offset.length() < center.x:
			var dot_pos := center + offset
			draw_surface.draw_circle(dot_pos, PLAYER_DOT_SIZE, Color(0.3, 0.5, 1.0))

	# Draw player (white dot in center, always)
	draw_surface.draw_circle(center, PLAYER_DOT_SIZE, Color.WHITE)

	# Draw player facing direction indicator
	var facing := Vector2.ZERO
	if player_ref.has_method("_get_direction_name"):
		facing = player_ref.facing_direction.normalized()
	if facing != Vector2.ZERO:
		var arrow_end := center + facing * 10.0
		draw_surface.draw_line(center, arrow_end, Color.WHITE, 1.5)

	# Draw border
	draw_surface.draw_rect(Rect2(Vector2.ZERO, MINIMAP_SIZE), Color(0.4, 0.4, 0.5), false, 1.0)

	# Draw cardinal directions
	var font := ThemeDB.fallback_font
	var font_size := 9
	draw_surface.draw_string(font, Vector2(center.x - 3, 10), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.8, 0.8, 0.8, 0.6))
	draw_surface.draw_string(font, Vector2(center.x - 3, MINIMAP_SIZE.y - 2), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.8, 0.8, 0.8, 0.6))
	draw_surface.draw_string(font, Vector2(2, center.y + 3), "W", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.8, 0.8, 0.8, 0.6))
	draw_surface.draw_string(font, Vector2(MINIMAP_SIZE.x - 10, center.y + 3), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.8, 0.8, 0.8, 0.6))

func _draw_zones(center: Vector2, player_pos: Vector2) -> void:
	for zone_id in ZoneData.ZONES:
		var zone: Dictionary = ZoneData.ZONES[zone_id]
		var bounds: Rect2 = zone["bounds"]
		var tier: int = zone.get("tier", ZoneData.ZoneTier.SAFE)
		var color: Color = ZoneData.ZONE_COLORS.get(tier, Color(0.2, 0.35, 0.15))
		color.a = 0.4

		# Convert zone bounds to minimap coordinates
		var zone_min := (bounds.position - player_pos) * MINIMAP_SCALE + center
		var zone_size := bounds.size * MINIMAP_SCALE
		var zone_rect := Rect2(zone_min, zone_size)

		# Clip to minimap bounds
		var visible_rect := zone_rect.intersection(Rect2(Vector2.ZERO, MINIMAP_SIZE))
		if visible_rect.has_area():
			draw_surface.draw_rect(visible_rect, color)
			# Zone border
			draw_surface.draw_rect(visible_rect, Color(color.r, color.g, color.b, 0.6), false, 0.5)

func _draw_waypoint(center: Vector2, player_pos: Vector2) -> void:
	if not GameManager.has_meta("waypoint"):
		return
	var waypoint: Vector2 = GameManager.get_meta("waypoint")
	var offset := (waypoint - player_pos) * MINIMAP_SCALE
	var dot_pos := center + offset

	# Clamp to minimap edge if out of bounds
	if dot_pos.x < 0 or dot_pos.x > MINIMAP_SIZE.x or dot_pos.y < 0 or dot_pos.y > MINIMAP_SIZE.y:
		var dir := offset.normalized()
		dot_pos = center + dir * min(offset.length(), center.x - 5)
		dot_pos.x = clamp(dot_pos.x, 5, MINIMAP_SIZE.x - 5)
		dot_pos.y = clamp(dot_pos.y, 5, MINIMAP_SIZE.y - 5)

	# Pulsing waypoint marker
	var pulse := (sin(Time.get_ticks_msec() / 300.0) + 1.0) / 2.0
	var wp_color := Color(1.0, 0.85, 0.0, 0.6 + pulse * 0.4)
	draw_surface.draw_circle(dot_pos, WAYPOINT_DOT_SIZE, wp_color)
	# Diamond shape
	var d := WAYPOINT_DOT_SIZE + 2
	var points := PackedVector2Array([
		dot_pos + Vector2(0, -d), dot_pos + Vector2(d, 0),
		dot_pos + Vector2(0, d), dot_pos + Vector2(-d, 0),
	])
	draw_surface.draw_polyline(points + PackedVector2Array([dot_pos + Vector2(0, -d)]), wp_color, 1.5)
