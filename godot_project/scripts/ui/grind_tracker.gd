extends PanelContainer
## Grinding stats tracker UI — shows silver/hr, kills/hr, session duration. BDO-inspired.

@onready var duration_label := Label.new()
@onready var silver_total_label := Label.new()
@onready var silver_hr_label := Label.new()
@onready var kills_label := Label.new()
@onready var kills_hr_label := Label.new()
@onready var rare_drops_label := Label.new()
@onready var zone_label := Label.new()

var is_visible_panel := false

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	custom_minimum_size = Vector2(220, 200)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -230
	offset_right = -10
	offset_top = 10
	offset_bottom = 220

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	var title := Label.new()
	title.text = "=== GRIND TRACKER ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	zone_label.text = "Zone: ---"
	zone_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(zone_label)

	duration_label.text = "Time: 00:00:00"
	duration_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(duration_label)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	silver_total_label.text = "Silver: 0"
	silver_total_label.add_theme_font_size_override("font_size", 11)
	silver_total_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(silver_total_label)

	silver_hr_label.text = "Silver/hr: 0"
	silver_hr_label.add_theme_font_size_override("font_size", 11)
	silver_hr_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(silver_hr_label)

	var sep3 := HSeparator.new()
	vbox.add_child(sep3)

	kills_label.text = "Kills: 0"
	kills_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(kills_label)

	kills_hr_label.text = "Kills/hr: 0"
	kills_hr_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(kills_hr_label)

	rare_drops_label.text = "Rare Drops: 0"
	rare_drops_label.add_theme_font_size_override("font_size", 11)
	rare_drops_label.add_theme_color_override("font_color", Color(0.6, 0.4, 1.0))
	vbox.add_child(rare_drops_label)

func _process(_delta: float) -> void:
	if not visible:
		return
	duration_label.text = "Time: " + SilverManager.get_session_duration_str()
	silver_total_label.text = "Silver: " + SilverManager.format_silver(SilverManager.silver)
	silver_hr_label.text = "Silver/hr: " + SilverManager.format_silver(SilverManager.get_silver_per_hour())
	kills_label.text = "Kills: " + str(SilverManager.session_kills)
	kills_hr_label.text = "Kills/hr: " + str(SilverManager.get_kills_per_hour())
	rare_drops_label.text = "Rare Drops: " + str(SilverManager.session_rare_drops)

func update_zone(zone_name: String) -> void:
	zone_label.text = "Zone: " + zone_name

func toggle_visible() -> void:
	is_visible_panel = not is_visible_panel
	visible = is_visible_panel
