extends Control
## Main menu — join or host a game.

@onready var username_input: LineEdit = $CenterContainer/VBoxContainer/UsernameInput
@onready var ip_input: LineEdit = $CenterContainer/VBoxContainer/IPInput
@onready var host_button: Button = $CenterContainer/VBoxContainer/HostButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/JoinButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var singleplayer_button: Button = $CenterContainer/VBoxContainer/SingleplayerButton

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	singleplayer_button.pressed.connect(_on_singleplayer_pressed)
	EventBus.connected_to_server.connect(_on_connected)
	status_label.text = ""

func _on_host_pressed() -> void:
	var username := username_input.text.strip_edges()
	if username.is_empty():
		status_label.text = "Please enter a username."
		return
	GameManager.player_name = username
	var error := NetworkManager.host_server()
	if error == OK:
		status_label.text = "Server started! Loading world..."
		GameManager.start_game(username)
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
	GameManager.start_game(username)

func _on_connected() -> void:
	GameManager.start_game(GameManager.player_name)
