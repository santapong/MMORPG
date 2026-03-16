extends Node
## Manages global game state, player data, and scene transitions.

# Player info
var player_name: String = "Player"
var player_id: int = -1

# Player stats
var player_stats: Dictionary = {
	"level": 1,
	"hp": 100,
	"max_hp": 100,
	"mp": 50,
	"max_mp": 50,
	"attack": 10,
	"defense": 5,
	"speed": 150.0,
	"exp": 0,
	"exp_to_level": 100,
}

# Game state
var is_in_game: bool = false
var current_map: String = ""

func _ready() -> void:
	EventBus.player_level_up.connect(_on_player_level_up)
	EventBus.player_died.connect(_on_player_died)

func start_game(username: String) -> void:
	player_name = username
	is_in_game = true
	get_tree().change_scene_to_file("res://scenes/maps/world.tscn")

func return_to_menu() -> void:
	is_in_game = false
	NetworkManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func add_exp(amount: int) -> void:
	player_stats["exp"] += amount
	while player_stats["exp"] >= player_stats["exp_to_level"]:
		player_stats["exp"] -= player_stats["exp_to_level"]
		player_stats["level"] += 1
		player_stats["exp_to_level"] = _calculate_exp_to_level(player_stats["level"])
		_apply_level_up_bonuses()
		EventBus.player_level_up.emit(player_id, player_stats["level"])
	EventBus.player_exp_changed.emit(
		player_id, player_stats["exp"], player_stats["exp_to_level"]
	)

func _calculate_exp_to_level(level: int) -> int:
	return int(100 * pow(level, 1.5))

func _apply_level_up_bonuses() -> void:
	player_stats["max_hp"] += 10
	player_stats["hp"] = player_stats["max_hp"]
	player_stats["max_mp"] += 5
	player_stats["mp"] = player_stats["max_mp"]
	player_stats["attack"] += 2
	player_stats["defense"] += 1

func _on_player_level_up(_player_id: int, new_level: int) -> void:
	print("Level up! Now level ", new_level)

func _on_player_died(_player_id: int) -> void:
	# Respawn after delay
	await get_tree().create_timer(3.0).timeout
	player_stats["hp"] = player_stats["max_hp"]
	player_stats["mp"] = player_stats["max_mp"]
	EventBus.player_respawned.emit(player_id)
