extends Node
class_name ChatSystem
## Handles sending and displaying chat messages across channels.

signal message_added(sender: String, text: String, channel: String)

var chat_history: Array[Dictionary] = []
const MAX_HISTORY: int = 100

var current_channel: String = "global"
var available_channels: Array[String] = ["global", "party", "whisper", "system"]

func _ready() -> void:
	EventBus.chat_message_received.connect(_on_message_received)

func send_message(text: String) -> void:
	if text.is_empty():
		return

	# Parse commands
	if text.begins_with("/"):
		_handle_command(text)
		return

	var sender_name := GameManager.player_name

	# Add locally
	_add_message(sender_name, text, current_channel)

	# Broadcast to other players
	if multiplayer.has_multiplayer_peer():
		NetworkManager.send_chat_message.rpc(sender_name, text, current_channel)

func _handle_command(text: String) -> void:
	var parts := text.split(" ", false, 2)
	var command: String = parts[0].to_lower()

	match command:
		"/whisper", "/w":
			if parts.size() >= 3:
				_send_whisper(parts[1], parts[2])
			else:
				_add_message("System", "Usage: /whisper <player> <message>", "system")
		"/party", "/p":
			if parts.size() >= 2:
				current_channel = "party"
				send_message(parts[1])
				current_channel = "global"
			else:
				_add_message("System", "Usage: /party <message>", "system")
		"/help":
			_add_message("System", "Commands: /whisper, /party, /help", "system")
		_:
			_add_message("System", "Unknown command: " + command, "system")

func _send_whisper(target_name: String, message: String) -> void:
	_add_message("To " + target_name, message, "whisper")
	# In a full implementation, send only to the target player

func _on_message_received(sender: String, text: String, channel: String) -> void:
	_add_message(sender, text, channel)

func _add_message(sender: String, text: String, channel: String) -> void:
	var entry := {
		"sender": sender,
		"text": text,
		"channel": channel,
		"timestamp": Time.get_ticks_msec(),
	}
	chat_history.append(entry)
	if chat_history.size() > MAX_HISTORY:
		chat_history.pop_front()
	message_added.emit(sender, text, channel)
