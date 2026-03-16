extends Control
## Main menu — character select (5 slots) + class selection + join or host a game. BDO-style.

@onready var username_input: LineEdit = $CenterContainer/VBoxContainer/UsernameInput
@onready var ip_input: LineEdit = $CenterContainer/VBoxContainer/IPInput
@onready var host_button: Button = $CenterContainer/VBoxContainer/HostButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/JoinButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var singleplayer_button: Button = $CenterContainer/VBoxContainer/SingleplayerButton
@onready var class_container: HBoxContainer = $CenterContainer/VBoxContainer/ClassContainer
@onready var class_desc_label: Label = $CenterContainer/VBoxContainer/ClassDescLabel

var selected_class: ClassData.ClassType = ClassData.ClassType.WARRIOR
var class_buttons: Dictionary = {}

# Character select UI (built dynamically)
var char_select_panel: PanelContainer = null
var create_char_panel: PanelContainer = null
var slot_buttons: Array[Button] = []
var delete_buttons: Array[Button] = []
var selected_slot: int = -1

# Screens: "char_select" -> "create_char" -> "play_options" or "char_select" -> "play_options"
var current_screen: String = "char_select"

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	singleplayer_button.pressed.connect(_on_singleplayer_pressed)
	EventBus.connected_to_server.connect(_on_connected)
	status_label.text = ""
	_setup_class_buttons()

	# Build character select and creation panels
	_build_character_select()
	_build_create_character()

	# Start on character select screen
	_show_screen("char_select")

func _build_character_select() -> void:
	char_select_panel = PanelContainer.new()
	char_select_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	char_select_panel.custom_minimum_size = Vector2(500, 420)
	char_select_panel.anchor_left = 0.5
	char_select_panel.anchor_right = 0.5
	char_select_panel.anchor_top = 0.5
	char_select_panel.anchor_bottom = 0.5
	char_select_panel.offset_left = -250
	char_select_panel.offset_right = 250
	char_select_panel.offset_top = -210
	char_select_panel.offset_bottom = 210
	add_child(char_select_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	char_select_panel.add_child(vbox)

	var title := Label.new()
	title.text = "PIXEL GRINDER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Select Your Character"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	# 5 character slots
	for i in SaveManager.MAX_SLOTS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		vbox.add_child(hbox)

		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(380, 50)
		slot_btn.add_theme_font_size_override("font_size", 12)
		var idx := i
		slot_btn.pressed.connect(_on_slot_pressed.bind(idx))
		hbox.add_child(slot_btn)
		slot_buttons.append(slot_btn)

		var del_btn := Button.new()
		del_btn.text = "X"
		del_btn.custom_minimum_size = Vector2(40, 50)
		del_btn.add_theme_font_size_override("font_size", 12)
		del_btn.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		del_btn.tooltip_text = "Delete character"
		del_btn.pressed.connect(_on_delete_pressed.bind(idx))
		hbox.add_child(del_btn)
		delete_buttons.append(del_btn)

	vbox.add_child(HSeparator.new())

	var controls := Label.new()
	controls.text = "WASD: Move | Click: Attack | 1-4: Skills | G: Grind | P: Enhance | I: Inventory"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 9)
	controls.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(controls)

	_refresh_slot_buttons()

