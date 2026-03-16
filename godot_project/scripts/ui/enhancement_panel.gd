extends PanelContainer
## BDO-inspired enhancement panel. Enhance equipment from +0 to +20.

var equipment_system: EquipmentSystem = null
var selected_slot: String = ""
var slot_buttons: Dictionary = {} # slot -> Button
var info_label := Label.new()
var enhance_button := Button.new()
var failstack_label := Label.new()
var rate_label := Label.new()
var cost_label := Label.new()

func _ready() -> void:
	_build_ui()
	visible = false

func setup(equip_sys: EquipmentSystem) -> void:
	equipment_system = equip_sys
	if equipment_system:
		equipment_system.enhancement_success.connect(_on_enhance_success)
		equipment_system.enhancement_failed.connect(_on_enhance_failed)
		equipment_system.equipment_changed.connect(_on_equipment_changed)

func _build_ui() -> void:
	custom_minimum_size = Vector2(300, 350)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -150
	offset_right = 150
	offset_top = -175
	offset_bottom = 175

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	var title := Label.new()
	title.text = "=== ENHANCEMENT ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Equipment slot buttons
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for slot in EquipmentSystem.SLOTS:
		var btn := Button.new()
		btn.text = slot.capitalize() + ": Empty"
		btn.custom_minimum_size = Vector2(140, 28)
		btn.pressed.connect(_on_slot_selected.bind(slot))
		grid.add_child(btn)
		slot_buttons[slot] = btn

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	info_label.text = "Select an equipment slot"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_label.custom_minimum_size = Vector2(0, 40)
	info_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(info_label)

	failstack_label.text = "Failstacks: 0"
	failstack_label.add_theme_font_size_override("font_size", 11)
	failstack_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	vbox.add_child(failstack_label)

	rate_label.text = "Success Rate: ---"
	rate_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(rate_label)

	cost_label.text = "Cost: ---"
	cost_label.add_theme_font_size_override("font_size", 11)
	cost_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(cost_label)

	enhance_button.text = "ENHANCE"
	enhance_button.custom_minimum_size = Vector2(0, 35)
	enhance_button.pressed.connect(_on_enhance_pressed)
	enhance_button.disabled = true
	vbox.add_child(enhance_button)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): visible = false)
	vbox.add_child(close_btn)

func _on_slot_selected(slot: String) -> void:
	selected_slot = slot
	_update_info()

func _update_info() -> void:
	if not equipment_system:
		return

	_update_slot_buttons()
	failstack_label.text = "Failstacks: %d (+%d%%)" % [equipment_system.failstacks, equipment_system.failstacks]

	if selected_slot.is_empty():
		return

	var item := equipment_system.get_equipped(selected_slot)
	if item.is_empty():
		info_label.text = "No item equipped in " + selected_slot
		enhance_button.disabled = true
		rate_label.text = "Success Rate: ---"
		cost_label.text = "Cost: ---"
		return

	var level: int = item.get("enhance_level", 0)
	var display_name := equipment_system.get_enhance_display_name(item)
	info_label.text = display_name

	if level >= 20:
		enhance_button.disabled = true
		rate_label.text = "MAX ENHANCEMENT"
		cost_label.text = ""
		return

	var next_level := level + 1
	var base_rate: float = EquipmentSystem.ENHANCEMENT_RATES.get(next_level, 0.01)
	var bonus: float = equipment_system.failstacks * 0.01
	var final_rate: float = min(0.95, base_rate + bonus)
	rate_label.text = "Success Rate: %.1f%%" % (final_rate * 100)

	var silver_cost: int = EquipmentSystem.ENHANCE_COST.get(next_level, 0)
	cost_label.text = "Cost: %s Silver" % SilverManager.format_silver(silver_cost)
	enhance_button.disabled = SilverManager.silver < silver_cost

func _update_slot_buttons() -> void:
	if not equipment_system:
		return
	for slot in slot_buttons:
		var item := equipment_system.get_equipped(slot)
		if item.is_empty():
			slot_buttons[slot].text = slot.capitalize() + ": Empty"
		else:
			slot_buttons[slot].text = slot.capitalize() + ": " + equipment_system.get_enhance_display_name(item)

func _on_enhance_pressed() -> void:
	if equipment_system and not selected_slot.is_empty():
		equipment_system.enhance_item(selected_slot)
		_update_info()

func _on_enhance_success(slot: String, new_level: int) -> void:
	info_label.text = "SUCCESS! Enhanced to +%d!" % new_level
	info_label.add_theme_color_override("font_color", Color(0.2, 1, 0.3))
	get_tree().create_timer(1.0).timeout.connect(func():
		info_label.remove_theme_color_override("font_color")
		_update_info()
	)

func _on_enhance_failed(slot: String, _level: int) -> void:
	info_label.text = "Enhancement FAILED! Failstacks +1"
	info_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	get_tree().create_timer(1.0).timeout.connect(func():
		info_label.remove_theme_color_override("font_color")
		_update_info()
	)

func _on_equipment_changed(_slot: String) -> void:
	_update_info()
