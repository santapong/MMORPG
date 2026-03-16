extends CharacterBody2D
class_name MiniEnemy
## Temporary mini enemy spawned by split abilities (bone split, slime split).
## Chases nearest player, attacks, then despawns after lifetime expires.

@onready var sprite: Sprite2D = $Sprite2D
@onready var nametag: Label = $Nametag

var mini_name: String = "Minion"
var max_hp: int = 30
var current_hp: int = 30
var attack_power: int = 5
var defense: int = 0
var move_speed: float = 60.0
var attack_range: float = 25.0
var detection_range: float = 180.0

var target: Node2D = null
var state: String = "chase" # chase, attack, dead
var attack_cooldown: float = 0.0
var lifetime: float = 8.0
var lifetime_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	nametag.text = mini_name
	current_hp = max_hp

func setup_mini(stats: Dictionary, life: float, initial_target: Node2D) -> void:
	mini_name = stats.get("name", "Minion")
	max_hp = stats.get("hp", 30)
	current_hp = max_hp
	attack_power = stats.get("atk", 5)
	defense = stats.get("def", 0)
	move_speed = stats.get("speed", 60.0)
	lifetime = life
	lifetime_timer = life
	target = initial_target

	# Apply visual style
	var color: Color = stats.get("color", Color(0.8, 0.8, 0.8, 0.8))
	var mini_scale: Vector2 = stats.get("scale", Vector2(0.5, 0.5))
	call_deferred("_apply_visuals", color, mini_scale)

func _apply_visuals(color: Color, mini_scale: Vector2) -> void:
	if sprite:
		sprite.modulate = color
		sprite.scale = mini_scale
	if nametag:
		nametag.text = mini_name

func _physics_process(delta: float) -> void:
	if state == "dead":
		return

	# Lifetime countdown
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		_despawn()
		return

	# Fade out in last 2 seconds
	if lifetime_timer < 2.0:
		modulate.a = lifetime_timer / 2.0

	attack_cooldown -= delta

	match state:
		"chase":
			_do_chase()
		"attack":
			_do_attack()

	move_and_slide()

func _do_chase() -> void:
	if not is_instance_valid(target):
		target = _find_nearest_player()
		if not is_instance_valid(target):
			_despawn()
			return

	var distance := global_position.distance_to(target.global_position)

	if distance <= attack_range:
		state = "attack"
		velocity = Vector2.ZERO
		return

	var dir := (target.global_position - global_position).normalized()
	velocity = dir * move_speed

func _do_attack() -> void:
	if not is_instance_valid(target):
		state = "chase"
		return

	var distance := global_position.distance_to(target.global_position)
	if distance > attack_range * 1.5:
		state = "chase"
		return

	if attack_cooldown <= 0.0:
		if target.has_method("take_damage"):
			var damage := CombatSystem.calculate_damage(attack_power, 0)
			target.take_damage(damage, get_instance_id())
		attack_cooldown = 0.8 # Attacks slightly faster than normal enemies

func take_damage(amount: int, attacker_id: int) -> void:
	var actual_damage := CombatSystem.calculate_damage(amount, defense)
	current_hp -= actual_damage
	EventBus.damage_dealt.emit(attacker_id, get_instance_id(), actual_damage)

	# Flash white
	if sprite:
		sprite.modulate = Color.WHITE
		get_tree().create_timer(0.1).timeout.connect(func():
			if is_instance_valid(self) and sprite:
				sprite.modulate = Color(0.8, 0.8, 0.8, 0.8)
		)

	if current_hp <= 0:
		_die()

func _die() -> void:
	state = "dead"
	EventBus.entity_died.emit(get_instance_id())
	# Mini enemies give small exp
	GameManager.add_exp(5)
	_despawn()

func _despawn() -> void:
	state = "dead"
	set_physics_process(false)
	queue_free()

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
