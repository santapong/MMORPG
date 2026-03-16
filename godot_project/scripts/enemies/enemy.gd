extends CharacterBody2D
class_name Enemy
## Enemy with AI, health, drops, and zone-based stats. BDO-style grinding mob.

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
var spawn_position: Vector2 = Vector2.ZERO
var respawn_time: float = 8.0

# Mob identity for drop tables
var mob_id: String = "slime"

# Special ability system
var ability: Dictionary = {}
var ability_cooldown_timer: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_speed_override: float = 0.0
var has_death_split: bool = false
var buff_active: bool = false
var buff_timer: float = 0.0
var original_attack_power: int = 0
var original_move_speed: float = 0.0

# Possible item drops: [{"id": "potion", "chance": 0.5}, ...]
@export var drop_table: Array[Dictionary] = []

# Silver value (BDO trash loot)
var silver_per_kill: int = 0

# Mob color tints by type
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
	spawn_position = global_position
	add_to_group("enemies")
	nametag.text = enemy_name
	_update_hp_bar()
	# Apply mob color
	sprite.modulate = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
	# Load special ability
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

	# Load drop table from ZoneData
	var drops := ZoneData.get_mob_drops(id)
	drop_table.clear()
	for drop in drops:
		drop_table.append(drop)

	current_hp = max_hp
	sprite.modulate = MOB_COLORS.get(id, Color(1, 0.3, 0.3))
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

	# Handle active dash (lunge bite / fire dash)
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed_override
		move_and_slide()
		if dash_timer <= 0.0:
			is_dashing = false
			_finish_lunge_bite()
		return

	# Handle buff expiry
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

func _do_idle(delta: float) -> void:
	# Wander randomly near spawn
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		wander_timer = randf_range(1.0, 3.0)

	# Stay near spawn point
	if global_position.distance_to(spawn_position) > 150.0:
		wander_direction = (spawn_position - global_position).normalized()

	velocity = wander_direction * move_speed * 0.3

	# Check for nearby players
	target = _find_nearest_player()
	if target and global_position.distance_to(target.global_position) <= detection_range:
		state = "chase"

func _do_chase(_delta: float) -> void:
	if not is_instance_valid(target):
		state = "idle"
		return

	var distance := global_position.distance_to(target.global_position)

	if distance > detection_range * 1.5:
		target = null
		state = "idle"
		return

	# Try special ability while chasing
	if not ability.is_empty() and ability_cooldown_timer <= 0.0:
		if _try_use_ability(distance):
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

	# Try special ability during attack phase
	if not ability.is_empty() and ability_cooldown_timer <= 0.0:
		_try_use_ability(distance)

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

	# Flash white
	sprite.modulate = Color.WHITE
	var original_color: Color = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
	get_tree().create_timer(0.1).timeout.connect(func(): sprite.modulate = original_color)

	if current_hp <= 0:
		_die(attacker_id)

func _die(killer_id: int) -> void:
	state = "dead"

	# Death-triggered split (e.g. Big Slime splits into mini slimes)
	if has_death_split and not ability.is_empty():
		_do_split()

	EventBus.entity_died.emit(get_instance_id())
	GameManager.add_exp(exp_reward)

	# Award silver for kill
	if silver_per_kill > 0:
		SilverManager.add_silver(silver_per_kill, "mob_kill")
		EventBus.silver_pickup.emit(global_position, silver_per_kill)

	# Drop items from drop table
	for drop in drop_table:
		if randf() <= drop.get("chance", 0.0):
			var item := drop.duplicate()
			item.erase("chance") # Remove chance from the item data

			# Handle trash loot — auto-sell for silver
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

	# Respawn after delay
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
	sprite.modulate = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
	# Reset ability state
	ability_cooldown_timer = 0.0
	is_dashing = false
	_remove_buff()

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

# ── Special Ability System ──────────────────────────────────────────

func _try_use_ability(distance_to_target: float) -> bool:
	if ability.is_empty() or not is_instance_valid(target):
		return false

	var atype: String = ability.get("type", "")
	match atype:
		"lunge_bite":
			# Dash toward target when within reasonable range
			if distance_to_target <= detection_range and distance_to_target > attack_range:
				_do_lunge_bite()
				return true
		"split":
			if ability.get("trigger", "") == "on_ability":
				# Bone Golem splits mid-fight when HP below 60%
				if float(current_hp) / float(max_hp) <= 0.6:
					_do_split()
					ability_cooldown_timer = ability.get("cooldown", 10.0)
					return false # Continue normal behavior after split
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
			# Blink closer to target when far away
			if distance_to_target > attack_range * 2.0:
				_do_teleport()
				return true
		"knockback":
			if distance_to_target <= attack_range * 1.5:
				_do_knockback()
				return true
		"buff_allies":
			_do_buff_allies()
			return false # Don't interrupt combat flow
	return false

func _do_lunge_bite() -> void:
	## Wolf/Hellhound dash — lunge toward the target at high speed, then bite.
	if not is_instance_valid(target):
		return
	dash_direction = (target.global_position - global_position).normalized()
	dash_speed_override = ability.get("dash_speed", 300.0)
	dash_timer = ability.get("dash_duration", 0.2)
	is_dashing = true
	ability_cooldown_timer = ability.get("cooldown", 5.0)
	# Visual: tint slightly brighter during dash
	sprite.modulate = Color(1.0, 0.9, 0.6)

func _finish_lunge_bite() -> void:
	## Called when the dash ends — deal boosted bite damage.
	sprite.modulate = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range * 2.5:
		if target.has_method("take_damage"):
			var mult: float = ability.get("damage_mult", 1.8)
			var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
			target.take_damage(damage, get_instance_id())
			EventBus.critical_hit.emit(target.global_position, damage)
	velocity = Vector2.ZERO
	attack_cooldown = 0.5 # Short cooldown after bite

