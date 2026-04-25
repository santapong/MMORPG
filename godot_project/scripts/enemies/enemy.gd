extends CharacterBody3D
class_name Enemy
## 3D enemy with AI, health, drops, and zone-based stats.
## Stored ranges and speeds are in pixel units (legacy ZoneData); they're
## scaled by WORLD_SCALE (1/30) into meters at use sites so the existing
## tuning data stays untouched.

const WORLD_SCALE: float = 1.0 / 30.0

@export var enemy_name: String = "Slime"
@export var max_hp: int = 50
@export var attack_power: int = 5
@export var defense: int = 2
@export var move_speed: float = 60.0       # px/s (legacy)
@export var detection_range: float = 200.0  # px (legacy)
@export var attack_range: float = 30.0      # px (legacy)
@export var exp_reward: int = 25

@onready var mesh: MeshInstance3D = $Mesh
@onready var hp_label: Label3D = $HPLabel
@onready var nametag: Label3D = $Nametag

var current_hp: int
var target: Node3D = null
var state: String = "idle" # idle, chase, attack, dead
var wander_timer: float = 0.0
var wander_direction: Vector3 = Vector3.ZERO
var attack_cooldown: float = 0.0
var spawn_position: Vector3 = Vector3.ZERO
var respawn_time: float = 8.0

var mob_id: String = "slime"

var ability: Dictionary = {}
var ability_cooldown_timer: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var dash_speed_override: float = 0.0
var has_death_split: bool = false
var buff_active: bool = false
var buff_timer: float = 0.0
var original_attack_power: int = 0
var original_move_speed: float = 0.0

@export var drop_table: Array[Dictionary] = []

var silver_per_kill: int = 0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

const MOB_COLORS := {
	"slime": Color(0.3, 1.0, 0.3),
	"big_slime": Color(0.2, 0.8, 0.2),
	"wolf": Color(0.6, 0.5, 0.4),
	"alpha_wolf": Color(0.4, 0.3, 0.25),
	"forest_spirit": Color(0.5, 1.0, 0.8, 0.8),
	"bandit": Color(0.8, 0.5, 0.3),
	"bandit_archer": Color(0.7, 0.4, 0.3),
	"bandit_chief": Color(0.9, 0.3, 0.2),
	"skeleton": Color(0.9, 0.9, 0.8),
	"skeleton_mage": Color(0.7, 0.5, 0.9),
	"bone_golem": Color(0.8, 0.7, 0.6),
	"lich": Color(0.5, 0.2, 0.8),
	"imp": Color(1.0, 0.4, 0.2),
	"demon_soldier": Color(0.8, 0.1, 0.1),
	"hellhound": Color(1.0, 0.3, 0.0),
	"demon_lord": Color(0.6, 0.0, 0.0),
}

func _ready() -> void:
	current_hp = max_hp
	if spawn_position == Vector3.ZERO:
		spawn_position = global_position
	add_to_group("enemies")
	nametag.text = enemy_name
	_update_hp_bar()
	_apply_color(MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3)))
	_setup_ability()

func setup_from_mob_id(id: String, zone_silver: int = 0) -> void:
	mob_id = id
	var stats := ZoneData.get_mob_stats(id)
	if stats.is_empty():
		return
	max_hp = stats.get("hp", 50)
	attack_power = stats.get("atk", 5)
	defense = stats.get("def", 2)
	move_speed = stats.get("speed", 60.0)
	exp_reward = stats.get("exp", 25)
	detection_range = stats.get("detect", 200.0)
	silver_per_kill = zone_silver

	var drops := ZoneData.get_mob_drops(id)
	drop_table.clear()
	for drop in drops:
		drop_table.append(drop)

	current_hp = max_hp
	if mesh:
		_apply_color(MOB_COLORS.get(id, Color(1, 0.3, 0.3)))
	_setup_ability()

func _setup_ability() -> void:
	ability = EnemyAbilities.get_ability(mob_id)
	if ability.is_empty():
		return
	has_death_split = ability.get("trigger", "") == "on_death"
	original_attack_power = attack_power
	original_move_speed = move_speed

