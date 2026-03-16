extends Node2D
## Main game world — spawns player, enemies, NPCs, and UI.

const PlayerScene := preload("res://scenes/player/player.tscn")
const OtherPlayerScene := preload("res://scenes/player/other_player.tscn")
const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const NPCScene := preload("res://scenes/npcs/npc.tscn")

@onready var entities: Node2D = $Entities
@onready var ui_layer: CanvasLayer = $UILayer

var local_player: Player = null
var other_players: Dictionary = {} # peer_id -> OtherPlayer node

func _ready() -> void:
	_spawn_local_player()
	_spawn_enemies()
	_spawn_npcs()

	# Listen for other players joining/leaving
	EventBus.player_joined.connect(_on_player_joined)
	EventBus.player_left.connect(_on_player_left)

func _process(_delta: float) -> void:
	# Sync remote player positions
	for peer_id in NetworkManager.players:
		if peer_id == GameManager.player_id:
			continue
		if peer_id in other_players:
			var pos: Vector2 = NetworkManager.players[peer_id].get("position", Vector2.ZERO)
			other_players[peer_id].update_position(pos)

func _spawn_local_player() -> void:
	local_player = PlayerScene.instantiate() as Player
	local_player.is_local = true
	local_player.player_peer_id = GameManager.player_id
	local_player.global_position = Vector2(400, 300)
	entities.add_child(local_player)

func _spawn_enemies() -> void:
	var enemy_spawns := [
		{"name": "Slime", "pos": Vector2(600, 200), "hp": 50, "atk": 5, "exp": 25},
		{"name": "Slime", "pos": Vector2(700, 350), "hp": 50, "atk": 5, "exp": 25},
		{"name": "Slime", "pos": Vector2(500, 500), "hp": 50, "atk": 5, "exp": 25},
		{"name": "Wolf", "pos": Vector2(900, 400), "hp": 80, "atk": 10, "exp": 50},
		{"name": "Wolf", "pos": Vector2(1000, 250), "hp": 80, "atk": 10, "exp": 50},
	]

	for data in enemy_spawns:
		var enemy := EnemyScene.instantiate() as Enemy
		enemy.enemy_name = data["name"]
		enemy.global_position = data["pos"]
		enemy.max_hp = data["hp"]
		enemy.attack_power = data["atk"]
		enemy.exp_reward = data["exp"]
		enemy.drop_table = [
			{"id": "health_potion", "name": "Health Potion", "type": "consumable",
			 "effect": "heal", "value": 30, "stackable": true, "quantity": 1, "chance": 0.4},
		]
		entities.add_child(enemy)

func _spawn_npcs() -> void:
	var npc_data := [
		{
			"name": "Elder Gorn",
			"pos": Vector2(300, 200),
			"dialog": [
				"Welcome, adventurer! This is the starting village.",
				"Beware of the slimes in the eastern fields.",
				"Come back when you're stronger. There are wolves further out."
			],
		},
		{
			"name": "Merchant Lyra",
			"pos": Vector2(200, 350),
			"dialog": [
				"Looking to buy something?",
				"I've got potions and basic gear.",
				"Come back anytime!"
			],
			"is_shop": true,
		},
	]

	for data in npc_data:
		var npc := NPCScene.instantiate() as NPC
		npc.npc_name = data["name"]
		npc.global_position = data["pos"]
		npc.dialog_lines = data["dialog"]
		npc.is_shopkeeper = data.get("is_shop", false)
		entities.add_child(npc)

func _on_player_joined(peer_id: int, player_name: String) -> void:
	if peer_id == GameManager.player_id:
		return
	var other := OtherPlayerScene.instantiate() as OtherPlayer
	other.peer_id = peer_id
	other.player_name = player_name
	entities.add_child(other)
	other_players[peer_id] = other

func _on_player_left(peer_id: int) -> void:
	if peer_id in other_players:
		other_players[peer_id].queue_free()
		other_players.erase(peer_id)