func _do_split() -> void:
	## Spawn mini enemies around this enemy's position.
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
		var offset := Vector2(cos(angle), sin(angle)) * 30.0
		mini.global_position = global_position + offset
		mini.setup_mini(mini_stats, lifetime, target)
		get_parent().add_child(mini)

func _do_ranged_attack() -> void:
	## Instant ranged damage (skeleton bone toss, bandit arrows).
	if not is_instance_valid(target):
		return
	ability_cooldown_timer = ability.get("cooldown", 4.0)
	var mult: float = ability.get("damage_mult", 1.5)
	var proj_count: int = ability.get("projectile_count", 1)
	for i in proj_count:
		if target.has_method("take_damage"):
			var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
			target.take_damage(damage, get_instance_id())
	# Flash sprite to indicate ranged attack
	sprite.modulate = Color(1.0, 0.6, 0.2)
	var original_color: Color = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
	get_tree().create_timer(0.2).timeout.connect(func(): sprite.modulate = original_color)

func _do_aoe_attack() -> void:
	## Area damage hitting all players in radius (Demon Lord hellfire).
	ability_cooldown_timer = ability.get("cooldown", 10.0)
	var aoe_radius: float = ability.get("aoe_radius", 120.0)
	var mult: float = ability.get("damage_mult", 3.0)
	var players := get_tree().get_nodes_in_group("players")
	for p in players:
		if global_position.distance_to(p.global_position) <= aoe_radius:
			if p.has_method("take_damage"):
				var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
				p.take_damage(damage, get_instance_id())
				EventBus.critical_hit.emit(p.global_position, damage)
	# Visual flash for AoE
	sprite.modulate = Color(1.0, 0.2, 0.0)
	var original_color: Color = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
	get_tree().create_timer(0.3).timeout.connect(func(): sprite.modulate = original_color)

func _do_life_drain() -> void:
	## Lich drains life — damages target and heals self.
	if not is_instance_valid(target):
		return
	ability_cooldown_timer = ability.get("cooldown", 8.0)
	var mult: float = ability.get("damage_mult", 2.5)
	var heal_pct: float = ability.get("heal_percent", 0.5)
	if target.has_method("take_damage"):
		var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
		target.take_damage(damage, get_instance_id())
		# Heal self
		var heal_amount := int(damage * heal_pct)
		current_hp = min(current_hp + heal_amount, max_hp)
		_update_hp_bar()
	# Purple flash for drain
	sprite.modulate = Color(0.8, 0.2, 1.0)
	var original_color: Color = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
	get_tree().create_timer(0.3).timeout.connect(func(): sprite.modulate = original_color)

func _do_teleport() -> void:
	## Imp blinks closer to target.
	if not is_instance_valid(target):
		return
	ability_cooldown_timer = ability.get("cooldown", 6.0)
	var tp_range: float = ability.get("teleport_range", 120.0)
	var dir := (target.global_position - global_position).normalized()
	var dist := global_position.distance_to(target.global_position)
	# Teleport to within attack range of target
	var tp_dist := min(dist - attack_range, tp_range)
	global_position += dir * tp_dist
	# Visual: brief flicker
	visible = false
	get_tree().create_timer(0.1).timeout.connect(func(): visible = true)

func _do_knockback() -> void:
	## Demon Soldier shield bash — damage + push player back.
	if not is_instance_valid(target):
		return
	ability_cooldown_timer = ability.get("cooldown", 7.0)
	var mult: float = ability.get("damage_mult", 1.6)
	var kb_force: float = ability.get("knockback_force", 200.0)
	if target.has_method("take_damage"):
		var damage := CombatSystem.calculate_damage(int(attack_power * mult), 0)
		target.take_damage(damage, get_instance_id())
	# Push target away
	if target is CharacterBody2D:
		var push_dir := (target.global_position - global_position).normalized()
		target.velocity = push_dir * kb_force
	# Visual flash
	sprite.modulate = Color(1.0, 0.5, 0.0)
	var original_color: Color = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
	get_tree().create_timer(0.2).timeout.connect(func(): sprite.modulate = original_color)

func _do_buff_allies() -> void:
	## Bandit Chief rallies nearby bandits — boost speed and attack.
	ability_cooldown_timer = ability.get("cooldown", 15.0)
	var buff_radius: float = ability.get("buff_radius", 150.0)
	var speed_mult: float = ability.get("buff_speed_mult", 1.4)
	var atk_mult: float = ability.get("buff_atk_mult", 1.3)
	var duration: float = ability.get("buff_duration", 6.0)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == self:
			continue
		if e is Enemy and global_position.distance_to(e.global_position) <= buff_radius:
			e._apply_buff(speed_mult, atk_mult, duration)
	# Self flash
	sprite.modulate = Color(1.0, 1.0, 0.3)
	var original_color: Color = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
	get_tree().create_timer(0.3).timeout.connect(func(): sprite.modulate = original_color)

func _apply_buff(speed_mult: float, atk_mult: float, duration: float) -> void:
	if buff_active:
		return # Don't stack buffs
	buff_active = true
	buff_timer = duration
	original_attack_power = attack_power
	original_move_speed = move_speed
	attack_power = int(attack_power * atk_mult)
	move_speed = move_speed * speed_mult
	# Yellow tint while buffed
	sprite.modulate = Color(1.0, 1.0, 0.5)

func _remove_buff() -> void:
	if not buff_active:
		return
	buff_active = false
	buff_timer = 0.0
	if original_attack_power > 0:
		attack_power = original_attack_power
	if original_move_speed > 0.0:
		move_speed = original_move_speed
	sprite.modulate = MOB_COLORS.get(mob_id, Color(1, 0.3, 0.3))
