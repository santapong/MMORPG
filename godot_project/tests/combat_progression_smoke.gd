extends Node
## Deterministic contract test for all three class combat profiles.

var failed := false

func _require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("COMBAT PROGRESSION SMOKE: " + message)

func _ready() -> void:
	for class_type in ClassData.get_all_classes():
		var profile := CombatProfile.get_profile(class_type)
		_require(profile["combo"].size() == 3, "every class needs a three-hit combo")
		_require(float(profile["basic_range"]) > 0.0, "basic range must be positive")
		_require(float(profile["dodge_cost"]) > 0.0, "dodge must spend stamina")
		_require(float(profile["invulnerable"]) <= float(profile["dodge_duration"]), "i-frames exceed dodge")
		_require(ClassData.get_class_info(class_type)["skills"].size() == 4, "every class needs four skills")
		var weapon_id := CombatProfile.quest_weapon_id(class_type)
		var weapon := EquipmentData.get_equipment(weapon_id)
		_require(not weapon.is_empty(), "quest weapon is missing: " + weapon_id)
		_require(int(weapon.get("level_req", 99)) == 1, "quest weapon must equip at level one")

	_require(CombatProfile.get_profile(ClassData.ClassType.MAGE)["basic_range"] > CombatProfile.get_profile(ClassData.ClassType.WARRIOR)["basic_range"], "Mage must be ranged")
	_require(CombatProfile.get_profile(ClassData.ClassType.RANGER)["basic_range"] > CombatProfile.get_profile(ClassData.ClassType.MAGE)["basic_range"], "Ranger must have the longest basic range")
	var base_item := EquipmentData.get_equipment("wooden_sword")
	for trait_id in ["offense", "defense", "mobility"]:
		var item := CombatProfile.apply_loot_trait(base_item, trait_id)
		_require(item.get("trait", "") == trait_id, "loot trait id was not retained")
		_require(item["name"] != base_item["name"], "loot trait must be visible in the name")

	if failed:
		get_tree().quit(1)
	else:
		print("COMBAT_PROGRESSION_SMOKE_OK")
		get_tree().quit(0)
