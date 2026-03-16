extends PanelContainer
## BDO-inspired enhancement panel with full UI overhaul.
## Features: stats preview, grade colors, history log, failstack guide,
## material counts, Cron stone toggle, visual feedback.

var equipment_system: EquipmentSystem = null
var selected_slot: String = ""
var slot_buttons: Dictionary = {} # slot -> Button
var info_label := Label.new()
var enhance_button := Button.new()
var failstack_label := Label.new()
var rate_label := Label.new()
var cost_label := Label.new()
var material_label := Label.new()
var cron_toggle := CheckButton.new()
var cron_cost_label := Label.new()
var stats_preview_label := Label.new()
var history_label := Label.new()
var failstack_guide_label := Label.new()
var feedback_label := Label.new()

# Visual feedback
var _flash_timer: float = 0.0
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_build_ui()
	visible = false

func setup(equip_sys: EquipmentSystem) -> void:
	equipment_system = equip_sys
	if equipment_system:
		equipment_system.enhancement_success.connect(_on_enhance_success)
		equipment_system.enhancement_failed.connect(_on_enhance_failed)
		equipment_system.enhancement_downgraded.connect(_on_enhance_downgraded)
		equipment_system.equipment_changed.connect(_on_equipment_changed)

func _process(delta: float) -> void:
	# Screen shake effect
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var offset := Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		position = _original_position + offset
		if _shake_timer <= 0.0:
			position = _original_position

	# Flash timer
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			feedback_label.text = ""
			feedback_label.remove_theme_color_override("font_color")

func _build_ui() -> void:
	custom_minimum_size = Vector2(380, 560)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -190
	offset_right = 190
	offset_top = -280
	offset_bottom = 280

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "=== ENHANCEMENT ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Equipment slot buttons (2-column grid)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 3)
	vbox.add_child(grid)

	for slot in EquipmentSystem.SLOTS:
		var btn := Button.new()
		btn.text = slot.capitalize() + ": Empty"
		btn.custom_minimum_size = Vector2(170, 26)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_slot_selected.bind(slot))
		grid.add_child(btn)
		slot_buttons[slot] = btn

	vbox.add_child(HSeparator.new())

	# Item info with grade color
	info_label.text = "Select an equipment slot"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_label.custom_minimum_size = Vector2(0, 24)
	info_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(info_label)

	# Stats preview (before -> after)
	stats_preview_label.text = ""
	stats_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	stats_preview_label.custom_minimum_size = Vector2(0, 30)
	stats_preview_label.add_theme_font_size_override("font_size", 10)
	stats_preview_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	vbox.add_child(stats_preview_label)

	vbox.add_child(HSeparator.new())

	# Failstack display
	failstack_label.text = "Failstacks: 0"
	failstack_label.add_theme_font_size_override("font_size", 11)
	failstack_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	vbox.add_child(failstack_label)

	# Failstack recommendation
	failstack_guide_label.text = ""
	failstack_guide_label.add_theme_font_size_override("font_size", 9)
	failstack_guide_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	vbox.add_child(failstack_guide_label)

	# Success rate
	rate_label.text = "Success Rate: ---"
	rate_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(rate_label)

	# Silver cost
	cost_label.text = "Cost: ---"
	cost_label.add_theme_font_size_override("font_size", 11)
	cost_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(cost_label)

	# Material requirement
	material_label.text = "Material: ---"
	material_label.add_theme_font_size_override("font_size", 11)
	material_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(material_label)

	# Cron stone toggle
	var cron_hbox := HBoxContainer.new()
	cron_toggle.text = "Use Cron Stones"
	cron_toggle.add_theme_font_size_override("font_size", 10)
	cron_toggle.toggled.connect(_on_cron_toggled)
	cron_hbox.add_child(cron_toggle)
	cron_cost_label.text = ""
	cron_cost_label.add_theme_font_size_override("font_size", 10)
	cron_cost_label.add_theme_color_override("font_color", Color(0.9, 0.6, 1.0))
	cron_hbox.add_child(cron_cost_label)
	vbox.add_child(cron_hbox)

	# Feedback label (success/fail flash)
	feedback_label.text = ""
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(feedback_label)

	# Enhance button
	enhance_button.text = "ENHANCE"
	enhance_button.custom_minimum_size = Vector2(0, 32)
	enhance_button.pressed.connect(_on_enhance_pressed)
	enhance_button.disabled = true
	vbox.add_child(enhance_button)

	vbox.add_child(HSeparator.new())

	# Enhancement history
	var history_title := Label.new()
	history_title.text = "--- History ---"
	history_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	history_title.add_theme_font_size_override("font_size", 10)
	history_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(history_title)

	history_label.text = "No enhancement attempts yet."
	history_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	history_label.custom_minimum_size = Vector2(0, 40)
	history_label.add_theme_font_size_override("font_size", 9)
	history_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(history_label)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): visible = false)
	vbox.add_child(close_btn)

func _on_slot_selected(slot: String) -> void:
	selected_slot = slot
	_update_info()

