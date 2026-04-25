extends CharacterBody3D
class_name Player
## 3D player controller — WASD ground movement on X/Z, gravity on Y,
## mouse-look on the SpringArm3D camera. BDO action-cam style.

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

var is_local: bool = false
var player_peer_id: int = -1
var facing_direction: Vector3 = Vector3.FORWARD

var skill_system: SkillSystem = null
var equipment: EquipmentSystem = null

var mana_regen_timer: float = 0.0
const MANA_REGEN_INTERVAL: float = 2.0
const MANA_REGEN_AMOUNT: int = 3

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	if is_local:
		camera.current = true
		nametag.text = GameManager.player_name
		speed = float(GameManager.player_stats["speed"]) / 30.0  # 2D px/s → m/s
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		skill_system = SkillSystem.new()
		add_child(skill_system)
		skill_system.setup(self)

		equipment = EquipmentSystem.new()
		add_child(equipment)

		var class_info := ClassData.get_class_info(GameManager.player_class)
		var class_color: Color = class_info.get("color", Color.WHITE)
		var mat: StandardMaterial3D = mesh.get_active_material(0)
		if mat:
			mat = mat.duplicate()
			mat.albedo_color = class_color
			mesh.set_surface_override_material(0, mat)
	else:
		camera.current = false

func get_skill_system() -> SkillSystem:
	return skill_system

func get_equipment_system() -> EquipmentSystem:
	return equipment

func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-70), deg_to_rad(20))
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _physics_process(delta: float) -> void:
	if not is_local:
		return

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

	move_and_slide()

	if multiplayer.has_multiplayer_peer():
		NetworkManager.sync_player_position.rpc(global_position)

	if Input.is_action_just_pressed("attack"):
		_perform_attack()

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

func _perform_attack() -> void:
	if animation_player.has_animation("attack"):
		animation_player.play("attack")

	var total_attack := GameManager.get_total_attack()
	for body in attack_area.get_overlapping_bodies():
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
	if randf() < GameManager.get_dodge_chance():
		return
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
