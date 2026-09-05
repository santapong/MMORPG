extends Control
## Responsive, code-drawn pixel landscape for the title and character screens.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	# Broad color bands stay crisp at every window size.
	var sky := [Color("171225"), Color("241936"), Color("3c2850"), Color("70415e"), Color("c06b67")]
	var band_h := h * 0.13
	for i in sky.size():
		draw_rect(Rect2(0, i * band_h, w, band_h + 1), sky[i])
	draw_rect(Rect2(0, band_h * sky.size(), w, h), Color("172b32"))

	# Square moon, stepped mountains, and chunky treeline sell the pixel scale.
	var unit := maxf(6.0, floorf(minf(w, h) / 90.0) * 2.0)
	draw_rect(Rect2(w * 0.76, h * 0.12, unit * 8, unit * 8), Color("ffe7a1"))
	draw_rect(Rect2(w * 0.76 - unit, h * 0.12 + unit * 2, unit, unit * 4), Color("ffe7a1"))
	draw_rect(Rect2(w * 0.76 + unit * 8, h * 0.12 + unit, unit, unit * 5), Color("ffe7a1"))

	var ridge := PackedVector2Array([
		Vector2(0, h * 0.63), Vector2(w * 0.12, h * 0.42), Vector2(w * 0.2, h * 0.54),
		Vector2(w * 0.33, h * 0.31), Vector2(w * 0.46, h * 0.56), Vector2(w * 0.61, h * 0.37),
		Vector2(w * 0.72, h * 0.56), Vector2(w * 0.86, h * 0.34), Vector2(w, h * 0.57),
		Vector2(w, h * 0.78), Vector2(0, h * 0.78)
	])
	draw_colored_polygon(ridge, Color("26364b"))

	for x in range(0, int(w), int(unit * 7)):
		var tree_h := unit * (5 + ((x / int(unit)) as int) % 4)
		draw_rect(Rect2(x + unit * 2, h * 0.61 - tree_h, unit * 2, tree_h), Color("19343a"))
		draw_rect(Rect2(x, h * 0.58 - tree_h, unit * 6, unit * 3), Color("235046"))
		draw_rect(Rect2(x + unit, h * 0.55 - tree_h, unit * 4, unit * 3), Color("2c6a50"))

	# Foreground checkerboard echoes the game's tiled battlefield.
	var tile := unit * 5
	for y in range(int(h * 0.7), int(h) + int(tile), int(tile)):
		for x in range(0, int(w) + int(tile), int(tile)):
			var checker := (x / int(tile) + y / int(tile)) as int
			var color := Color("1d3d3a") if checker % 2 == 0 else Color("244942")
			draw_rect(Rect2(x, y, tile + 1, tile + 1), color)

	# Tiny block slimes frame the menu instead of generic decoration.
	_draw_slime(Vector2(w * 0.1, h * 0.77), unit, Color("72d6a0"))
	_draw_slime(Vector2(w * 0.86, h * 0.81), unit * 1.35, Color("9bdd62"))

func _draw_slime(origin: Vector2, unit: float, color: Color) -> void:
	draw_rect(Rect2(origin.x, origin.y, unit * 7, unit * 4), Color("0e1821"))
	draw_rect(Rect2(origin.x + unit, origin.y - unit, unit * 5, unit * 5), color)
	draw_rect(Rect2(origin.x + unit * 2, origin.y - unit * 2, unit * 3, unit), color.lightened(0.12))
	draw_rect(Rect2(origin.x + unit * 2, origin.y + unit, unit, unit), Color("171225"))
	draw_rect(Rect2(origin.x + unit * 4, origin.y + unit, unit, unit), Color("171225"))