func _physics_process(delta: float) -> void:
	if state == "dead":
		return

	attack_cooldown -= delta
	ability_cooldown_timer -= delta

	# Gravity always.
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction.x * dash_speed_override * WORLD_SCALE
		velocity.z = dash_direction.z * dash_speed_override * WORLD_SCALE
		move_and_slide()
		if dash_timer <= 0.0:
			is_dashing = false
			_finish_lunge_bite()
		return

	if buff_active:
		buff_timer -= delta
		if buff_timer <= 0.0:
			_remove_buff()

	match state:
		"idle":
			_do_idle(delta)
		"chase":
			_do_chase(delta)
		"attack":
			_do_attack()

	move_and_slide()
	_face_velocity(delta)

func _face_velocity(delta: float) -> void:
	var horiz := Vector3(velocity.x, 0, velocity.z)
	if horiz.length() < 0.05:
		return
	var target_yaw := atan2(horiz.x, horiz.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 8.0 * delta)

func _ground_distance(a: Vector3, b: Vector3) -> float:
	# 2D distance on the ground plane, in pixel units (matches legacy tuning).
	var dx := (a.x - b.x) / WORLD_SCALE
	var dz := (a.z - b.z) / WORLD_SCALE
	return sqrt(dx * dx + dz * dz)

func _do_idle(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		wander_timer = randf_range(1.0, 3.0)

	if _ground_distance(global_position, spawn_position) > 150.0:
		var to_spawn := spawn_position - global_position
		to_spawn.y = 0
		wander_direction = to_spawn.normalized()

	velocity.x = wander_direction.x * move_speed * WORLD_SCALE * 0.3
	velocity.z = wander_direction.z * move_speed * WORLD_SCALE * 0.3

	target = _find_nearest_player()
	if target and _ground_distance(global_position, target.global_position) <= detection_range:
		state = "chase"

func _do_chase(_delta: float) -> void:
	if not is_instance_valid(target):
		state = "idle"
		return

	var dist := _ground_distance(global_position, target.global_position)

	if dist > detection_range * 1.5:
		target = null
		state = "idle"
		return

	if not ability.is_empty() and ability_cooldown_timer <= 0.0:
		if _try_use_ability(dist):
			return

	if dist <= attack_range:
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
		state = "idle"
		return

	var dist := _ground_distance(global_position, target.global_position)
	if dist > attack_range * 1.5:
		state = "chase"
		return

	if not ability.is_empty() and ability_cooldown_timer <= 0.0:
		_try_use_ability(dist)

	if attack_cooldown <= 0.0:
		if target.has_method("take_damage"):
			var damage := CombatSystem.calculate_damage(attack_power, 0)
			target.take_damage(damage, get_instance_id())
		attack_cooldown = 1.0

func take_damage(amount: int, attacker_id: int) -> void:
	var actual_damage := CombatSystem.calculate_damage(amount, defense)
	current_hp -= actual_damage
	_update_hp_bar()

	EventBus.damage_dealt.emit(attacker_id, get_instance_id(), actual_damage)

	_flash(Color.WHITE, 0.1)

	if current_hp <= 0:
		_die(attacker_id)

func _die(killer_id: int) -> void:
	state = "dead"

	if has_death_split and not ability.is_empty():
		_do_split()

	EventBus.entity_died.emit(get_instance_id())
	GameManager.add_exp(exp_reward)

	if silver_per_kill > 0:
		SilverManager.add_silver(silver_per_kill, "mob_kill")
		EventBus.silver_pickup.emit(global_position, silver_per_kill)

	for drop in drop_table:
		if randf() <= drop.get("chance", 0.0):
			var item := drop.duplicate()
			item.erase("chance")

			if item.get("type", "") == "trash_loot":
				var silver_val: int = item.get("silver_value", 0) * item.get("quantity", 1)
				SilverManager.add_silver(silver_val, "trash_loot")
				EventBus.silver_pickup.emit(global_position, silver_val)
			elif item.get("type", "") == "rare_drop":
				var silver_val: int = item.get("silver_value", 0)
				SilverManager.add_silver(silver_val, "rare_drop")
				SilverManager.session_rare_drops += 1
				SilverManager.rare_drop_obtained.emit(item.get("name", "Unknown"))
				EventBus.silver_pickup.emit(global_position, silver_val)
			elif item.get("type", "") == "enhancement_mat":
				EventBus.item_picked_up.emit(item)
			else:
				EventBus.item_picked_up.emit(item)

	visible = false
	set_physics_process(false)
	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _respawn() -> void:
	current_hp = max_hp
	state = "idle"
	global_position = spawn_position
	visible = true
	set_physics_process(true)
	_update_hp_bar()
	_apply_color(MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3)))
	ability_cooldown_timer = 0.0
	is_dashing = false
	_remove_buff()

