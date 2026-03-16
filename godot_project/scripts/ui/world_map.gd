extends CanvasLayer
## Full world map overlay — press M to open. Shows all zones, NPCs, and player position.
## Click on a zone to set a navigation waypoint.

const MAP_SCALE := 0.3 # World to screen scale
const WORLD_SIZE := Vector2(2000, 1200) # Total world dimensions

var map_panel: PanelContainer = null
var draw_surface: Control = null
var info_label := Label.new()
var distance_label := Label.new()
var player_ref: Node2D = null
var hovered_zone: String = ""

func _ready() -> void:
	layer = 20
	_build_ui()
	visible = false

func _build_ui() -> void:
	map_panel = PanelContainer.new()
	map_panel.anchor_left = 0.0
	map_panel.anchor_right = 1.0
	map_panel.anchor_top = 0.0
	map_panel.anchor_bottom = 1.0
	map_panel.offset_left = 40
	map_panel.offset_right = -40
	map_panel.offset_top = 40
	map_panel.offset_bottom = -40
	add_child(map_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	map_panel.add_child(vbox)

	# Title bar
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "WORLD MAP"
	title.add_theme_font_size_override("font_size", 18)
	title_row.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)

	var close_btn := Button.new()
	close_btn.text = "Close [M]"
	close_btn.pressed.connect(func(): visible = false)
	title_row.add_child(close_btn)

	# Info labels
	var info_row := HBoxContainer.new()
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.add_theme_constant_override("separation", 20)
	vbox.add_child(info_row)

	info_label.text = "Click a zone to set waypoint"
	info_label.add_theme_font_size_override("font_size", 12)
	info_row.add_child(info_label)

	distance_label.text = ""
	distance_label.add_theme_font_size_override("font_size", 12)
	distance_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	info_row.add_child(distance_label)

	# Map draw surface
	draw_surface = Control.new()
	draw_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	draw_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draw_surface.custom_minimum_size = WORLD_SIZE * MAP_SCALE
	draw_surface.draw.connect(_on_draw)
	draw_surface.gui_input.connect(_on_map_input)
	draw_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(draw_surface)

	# Legend
	var legend_row := HBoxContainer.new()
	legend_row.alignment = BoxContainer.ALIGNMENT_CENTER
	legend_row.add_theme_constant_override("separation", 15)
	vbox.add_child(legend_row)

	_add_legend_item(legend_row, Color.WHITE, "You")
	_add_legend_item(legend_row, Color(1, 0.3, 0.3), "Enemies")
	_add_legend_item(legend_row, Color(0.2, 0.9, 0.9), "NPCs")
	_add_legend_item(legend_row, Color(1, 0.85, 0.0), "Waypoint")
	_add_legend_item(legend_row, Color(0.3, 0.5, 1.0), "Players")

func _add_legend_item(parent: HBoxContainer, color: Color, text: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)
	parent.add_child(hbox)

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(10, 10)
	dot.color = color
	hbox.add_child(dot)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	hbox.add_child(lbl)

func setup(player: Node2D) -> void:
	player_ref = player

func _process(_delta: float) -> void:
	if not visible:
		return
	if draw_surface:
		draw_surface.queue_redraw()

	# Update distance to waypoint
	if player_ref and is_instance_valid(player_ref) and GameManager.has_meta("waypoint"):
		var wp: Vector2 = GameManager.get_meta("waypoint")
		var dist := player_ref.global_position.distance_to(wp)
		distance_label.text = "Distance: %d" % int(dist)
	else:
		distance_label.text = ""

