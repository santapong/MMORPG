extends PanelContainer
## Shows current zone name and recommended level.

var zone_name_label := Label.new()
var zone_tier_label := Label.new()
var zone_level_label := Label.new()
var current_zone_id: String = ""

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	custom_minimum_size = Vector2(200, 50)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -100
	offset_right = 100
	offset_top = 10
	offset_bottom = 60

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	zone_name_label.text = "Starter Village"
	zone_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(zone_name_label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	zone_tier_label.text = "Safe Zone"
	zone_tier_label.add_theme_font_size_override("font_size", 10)
	zone_tier_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	hbox.add_child(zone_tier_label)

	zone_level_label.text = "Lv. 1+"
	zone_level_label.add_theme_font_size_override("font_size", 10)
	hbox.add_child(zone_level_label)

func update_zone(player_pos: Vector2) -> void:
	var zone_id := ZoneData.get_zone_at_position(player_pos)
	if zone_id == current_zone_id:
		return

	current_zone_id = zone_id
	var zone := ZoneData.get_zone(zone_id)
	if zone.is_empty():
		return

	zone_name_label.text = zone.get("name", "Unknown")
	var tier: int = zone.get("tier", ZoneData.ZoneTier.SAFE)
	zone_tier_label.text = ZoneData.ZONE_TIER_NAMES.get(tier, "Unknown")

	# Color based on tier
	var tier_colors := {
		ZoneData.ZoneTier.SAFE: Color(0.3, 0.9, 0.3),
		ZoneData.ZoneTier.EASY: Color(0.5, 0.9, 0.3),
		ZoneData.ZoneTier.MEDIUM: Color(0.9, 0.9, 0.2),
		ZoneData.ZoneTier.HARD: Color(0.9, 0.4, 0.2),
		ZoneData.ZoneTier.NIGHTMARE: Color(0.9, 0.1, 0.1),
	}
	zone_tier_label.add_theme_color_override("font_color", tier_colors.get(tier, Color.WHITE))

	var rec_level: int = zone.get("recommended_level", 1)
	zone_level_label.text = "Lv. %d+" % rec_level

	EventBus.zone_changed.emit(zone_id, zone.get("name", ""))
