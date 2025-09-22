class_name Health
extends Node

signal max_health_changed(diff: int)
signal health_changed(diff: int)
signal health_depleted
@export var player_path: NodePath
@export var max_health: int = 500 : set = set_max_health, get = get_max_health
@export var immortality: bool = false : set = set_immortality, get = get_immortality
@onready var progress_bar: ProgressBar = $"../ProgressBar"

# Use a plain Timer type and assign null — avoids the `|` union syntax error
var immortality_timer: Timer = null

# will be filled in _ready()
var player: Node = null
var health_node: Node = null        # replace Node with your Health class if you have one
var health_bar: ProgressBar = null  # use TextureProgress if you're using that
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


func _ready() -> void:
	# 1) Try the inspector NodePath first
	if player_path and player_path != NodePath(""):
		player = get_node_or_null(player_path)
	
	# 2) fallback: try to find a node in the scene named "Player" (optional)
	if player == null:
		player = get_node_or_null("/root/Scene/Player")  # change to your actual scene path
	# or, find by group:
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	if player == null:
		push_warning("Player not found — assign player_path in the inspector or add player to 'player' group")
		return

	# 3) Access children of the player
	# adjust child names to match your scene tree (case sensitive)
	health_node = player.get_node_or_null("Health")
	# health bar is a child control of the player (or of a UI container under player)
	health_bar = player.get_node_or_null("ProgressBar") as ProgressBar
	# if your health bar is TextureProgress, cast accordingly:
	# health_bar = player.get_node_or_null("UI/HealthBar") as TextureProgress

	# null checks
	if health_node == null:
		push_warning("Player Health node not found at 'Player/Health'.")
	if health_bar == null:
		push_warning("Health ProgressBar not found at 'Player/ProgressBar'.")

	# 4) initialize the bar if both exist (set max and value)
	if health_node and health_bar:
		if health_node.has_method("get_max_health") and health_node.has_method("get_health"):
			health_bar.max_value = health_node.get_max_health()
			health_bar.value = health_node.get_health()
		else:
			# try common property names:
			if health_node.has_variable("maxHealth"):
				health_bar.max_value = int(health_node.maxHealth)
			if health_node.has_variable("currentHealth"):
				health_bar.value = int(health_node.currentHealth)

		# 5) connect a signal so the UI updates automatically when health changes
		# replace "health_changed" with the actual signal name your Health node emits
		if not health_node.is_connected("health_changed", Callable(self, "_on_player_health_changed")):
			if health_node.has_signal("health_changed"):
				health_node.connect("health_changed", Callable(self, "_on_player_health_changed"))
			elif health_node.has_signal("healthChanged"):
				health_node.connect("healthChanged", Callable(self, "_on_player_health_changed"))
			# some implementations use a custom method or direct property change; adapt as needed

# 6) signal handler that updates the bar
func _on_player_health_changed(new_health: int) -> void:
	if health_bar:
		health_bar.value = new_health

# Optional helper to refresh the bar from the Health node when needed
func refresh_health_bar() -> void:
	if health_node and health_bar:
		# prefer method calls if available
		if health_node.has_method("get_health"):
			health_bar.value = health_node.get_health()
		elif health_node.has_variable("currentHealth"):
			health_bar.value = int(health_node.currentHealth)
func _on_healthbar_visibility_changed() -> void:
	pass # Replace with function body.