func _build_create_character() -> void:
	create_char_panel = PanelContainer.new()
	create_char_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	create_char_panel.custom_minimum_size = Vector2(400, 320)
	create_char_panel.anchor_left = 0.5
	create_char_panel.anchor_right = 0.5
	create_char_panel.anchor_top = 0.5
	create_char_panel.anchor_bottom = 0.5
	create_char_panel.offset_left = -200
	create_char_panel.offset_right = 200
	create_char_panel.offset_top = -160
	create_char_panel.offset_bottom = 160
	create_char_panel.visible = false
	add_child(create_char_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	create_char_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Create New Character"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Name input
	var name_label := Label.new()
	name_label.text = "Character Name:"
	vbox.add_child(name_label)

	var name_input := LineEdit.new()
	name_input.name = "CreateNameInput"
	name_input.placeholder_text = "Enter character name..."
	name_input.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(name_input)

	# Class selection
	var class_label := Label.new()
	class_label.text = "Choose Class:"
	vbox.add_child(class_label)

	var class_hbox := HBoxContainer.new()
	class_hbox.name = "CreateClassContainer"
	class_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(class_hbox)

	var create_desc := Label.new()
	create_desc.name = "CreateClassDesc"
	create_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	create_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	create_desc.custom_minimum_size = Vector2(0, 35)
	create_desc.add_theme_font_size_override("font_size", 10)
	vbox.add_child(create_desc)

	var _create_selected_class := ClassData.ClassType.WARRIOR
	for class_type in ClassData.get_all_classes():
		var info := ClassData.get_class_info(class_type)
		var btn := Button.new()
		btn.text = info["name"]
		btn.custom_minimum_size = Vector2(90, 30)
		btn.pressed.connect(_on_create_class_selected.bind(class_type))
		class_hbox.add_child(btn)

	# Error label
	var error_label := Label.new()
	error_label.name = "CreateErrorLabel"
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	error_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(error_label)

	# Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_hbox)

	var create_btn := Button.new()
	create_btn.text = "Create"
	create_btn.custom_minimum_size = Vector2(100, 35)
	create_btn.pressed.connect(_on_create_confirmed)
	btn_hbox.add_child(create_btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(100, 35)
	back_btn.pressed.connect(_on_create_back)
	btn_hbox.add_child(back_btn)

	_update_create_class_display()

# State for character creation
var _create_selected_class: ClassData.ClassType = ClassData.ClassType.WARRIOR

func _refresh_slot_buttons() -> void:
	var slots := SaveManager.get_all_slot_info()
	for i in SaveManager.MAX_SLOTS:
		var info: Dictionary = slots[i]
		if info.is_empty():
			slot_buttons[i].text = "--- Empty Slot %d ---" % (i + 1)
			slot_buttons[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			delete_buttons[i].visible = false
		else:
			var class_name_str := ClassData.get_class_name_str(info.get("class", 0))
			var level: int = info.get("level", 1)
			var name: String = info.get("name", "Unknown")
			var silver: int = info.get("silver", 0)
			var gs: int = info.get("gear_score", 0)
			var playtime_str := SaveManager.format_playtime(info.get("playtime", 0))
			slot_buttons[i].text = "Slot %d:  %s  |  Lv.%d %s  |  GS: %d  |  %s  |  %s" % [
				i + 1, name, level, class_name_str, gs,
				SilverManager.format_silver(silver), playtime_str
			]
			var class_info := ClassData.get_class_info(info.get("class", 0))
			slot_buttons[i].add_theme_color_override("font_color", class_info.get("color", Color.WHITE))
			delete_buttons[i].visible = true

func _show_screen(screen_name: String) -> void:
	current_screen = screen_name
	# Hide all
	char_select_panel.visible = false
	create_char_panel.visible = false
	$CenterContainer.visible = false

	match screen_name:
		"char_select":
			char_select_panel.visible = true
			_refresh_slot_buttons()
		"create_char":
			create_char_panel.visible = true
			var name_input: LineEdit = create_char_panel.find_child("CreateNameInput", true, false)
			if name_input:
				name_input.text = ""
			var error_label: Label = create_char_panel.find_child("CreateErrorLabel", true, false)
			if error_label:
				error_label.text = ""
			_create_selected_class = ClassData.ClassType.WARRIOR
			_update_create_class_display()
		"play_options":
			$CenterContainer.visible = true

func _on_slot_pressed(slot: int) -> void:
	selected_slot = slot
	if SaveManager.has_save(slot):
		# Load existing character and go to play options
		SaveManager.load_game(slot)
		username_input.text = GameManager.player_name
		selected_class = GameManager.player_class
		_update_class_selection()
		status_label.text = "Character loaded: %s (Lv.%d)" % [GameManager.player_name, GameManager.player_stats["level"]]
		_show_screen("play_options")
	else:
		# Open create character screen
		_show_screen("create_char")

func _on_delete_pressed(slot: int) -> void:
	if not SaveManager.has_save(slot):
		return
	# Delete with confirmation (simple: just delete)
	SaveManager.delete_save(slot)
	_refresh_slot_buttons()

func _on_create_class_selected(class_type: ClassData.ClassType) -> void:
	_create_selected_class = class_type
	_update_create_class_display()

func _update_create_class_display() -> void:
	var desc_label: Label = create_char_panel.find_child("CreateClassDesc", true, false)
	if desc_label:
		var info := ClassData.get_class_info(_create_selected_class)
		desc_label.text = info.get("description", "")

	# Highlight selected class button
	var class_hbox: HBoxContainer = create_char_panel.find_child("CreateClassContainer", true, false)
	if class_hbox:
		var classes := ClassData.get_all_classes()
		for i in class_hbox.get_child_count():
			var btn: Button = class_hbox.get_child(i)
			if i < classes.size() and classes[i] == _create_selected_class:
				btn.modulate = ClassData.get_class_info(classes[i]).get("color", Color.WHITE)
			else:
				btn.modulate = Color(0.6, 0.6, 0.6)

func _on_create_confirmed() -> void:
	var name_input: LineEdit = create_char_panel.find_child("CreateNameInput", true, false)
	var error_label: Label = create_char_panel.find_child("CreateErrorLabel", true, false)
	if not name_input:
		return

	var char_name := name_input.text.strip_edges()
	if char_name.is_empty():
		if error_label:
			error_label.text = "Please enter a character name."
		return
	if char_name.length() > 16:
		if error_label:
			error_label.text = "Name must be 16 characters or less."
		return

	# Create character and save
	GameManager.reset_state()
	SaveManager.create_character(selected_slot, char_name, _create_selected_class)
	SaveManager.load_game(selected_slot)

	username_input.text = char_name
	selected_class = _create_selected_class
	_update_class_selection()
	status_label.text = "New character created: %s" % char_name
	_show_screen("play_options")

func _on_create_back() -> void:
	_show_screen("char_select")

func _setup_class_buttons() -> void:
	for class_type in ClassData.get_all_classes():
		var info := ClassData.get_class_info(class_type)
		var btn := Button.new()
		btn.text = info["name"]
		btn.custom_minimum_size = Vector2(90, 35)
		btn.pressed.connect(_on_class_selected.bind(class_type))
		class_container.add_child(btn)
		class_buttons[class_type] = btn
	_update_class_selection()

func _on_class_selected(class_type: ClassData.ClassType) -> void:
	selected_class = class_type
	_update_class_selection()

func _update_class_selection() -> void:
	var info := ClassData.get_class_info(selected_class)
	class_desc_label.text = info.get("description", "")

	# Highlight selected button
	for ct in class_buttons:
		var btn: Button = class_buttons[ct]
		if ct == selected_class:
			btn.modulate = ClassData.get_class_info(ct).get("color", Color.WHITE)
		else:
			btn.modulate = Color(0.6, 0.6, 0.6)

func _start_with_class(username: String) -> void:
	GameManager.select_class(selected_class)
	GameManager.player_name = username
	# Save before entering world
	if selected_slot >= 0:
		SaveManager.save_game(selected_slot)
		SaveManager.start_playtime_tracking()
	GameManager.start_game(username)

func _on_host_pressed() -> void:
	var username := username_input.text.strip_edges()
	if username.is_empty():
		status_label.text = "Please enter a username."
		return
	GameManager.player_name = username
	var error := NetworkManager.host_server()
	if error == OK:
		status_label.text = "Server started! Loading world..."
		_start_with_class(username)
	else:
		status_label.text = "Failed to start server."

func _on_join_pressed() -> void:
	var username := username_input.text.strip_edges()
	var ip := ip_input.text.strip_edges()
	if username.is_empty():
		status_label.text = "Please enter a username."
		return
	if ip.is_empty():
		ip = "127.0.0.1"
	GameManager.player_name = username
	status_label.text = "Connecting to " + ip + "..."
	var error := NetworkManager.join_server(ip)
	if error != OK:
		status_label.text = "Failed to connect."

func _on_singleplayer_pressed() -> void:
	var username := username_input.text.strip_edges()
	if username.is_empty():
		status_label.text = "Please enter a username."
		return
	_start_with_class(username)

func _on_connected() -> void:
	GameManager.select_class(selected_class)
	GameManager.start_game(GameManager.player_name)
