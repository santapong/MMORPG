extends PanelContainer
class_name ChatBox
## In-game chat box UI — displays messages and handles input.

@onready var chat_log: RichTextLabel = $VBoxContainer/ChatLog
@onready var input_field: LineEdit = $VBoxContainer/HBoxContainer/InputField
@onready var send_button: Button = $VBoxContainer/HBoxContainer/SendButton

var chat_system: ChatSystem

func _ready() -> void:
	chat_system = ChatSystem.new()
	add_child(chat_system)
	chat_system.message_added.connect(_on_message_added)
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_text_submitted)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("chat_focus") and not input_field.has_focus():
		input_field.grab_focus()
		get_viewport().set_input_as_handled()

func _on_send_pressed() -> void:
	_submit_message()

func _on_text_submitted(_text: String) -> void:
	_submit_message()

func _submit_message() -> void:
	var text := input_field.text.strip_edges()
	if text.is_empty():
		return
	chat_system.send_message(text)
	input_field.text = ""
	input_field.release_focus()

func _on_message_added(sender: String, text: String, channel: String) -> void:
	var color: String
	match channel:
		"system":
			color = "yellow"
		"whisper":
			color = "pink"
		"party":
			color = "cyan"
		_:
			color = "white"

	chat_log.append_text(
		"[color=" + color + "][" + sender + "][/color]: " + text + "\n"
	)
