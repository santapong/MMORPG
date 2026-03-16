extends Node
## Manages global game state, player data, class selection, and scene transitions.

# Player info
var player_name: String = "Player"
var player_id: int = -1
var player_class: ClassData.ClassType = ClassData.ClassType.WARRIOR

# Player stats
var player_stats: Dictionary = {
	"level": 1,
	"hp": 100,
	"max_hp": 100,
	"mp": 50,
	"max_mp": 50,
	"attack": 10,
	"defense": 5,
	"speed": 150.0,
	"exp": 0,
	"exp_to_level": 100,
	"crit_chance": 0.1,
	"crit_damage": 2.0,
	# Equipment stat bonuses
	"equip_attack": 0,
	"equip_defense": 0,
	"equip_max_hp": 0,
	"equip_max_mp": 0,
	"equip_crit_chance": 0.0,
	"equip_speed": 0.0,
	# Skill tree passive bonuses
	"passive_attack_mult": 0.0,
	"passive_defense_mult": 0.0,
	"passive_max_hp_mult": 0.0,
	"passive_spell_damage_mult": 0.0,
	"passive_crit_chance": 0.0,
	"passive_crit_damage": 0.0,
	"passive_speed_mult": 0.0,
	"passive_dodge": 0.0,
	"passive_mana_regen": 0,
}

# Skill tree state
var skill_points: int = 0
var total_skill_points_earned: int = 0
var skill_levels: Dictionary = {} # skill_id -> level (1-5)

# Game state
var is_in_game: bool = false
var current_map: String = ""

# Active buffs from skills
var active_buffs: Array[Dictionary] = [] # [{type, value, remaining_time}]

func _ready() -> void:
	EventBus.player_level_up.connect(_on_player_level_up)
	EventBus.player_died.connect(_on_player_died)

func _process(delta: float) -> void:
	# Tick active buffs
	var expired := []
	for i in active_buffs.size():
		active_buffs[i]["remaining_time"] -= delta
		if active_buffs[i]["remaining_time"] <= 0.0:
			expired.append(i)
	# Remove expired buffs in reverse order
	for i in range(expired.size() - 1, -1, -1):
		active_buffs.remove_at(expired[i])

func select_class(class_type: ClassData.ClassType) -> void:
	player_class = class_type
	var info := ClassData.get_class_info(class_type)
	player_stats["hp"] = info["base_hp"]
	player_stats["max_hp"] = info["base_hp"]
	player_stats["mp"] = info["base_mp"]
	player_stats["max_mp"] = info["base_mp"]
	player_stats["attack"] = info["base_attack"]
	player_stats["defense"] = info["base_defense"]
	player_stats["speed"] = info["base_speed"]
	player_stats["crit_chance"] = info["crit_chance"]
	player_stats["crit_damage"] = 2.0
	player_stats["level"] = 1
	player_stats["exp"] = 0
	player_stats["exp_to_level"] = 100
	player_stats["equip_attack"] = 0
	player_stats["equip_defense"] = 0
	player_stats["equip_max_hp"] = 0
	player_stats["equip_max_mp"] = 0
	player_stats["equip_crit_chance"] = 0.0
	player_stats["equip_speed"] = 0.0
	# Reset skill tree
	skill_points = 0
	total_skill_points_earned = 0
	skill_levels = {}
	_reset_passives()
	EventBus.class_selected.emit(class_type)

func get_total_attack() -> int:
	var base: int = player_stats["attack"] + player_stats.get("equip_attack", 0)
	var passive_mult: float = 1.0 + player_stats.get("passive_attack_mult", 0.0)
	# Check active attack buffs
	var buff_mult := 1.0
	for buff in active_buffs:
		if buff["type"] == "attack_boost":
			buff_mult += buff["value"]
		elif buff["type"] == "attack_speed_boost":
			buff_mult += buff["value"]
	return int(base * passive_mult * buff_mult)

func get_total_defense() -> int:
	var base: int = player_stats["defense"] + player_stats.get("equip_defense", 0)
	var passive_mult: float = 1.0 + player_stats.get("passive_defense_mult", 0.0)
	# Check active defense buffs
	var buff_mult := 1.0
	for buff in active_buffs:
		if buff["type"] == "defense_boost":
			buff_mult += buff["value"]
	return int(base * passive_mult * buff_mult)

