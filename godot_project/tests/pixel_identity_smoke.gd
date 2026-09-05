extends Node
## Contract test for the visual identity pass: every first-look surface must
## communicate a voxel-pixel action RPG instead of a generic 3D prototype.

var failed := false

func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PIXEL IDENTITY SMOKE: " + message)

func _ready() -> void:
	var description := str(ProjectSettings.get_setting("application/config/description", ""))
	_require("voxel-pixel action RPG" in description, "project description does not name the genre")
	_require(int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1)) == 0, "canvas textures are not nearest-filtered")

	var menu := (load("res://scenes/main_menu/main_menu.tscn") as PackedScene).instantiate()
	_require(menu.get_node("CenterContainer/VBoxContainer/SubtitleLabel").text == "THE SLIME CROWN", "title screen lacks the quest identity")
	_require("HUNT SLIMES" in menu.get_node("CenterContainer/VBoxContainer/LoopLabel").text, "title screen lacks the game loop")
	_require(menu.get_node_or_null("Background") != null, "pixel title backdrop is missing")
	menu.queue_free()

	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	_require(player.get_node_or_null("PixelHead") != null, "player pixel head is missing")
	_require(player.get_node("ClassWeapons").get_child_count() == 3, "class silhouettes need three distinct weapons")
	player.queue_free()

	var enemy := (load("res://scenes/enemies/enemy.tscn") as PackedScene).instantiate()
	_require(enemy.get_node_or_null("PixelEyeLeft") != null, "slime pixel face is missing")
	_require(enemy.get_node_or_null("PixelCrown") != null, "boss crown is missing")
	enemy.queue_free()

	GameManager.reset_state()
	var world := (load("res://scenes/maps/world.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame
	_require(get_tree().get_nodes_in_group("pixel_world_art").size() == 1, "voxel world dressing is missing")
	_require(world.local_player.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "combat camera is not isometric-style orthographic")
	var ui_layer := world.get_node("UILayer") as CanvasLayer
	_require(ui_layer.visible, "gameplay UI layer is hidden")
	var hud_stats := world.get_node("UILayer/HUD/MarginContainer") as Control
	var objective := world.vertical_slice_node as Control
	var viewport_rect := world.get_viewport().get_visible_rect()
	_require(hud_stats.visible and viewport_rect.encloses(hud_stats.get_global_rect()), "player HUD is outside the viewport")
	_require(objective.visible and viewport_rect.encloses(objective.get_global_rect()), "quest card is outside the viewport")
	var genre_label := world.get_node("UILayer/HUD/GameIdentity/VBox/Genre") as Label
	_require("PIXEL ACTION RPG" in genre_label.text, "in-game HUD does not identify the genre")

	if failed:
		get_tree().quit(1)
	else:
		print("PIXEL_IDENTITY_SMOKE_OK")
		get_tree().quit(0)
