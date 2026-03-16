extends CharacterBody2D
class_name Enemy
## Basic enemy with AI, health, and drops.

@export var enemy_name: String = "Slime"
@export var max_hp: int = 50
@export var attack_power: int = 5
@export var defense: int = 2
@export var move_speed: float = 60.0
@export var detection_range: float = 200.0
@export var attack_range: float = 30.0
@export var exp_reward: int = 25

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var nametag: Label = $Nametag

var current_hp: int
var target: Node2D = null
var state: String = "idle" # idle, chase, attack, dead
var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var attack_cooldown: float = 0.0

# Possible item drops: [{"id": "potion", "chance": 0.5}, ...]
@export var drop_table: Array[Dictionary] = []

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	nametag.text = enemy_name
	_update_hp_bar()

func _physics_process(delta: float) -> void:
	if state == "dead":
		return

	attack_cooldown -= delta

	match state:
		"idle":
			_do_idle(delta)
		"chase":
			_do_chase(delta)
		"attack":
			_do_attack()

	move_and_slide()

func _do_idle(delta: float) -> void:
	# Wander randomly
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		wander_timer = randf_range(1.0, 3.0)

	velocity = wander_direction * move_speed * 0.3

	# Check for nearby players
	target = _find_nearest_player()
	if target and global_position.distance_to(target.global_position) <= detection_range:
		state = "chase"

func _do_chase(delta: float) -> void:
	if not is_instance_valid(target):
		state = "idle"
		return

	var distance := global_position.distance_to(target.global_position)

	if distance > detection_range * 1.5:
		target = null
		state = "idle"
		return

	if distance <= attack_range:
		state = "attack"
		velocity = Vector2.ZERO
		return

	var dir := (target.global_position - global_position).normalized()
	velocity = dir * move_speed

func _do_attack() -> void:
	if not is_instance_valid(target):
		state = "idle"
		return

	var distance := global_position.distance_to(target.global_position)
	if distance > attack_range * 1.5:
		state = "chase"
		return

	if attack_cooldown <= 0.0:
		if target.has_method("take_damage"):
			var damage := CombatSystem.calculate_damage(attack_power, 0)
			target.take_damage(damage, get_instance_id())
		attack_cooldown = 1.0

func take_damage(amount: int, attacker_id: int) -> void:
	var actual_damage := CombatSystem.calculate_damage(amount, defense)
	current_hp -= actual_damage
	_update_hp_bar()

	# Flash red
	sprite.modulate = Color.RED
	get_tree().create_timer(0.1).timeout.connect(func(): sprite.modulate = Color.WHITE)

	if current_hp <= 0:
		_die(attacker_id)

func _die(killer_id: int) -> void:
	state = "dead"
	EventBus.entity_died.emit(get_instance_id())
	GameManager.add_exp(exp_reward)

	# Drop items
	for drop in drop_table:
		if randf() <= drop.get("chance", 0.0):
			EventBus.item_picked_up.emit(drop)

	# Respawn after delay
	visible = false
	set_physics_process(false)
	await get_tree().create_timer(10.0).timeout
	_respawn()

func _respawn() -> void:
	current_hp = max_hp
	state = "idle"
	visible = true
	set_physics_process(true)
	_update_hp_bar()

func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.value = float(current_hp) / float(max_hp) * 100.0

func _find_nearest_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("players")
	var nearest: Node2D = null
	var nearest_dist := INF
	for p in players:
		var dist := global_position.distance_to(p.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = p
	return nearest
