extends ProgressBar

@export var player: CharacterBody2D

func _ready():
		# hide the percent text
	show_percentage = false
	# 1) Style the background (dark gray + border on all sides)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.2, 0.2)
	bg.border_color = Color(0.1, 0.1, 0.1)
	bg.border_width_top    = 2
	bg.border_width_bottom = 2
	bg.border_width_left   = 2
	bg.border_width_right  = 2
	add_theme_stylebox_override("bg", bg)

	# 2) Style the fill (solid green, no border)
	var fg = StyleBoxFlat.new()
	fg.bg_color = Color(0, 1, 0)
	# no need to set borders here if you want none
	add_theme_stylebox_override("fg", fg)

	# 3) Make the bar a reasonable size
	custom_minimum_size = Vector2(200, 24)

	# 4) Percent text color (so "100 %" isn’t white on white!)
	add_theme_color_override("font_color", Color(0, 0, 0))
	add_theme_color_override("font_color_disabled", Color(0.2, 0.2, 0.2))

	# 5) Configure value range
	min_value = 0
	max_value = 100
	value = 100

	# 6) Hook up the player’s healthChanged signal
	if player and player.has_signal("healthChanged"):
		player.healthChanged.connect(_on_health_changed)
		_on_health_changed()
	else:
		push_error("Player not assigned or signal missing!")

func _on_health_changed():
	if player.maxHealth > 0:
		value = player.currentHealth * 100.0 / player.maxHealth
	else:
		value = 0