func get_total_max_hp() -> int:
	var base: int = player_stats["max_hp"] + player_stats.get("equip_max_hp", 0)
	var passive_mult: float = 1.0 + player_stats.get("passive_max_hp_mult", 0.0)
	return int(base * passive_mult)

func get_total_max_mp() -> int:
	return player_stats["max_mp"] + player_stats.get("equip_max_mp", 0)

func get_total_crit_chance() -> float:
	return player_stats["crit_chance"] + player_stats.get("equip_crit_chance", 0.0) + player_stats.get("passive_crit_chance", 0.0)

func get_total_crit_damage() -> float:
	return player_stats.get("crit_damage", 2.0) + player_stats.get("passive_crit_damage", 0.0)

func get_total_speed() -> float:
	var base: float = player_stats["speed"] + player_stats.get("equip_speed", 0.0)
	var passive_mult: float = 1.0 + player_stats.get("passive_speed_mult", 0.0)
	return base * passive_mult

func get_spell_damage_mult() -> float:
	return 1.0 + player_stats.get("passive_spell_damage_mult", 0.0)

func get_dodge_chance() -> float:
	return player_stats.get("passive_dodge", 0.0)

func get_mana_regen_bonus() -> int:
	return player_stats.get("passive_mana_regen", 0)

# === Skill Tree ===

func upgrade_skill(skill_id: String) -> bool:
	var check := SkillTreeData.can_upgrade_skill(
		player_class, skill_id, skill_levels,
		player_stats["level"], skill_points
	)
	if not check["can_upgrade"]:
		return false

	skill_points -= 1
	var current_level: int = skill_levels.get(skill_id, 0)
	skill_levels[skill_id] = current_level + 1

	# Recalculate passives
	_apply_all_passives()

	EventBus.skill_upgraded.emit(skill_id, skill_levels[skill_id])
	if current_level == 0:
		EventBus.skill_unlocked.emit(skill_id)
	EventBus.skill_points_changed.emit(skill_points, total_skill_points_earned)
	return true

func get_skill_level(skill_id: String) -> int:
	return skill_levels.get(skill_id, 0)

func is_skill_unlocked(skill_id: String) -> bool:
	return skill_levels.get(skill_id, 0) > 0

func apply_buff(buff_type: String, buff_value: float, duration: float) -> void:
	active_buffs.append({
		"type": buff_type,
		"value": buff_value,
		"remaining_time": duration,
	})

func _apply_all_passives() -> void:
	_reset_passives()
	var tree := SkillTreeData.get_class_tree(player_class)
	var skills: Dictionary = tree.get("skills", {})

	for skill_id in skill_levels:
		var level: int = skill_levels[skill_id]
		if level <= 0:
			continue
		var entry: Dictionary = skills.get(skill_id, {})
		var bonuses: Dictionary = entry.get("upgrade_bonuses", {})
		var level_index := level - 1

		# Apply passive bonuses
		if bonuses.has("passive_value"):
			var values: Array = bonuses["passive_value"]
			if level_index < values.size():
				var skill_data = entry.get("skill_data", SkillData.get_skill(skill_id))
				match skill_data.get("passive_type", ""):
					"max_hp_percent":
						player_stats["passive_max_hp_mult"] = values[level_index]

		if bonuses.has("passive_spell_damage"):
			var values: Array = bonuses["passive_spell_damage"]
			if level_index < values.size():
				player_stats["passive_spell_damage_mult"] = values[level_index]

		if bonuses.has("passive_mana_regen"):
			var values: Array = bonuses["passive_mana_regen"]
			if level_index < values.size():
				player_stats["passive_mana_regen"] = values[level_index]

		if bonuses.has("passive_crit_chance"):
			var values: Array = bonuses["passive_crit_chance"]
			if level_index < values.size():
				player_stats["passive_crit_chance"] = values[level_index]

		if bonuses.has("passive_crit_damage"):
			var values: Array = bonuses["passive_crit_damage"]
			if level_index < values.size():
				player_stats["passive_crit_damage"] = values[level_index]

		if bonuses.has("passive_speed"):
			var values: Array = bonuses["passive_speed"]
			if level_index < values.size():
				player_stats["passive_speed_mult"] = values[level_index]

		if bonuses.has("passive_dodge"):
			var values: Array = bonuses["passive_dodge"]
			if level_index < values.size():
				player_stats["passive_dodge"] = values[level_index]

