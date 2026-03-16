extends CharacterBody2D
class_name Player
## Main player controller — handles movement, animation direction, and camera.

@export var speed: float = 150.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var nametag: Label = $Nametag

var is_local: bool = false
var player_peer_id: int = -1
var facing_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	if is_local:
		camera.enabled = true
		nametag.text = GameManager.player_name
	else:
		camera.enabled = false

func _physics_process(delta: float) -> void:
	if not is_local:
		return

	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	input_dir = input_dir.normalized()

	velocity = input_dir * speed

	if input_dir != Vector2.ZERO:
		facing_direction = input_dir
		_update_animation("walk")
	else:
		_update_animation("idle")

	move_and_slide()

	# Sync position to other players
	if multiplayer.has_multiplayer_peer():
		NetworkManager.sync_player_position.rpc(global_position)

	# Attack input
	if Input.is_action_just_pressed("attack"):
		_perform_attack()

	# Interact input
	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _update_animation(action: String) -> void:
	var dir_name := _get_direction_name()
	var anim_name := action + "_" + dir_name
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _get_direction_name() -> String:
	if abs(facing_direction.x) > abs(facing_direction.y):
		return "right" if facing_direction.x > 0 else "left"
	else:
		return "down" if facing_direction.y > 0 else "up"

func _perform_attack() -> void:
	var anim_name := "attack_" + _get_direction_name()
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

	# Check for enemies in attack area
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			var damage: int = GameManager.player_stats["attack"]
			if body.has_method("take_damage"):
				body.take_damage(damage, player_peer_id)
			if multiplayer.has_multiplayer_peer():
				NetworkManager.sync_damage.rpc(
					player_peer_id, body.get_instance_id(), damage
				)

func _try_interact() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("npcs") and body.has_method("interact"):
			body.interact()
			return

func take_damage(amount: int, _attacker_id: int) -> void:
	var actual_damage: int = max(1, amount - GameManager.player_stats["defense"])
	GameManager.player_stats["hp"] -= actual_damage
	EventBus.player_health_changed.emit(
		player_peer_id,
		GameManager.player_stats["hp"],
		GameManager.player_stats["max_hp"]
	)
	if GameManager.player_stats["hp"] <= 0:
		_die()

func _die() -> void:
	EventBus.player_died.emit(player_peer_id)
	visible = false
	set_physics_process(false)
	EventBus.player_respawned.connect(_on_respawned, CONNECT_ONE_SHOT)

func _on_respawned(_player_id: int) -> void:
	global_position = Vector2(400, 300) # Spawn point
	visible = true
	set_physics_process(true)
	EventBus.player_health_changed.emit(
		player_peer_id,
		GameManager.player_stats["hp"],
		GameManager.player_stats["max_hp"]
	)
