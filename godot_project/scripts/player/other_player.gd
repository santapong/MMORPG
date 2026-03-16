extends CharacterBody2D
class_name OtherPlayer
## Represents a remote player synced over the network.

@onready var sprite: Sprite2D = $Sprite2D
@onready var nametag: Label = $Nametag

var peer_id: int = -1
var player_name: String = "Player"
var target_position: Vector2 = Vector2.ZERO
var interpolation_speed: float = 10.0

func _ready() -> void:
	nametag.text = player_name

func _physics_process(delta: float) -> void:
	# Smoothly interpolate to the synced position
	global_position = global_position.lerp(target_position, interpolation_speed * delta)

func update_position(new_pos: Vector2) -> void:
	target_position = new_pos
