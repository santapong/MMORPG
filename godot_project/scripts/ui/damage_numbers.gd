extends Node2D
## Floating damage numbers — BDO-style combat feedback.

func _ready() -> void:
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.critical_hit.connect(_on_critical_hit)
	EventBus.silver_pickup.connect(_on_silver_pickup)

func spawn_number(pos: Vector2, text: String, color: Color, scale_val: float = 1.0) -> void:
	var label := Label.new()
	label.text = text
	label.global_position = pos + Vector2(randf_range(-10, 10), -20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", int(14 * scale_val))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	add_child(label)

	# Float up and fade out
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

func _on_damage_dealt(_attacker_id: int, _target_id: int, amount: int) -> void:
	# Find target position from the entity node
	var entities := get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("players")
	for entity in entities:
		if entity.get_instance_id() == _target_id:
			spawn_number(entity.global_position, str(amount), Color(1, 1, 0.3))
			return

func _on_critical_hit(pos: Vector2, amount: int) -> void:
	spawn_number(pos, "CRIT " + str(amount), Color(1, 0.3, 0.1), 1.5)

func _on_silver_pickup(pos: Vector2, amount: int) -> void:
	spawn_number(pos, "+" + SilverManager.format_silver(amount), Color(1, 0.85, 0.3), 0.8)
