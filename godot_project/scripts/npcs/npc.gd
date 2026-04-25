extends CharacterBody3D
class_name NPC
## 3D non-player character with dialog and interaction.

@export var npc_name: String = "Villager"
@export var dialog_lines: Array[String] = ["Hello, adventurer!", "Be careful out there."]
@export var is_shopkeeper: bool = false
@export var shop_items: Array[Dictionary] = []

@onready var mesh: MeshInstance3D = $Mesh
@onready var nametag: Label3D = $Nametag
@onready var interact_hint: Label3D = $InteractHint

var current_dialog_index: int = 0
var player_nearby: bool = false

func _ready() -> void:
	add_to_group("npcs")
	nametag.text = npc_name
	interact_hint.visible = false

func interact() -> void:
	if is_shopkeeper:
		_open_shop()
	else:
		_show_dialog()

func _show_dialog() -> void:
	if current_dialog_index >= dialog_lines.size():
		current_dialog_index = 0
		EventBus.npc_interaction_ended.emit(get_instance_id())
		return

	var line: String = dialog_lines[current_dialog_index]
	EventBus.npc_interaction_started.emit(get_instance_id(), npc_name)
	EventBus.ui_show_dialog.emit(npc_name, line, [])
	current_dialog_index += 1

func _open_shop() -> void:
	EventBus.npc_interaction_started.emit(get_instance_id(), npc_name)

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		player_nearby = true
		interact_hint.visible = true

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("players"):
		player_nearby = false
		interact_hint.visible = false
		current_dialog_index = 0
