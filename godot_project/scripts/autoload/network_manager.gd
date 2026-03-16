extends Node
## Handles multiplayer networking using Godot's built-in ENet.

const DEFAULT_PORT: int = 9999
const MAX_PLAYERS: int = 100

var peer: ENetMultiplayerPeer = null
var players: Dictionary = {} # peer_id -> { name, position, etc. }
var is_server: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# --- Host / Join ---

func host_server(port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		print("Failed to create server: ", error)
		return error
	multiplayer.multiplayer_peer = peer
	is_server = true
	var my_id := multiplayer.get_unique_id()
	players[my_id] = {"name": GameManager.player_name, "position": Vector2.ZERO}
	GameManager.player_id = my_id
	print("Server started on port ", port)
	EventBus.connected_to_server.emit()
	return OK

func join_server(address: String, port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		print("Failed to connect: ", error)
		return error
	multiplayer.multiplayer_peer = peer
	is_server = false
	print("Connecting to ", address, ":", port)
	return OK

func disconnect_from_server() -> void:
	if peer:
		multiplayer.multiplayer_peer = null
		peer = null
	players.clear()
	is_server = false

# --- Connection Callbacks ---

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	# Send our info to the new peer
	_register_player.rpc_id(id, GameManager.player_name)

func _on_peer_disconnected(id: int) -> void:
	var player_name: String = players.get(id, {}).get("name", "Unknown")
	players.erase(id)
	print("Peer disconnected: ", id)
	EventBus.player_left.emit(id)
	EventBus.chat_message_received.emit("System", player_name + " left the game.", "system")

func _on_connected_to_server() -> void:
	var my_id := multiplayer.get_unique_id()
	GameManager.player_id = my_id
	players[my_id] = {"name": GameManager.player_name, "position": Vector2.ZERO}
	print("Connected to server with ID: ", my_id)
	_register_player.rpc(GameManager.player_name)
	EventBus.connected_to_server.emit()

func _on_connection_failed() -> void:
	print("Connection failed!")
	disconnect_from_server()

func _on_server_disconnected() -> void:
	print("Server disconnected!")
	disconnect_from_server()
	EventBus.disconnected_from_server.emit()

# --- RPCs ---

@rpc("any_peer", "reliable")
func _register_player(player_name: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	players[sender_id] = {"name": player_name, "position": Vector2.ZERO}
	EventBus.player_joined.emit(sender_id, player_name)
	EventBus.chat_message_received.emit("System", player_name + " joined the game.", "system")

@rpc("any_peer", "unreliable")
func sync_player_position(pos: Vector2) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id in players:
		players[sender_id]["position"] = pos

@rpc("any_peer", "reliable")
func send_chat_message(sender_name: String, message: String, channel: String) -> void:
	EventBus.chat_message_received.emit(sender_name, message, channel)

@rpc("any_peer", "reliable")
func sync_damage(attacker_id: int, target_id: int, amount: int) -> void:
	EventBus.damage_dealt.emit(attacker_id, target_id, amount)
