extends Node
class_name SkillSystem
## Manages skill execution, cooldowns, and mana consumption.
## Now integrates with skill tree levels for scaling damage/cooldowns/costs.

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
		var skill := _get_effective_skill(skill_id)
		skill_cooldown_updated.emit(skill_id, max(0.0, cooldowns[skill_id]), skill.get("cooldown", 1.0))
		if cooldowns[skill_id] <= 0.0:
			finished.append(skill_id)
	for skill_id in finished:
		cooldowns.erase(skill_id)

func can_use_skill(skill_id: String) -> bool:
	var skill := _get_effective_skill(skill_id)
	if skill.is_empty():
		return false
	# Must be unlocked in skill tree (or be a base skill at level 0 = use base stats)
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

	var skill := _get_effective_skill(skill_id)
	var hit_enemies: Array[Node2D] = []

	# Check if this is a buff/passive skill
	if skill.get("buff_type", "") != "" and skill.get("damage_multiplier", 0.0) == 0.0:
		_apply_skill_buff(skill_id, skill)
		return []

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
	var base_attack := GameManager.get_total_attack()
	var base_damage: int = int(base_attack * skill["damage_multiplier"])

	# Apply spell damage multiplier for mage skills
	if skill.get("class", -1) == ClassData.ClassType.MAGE:
		base_damage = int(base_damage * GameManager.get_spell_damage_mult())

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

		if aoe_radius > 0.0:
			if entry["dist"] <= skill_range:
				_deal_damage_to(enemy, base_damage, skill_id)
				hit_enemies.append(enemy)
				hits_landed += 1
		else:
			_deal_damage_to(enemy, base_damage, skill_id)
			hit_enemies.append(enemy)
			hits_landed += 1

	skill_used.emit(skill_id)
	EventBus.skill_activated.emit(skill_id, owner_node.global_position)
	return hit_enemies

func _apply_skill_buff(skill_id: String, skill: Dictionary) -> void:
	## Apply a buff skill (consumes mana, starts cooldown, applies buff)
	GameManager.player_stats["mp"] -= skill["mana_cost"]
	EventBus.player_mana_changed.emit(
		GameManager.player_id,
		GameManager.player_stats["mp"],
		GameManager.player_stats["max_mp"]
	)
	cooldowns[skill_id] = skill["cooldown"]

	var buff_type: String = skill.get("buff_type", "")
	var buff_value: float = skill.get("buff_value", 0.0)
	var buff_duration: float = skill.get("buff_duration", 10.0)

	GameManager.apply_buff(buff_type, buff_value, buff_duration)

	skill_used.emit(skill_id)
	EventBus.skill_activated.emit(skill_id, owner_node.global_position if is_instance_valid(owner_node) else Vector2.ZERO)

func _deal_damage_to(enemy: Node2D, base_damage: int, _skill_id: String) -> void:
	var crit_result := CombatSystem.calculate_crit(
		base_damage,
		GameManager.get_total_crit_chance(),
		GameManager.get_total_crit_damage()
	)
	var final_damage: int = crit_result["damage"]
	if enemy.has_method("take_damage"):
		enemy.take_damage(final_damage, owner_node.get_instance_id())
	if crit_result["is_crit"]:
		EventBus.critical_hit.emit(enemy.global_position, final_damage)

func get_cooldown_percent(skill_id: String) -> float:
	if not cooldowns.has(skill_id):
		return 0.0
	var skill := _get_effective_skill(skill_id)
	return cooldowns[skill_id] / skill.get("cooldown", 1.0)

func _get_effective_skill(skill_id: String) -> Dictionary:
	## Get the skill with skill-tree level bonuses applied.
	var skill_level: int = GameManager.get_skill_level(skill_id)
	if skill_level > 0:
		return SkillTreeData.get_skill_at_level(GameManager.player_class, skill_id, skill_level)
	# Fallback to base skill data
	return SkillData.get_skill(skill_id)

func get_all_usable_skills() -> Array[String]:
	## Get all skills the player has unlocked (skill level > 0) plus base class skills.
	var result: Array[String] = []
	var class_info := ClassData.get_class_info(GameManager.player_class)
	var base_skills: Array = class_info.get("skills", [])

	# Add base class skills (always available at base level)
	for skill_id in base_skills:
		result.append(skill_id)

	# Add skill-tree unlocked skills not already in base
	for skill_id in GameManager.skill_levels:
		if GameManager.skill_levels[skill_id] > 0 and skill_id not in result:
			result.append(skill_id)

	return result