func _on_cron_toggled(pressed: bool) -> void:
	if equipment_system:
		equipment_system.use_cron_stones = pressed
	_update_info()

func _update_info() -> void:
	if not equipment_system:
		return

	_update_slot_buttons()
	failstack_label.text = "Failstacks: %d (+%d%%)" % [equipment_system.failstacks, equipment_system.failstacks]
	_update_history()

	if selected_slot.is_empty():
		stats_preview_label.text = ""
		material_label.text = "Material: ---"
		cron_cost_label.text = ""
		failstack_guide_label.text = ""
		return

	var item := equipment_system.get_equipped(selected_slot)
	if item.is_empty():
		info_label.text = "No item equipped in " + selected_slot
		info_label.remove_theme_color_override("font_color")
		enhance_button.disabled = true
		rate_label.text = "Success Rate: ---"
		cost_label.text = "Cost: ---"
		material_label.text = "Material: ---"
		stats_preview_label.text = ""
		cron_cost_label.text = ""
		failstack_guide_label.text = ""
		return

	var level: int = item.get("enhance_level", 0)
	var grade = item.get("grade", EquipmentData.Grade.COMMON)
	var grade_color: Color = EquipmentData.get_grade_color(grade)
	var display_name := equipment_system.get_enhance_display_name(item)

	# Show item name with grade color
	info_label.text = display_name
	info_label.add_theme_color_override("font_color", grade_color)

	if level >= 20:
		enhance_button.disabled = true
		rate_label.text = "MAX ENHANCEMENT (PEN)"
		cost_label.text = ""
		material_label.text = ""
		stats_preview_label.text = _build_stats_text(item, selected_slot, level, level)
		cron_cost_label.text = ""
		failstack_guide_label.text = ""
		return

	var next_level := level + 1

	# Success rate with failstack bonus
	var base_rate: float = EquipmentSystem.ENHANCEMENT_RATES.get(next_level, 0.01)
	var bonus: float = equipment_system.failstacks * 0.01
	var final_rate: float = min(0.95, base_rate + bonus)
	rate_label.text = "Success Rate: %.1f%% (base %.1f%% + fs %d%%)" % [final_rate * 100, base_rate * 100, equipment_system.failstacks]

	# Color the rate based on probability
	if final_rate >= 0.5:
		rate_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	elif final_rate >= 0.2:
		rate_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		rate_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	# Silver cost
	var silver_cost: int = EquipmentSystem.ENHANCE_COST.get(next_level, 0)
	cost_label.text = "Cost: %s Silver" % SilverManager.format_silver(silver_cost)

	# Material requirement
	var mat_id := equipment_system.get_required_material(selected_slot, next_level)
	var mat_needed: int = EquipmentSystem.MATERIAL_COST.get(next_level, 1)
	var mat_name := EquipmentSystem.get_material_name(mat_id)
	var mat_count := 0
	if equipment_system.inventory:
		mat_count = equipment_system.inventory.count_item(mat_id)
	var mat_color := Color(0.3, 1.0, 0.3) if mat_count >= mat_needed else Color(1.0, 0.3, 0.3)
	material_label.text = "Material: %s x%d (have %d)" % [mat_name, mat_needed, mat_count]
	material_label.add_theme_color_override("font_color", mat_color)

	# Cron stone cost
	if next_level >= 16:
		cron_toggle.visible = true
		var cron_cost := equipment_system.get_cron_cost(selected_slot)
		var cron_count := 0
		if equipment_system.inventory:
			cron_count = equipment_system.inventory.count_item(EquipmentSystem.MAT_CRON_STONE)
		cron_cost_label.text = " (Cost: %d, have %d)" % [cron_cost, cron_count]
	else:
		cron_toggle.visible = false
		cron_toggle.button_pressed = false
		cron_cost_label.text = ""

	# Stats preview (before -> after)
	stats_preview_label.text = _build_stats_text(item, selected_slot, level, next_level)

	# Failstack guide
	var rec: Array = EquipmentSystem.FAILSTACK_RECOMMENDATION.get(next_level, [0, 0])
	failstack_guide_label.text = "Recommended FS: %d - %d" % [rec[0], rec[1]]

	# Enable/disable button
	var check := equipment_system.can_enhance(selected_slot)
	enhance_button.disabled = not check["can"]
	if not check["can"] and not check["reason"].is_empty():
		enhance_button.tooltip_text = check["reason"]
	else:
		enhance_button.tooltip_text = ""

