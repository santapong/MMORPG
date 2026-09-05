extends CharacterBody3D
class_name Player
## 2.5D voxel-pixel player controller — camera-relative action RPG movement.

const CombatProfiles := preload("res://scripts/combat/combat_profile.gd")

@export var speed: float = 4.5
@export var mouse_sensitivity: float = 0.005

@onready var mesh: MeshInstance3D = $Mesh
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var attack_area: Area3D = $AttackArea
@onready var nametag: Label3D = $Nametag
@onready var pixel_head: MeshInstance3D = $PixelHead
@onready var pixel_arm_left: MeshInstance3D = $PixelArmLeft
@onready var pixel_arm_right: MeshInstance3D = $PixelArmRight
@onready var pixel_leg_left: MeshInstance3D = $PixelLegLeft
@onready var pixel_leg_right: MeshInstance3D = $PixelLegRight
@onready var class_weapons: Node3D = $ClassWeapons

var is_local: bool = false
var player_peer_id: int = -1
var facing_direction: Vector3 = Vector3.FORWARD

var skill_system: SkillSystem = null
var equipment: EquipmentSystem = null

var mana_regen_timer: float = 0.0
const MANA_REGEN_INTERVAL: float = 2.0
const MANA_REGEN_AMOUNT: int = 3

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# BDO-style attack chunk state machine.
# Each attack is a chunk with three phases:
#   startup        — 0..cancel_open    : new attacks are queued, not played
#   cancel_window  — cancel_open..end  : next attack cancels current and chains
#   recovery       — after end         : back to neutral, can move freely
# Once GLTF rigs land, replace _update_animation("attack") with
# AnimationTree.travel("attack_chunk_<N>") and read durations from the
# AnimationNodeStateMachine.
const ATTACK_CHUNK_DURATION: float = 0.4
const ATTACK_CANCEL_WINDOW_OPEN: float = 0.24  # 60% — BDO research target
var _attack_phase: String = "neutral"  # neutral / startup / cancel_window
var _attack_phase_timer: float = 0.0
var _queued_attack: bool = false
var _combo_index: int = 0
const COMBO_MAX: int = 3

const MAX_STAMINA := 100.0
const STAMINA_REGEN_PER_SECOND := 24.0
var stamina := MAX_STAMINA
var _dodge_remaining := 0.0
var _invulnerable_remaining := 0.0
var _dodge_direction := Vector3.ZERO
var _combat_profile: Dictionary = {}
var _walk_phase := 0.0

func _ready() -> void:
	if is_local:
		_combat_profile = CombatProfiles.get_profile(GameManager.player_class)
		camera.current = true
		nametag.text = GameManager.player_name
		nametag.visible = false
		speed = float(GameManager.player_stats["speed"]) / 30.0  # 2D px/s → m/s
		# The camera is deliberately locked to the isometric angle. A visible cursor
		# makes click-to-attack readable and prevents accidental camera drift.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		skill_system = SkillSystem.new()
		add_child(skill_system)
		skill_system.setup(self)

		equipment = EquipmentSystem.new()
		add_child(equipment)

		_apply_pixel_class(GameManager.player_class)
	else:
		camera.current = false

func _apply_pixel_class(class_type: ClassData.ClassType) -> void:
	var class_info := ClassData.get_class_info(class_type)
	var class_color: Color = class_info.get("color", Color.WHITE)
	for part in [mesh, pixel_arm_left, pixel_arm_right]:
		var mat: StandardMaterial3D = part.get_active_material(0)
		if mat:
			mat = mat.duplicate()
			mat.albedo_color = class_color
			part.set_surface_override_material(0, mat)
	var weapon_name := ClassData.get_class_name_str(class_type)
	for weapon in class_weapons.get_children():
		weapon.visible = weapon.name == weapon_name

func get_skill_system() -> SkillSystem:
	return skill_system

func get_equipment_system() -> EquipmentSystem:
	return equipment

