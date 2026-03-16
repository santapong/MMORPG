extends Control
## On-screen navigation arrow pointing toward the active waypoint.
## Shows distance and direction when waypoint is set.

var player_ref: Node2D = null
var arrow_size := 20.0
var arrow_distance := 80.0 # Distance from screen center

var distance_label := Label.new()

func _ready() -> void:
	_build_ui()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_ui() -> void:
	# Distance label below the arrow
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.add_theme_font_size_override("font_size", 11)
	distance_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	distance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(distance_label)

func setup(player: Node2D) -> void:
	player_ref = player

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		distance_label.visible = false
		return

	if not GameManager.has_meta("waypoint"):
		distance_label.visible = false
		return

	var waypoint: Vector2 = GameManager.get_meta("waypoint")
	var dist := player_ref.global_position.distance_to(waypoint)

	# Hide arrow if very close to waypoint
	if dist < 50.0:
		distance_label.visible = false
		# Auto-clear waypoint when reached
		if dist < 20.0:
			GameManager.remove_meta("waypoint")
			EventBus.waypoint_cleared.emit()
		return

	distance_label.visible = true
	distance_label.text = "%d" % int(dist)

	# Calculate direction from player to waypoint
	var direction := (waypoint - player_ref.global_position).normalized()

	# Position the arrow at edge of a circle around screen center
	var screen_center := get_viewport_rect().size / 2.0
	var arrow_pos := screen_center + direction * arrow_distance

	# Draw arrow triangle pointing toward waypoint
	var angle := direction.angle()
	var p1 := arrow_pos + Vector2(cos(angle), sin(angle)) * arrow_size
	var p2 := arrow_pos + Vector2(cos(angle + 2.5), sin(angle + 2.5)) * (arrow_size * 0.6)
	var p3 := arrow_pos + Vector2(cos(angle - 2.5), sin(angle - 2.5)) * (arrow_size * 0.6)

	var pulse := (sin(Time.get_ticks_msec() / 300.0) + 1.0) / 2.0
	var color := Color(1, 0.85, 0.3, 0.6 + pulse * 0.4)

	draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([color, color, color]))
	draw_polyline(PackedVector2Array([p1, p2, p3, p1]), Color(1, 0.9, 0.5), 1.5)

	# Position distance label below arrow
	distance_label.position = arrow_pos + Vector2(-20, arrow_size + 5)
	distance_label.size = Vector2(40, 20)
