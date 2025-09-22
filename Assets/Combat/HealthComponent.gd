class_name HealthComponent
extends Node

# Signals
signal health_changed(current: int, maximum: int)
signal damage_taken(amount: int)
signal health_depleted()
signal healed(amount: int)

# Health properties
@export var max_health: int = 100
@export var current_health: int = 100
@export var show_damage_numbers: bool = true
@export var damage_number_color: Color = Color.RED
@export var heal_number_color: Color = Color.GREEN

# Damage number scene (optional)
@export var damage_number_scene: PackedScene = null

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	"""Apply damage to health"""
	if current_health <= 0:
		return
	
	var previous_health = current_health
	current_health = max(0, current_health - amount)
	
	# Show damage number
	if show_damage_numbers and amount > 0:
		_spawn_damage_number(amount, damage_number_color)
	
	# Emit signals
	damage_taken.emit(amount)
	health_changed.emit(current_health, max_health)
	
	# Check for death
	if current_health <= 0 and previous_health > 0:
		health_depleted.emit()

func heal(amount: int) -> void:
	"""Restore health"""
	if current_health >= max_health:
		return
	
	var previous_health = current_health
	current_health = min(max_health, current_health + amount)
	var actual_heal = current_health - previous_health
	
	# Show heal number
	if show_damage_numbers and actual_heal > 0:
		_spawn_damage_number(actual_heal, heal_number_color)
	
	# Emit signals
	if actual_heal > 0:
		healed.emit(actual_heal)
		health_changed.emit(current_health, max_health)

func set_health(value: int) -> void:
	"""Set health to a specific value"""
	current_health = clamp(value, 0, max_health)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		health_depleted.emit()

func reset() -> void:
	"""Reset health to maximum"""
	current_health = max_health
	health_changed.emit(current_health, max_health)

func get_health_percentage() -> float:
	"""Get health as a percentage (0.0 to 1.0)"""
	return float(current_health) / float(max_health) if max_health > 0 else 0.0

func is_alive() -> bool:
	"""Check if entity is alive"""
	return current_health > 0

func is_full_health() -> bool:
	"""Check if at full health"""
	return current_health >= max_health

func _spawn_damage_number(value: int, color: Color) -> void:
	"""Spawn a floating damage number"""
	if not damage_number_scene:
		# Create a simple label if no scene provided
		var label = Label.new()
		label.text = str(value)
		label.modulate = color
		label.z_index = 100
		
		var parent = get_parent()
		if parent and parent is Node2D:
			parent.add_child(label)
			label.position = Vector2(0, -30)
			
			# Animate the number floating up and fading
			var tween = get_tree().create_tween()
			tween.set_parallel(true)
			tween.tween_property(label, "position:y", label.position.y - 50, 1.0)
			tween.tween_property(label, "modulate:a", 0.0, 1.0)
			tween.chain().tween_callback(label.queue_free)
	else:
		# Use provided damage number scene
		var instance = damage_number_scene.instantiate()
		if instance.has_method("setup"):
			instance.setup(value, color)
		
		var parent = get_parent()
		if parent and parent is Node2D:
			parent.add_child(instance)
			instance.position = Vector2(0, -30)