func _build_stats_text(item: Dictionary, slot: String, current_level: int, next_level: int) -> String:
	var current_stats := equipment_system.get_enhanced_item_stats(item, slot, current_level)
	var next_stats := equipment_system.get_enhanced_item_stats(item, slot, next_level)

	var stat_names := {
		"attack": "ATK", "defense": "DEF", "max_hp": "HP",
		"max_mp": "MP", "crit_chance": "CRIT", "speed": "SPD"
	}

	var lines := []
	for stat_key in stat_names:
		var curr_val = current_stats.get(stat_key, 0)
		var next_val = next_stats.get(stat_key, 0)
		if curr_val == 0 and next_val == 0:
			continue
		var label: String = stat_names[stat_key]
		if stat_key == "crit_chance":
			var delta := next_val - curr_val
			var delta_str := ""
			if current_level != next_level:
				if delta > 0:
					delta_str = " (+%.1f%%)" % (delta * 100)
				elif delta < 0:
					delta_str = " (%.1f%%)" % (delta * 100)
			lines.append("%s: %.1f%%%s" % [label, curr_val * 100, delta_str])
		else:
			var delta: int = int(next_val) - int(curr_val)
			var delta_str := ""
			if current_level != next_level:
				if delta > 0:
					delta_str = " (+%d)" % delta
				elif delta < 0:
					delta_str = " (%d)" % delta
			lines.append("%s: %d%s" % [label, int(curr_val), delta_str])

	if lines.is_empty():
		return ""
	return "Stats: " + " | ".join(lines)

func _update_slot_buttons() -> void:
	if not equipment_system:
		return
	for slot in slot_buttons:
		var item := equipment_system.get_equipped(slot)
		var btn: Button = slot_buttons[slot]
		if item.is_empty():
			btn.text = slot.capitalize() + ": Empty"
			btn.remove_theme_color_override("font_color")
		else:
			btn.text = slot.capitalize() + ": " + equipment_system.get_enhance_display_name(item)
			var grade = item.get("grade", EquipmentData.Grade.COMMON)
			btn.add_theme_color_override("font_color", EquipmentData.get_grade_color(grade))
			# Enhancement glow color overlay on button
			var enhance_level: int = item.get("enhance_level", 0)
			var glow_color := _get_enhance_glow_color(enhance_level)
			if glow_color != Color.WHITE:
				btn.add_theme_color_override("font_color", glow_color)

func _get_enhance_glow_color(level: int) -> Color:
	if level >= 20:
		return Color(1.0, 0.65, 0.0) # Orange (PEN)
	elif level >= 15:
		return Color(0.7, 0.3, 0.9) # Purple
	elif level >= 10:
		return Color(0.3, 0.5, 1.0) # Blue
	elif level >= 5:
		return Color(0.3, 0.9, 0.3) # Green
	return Color.WHITE

func _update_history() -> void:
	if not equipment_system or equipment_system.enhancement_history.is_empty():
		history_label.text = "No enhancement attempts yet."
		return

	var lines := []
	for entry in equipment_system.enhancement_history:
		var success_str := "OK" if entry["success"] else "FAIL"
		var level_str: String
		if entry["success"]:
			level_str = "+%d -> +%d" % [entry["from"], entry["to"]]
		elif entry["to"] < entry["from"]:
			level_str = "+%d -> +%d (downgrade!)" % [entry["from"], entry["to"]]
		else:
			level_str = "+%d (no change)" % entry["from"]
		lines.append("[%s] %s %s" % [success_str, entry["item"], level_str])
	history_label.text = "\n".join(lines)

func _on_enhance_pressed() -> void:
	if equipment_system and not selected_slot.is_empty():
		_original_position = position
		equipment_system.enhance_item(selected_slot)
		_update_info()

func _on_enhance_success(slot: String, new_level: int) -> void:
	# Green flash + success message
	var level_name := ""
	if EquipmentSystem.FORCED_ENHANCE_NAMES.has(new_level):
		level_name = " (%s)" % EquipmentSystem.FORCED_ENHANCE_NAMES[new_level]
	feedback_label.text = "SUCCESS! +%d%s" % [new_level, level_name]
	feedback_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	_flash_timer = 2.0

	# Screen shake (gentle on success)
	_shake_timer = 0.2
	_shake_intensity = 3.0

	# Flash panel green briefly
	modulate = Color(0.5, 1.0, 0.5)
	get_tree().create_timer(0.3).timeout.connect(func(): modulate = Color.WHITE)

	_update_info()

func _on_enhance_failed(slot: String, _level: int) -> void:
	feedback_label.text = "FAILED! Failstacks +1"
	feedback_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	_flash_timer = 2.0

	# Screen shake (stronger on failure)
	_shake_timer = 0.3
	_shake_intensity = 5.0

	# Flash panel red briefly
	modulate = Color(1.0, 0.5, 0.5)
	get_tree().create_timer(0.3).timeout.connect(func(): modulate = Color.WHITE)

	_update_info()

func _on_enhance_downgraded(slot: String, old_level: int, new_level: int) -> void:
	feedback_label.text = "DOWNGRADED! +%d -> +%d" % [old_level, new_level]
	feedback_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	_flash_timer = 3.0

	# Heavy screen shake on downgrade
	_shake_timer = 0.5
	_shake_intensity = 8.0

	# Flash panel dark red
	modulate = Color(1.0, 0.3, 0.3)
	get_tree().create_timer(0.5).timeout.connect(func(): modulate = Color.WHITE)

	_update_info()

func _on_equipment_changed(_slot: String) -> void:
	_update_info()
