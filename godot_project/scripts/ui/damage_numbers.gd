extends Node3D
## Floating 3D damage numbers — billboarded Label3D nodes that float and fade.
## Spawned in world space and tweened up over the entity that took damage.

func _ready() -> void:
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.critical_hit.connect(_on_critical_hit)
	EventBus.silver_pickup.connect(_on_silver_pickup)

func spawn_number(pos: Vector3, text: String, color: Color, scale_val: float = 1.0) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	label.font_size = int(28 * scale_val)
	label.outline_size = 6
	label.modulate = color
	label.no_depth_test = true
	var jitter := Vector3(randf_range(-0.2, 0.2), 1.4, randf_range(-0.2, 0.2))
	label.global_position = pos + jitter
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y + 1.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

func _on_damage_dealt(_attacker_id: int, target_id: int, amount: int) -> void:
	var entities := get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("players")
	for entity in entities:
		if entity.get_instance_id() == target_id:
			spawn_number(entity.global_position, str(amount), Color(1, 1, 0.3))
			return

func _on_critical_hit(pos: Vector3, amount: int) -> void:
	spawn_number(pos, "CRIT " + str(amount), Color(1, 0.3, 0.1), 1.5)

func _on_silver_pickup(pos: Vector3, amount: int) -> void:
	spawn_number(pos, "+" + SilverManager.format_silver(amount), Color(1, 0.85, 0.3), 0.8)