func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_local:
		return

	_tick_combat_mobility(delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	# Move relative to camera yaw so W is "forward from camera".
	var basis_yaw := Basis(Vector3.UP, camera_pivot.rotation.y)
	var move_vec: Vector3 = basis_yaw * Vector3(input_dir.x, 0.0, input_dir.y)

	var move_speed := float(GameManager.get_total_speed()) / 30.0
	if _dodge_remaining > 0.0:
		velocity.x = _dodge_direction.x * float(_combat_profile["dodge_speed"])
		velocity.z = _dodge_direction.z * float(_combat_profile["dodge_speed"])
	else:
		velocity.x = move_vec.x * move_speed
		velocity.z = move_vec.z * move_speed

	if move_vec.length() > 0.01:
		facing_direction = move_vec.normalized()
		# Face movement direction (smooth turn).
		var target_yaw := atan2(facing_direction.x, facing_direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 12.0 * delta)
		_update_animation("walk")
	else:
		_update_animation("idle")
	_animate_pixel_walk(move_vec.length() > 0.01, delta)

	move_and_slide()

	if multiplayer.has_multiplayer_peer():
		NetworkManager.sync_player_position.rpc(global_position)

	_tick_attack_phase(delta)

	if Input.is_action_just_pressed("attack"):
		_on_attack_input()
	if Input.is_action_just_pressed("dodge"):
		_start_dodge(move_vec)

	if Input.is_action_just_pressed("interact"):
		_try_interact()

	mana_regen_timer += delta
	if mana_regen_timer >= MANA_REGEN_INTERVAL:
		mana_regen_timer = 0.0
		_regen_mana()

func _update_animation(action: String) -> void:
	# Placeholder — animation graph lands in step 10 with the GLTF rig.
	if animation_player.has_animation(action):
		animation_player.play(action)

func _animate_pixel_walk(is_moving: bool, delta: float) -> void:
	if is_moving:
		_walk_phase += delta * 11.0
		var swing := sin(_walk_phase) * 0.38
		pixel_arm_left.rotation.x = swing
		pixel_arm_right.rotation.x = -swing
		pixel_leg_left.rotation.x = -swing * 0.65
		pixel_leg_right.rotation.x = swing * 0.65
		pixel_head.position.y = 1.84 + absf(sin(_walk_phase * 2.0)) * 0.035
	else:
		pixel_arm_left.rotation.x = lerpf(pixel_arm_left.rotation.x, 0.0, delta * 12.0)
		pixel_arm_right.rotation.x = lerpf(pixel_arm_right.rotation.x, 0.0, delta * 12.0)
		pixel_leg_left.rotation.x = lerpf(pixel_leg_left.rotation.x, 0.0, delta * 12.0)
		pixel_leg_right.rotation.x = lerpf(pixel_leg_right.rotation.x, 0.0, delta * 12.0)
		pixel_head.position.y = lerpf(pixel_head.position.y, 1.84, delta * 12.0)

func _on_attack_input() -> void:
	## Public entry point for the attack action — gated by the chunk machine.
	match _attack_phase:
		"neutral":
			_start_attack_chunk(0)
		"startup":
			# Buffered: fires automatically when cancel window opens.
			_queued_attack = true
		"cancel_window":
			# Chain immediately into the next chunk.
			_start_attack_chunk(_combo_index + 1)

func _start_attack_chunk(combo_index: int) -> void:
	_combo_index = wrapi(combo_index, 0, COMBO_MAX)
	_attack_phase = "startup"
	_attack_phase_timer = 0.0
	_queued_attack = false
	_perform_attack()

func _tick_attack_phase(delta: float) -> void:
	if _attack_phase == "neutral":
		return
	_attack_phase_timer += delta
	if _attack_phase == "startup" and _attack_phase_timer >= ATTACK_CANCEL_WINDOW_OPEN:
		_attack_phase = "cancel_window"
		# Auto-resolve a buffered input as soon as the cancel opens.
		if _queued_attack:
			_start_attack_chunk(_combo_index + 1)
			return
	if _attack_phase_timer >= ATTACK_CHUNK_DURATION:
		_attack_phase = "neutral"
		_attack_phase_timer = 0.0
		_combo_index = 0

func _perform_attack() -> void:
	# Once GLTF rigs land, replace this with
	#   anim_tree.travel("attack_chunk_%d" % _combo_index)
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
	var active_weapon: Node3D = class_weapons.get_child(GameManager.player_class)
	if active_weapon:
		active_weapon.rotation.z = -0.7
		var swing_tween := create_tween()
		swing_tween.tween_property(active_weapon, "rotation:z", 0.35, 0.1)
		swing_tween.tween_property(active_weapon, "rotation:z", 0.0, 0.12)

	var total_attack := int(
		GameManager.get_total_attack()
		* CombatProfiles.combo_multiplier(GameManager.player_class, _combo_index)
	)
	for body in _basic_attack_targets():
		if body.is_in_group("enemies"):
			var crit_result := CombatSystem.calculate_crit(
				total_attack, GameManager.get_total_crit_chance(), GameManager.get_total_crit_damage()
			)
			var damage: int = crit_result["damage"]
			if body.has_method("take_damage"):
				body.take_damage(damage, player_peer_id)
			if crit_result["is_crit"]:
				EventBus.critical_hit.emit(body.global_position, damage)
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
	if _invulnerable_remaining > 0.0:
		return
	if randf() < GameManager.get_dodge_chance():
		return
	if _dodge_remaining > 0.0:
		amount = ceili(float(amount) * (1.0 - float(_combat_profile.get("damage_reduction", 0.0))))
	var total_def := GameManager.get_total_defense()
	var actual_damage: int = max(1, amount - total_def)
	GameManager.player_stats["hp"] -= actual_damage
	EventBus.player_health_changed.emit(
		player_peer_id,
		GameManager.player_stats["hp"],
		GameManager.player_stats["max_hp"]
	)
	_flash_damage()
	if GameManager.player_stats["hp"] <= 0:
		_die()

func grant_invulnerability(seconds: float) -> void:
	_invulnerable_remaining = maxf(_invulnerable_remaining, seconds)

func _start_dodge(move_vec: Vector3) -> bool:
	if _dodge_remaining > 0.0:
		return false
	var cost := float(_combat_profile.get("dodge_cost", 35.0))
	if stamina < cost:
		return false
	stamina -= cost
	_dodge_remaining = float(_combat_profile.get("dodge_duration", 0.25))
	_invulnerable_remaining = float(_combat_profile.get("invulnerable", 0.15))
	_dodge_direction = move_vec.normalized() if move_vec.length() > 0.01 else facing_direction
	EventBus.player_stamina_changed.emit(player_peer_id, stamina, MAX_STAMINA)
	EventBus.dodge_started.emit(player_peer_id, _dodge_remaining)
	return true

func _tick_combat_mobility(delta: float) -> void:
	_dodge_remaining = maxf(0.0, _dodge_remaining - delta)
	_invulnerable_remaining = maxf(0.0, _invulnerable_remaining - delta)
	if _dodge_remaining <= 0.0 and stamina < MAX_STAMINA:
		var previous := stamina
		stamina = minf(MAX_STAMINA, stamina + STAMINA_REGEN_PER_SECOND * delta)
		if floori(previous) != floori(stamina):
			EventBus.player_stamina_changed.emit(player_peer_id, stamina, MAX_STAMINA)

func _basic_attack_targets() -> Array[Node3D]:
	var candidates: Array[Dictionary] = []
	var attack_range := float(_combat_profile.get("basic_range", 1.9))
	var arc_cos := float(_combat_profile.get("basic_arc_cos", -0.2))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.visible:
			continue
		var offset: Vector3 = enemy.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance <= attack_range and distance > 0.001 and facing_direction.dot(offset / distance) >= arc_cos:
			candidates.append({"enemy": enemy, "distance": distance})
	candidates.sort_custom(func(a, b): return a["distance"] < b["distance"])
	var result: Array[Node3D] = []
	for entry in candidates.slice(0, int(_combat_profile.get("max_targets", 1))):
		result.append(entry["enemy"])
	return result

func _flash_damage() -> void:
	var mat: StandardMaterial3D = mesh.get_active_material(0)
	if mat == null:
		return
	var original := mat.albedo_color
	mat.albedo_color = Color.RED
	get_tree().create_timer(0.15).timeout.connect(
		func(): mat.albedo_color = original
	)

func _die() -> void:
	EventBus.player_died.emit(player_peer_id)
	visible = false
	set_physics_process(false)
	if not EventBus.player_respawned.is_connected(_on_respawned):
		EventBus.player_respawned.connect(_on_respawned, CONNECT_ONE_SHOT)

func _on_respawned(_player_id: int) -> void:
	global_position = Vector3(0, 1, 0)
	visible = true
	set_physics_process(true)
	EventBus.player_health_changed.emit(
		player_peer_id,
		GameManager.player_stats["hp"],
		GameManager.player_stats["max_hp"]
	)

func _regen_mana() -> void:
	var total_max_mp := GameManager.get_total_max_mp()
	if GameManager.player_stats["mp"] < total_max_mp:
		var regen := MANA_REGEN_AMOUNT + GameManager.get_mana_regen_bonus()
		GameManager.player_stats["mp"] = min(
			GameManager.player_stats["mp"] + regen,
			total_max_mp
		)
		EventBus.player_mana_changed.emit(
			player_peer_id,
			GameManager.player_stats["mp"],
			GameManager.player_stats["max_mp"]
		)
