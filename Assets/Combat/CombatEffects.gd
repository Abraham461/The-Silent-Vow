class_name CombatEffects
extends Node

# Visual effect properties
@export var hit_flash_color: Color = Color(1, 0.3, 0.3, 1)
@export var hit_flash_duration: float = 0.1
@export var screen_shake_enabled: bool = true
@export var screen_shake_intensity: float = 5.0
@export var hit_stop_enabled: bool = true
@export var hit_stop_duration: float = 0.05

# Audio properties
@export var hit_sound: AudioStream = null
@export var critical_hit_sound: AudioStream = null
@export var block_sound: AudioStream = null

# Particle effects
@export var hit_particle_scene: PackedScene = null
@export var blood_particle_scene: PackedScene = null

# References
var sprite_node: Node2D = null
var camera: Camera2D = null
var audio_player: AudioStreamPlayer2D = null

func _ready() -> void:
	# Find sprite node in parent
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is AnimatedSprite2D or child is Sprite2D:
				sprite_node = child
				break
	
	# Create audio player if needed
	if not audio_player:
		audio_player = AudioStreamPlayer2D.new()
		add_child(audio_player)
	
	# Find camera in scene
	camera = get_viewport().get_camera_2d()

func play_hit_effect(damage: int, position: Vector2, is_critical: bool = false) -> void:
	"""Play hit effect at specified position"""
	# Visual flash
	if sprite_node:
		flash_sprite()
	
	# Screen shake
	if screen_shake_enabled and camera:
		shake_screen(damage)
	
	# Hit stop (freeze frame)
	if hit_stop_enabled:
		apply_hit_stop()
	
	# Spawn particles
	if hit_particle_scene:
		spawn_hit_particles(position)
	
	# Play sound
	if is_critical and critical_hit_sound:
		play_sound(critical_hit_sound)
	elif hit_sound:
		play_sound(hit_sound)

func flash_sprite() -> void:
	"""Flash the sprite with hit color"""
	if not sprite_node:
		return
	
	var original_modulate = sprite_node.modulate
	sprite_node.modulate = hit_flash_color
	
	await get_tree().create_timer(hit_flash_duration).timeout
	sprite_node.modulate = original_modulate

func shake_screen(intensity_multiplier: float = 1.0) -> void:
	"""Apply screen shake effect"""
	if not camera:
		return
	
	var shake_amount = screen_shake_intensity * intensity_multiplier
	var original_offset = camera.offset
	
	# Shake for a short duration
	var shake_duration = 0.2
	var elapsed = 0.0
	
	while elapsed < shake_duration:
		var offset_x = randf_range(-shake_amount, shake_amount)
		var offset_y = randf_range(-shake_amount, shake_amount)
		camera.offset = original_offset + Vector2(offset_x, offset_y)
		
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
		# Reduce shake over time
		shake_amount *= 0.9
	
	camera.offset = original_offset

func apply_hit_stop() -> void:
	"""Apply hit stop (freeze frame) effect"""
	var original_time_scale = Engine.time_scale
	Engine.time_scale = 0.1
	
	await get_tree().create_timer(hit_stop_duration * 0.1).timeout
	Engine.time_scale = original_time_scale

func spawn_hit_particles(position: Vector2) -> void:
	"""Spawn hit particle effect"""
	if not hit_particle_scene:
		return
	
	var particles = hit_particle_scene.instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = position
	
	# Auto-remove after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if particles and is_instance_valid(particles):
		particles.queue_free()

func spawn_blood_particles(position: Vector2, direction: Vector2) -> void:
	"""Spawn blood particle effect"""
	if not blood_particle_scene:
		return
	
	var particles = blood_particle_scene.instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = position
	
	# Set direction if particle system supports it
	if particles.has_method("set_direction"):
		particles.set_direction(direction)
	
	# Auto-remove after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if particles and is_instance_valid(particles):
		particles.queue_free()

func play_sound(sound: AudioStream) -> void:
	"""Play a sound effect"""
	if not audio_player or not sound:
		return
	
	audio_player.stream = sound
	audio_player.play()

func play_death_effect() -> void:
	"""Play death effect"""
	if sprite_node:
		# Fade out
		var tween = get_tree().create_tween()
		tween.tween_property(sprite_node, "modulate:a", 0.0, 0.5)

func play_block_effect(position: Vector2) -> void:
	"""Play block/parry effect"""
	if block_sound:
		play_sound(block_sound)
	
	# Create spark effect
	var spark = Label.new()
	spark.text = "BLOCK!"
	spark.modulate = Color.YELLOW
	spark.z_index = 100
	
	get_tree().current_scene.add_child(spark)
	spark.global_position = position
	
	# Animate
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(spark, "position:y", spark.position.y - 30, 0.5)
	tween.tween_property(spark, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(spark.queue_free)

func create_hit_spark(position: Vector2, color: Color = Color.WHITE) -> void:
	"""Create a simple hit spark effect"""
	var spark = ColorRect.new()
	spark.size = Vector2(20, 20)
	spark.color = color
	spark.position = Vector2(-10, -10)  # Center it
	spark.z_index = 100
	
	var spark_container = Node2D.new()
	get_tree().current_scene.add_child(spark_container)
	spark_container.add_child(spark)
	spark_container.global_position = position
	
	# Animate the spark
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(spark, "scale", Vector2(2, 2), 0.1)
	tween.tween_property(spark, "modulate:a", 0.0, 0.1)
	tween.chain().tween_callback(spark_container.queue_free)
