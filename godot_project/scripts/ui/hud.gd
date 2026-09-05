extends CanvasLayer
class_name HUD
## Hard-edged pixel HUD — identity, combat loop, vitals, level, and silver.

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var mp_bar: ProgressBar = $MarginContainer/VBoxContainer/MPBar
@onready var exp_bar: ProgressBar = $MarginContainer/VBoxContainer/EXPBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPBar/HPLabel
@onready var mp_label: Label = $MarginContainer/VBoxContainer/MPBar/MPLabel
@onready var silver_label: Label = $MarginContainer/VBoxContainer/SilverLabel
@onready var class_label: Label = $MarginContainer/VBoxContainer/ClassLabel
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaBar

func _ready() -> void:
	PixelTheme.apply($MarginContainer)
	PixelTheme.apply($GameIdentity)
	PixelTheme.apply($CombatHelp)
	hp_bar.add_theme_stylebox_override("fill", _bar_fill(PixelTheme.RED))
	mp_bar.add_theme_stylebox_override("fill", _bar_fill(PixelTheme.BLUE))
	stamina_bar.add_theme_stylebox_override("fill", _bar_fill(PixelTheme.GOLD))
	exp_bar.add_theme_stylebox_override("fill", _bar_fill(PixelTheme.MINT))
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_mana_changed.connect(_on_mana_changed)
	EventBus.player_exp_changed.connect(_on_exp_changed)
	EventBus.player_stamina_changed.connect(_on_stamina_changed)
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
	class_label.text = class_name_str.to_upper() + "  •  PIXEL HERO"
	class_label.add_theme_color_override(
		"font_color", ClassData.get_class_info(GameManager.player_class).get("color", Color.WHITE).lightened(0.2)
	)

func _bar_fill(color: Color) -> StyleBoxFlat:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.border_color = color.lightened(0.28)
	fill.set_border_width_all(2)
	fill.set_corner_radius_all(0)
	return fill

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

func _on_stamina_changed(_player_id: int, current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
