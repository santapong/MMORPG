extends Control
## Main menu — class selection + join or host a game. BDO-style.

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

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	singleplayer_button.pressed.connect(_on_singleplayer_pressed)
	EventBus.connected_to_server.connect(_on_connected)
	status_label.text = ""
	_setup_class_buttons()

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
