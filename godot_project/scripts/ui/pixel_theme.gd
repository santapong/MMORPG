extends RefCounted
class_name PixelTheme
## Shared hard-edged UI theme for the voxel-pixel presentation.

const INK := Color("171225")
const PANEL := Color("241b35")
const PANEL_LIGHT := Color("332545")
const CREAM := Color("fff1d2")
const MUTED := Color("bcaec9")
const GOLD := Color("f6c85f")
const MINT := Color("72d6a0")
const RED := Color("e85d75")
const BLUE := Color("66a5df")

static var _theme: Theme

static func build() -> Theme:
	if _theme:
		return _theme

	_theme = Theme.new()
	_theme.default_font_size = 15
	_theme.set_color("font_color", "Label", CREAM)
	_theme.set_color("font_shadow_color", "Label", Color(0.03, 0.02, 0.05, 0.85))
	_theme.set_constant("shadow_offset_x", "Label", 2)
	_theme.set_constant("shadow_offset_y", "Label", 2)

	_theme.set_stylebox("panel", "PanelContainer", _box(PANEL, GOLD, 3, 8))
	_theme.set_stylebox("panel", "Panel", _box(PANEL, GOLD, 3, 8))

	_theme.set_stylebox("normal", "Button", _box(PANEL_LIGHT, Color("6d527d"), 3, 9))
	_theme.set_stylebox("hover", "Button", _box(Color("493357"), GOLD, 3, 9))
	_theme.set_stylebox("pressed", "Button", _box(Color("1c452f"), MINT, 3, 9))
	_theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, CREAM, 2, 4))
	_theme.set_stylebox("disabled", "Button", _box(Color("211a2c"), Color("4b4057"), 3, 9))
	_theme.set_color("font_color", "Button", CREAM)
	_theme.set_color("font_hover_color", "Button", Color.WHITE)
	_theme.set_color("font_pressed_color", "Button", Color.WHITE)
	_theme.set_color("font_disabled_color", "Button", Color("756b80"))
	_theme.set_constant("outline_size", "Button", 2)
	_theme.set_color("font_outline_color", "Button", INK)

	_theme.set_stylebox("normal", "LineEdit", _box(Color("120f1c"), Color("6d527d"), 3, 8))
	_theme.set_stylebox("focus", "LineEdit", _box(Color("120f1c"), GOLD, 3, 8))
	_theme.set_color("font_color", "LineEdit", CREAM)
	_theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	_theme.set_color("caret_color", "LineEdit", GOLD)

	_theme.set_stylebox("background", "ProgressBar", _box(INK, Color("503b61"), 2, 2))
	_theme.set_stylebox("fill", "ProgressBar", _box(MINT, Color("d9ffbd"), 1, 1))
	_theme.set_color("font_color", "ProgressBar", CREAM)

	_theme.set_stylebox("panel", "PopupMenu", _box(PANEL, GOLD, 3, 8))
	_theme.set_stylebox("normal", "TooltipPanel", _box(PANEL, CREAM, 2, 7))
	_theme.set_color("font_color", "TooltipLabel", CREAM)
	_theme.set_color("separator", "HSeparator", Color("6d527d"))
	_theme.set_constant("separation", "VBoxContainer", 8)
	_theme.set_constant("separation", "HBoxContainer", 8)
	return _theme

static func apply(control: Control) -> void:
	control.theme = build()

static func _box(color: Color, border: Color, width: int, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(0)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	box.shadow_color = Color(0.03, 0.02, 0.05, 0.8)
	box.shadow_size = 5
	box.shadow_offset = Vector2(4, 4)
	return box
