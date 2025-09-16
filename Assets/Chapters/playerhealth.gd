extends Node

signal max_health_changed(diff: int)
signal health_changed(diff: int)
signal health_depleted

@export var max_health: int = 50 : set = set_max_health, get = get_max_health
@export var immortality: bool = false : set = set_immortality, get = get_immortality

# Use a plain Timer type and assign null — avoids the `|` union syntax error
var immortality_timer: Timer = null

@onready var health: int = max_health : set = set_health, get = get_health

func set_max_health(value: int) -> void:
	var clamped_value: int = 1 if value <= 0 else value
	if clamped_value != max_health:
		var difference: int = clamped_value - max_health
		max_health = clamped_value
		max_health_changed.emit(difference)
		if health > max_health:
			set_health(max_health)

func get_max_health() -> int:
	return max_health

func set_immortality(value: bool) -> void:
	immortality = value

func get_immortality() -> bool:
	return immortality

func set_temporary_immortality(time: float) -> void:
	if immortality_timer == null:
		immortality_timer = Timer.new()
		immortality_timer.one_shot = true
		add_child(immortality_timer)

	# Create a bound Callable and reuse it for is_connected/disconnect/connect
	var cb: Callable = Callable(self, "set_immortality").bind(false)

	if immortality_timer.timeout.is_connected(cb):
		immortality_timer.timeout.disconnect(cb)

	immortality_timer.wait_time = time
	immortality_timer.timeout.connect(cb)
	immortality = true
	immortality_timer.start()

func set_health(value: int) -> void:
	# Ignore damage when immortal
	if value < health and immortality:
		return

	var clamped_value: int = clamp(value, 0, max_health)
	if clamped_value != health:
		var difference: int = clamped_value - health
		health = clamped_value
		health_changed.emit(difference)
		if health == 0:
			health_depleted.emit()

func get_health() -> int:
	return health
