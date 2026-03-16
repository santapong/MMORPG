extends CharacterBody2D
class_name Player
## Main player controller — handles movement, skills, and combat. BDO-style grinding.

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

# Skill system
var skill_system: SkillSystem = null

# Equipment system
var equipment: EquipmentSystem = null

# Mana regen
var mana_regen_timer: float = 0.0
const MANA_REGEN_INTERVAL: float = 2.0
const MANA_REGEN_AMOUNT: int = 3

func _ready() -> void:
	if is_local:
		camera.enabled = true
		nametag.text = GameManager.player_name
		speed = GameManager.player_stats["speed"]

		# Initialize skill system
		skill_system = SkillSystem.new()
		add_child(skill_system)
		skill_system.setup(self)

		# Initialize equipment system
		equipment = EquipmentSystem.new()
		add_child(equipment)

		# Tint sprite based on class
		var class_info := ClassData.get_class_info(GameManager.player_class)
		sprite.modulate = class_info.get("color", Color.WHITE)
	else:
		camera.enabled = false

func get_skill_system() -> SkillSystem:
	return skill_system

func get_equipment_system() -> EquipmentSystem:
	return equipment

func _physics_process(delta: float) -> void:
	if not is_local:
		return

	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	input_dir = input_dir.normalized()

	velocity = input_dir * GameManager.get_total_speed()

	if input_dir != Vector2.ZERO:
		facing_direction = input_dir
		_update_animation("walk")
	else:
		_update_animation("idle")

	move_and_slide()

	# Sync position to other players
	if multiplayer.has_multiplayer_peer():
		NetworkManager.sync_player_position.rpc(global_position)

	# Attack input (basic attack)
	if Input.is_action_just_pressed("attack"):
		_perform_attack()

	# Interact input
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	# Mana regen
	mana_regen_timer += delta
	if mana_regen_timer >= MANA_REGEN_INTERVAL:
		mana_regen_timer = 0.0
		_regen_mana()

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
	# Dodge check from passive skills
	if randf() < GameManager.get_dodge_chance():
		return # Dodged!
	var total_def := GameManager.get_total_defense()
	var actual_damage: int = max(1, amount - total_def)
	GameManager.player_stats["hp"] -= actual_damage
	EventBus.player_health_changed.emit(
		player_peer_id,
		GameManager.player_stats["hp"],
		GameManager.player_stats["max_hp"]
	)
	# Flash red
	sprite.modulate = Color.RED
	var class_color: Color = ClassData.get_class_info(GameManager.player_class).get("color", Color.WHITE)
	get_tree().create_timer(0.15).timeout.connect(func(): sprite.modulate = class_color)
	if GameManager.player_stats["hp"] <= 0:
		_die()

func _die() -> void:
	EventBus.player_died.emit(player_peer_id)
	visible = false
	set_physics_process(false)
	EventBus.player_respawned.connect(_on_respawned, CONNECT_ONE_SHOT)

func _on_respawned(_player_id: int) -> void:
	global_position = Vector2(300, 300) # Spawn point in starter village
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