func _on_draw() -> void:
	if not draw_surface:
		return

	var surface_size := draw_surface.size
	var scale_x := surface_size.x / WORLD_SIZE.x
	var scale_y := surface_size.y / WORLD_SIZE.y
	var draw_scale := min(scale_x, scale_y)

	# Background
	draw_surface.draw_rect(Rect2(Vector2.ZERO, surface_size), Color(0.05, 0.05, 0.08))

	var font := ThemeDB.fallback_font

	# Draw zones
	hovered_zone = ""
	var mouse_pos := draw_surface.get_local_mouse_position()

	for zone_id in ZoneData.ZONES:
		var zone: Dictionary = ZoneData.ZONES[zone_id]
		var bounds: Rect2 = zone["bounds"]
		var tier: int = zone.get("tier", ZoneData.ZoneTier.SAFE)
		var color: Color = ZoneData.ZONE_COLORS.get(tier, Color(0.2, 0.35, 0.15))

		var map_rect := Rect2(
			bounds.position * draw_scale,
			bounds.size * draw_scale
		)

		# Check hover
		if map_rect.has_point(mouse_pos):
			hovered_zone = zone_id
			color = color.lightened(0.2)
			info_label.text = "%s | %s | Lv. %d+" % [
				zone.get("name", ""),
				ZoneData.ZONE_TIER_NAMES.get(tier, ""),
				zone.get("recommended_level", 1)
			]

		draw_surface.draw_rect(map_rect, color)
		draw_surface.draw_rect(map_rect, Color(0.5, 0.5, 0.6, 0.5), false, 1.0)

		# Zone name
		var name_pos := map_rect.position + Vector2(5, 15)
		draw_surface.draw_string(font, name_pos, zone.get("name", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.8))

		# Recommended level
		var level_text := "Lv. %d+" % zone.get("recommended_level", 1)
		var level_pos := map_rect.position + Vector2(5, 28)
		draw_surface.draw_string(font, level_pos, level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.8, 0.8, 0.6))

		# Mob count
		var mob_count: int = zone.get("mob_count", 0)
		if mob_count > 0:
			var mob_text := "Mobs: %d" % mob_count
			var mob_pos := map_rect.position + Vector2(5, 40)
			draw_surface.draw_string(font, mob_pos, mob_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.5, 0.5, 0.6))

	# Draw NPCs
	var npcs := draw_surface.get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		var npc_pos := npc.global_position * draw_scale
		draw_surface.draw_circle(npc_pos, 5, Color(0.2, 0.9, 0.9))

		# NPC name
		if npc.has_method("get") or "npc_name" in npc:
			draw_surface.draw_string(font, npc_pos + Vector2(7, 4), npc.npc_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.9, 0.9, 0.8))

	# Draw waypoint
	if GameManager.has_meta("waypoint"):
		var wp: Vector2 = GameManager.get_meta("waypoint")
		var wp_screen := wp * draw_scale
		var pulse := (sin(Time.get_ticks_msec() / 250.0) + 1.0) / 2.0
		var wp_size := 6.0 + pulse * 3.0
		draw_surface.draw_circle(wp_screen, wp_size, Color(1, 0.85, 0.0, 0.7))
		# X mark
		var x_size := 4.0
		draw_surface.draw_line(wp_screen - Vector2(x_size, x_size), wp_screen + Vector2(x_size, x_size), Color(1, 0.85, 0.0), 2.0)
		draw_surface.draw_line(wp_screen - Vector2(-x_size, x_size), wp_screen + Vector2(-x_size, x_size), Color(1, 0.85, 0.0), 2.0)

	# Draw player
	if player_ref and is_instance_valid(player_ref):
		var p_pos := player_ref.global_position * draw_scale
		draw_surface.draw_circle(p_pos, 6, Color.WHITE)
		# Arrow showing facing direction
		var facing := player_ref.facing_direction.normalized()
		if facing != Vector2.ZERO:
			draw_surface.draw_line(p_pos, p_pos + facing * 12, Color.WHITE, 2.0)

	# Draw grid
	for x in range(0, int(WORLD_SIZE.x), 200):
		var lx := x * draw_scale
		draw_surface.draw_line(Vector2(lx, 0), Vector2(lx, surface_size.y), Color(0.3, 0.3, 0.3, 0.15))
	for y in range(0, int(WORLD_SIZE.y), 200):
		var ly := y * draw_scale
		draw_surface.draw_line(Vector2(0, ly), Vector2(surface_size.x, ly), Color(0.3, 0.3, 0.3, 0.15))

func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var surface_size := draw_surface.size
		var draw_scale := min(surface_size.x / WORLD_SIZE.x, surface_size.y / WORLD_SIZE.y)
		var world_pos := event.position / draw_scale

		# Set waypoint
		GameManager.set_meta("waypoint", world_pos)
		EventBus.waypoint_set.emit(world_pos)
		info_label.text = "Waypoint set! Navigate to marker."

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# Right-click to clear waypoint
		if GameManager.has_meta("waypoint"):
			GameManager.remove_meta("waypoint")
			EventBus.waypoint_cleared.emit()
			info_label.text = "Waypoint cleared."