func _update_hp_bar() -> void:
	if hp_label:
		var pct := int(float(current_hp) / float(max_hp) * 100.0)
		hp_label.text = "%d%%" % pct

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

func _apply_color(color: Color) -> void:
	if mesh == null:
		return
	var mat: StandardMaterial3D = mesh.get_active_material(0)
	if mat == null:
		return
	mat = mat.duplicate()
	mat.albedo_color = color
	mesh.set_surface_override_material(0, mat)

func _flash(flash_color: Color, duration: float) -> void:
	if mesh == null:
		return
	var mat: StandardMaterial3D = mesh.get_active_material(0)
	if mat == null:
		return
	var original := mat.albedo_color
	mat.albedo_color = flash_color
	get_tree().create_timer(duration).timeout.connect(
		func(): if is_instance_valid(self) and mat: mat.albedo_color = original
	)

# ── Special Ability System ──────────────────────────────────────────

func _try_use_ability(distance_to_target: float) -> bool:
	if ability.is_empty() or not is_instance_valid(target):
		return false

	var atype: String = ability.get("type", "")
	match atype:
		"lunge_bite":
			if distance_to_target <= detection_range and distance_to_target > attack_range:
				_do_lunge_bite()
				return true
		"split":
			if ability.get("trigger", "") == "on_ability":
				if float(current_hp) / float(max_hp) <= 0.6:
					_do_split()
					ability_cooldown_timer = ability.get("cooldown", 10.0)
					return false
		"ranged":
			var ability_range: float = ability.get("range", 150.0)
			if distance_to_target <= ability_range and distance_to_target > attack_range:
				_do_ranged_attack()
				return true
		"aoe":
			var aoe_radius: float = ability.get("aoe_radius", 100.0)
			if distance_to_target <= aoe_radius:
				_do_aoe_attack()
				return true
		"drain":
			var drain_range: float = ability.get("range", 100.0)
			if distance_to_target <= drain_range:
				_do_life_drain()
				return true
		"teleport":
			if distance_to_target > attack_range * 2.0:
				_do_teleport()
				return true
		"knockback":
			if distance_to_target <= attack_range * 1.5:
				_do_knockback()
				return true
		"buff_allies":
			_do_buff_allies()
			return false
	return false

func _do_lunge_bite() -> void:
	if not is_instance_valid(target):
		return
	var dir := target.global_position - global_position
	dir.y = 0
	dash_direction = dir.normalized()
	dash_speed_override = ability.get("dash_speed", 300.0)
	dash_timer = ability.get("dash_duration", 0.2)
	is_dashing = true
	ability_cooldown_timer = ability.get("cooldown", 5.0)
	_apply_color(Color(1.0, 0.9, 0.6))

func _finish_lunge_bite() -> void:
	_apply_color(MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3)))
	if is_instance_valid(target) and _ground_distance(global_position, target.global_position) <= attack_range * 2.5:
		if target.has_method("take_damage"):
			var mult: float = ability.get("damage_mult", 1.8)
			var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
			target.take_damage(damage, get_instance_id())
			EventBus.critical_hit.emit(target.global_position, damage)
	velocity.x = 0
	velocity.z = 0
	attack_cooldown = 0.5

func _do_split() -> void:
	var split_count: int = ability.get("split_count", 2)
	var mini_id: String = ability.get("split_mob", "mini_skeleton")
	var lifetime: float = ability.get("split_lifetime", 8.0)
	var mini_stats := EnemyAbilities.get_mini_mob(mini_id)
	if mini_stats.is_empty():
		return

	var MiniEnemyScene := preload("res://scenes/enemies/mini_enemy.tscn")
	for i in split_count:
		var mini := MiniEnemyScene.instantiate()
		var angle := TAU * float(i) / float(split_count)
		var offset := Vector3(cos(angle), 0, sin(angle)) * (30.0 * WORLD_SCALE)
		mini.global_position = global_position + offset
		mini.setup_mini(mini_stats, lifetime, target)
		get_parent().add_child(mini)

