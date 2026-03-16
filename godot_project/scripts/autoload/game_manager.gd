extends Node
## Manages global game state, player data, class selection, and scene transitions.

# Player info
var player_name: String = "Player"
var player_id: int = -1
var player_class: ClassData.ClassType = ClassData.ClassType.WARRIOR

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
	"crit_chance": 0.1,
	"equip_attack": 0,
	"equip_defense": 0,
}

# Game state
var is_in_game: bool = false
var current_map: String = ""

func _ready() -> void:
	EventBus.player_level_up.connect(_on_player_level_up)
	EventBus.player_died.connect(_on_player_died)

func select_class(class_type: ClassData.ClassType) -> void:
	player_class = class_type
	var info := ClassData.get_class_info(class_type)
	player_stats["hp"] = info["base_hp"]
	player_stats["max_hp"] = info["base_hp"]
	player_stats["mp"] = info["base_mp"]
	player_stats["max_mp"] = info["base_mp"]
	player_stats["attack"] = info["base_attack"]
	player_stats["defense"] = info["base_defense"]
	player_stats["speed"] = info["base_speed"]
	player_stats["crit_chance"] = info["crit_chance"]
	player_stats["level"] = 1
	player_stats["exp"] = 0
	player_stats["exp_to_level"] = 100
	player_stats["equip_attack"] = 0
	player_stats["equip_defense"] = 0
	EventBus.class_selected.emit(class_type)

func get_total_attack() -> int:
	return player_stats["attack"] + player_stats.get("equip_attack", 0)

func get_total_defense() -> int:
	return player_stats["defense"] + player_stats.get("equip_defense", 0)

func start_game(username: String) -> void:
	player_name = username
	is_in_game = true
	SilverManager.start_session()
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
	var info := ClassData.get_class_info(player_class)
	player_stats["max_hp"] += info.get("hp_per_level", 10)
	player_stats["hp"] = player_stats["max_hp"]
	player_stats["max_mp"] += info.get("mp_per_level", 5)
	player_stats["mp"] = player_stats["max_mp"]
	player_stats["attack"] += info.get("atk_per_level", 2)
	player_stats["defense"] += info.get("def_per_level", 1)

func _on_player_level_up(_player_id: int, new_level: int) -> void:
	print("Level up! Now level ", new_level)

func _on_player_died(_player_id: int) -> void:
	# Respawn after delay
	await get_tree().create_timer(3.0).timeout
	player_stats["hp"] = player_stats["max_hp"]
	player_stats["mp"] = player_stats["max_mp"]
	EventBus.player_respawned.emit(player_id)
