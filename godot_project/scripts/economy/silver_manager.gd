extends Node
## Autoload: Manages silver currency and economy. BDO-inspired trash loot system.

signal silver_changed(amount: int)
signal silver_earned(amount: int, source: String)
signal rare_drop_obtained(item_name: String)

var silver: int = 0

# Grinding session stats
var session_start_time: float = 0.0
var session_silver_earned: int = 0
var session_kills: int = 0
var session_rare_drops: int = 0

func _ready() -> void:
	EventBus.entity_died.connect(_on_entity_died)

func start_session() -> void:
	session_start_time = Time.get_unix_time_from_system()
	session_silver_earned = 0
	session_kills = 0
	session_rare_drops = 0

func add_silver(amount: int, source: String = "loot") -> void:
	silver += amount
	session_silver_earned += amount
	silver_changed.emit(silver)
	silver_earned.emit(amount, source)

func remove_silver(amount: int) -> bool:
	if silver < amount:
		return false
	silver -= amount
	silver_changed.emit(silver)
	return true

func get_silver_per_hour() -> int:
	var elapsed := Time.get_unix_time_from_system() - session_start_time
	if elapsed < 1.0:
		return 0
	return int(session_silver_earned / elapsed * 3600.0)

func get_kills_per_hour() -> int:
	var elapsed := Time.get_unix_time_from_system() - session_start_time
	if elapsed < 1.0:
		return 0
	return int(session_kills / elapsed * 3600.0)

func get_session_duration_str() -> String:
	var elapsed := int(Time.get_unix_time_from_system() - session_start_time)
	var hours := elapsed / 3600
	var minutes := (elapsed % 3600) / 60
	var seconds := elapsed % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func format_silver(amount: int) -> String:
	if amount >= 1_000_000_000:
		return "%.1fB" % (amount / 1_000_000_000.0)
	elif amount >= 1_000_000:
		return "%.1fM" % (amount / 1_000_000.0)
	elif amount >= 1_000:
		return "%.1fK" % (amount / 1_000.0)
	return str(amount)

func _on_entity_died(_entity_id: int) -> void:
	session_kills += 1
