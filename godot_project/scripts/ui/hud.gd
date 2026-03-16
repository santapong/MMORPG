extends CanvasLayer
class_name HUD
## Main game HUD — health, mana, exp, level, silver, and class display. BDO-style.

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var mp_bar: ProgressBar = $MarginContainer/VBoxContainer/MPBar
@onready var exp_bar: ProgressBar = $MarginContainer/VBoxContainer/EXPBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPBar/HPLabel
@onready var mp_label: Label = $MarginContainer/VBoxContainer/MPBar/MPLabel
@onready var silver_label: Label = $MarginContainer/VBoxContainer/SilverLabel
@onready var class_label: Label = $MarginContainer/VBoxContainer/ClassLabel

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_mana_changed.connect(_on_mana_changed)
	EventBus.player_exp_changed.connect(_on_exp_changed)
	EventBus.player_level_up.connect(_on_level_up)
	SilverManager.silver_changed.connect(_on_silver_changed)
	_refresh()

func _refresh() -> void:
	var stats: Dictionary = GameManager.player_stats
	_update_hp(stats["hp"], stats["max_hp"])
	_update_mp(stats["mp"], stats["max_mp"])
	_update_exp(stats["exp"], stats["exp_to_level"])
	level_label.text = "Lv. " + str(stats["level"])
	_update_silver(SilverManager.silver)

	var class_name_str := ClassData.get_class_name_str(GameManager.player_class)
	class_label.text = class_name_str

func _update_hp(current: int, max_val: int) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = current
	hp_label.text = str(current) + " / " + str(max_val)

func _update_mp(current: int, max_val: int) -> void:
	mp_bar.max_value = max_val
	mp_bar.value = current
	mp_label.text = str(current) + " / " + str(max_val)

func _update_exp(current: int, to_next: int) -> void:
	exp_bar.max_value = to_next
	exp_bar.value = current

func _update_silver(amount: int) -> void:
	silver_label.text = "Silver: " + SilverManager.format_silver(amount)

func _on_health_changed(_player_id: int, current: int, max_val: int) -> void:
	_update_hp(current, max_val)

func _on_mana_changed(_player_id: int, current: int, max_val: int) -> void:
	_update_mp(current, max_val)

func _on_exp_changed(_player_id: int, current: int, to_next: int) -> void:
	_update_exp(current, to_next)

func _on_level_up(_player_id: int, new_level: int) -> void:
	level_label.text = "Lv. " + str(new_level)
	_refresh()

func _on_silver_changed(amount: int) -> void:
	_update_silver(amount)
