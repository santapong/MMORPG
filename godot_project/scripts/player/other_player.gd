extends CharacterBody3D
class_name OtherPlayer
## 3D remote player synced over the network.

@onready var mesh: MeshInstance3D = $Mesh
@onready var nametag: Label3D = $Nametag

var peer_id: int = -1
var player_name: String = "Player"
var target_position: Vector3 = Vector3.ZERO
var interpolation_speed: float = 10.0

func _ready() -> void:
	nametag.text = player_name
	target_position = global_position

func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(target_position, interpolation_speed * delta)

func update_position(new_pos: Vector3) -> void:
	target_position = new_pos
