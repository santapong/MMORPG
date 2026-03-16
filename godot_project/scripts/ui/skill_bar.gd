extends PanelContainer
## Skill hotbar UI — shows 4 skill slots with cooldown overlays.

var skill_buttons: Array[Button] = []
var cooldown_labels: Array[Label] = []
var skill_ids: Array[String] = []
var skill_system: SkillSystem = null

func _ready() -> void:
	_build_ui()
	EventBus.class_selected.connect(_on_class_selected)

func setup(system: SkillSystem) -> void:
	skill_system = system
	if skill_system:
		skill_system.skill_cooldown_updated.connect(_on_cooldown_updated)

func _build_ui() -> void:
	custom_minimum_size = Vector2(280, 70)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -140
	offset_right = 140
	offset_top = -80
	offset_bottom = -10

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	for i in 4:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(60, 60)
		hbox.add_child(slot)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_child(vbox)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(50, 36)
		btn.text = str(i + 1)
		btn.pressed.connect(_on_skill_pressed.bind(i))
		vbox.add_child(btn)
		skill_buttons.append(btn)

		var cd_label := Label.new()
		cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_label.add_theme_font_size_override("font_size", 10)
		cd_label.text = ""
		vbox.add_child(cd_label)
		cooldown_labels.append(cd_label)

func _on_class_selected(class_type: ClassData.ClassType) -> void:
	var class_info := ClassData.get_class_info(class_type)
	skill_ids.clear()
	skill_ids.assign(class_info.get("skills", []))
	_update_buttons()

func _update_buttons() -> void:
	for i in 4:
		if i < skill_ids.size():
			var skill := SkillData.get_skill(skill_ids[i])
			skill_buttons[i].text = skill.get("name", str(i + 1))
			skill_buttons[i].tooltip_text = skill.get("description", "")
			skill_buttons[i].disabled = false
			# Tint button with skill color
			var color: Color = skill.get("icon_color", Color.WHITE)
			skill_buttons[i].modulate = color
		else:
			skill_buttons[i].text = "-"
			skill_buttons[i].disabled = true
			skill_buttons[i].modulate = Color.WHITE

func _process(_delta: float) -> void:
	# Check for hotkey inputs
	for i in skill_ids.size():
		if i >= 4:
			break
		var action := "skill_%d" % (i + 1)
		if Input.is_action_just_pressed(action):
			_on_skill_pressed(i)

func _on_skill_pressed(index: int) -> void:
	if index >= skill_ids.size():
		return
	if skill_system:
		skill_system.use_skill(skill_ids[index])

func _on_cooldown_updated(skill_id: String, remaining: float, _total: float) -> void:
	var idx := skill_ids.find(skill_id)
	if idx < 0 or idx >= cooldown_labels.size():
		return
	if remaining > 0.0:
		cooldown_labels[idx].text = "%.1f" % remaining
		skill_buttons[idx].disabled = true
	else:
		cooldown_labels[idx].text = ""
		skill_buttons[idx].disabled = false
