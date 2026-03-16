extends Node
class_name SkillSystem
## Manages skill execution, cooldowns, and mana consumption.

signal skill_used(skill_id: String)
signal skill_cooldown_updated(skill_id: String, remaining: float, total: float)
signal skill_failed(skill_id: String, reason: String)

var cooldowns: Dictionary = {} # skill_id -> remaining cooldown
var owner_node: Node2D = null

func _ready() -> void:
	pass

func setup(owner: Node2D) -> void:
	owner_node = owner

func _process(delta: float) -> void:
	# Tick cooldowns
	var finished := []
	for skill_id in cooldowns:
		cooldowns[skill_id] -= delta
		var skill := SkillData.get_skill(skill_id)
		skill_cooldown_updated.emit(skill_id, max(0.0, cooldowns[skill_id]), skill.get("cooldown", 1.0))
		if cooldowns[skill_id] <= 0.0:
			finished.append(skill_id)
	for skill_id in finished:
		cooldowns.erase(skill_id)

func can_use_skill(skill_id: String) -> bool:
	var skill := SkillData.get_skill(skill_id)
	if skill.is_empty():
		return false
	if cooldowns.has(skill_id):
		skill_failed.emit(skill_id, "On cooldown")
		return false
	if GameManager.player_stats["mp"] < skill.get("mana_cost", 0):
		skill_failed.emit(skill_id, "Not enough mana")
		return false
	return true

func use_skill(skill_id: String) -> Array[Node2D]:
	## Execute a skill. Returns array of hit enemies.
	if not can_use_skill(skill_id):
		return []

	var skill := SkillData.get_skill(skill_id)
	var hit_enemies: Array[Node2D] = []

	# Consume mana
	GameManager.player_stats["mp"] -= skill["mana_cost"]
	EventBus.player_mana_changed.emit(
		GameManager.player_id,
		GameManager.player_stats["mp"],
		GameManager.player_stats["max_mp"]
	)

	# Start cooldown
	cooldowns[skill_id] = skill["cooldown"]

	# Find targets
	if not is_instance_valid(owner_node):
		return []

	var enemies := owner_node.get_tree().get_nodes_in_group("enemies")
	var base_damage: int = int(GameManager.player_stats["attack"] * skill["damage_multiplier"])
	var skill_range: float = skill.get("range", 40.0)
	var aoe_radius: float = skill.get("aoe_radius", 0.0)
	var max_hits: int = skill.get("hits", 1)
	var hits_landed := 0

	# Sort enemies by distance
	var enemies_with_dist := []
	for e in enemies:
		if not is_instance_valid(e) or not e.visible:
			continue
		var dist: float = owner_node.global_position.distance_to(e.global_position)
		if dist <= skill_range:
			enemies_with_dist.append({"enemy": e, "dist": dist})
	enemies_with_dist.sort_custom(func(a, b): return a["dist"] < b["dist"])

	for entry in enemies_with_dist:
		if hits_landed >= max_hits:
			break
		var enemy: Node2D = entry["enemy"]

		# For AoE, check if within AoE radius of the nearest enemy or player
		if aoe_radius > 0.0:
			# AoE centered on nearest enemy for targeting
			if entry["dist"] <= skill_range:
				_deal_damage_to(enemy, base_damage, skill_id)
				hit_enemies.append(enemy)
				hits_landed += 1
		else:
			# Single target - hit nearest
			_deal_damage_to(enemy, base_damage, skill_id)
			hit_enemies.append(enemy)
			hits_landed += 1

	skill_used.emit(skill_id)
	EventBus.skill_activated.emit(skill_id, owner_node.global_position)
	return hit_enemies

func _deal_damage_to(enemy: Node2D, base_damage: int, _skill_id: String) -> void:
	var crit_result := CombatSystem.calculate_crit(
		base_damage, GameManager.player_stats.get("crit_chance", 0.1)
	)
	var final_damage: int = crit_result["damage"]
	if enemy.has_method("take_damage"):
		enemy.take_damage(final_damage, owner_node.get_instance_id())
	if crit_result["is_crit"]:
		EventBus.critical_hit.emit(enemy.global_position, final_damage)

func get_cooldown_percent(skill_id: String) -> float:
	if not cooldowns.has(skill_id):
		return 0.0
	var skill := SkillData.get_skill(skill_id)
	return cooldowns[skill_id] / skill.get("cooldown", 1.0)