func _reset_passives() -> void:
	player_stats["passive_attack_mult"] = 0.0
	player_stats["passive_defense_mult"] = 0.0
	player_stats["passive_max_hp_mult"] = 0.0
	player_stats["passive_spell_damage_mult"] = 0.0
	player_stats["passive_crit_chance"] = 0.0
	player_stats["passive_crit_damage"] = 0.0
	player_stats["passive_speed_mult"] = 0.0
	player_stats["passive_dodge"] = 0.0
	player_stats["passive_mana_regen"] = 0

# === Leveling ===

func reset_state() -> void:
	## Reset all player state for a fresh character.
	player_name = "Player"
	player_class = ClassData.ClassType.WARRIOR
	skill_points = 0
	total_skill_points_earned = 0
	skill_levels = {}
	active_buffs.clear()
	_reset_passives()
	player_stats = {
		"level": 1, "hp": 100, "max_hp": 100, "mp": 50, "max_mp": 50,
		"attack": 10, "defense": 5, "speed": 150.0,
		"exp": 0, "exp_to_level": 100, "crit_chance": 0.1, "crit_damage": 2.0,
		"equip_attack": 0, "equip_defense": 0, "equip_max_hp": 0, "equip_max_mp": 0,
		"equip_crit_chance": 0.0, "equip_speed": 0.0,
		"passive_attack_mult": 0.0, "passive_defense_mult": 0.0,
		"passive_max_hp_mult": 0.0, "passive_spell_damage_mult": 0.0,
		"passive_crit_chance": 0.0, "passive_crit_damage": 0.0,
		"passive_speed_mult": 0.0, "passive_dodge": 0.0, "passive_mana_regen": 0,
	}

func start_game(username: String) -> void:
	player_name = username
	is_in_game = true
	SilverManager.start_session()
	get_tree().change_scene_to_file("res://scenes/maps/world.tscn")

func return_to_menu() -> void:
	# Auto-save before leaving
	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	is_in_game = false
	NetworkManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func add_exp(amount: int) -> void:
	player_stats["exp"] += amount
	while player_stats["exp"] >= player_stats["exp_to_level"]:
		player_stats["exp"] -= player_stats["exp_to_level"]
		player_stats["level"] += 1
		player_stats["exp_to_level"] = _calculate_exp_to_level(player_stats["level"])
		_apply_level_up_bonuses()
		# Award skill point
		skill_points += SkillTreeData.SKILL_POINTS_PER_LEVEL
		total_skill_points_earned += SkillTreeData.SKILL_POINTS_PER_LEVEL
		EventBus.player_level_up.emit(player_id, player_stats["level"])
		EventBus.skill_points_changed.emit(skill_points, total_skill_points_earned)
	EventBus.player_exp_changed.emit(
		player_id, player_stats["exp"], player_stats["exp_to_level"]
	)

func _calculate_exp_to_level(level: int) -> int:
	return int(100 * pow(level, 1.5))

func _apply_level_up_bonuses() -> void:
	var info := ClassData.get_class_info(player_class)
	player_stats["max_hp"] += info.get("hp_per_level", 10)
	player_stats["hp"] = player_stats["max_hp"]
	player_stats["max_mp"] += info.get("mp_per_level", 5)
	player_stats["mp"] = player_stats["max_mp"]
	player_stats["attack"] += info.get("atk_per_level", 2)
	player_stats["defense"] += info.get("def_per_level", 1)

func _on_player_level_up(_player_id: int, new_level: int) -> void:
	print("Level up! Now level ", new_level, " (+1 skill point)")

func _on_player_died(_player_id: int) -> void:
	# Respawn after delay
	await get_tree().create_timer(3.0).timeout
	player_stats["hp"] = player_stats["max_hp"]
	player_stats["mp"] = player_stats["max_mp"]
	active_buffs.clear()
	EventBus.player_respawned.emit(player_id)