func _do_ranged_attack() -> void:
	if not is_instance_valid(target):
		return
	ability_cooldown_timer = ability.get("cooldown", 4.0)
	var mult: float = ability.get("damage_mult", 1.5)
	var proj_count: int = ability.get("projectile_count", 1)
	for i in proj_count:
		if target.has_method("take_damage"):
			var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
			target.take_damage(damage, get_instance_id())
	_flash(Color(1.0, 0.6, 0.2), 0.2)

func _do_aoe_attack() -> void:
	ability_cooldown_timer = ability.get("cooldown", 10.0)
	var aoe_radius: float = ability.get("aoe_radius", 120.0)
	var mult: float = ability.get("damage_mult", 3.0)
	var players := get_tree().get_nodes_in_group("players")
	for p in players:
		if _ground_distance(global_position, p.global_position) <= aoe_radius:
			if p.has_method("take_damage"):
				var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
				p.take_damage(damage, get_instance_id())
				EventBus.critical_hit.emit(p.global_position, damage)
	_flash(Color(1.0, 0.2, 0.0), 0.3)

func _do_life_drain() -> void:
	if not is_instance_valid(target):
		return
	ability_cooldown_timer = ability.get("cooldown", 8.0)
	var mult: float = ability.get("damage_mult", 2.5)
	var heal_pct: float = ability.get("heal_percent", 0.5)
	if target.has_method("take_damage"):
		var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
		target.take_damage(damage, get_instance_id())
		var heal_amount := int(damage * heal_pct)
		current_hp = min(current_hp + heal_amount, max_hp)
		_update_hp_bar()
	_flash(Color(0.8, 0.2, 1.0), 0.3)

func _do_teleport() -> void:
	if not is_instance_valid(target):
		return
	ability_cooldown_timer = ability.get("cooldown", 6.0)
	var tp_range: float = ability.get("teleport_range", 120.0)
	var dir := target.global_position - global_position
	dir.y = 0
	dir = dir.normalized()
	var dist := _ground_distance(global_position, target.global_position)
	var tp_dist := min(dist - attack_range, tp_range)
	global_position += dir * tp_dist * WORLD_SCALE
	visible = false
	get_tree().create_timer(0.1).timeout.connect(
		func(): if is_instance_valid(self): visible = true
	)

func _do_knockback() -> void:
	if not is_instance_valid(target):
		return
	ability_cooldown_timer = ability.get("cooldown", 7.0)
	var mult: float = ability.get("damage_mult", 1.6)
	var kb_force: float = ability.get("knockback_force", 200.0)
	if target.has_method("take_damage"):
		var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
		target.take_damage(damage, get_instance_id())
	if target is CharacterBody3D:
		var push_dir := target.global_position - global_position
		push_dir.y = 0
		push_dir = push_dir.normalized()
		target.velocity.x = push_dir.x * kb_force * WORLD_SCALE
		target.velocity.z = push_dir.z * kb_force * WORLD_SCALE
	_flash(Color(1.0, 0.5, 0.0), 0.2)

func _do_buff_allies() -> void:
	ability_cooldown_timer = ability.get("cooldown", 15.0)
	var buff_radius: float = ability.get("buff_radius", 150.0)
	var speed_mult: float = ability.get("buff_speed_mult", 1.4)
	var atk_mult: float = ability.get("buff_atk_mult", 1.3)
	var duration: float = ability.get("buff_duration", 6.0)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == self:
			continue
		if e is Enemy and _ground_distance(global_position, e.global_position) <= buff_radius:
			e._apply_buff(speed_mult, atk_mult, duration)
	_flash(Color(1.0, 1.0, 0.3), 0.3)

func _apply_buff(speed_mult: float, atk_mult: float, duration: float) -> void:
	if buff_active:
		return
	buff_active = true
	buff_timer = duration
	original_attack_power = attack_power
	original_move_speed = move_speed
	attack_power = int(attack_power * atk_mult)
	move_speed = move_speed * speed_mult
	_apply_color(Color(1.0, 1.0, 0.5))

func _remove_buff() -> void:
	if not buff_active:
		return
	buff_active = false
	buff_timer = 0.0
	if original_attack_power > 0:
		attack_power = original_attack_power
	if original_move_speed > 0.0:
		move_speed = original_move_speed
	_apply_color(MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3)))
