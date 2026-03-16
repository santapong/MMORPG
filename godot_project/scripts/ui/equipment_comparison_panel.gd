extends PanelContainer
## Equipment comparison panel — shows side-by-side stat comparison when equipping new gear.
## Green/red stat delta indicators with "Would you like to equip?" confirmation.

signal equip_confirmed(item: Dictionary)
signal equip_cancelled()

var _new_item: Dictionary = {}
var _current_item: Dictionary = {}
var _slot: String = ""
var _equipment_system: EquipmentSystem = null

var left_label := Label.new() # Current item
var right_label := Label.new() # New item
var delta_label := Label.new() # Stat deltas
var confirm_button := Button.new()
var cancel_button := Button.new()

func _ready() -> void:
	_build_ui()
	visible = false

func setup(equip_sys: EquipmentSystem) -> void:
	_equipment_system = equip_sys

func show_comparison(current_item: Dictionary, new_item: Dictionary, slot: String) -> void:
	_current_item = current_item
	_new_item = new_item
	_slot = slot
	_update_display()
	visible = true

func _build_ui() -> void:
	custom_minimum_size = Vector2(400, 300)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -200
	offset_right = 200
	offset_top = -150
	offset_bottom = 150

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "=== EQUIPMENT COMPARISON ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Side-by-side layout
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	# Current item (left)
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_vbox)

	var current_title := Label.new()
	current_title.text = "EQUIPPED"
	current_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_title.add_theme_font_size_override("font_size", 10)
	current_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	left_vbox.add_child(current_title)

	left_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	left_label.add_theme_font_size_override("font_size", 10)
	left_label.custom_minimum_size = Vector2(150, 100)
	left_vbox.add_child(left_label)

	# Separator
	var vsep := VSeparator.new()
	hbox.add_child(vsep)

	# New item (right)
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_vbox)

	var new_title := Label.new()
	new_title.text = "NEW ITEM"
	new_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_title.add_theme_font_size_override("font_size", 10)
	new_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	right_vbox.add_child(new_title)

	right_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_label.add_theme_font_size_override("font_size", 10)
	right_label.custom_minimum_size = Vector2(150, 100)
	right_vbox.add_child(right_label)

	vbox.add_child(HSeparator.new())

	# Delta summary
	delta_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delta_label.add_theme_font_size_override("font_size", 11)
	delta_label.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(delta_label)

	vbox.add_child(HSeparator.new())

	# Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 8)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	confirm_button.text = "Equip"
	confirm_button.custom_minimum_size = Vector2(80, 30)
	confirm_button.pressed.connect(_on_confirm)
	btn_hbox.add_child(confirm_button)

	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(80, 30)
	cancel_button.pressed.connect(_on_cancel)
	btn_hbox.add_child(cancel_button)

func _update_display() -> void:
	# Current item display
	if _current_item.is_empty():
		left_label.text = "(Empty slot)"
		left_label.remove_theme_color_override("font_color")
	else:
		var grade = _current_item.get("grade", EquipmentData.Grade.COMMON)
		left_label.text = _format_item_stats(_current_item)
		left_label.add_theme_color_override("font_color", EquipmentData.get_grade_color(grade))

	# New item display
	var new_grade = _new_item.get("grade", EquipmentData.Grade.COMMON)
	right_label.text = _format_item_stats(_new_item)
	right_label.add_theme_color_override("font_color", EquipmentData.get_grade_color(new_grade))

	# Delta
	delta_label.text = _build_delta_text()

func _format_item_stats(item: Dictionary) -> String:
	if item.is_empty():
		return "(None)"

	var lines := []
	var name: String = item.get("name", "Unknown")
	var grade = item.get("grade", EquipmentData.Grade.COMMON)
	var grade_name := EquipmentData.get_grade_name(grade)
	var enhance_level: int = item.get("enhance_level", 0)

	var display_name := name
	if enhance_level > 0:
		if enhance_level >= 16 and EquipmentSystem.FORCED_ENHANCE_NAMES.has(enhance_level):
			display_name = "%s %s" % [EquipmentSystem.FORCED_ENHANCE_NAMES[enhance_level], name]
		else:
			display_name = "+%d %s" % [enhance_level, name]
	lines.append("[%s] %s" % [grade_name, display_name])
	lines.append("")

	var stat_names := {
		"attack": "ATK", "defense": "DEF", "max_hp": "HP",
		"max_mp": "MP", "crit_chance": "CRIT%", "speed": "SPD"
	}

	var stats: Dictionary = item.get("stats", {})
	for stat_key in stat_names:
		var val = stats.get(stat_key, 0)
		if val == 0:
			continue
		if stat_key == "crit_chance":
			lines.append("%s: %.1f%%" % [stat_names[stat_key], val * 100])
		else:
			lines.append("%s: %d" % [stat_names[stat_key], int(val)])

	if enhance_level > 0:
		lines.append("Enhancement: +%d" % enhance_level)

	return "\n".join(lines)

func _build_delta_text() -> String:
	var stat_names := {
		"attack": "ATK", "defense": "DEF", "max_hp": "HP",
		"max_mp": "MP", "crit_chance": "CRIT", "speed": "SPD"
	}

	var current_stats: Dictionary = _current_item.get("stats", {})
	var new_stats: Dictionary = _new_item.get("stats", {})

	# Include enhancement bonuses
	var current_enhance: int = _current_item.get("enhance_level", 0)
	var new_enhance: int = _new_item.get("enhance_level", 0)

	var current_total := {}
	var new_total := {}

	if _equipment_system and not _slot.is_empty():
		current_total = _equipment_system.get_enhanced_item_stats(_current_item, _slot, current_enhance) if not _current_item.is_empty() else {}
		new_total = _equipment_system.get_enhanced_item_stats(_new_item, _slot, new_enhance)
	else:
		current_total = current_stats
		new_total = new_stats

	var deltas := []
	for stat_key in stat_names:
		var curr_val = current_total.get(stat_key, 0)
		var new_val = new_total.get(stat_key, 0)
		var diff = new_val - curr_val
		if abs(diff) < 0.001:
			continue
		var label: String = stat_names[stat_key]
		if stat_key == "crit_chance":
			if diff > 0:
				deltas.append("[color=green]+%.1f%% %s[/color]" % [diff * 100, label])
			else:
				deltas.append("[color=red]%.1f%% %s[/color]" % [diff * 100, label])
		else:
			if diff > 0:
				deltas.append("+%d %s" % [int(diff), label])
			else:
				deltas.append("%d %s" % [int(diff), label])

	if deltas.is_empty():
		return "No stat change"
	return "  ".join(deltas)

func _on_confirm() -> void:
	equip_confirmed.emit(_new_item)
	visible = false

func _on_cancel() -> void:
	equip_cancelled.emit()
	visible = false
