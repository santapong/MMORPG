extends Node
class_name CombatSystem
## Handles damage calculation and combat logic.

static func calculate_damage(attacker_atk: int, defender_def: int) -> int:
	var base_damage := max(1, attacker_atk - defender_def)
	# Add some variance: +/- 20%
	var variance := randf_range(0.8, 1.2)
	return int(base_damage * variance)

static func calculate_crit(base_damage: int, crit_chance: float = 0.1, crit_multiplier: float = 2.0) -> Dictionary:
	var is_crit := randf() < crit_chance
	var final_damage := base_damage
	if is_crit:
		final_damage = int(base_damage * crit_multiplier)
	return {"damage": final_damage, "is_crit": is_crit}
