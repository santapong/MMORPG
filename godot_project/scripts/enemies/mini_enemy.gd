extends CharacterBody3D
class_name MiniEnemy
## 3D temporary mini enemy spawned by split abilities.
## Chases nearest player, attacks, then despawns after lifetime expires.

const WORLD_SCALE: float = 1.0 / 30.0

@onready var mesh: MeshInstance3D = $Mesh
@onready var nametag: Label3D = $Nametag

var mini_name: String = "Minion"
var max_hp: int = 30
var current_hp: int = 30
var attack_power: int = 5
var defense: int = 0
var move_speed: float = 60.0      # px/s legacy
var attack_range: float = 25.0     # px legacy
var detection_range: float = 180.0 # px legacy

var target: Node3D = null
var state: String = "chase"
var attack_cooldown: float = 0.0
var lifetime: float = 8.0
var lifetime_timer: float = 0.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	add_to_group("enemies")
	nametag.text = mini_name
	current_hp = max_hp

func setup_mini(stats: Dictionary, life: float, initial_target: Node3D) -> void:
	mini_name = stats.get("name", "Minion")
	max_hp = stats.get("hp", 30)
	current_hp = max_hp
	attack_power = stats.get("atk", 5)
	defense = stats.get("def", 0)
	move_speed = stats.get("speed", 60.0)
	lifetime = life
	lifetime_timer = life
	target = initial_target

	var color: Color = stats.get("color", Color(0.8, 0.8, 0.8, 0.85))
	var mini_scale_2d: Vector2 = stats.get("scale", Vector2(0.5, 0.5))
	var uniform_scale := mini_scale_2d.x
	call_deferred("_apply_visuals", color, uniform_scale)

func _apply_visuals(color: Color, uniform_scale: float) -> void:
	if mesh:
		var mat: StandardMaterial3D = mesh.get_active_material(0)
		if mat:
			mat = mat.duplicate()
			mat.albedo_color = color
			mesh.set_surface_override_material(0, mat)
		mesh.scale = Vector3.ONE * uniform_scale
	if nametag:
		nametag.text = mini_name

func _ground_distance(a: Vector3, b: Vector3) -> float:
	var dx := (a.x - b.x) / WORLD_SCALE
	var dz := (a.z - b.z) / WORLD_SCALE
	return sqrt(dx * dx + dz * dz)

func _physics_process(delta: float) -> void:
	if state == "dead":
		return

	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		_despawn()
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	if lifetime_timer < 2.0 and mesh:
		var mat: StandardMaterial3D = mesh.get_active_material(0)
		if mat:
			var c := mat.albedo_color
			c.a = lifetime_timer / 2.0
			mat.albedo_color = c

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

	var distance := _ground_distance(global_position, target.global_position)

	if distance <= attack_range:
		state = "attack"
		velocity.x = 0
		velocity.z = 0
		return

	var dir := target.global_position - global_position
	dir.y = 0
	dir = dir.normalized()
	velocity.x = dir.x * move_speed * WORLD_SCALE
	velocity.z = dir.z * move_speed * WORLD_SCALE

func _do_attack() -> void:
	if not is_instance_valid(target):
		state = "chase"
		return

	var distance := _ground_distance(global_position, target.global_position)
	if distance > attack_range * 1.5:
		state = "chase"
		return

	if attack_cooldown <= 0.0:
		if target.has_method("take_damage"):
			var damage := CombatSystem.calculate_damage(attack_power, 0)
			target.take_damage(damage, get_instance_id())
		attack_cooldown = 0.8

func take_damage(amount: int, attacker_id: int) -> void:
	var actual_damage := CombatSystem.calculate_damage(amount, defense)
	current_hp -= actual_damage
	EventBus.damage_dealt.emit(attacker_id, get_instance_id(), actual_damage)

	if mesh:
		var mat: StandardMaterial3D = mesh.get_active_material(0)
		if mat:
			var original := mat.albedo_color
			mat.albedo_color = Color.WHITE
			get_tree().create_timer(0.1).timeout.connect(
				func():
					if is_instance_valid(self) and mat:
						mat.albedo_color = original
			)

	if current_hp <= 0:
		_die()

func _die() -> void:
	state = "dead"
	EventBus.entity_died.emit(get_instance_id())
	GameManager.add_exp(5)
	_despawn()

func _despawn() -> void:
	state = "dead"
	set_physics_process(false)
	queue_free()

func _find_nearest_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("players")
	var nearest: Node3D = null
	var nearest_dist := INF
	for p in players:
		var dist := _ground_distance(global_position, p.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = p
	return nearest
