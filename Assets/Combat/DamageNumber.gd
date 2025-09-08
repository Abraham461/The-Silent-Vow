class_name DamageNumber
extends Label

# Damage number properties
var damage_value: int = 0
var text_color: Color = Color.RED
var is_critical: bool = false

# Movement properties
var float_speed: float = 50.0
var fade_speed: float = 1.0

# Internal state
var velocity: Vector2 = Vector2.ZERO

func _ready():
	# Set initial properties
	velocity = Vector2(randf_range(-20, 20), -float_speed)
	modulate = text_color
	text = str(damage_value)
	
	# Make it face the camera
	if get_parent() is CanvasLayer:
		z_index = 1000

func _process(delta):
	# Move upward with some horizontal drift
	velocity.y += 10 * delta  # Gravity effect
	position += velocity * delta
	
	# Fade out over time
	modulate.a -= fade_speed * delta
	
	# Remove when fully transparent
	if modulate.a <= 0:
		queue_free()

func setup(value: int, color: Color = Color.RED, critical: bool = false):
	"""Initialize the damage number with value and color"""
	damage_value = value
	text_color = color
	is_critical = critical
	
	# Apply properties
	modulate = text_color
	text = str(damage_value)
	
	# Make critical hits more prominent
	if is_critical:
		add_theme_font_size_override("font_size", 32)
		modulate = Color(color.r * 1.5, color.g * 1.5, color.b * 1.5)
	
	# Random horizontal drift
	velocity.x = randf_range(-30, 30)
