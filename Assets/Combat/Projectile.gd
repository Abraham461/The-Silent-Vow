class_name Projectile
extends CharacterBody2D

# Signals
signal hit_target(target: Node)
signal lifetime_expired()

# Projectile properties
@export var speed: float = 200.0
@export var damage: int = 10
@export var team: int = 0  # Team this projectile belongs to
@export var lifetime: float = 5.0  # Time before projectile expires
@export var pierce_count: int = 0  # Number of targets that can be hit (-1 for infinite)
@export var destroy_on_hit: bool = true  # Whether to destroy on hit

# Visual properties
@export var hit_effect_scene: PackedScene = null
@export var trail_effect_scene: PackedScene = null

# Node references
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var area: Area2D = $Area2D if has_node("Area2D") else null

# Internal state
var direction: Vector2 = Vector2.RIGHT
var targets_hit: Array = []
var lifetime_timer: float = 0.0
var trail_timer: float = 0.0

func _ready() -> void:
	# Add to appropriate group
	add_to_group("projectiles")
	
	# Connect area signals if present
	if area:
		area.area_entered.connect(_on_area_entered)
	
	# Set initial rotation based on direction
	if sprite:
		sprite.rotation = direction.angle()

func _physics_process(delta: float) -> void:
	# Move projectile
	velocity = direction * speed
	move_and_slide()
	
	# Update lifetime
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		emit_signal("lifetime_expired")
		queue_free()
		return
	
	# Update trail effect timer
	trail_timer += delta
	if trail_timer >= 0.1:  # Create trail every 0.1 seconds
		trail_timer = 0.0
		_create_trail_effect()

func _on_area_entered(area: Area2D) -> void:
	# Only process hurtboxes
	if not area.is_in_group("HurtBox"):
		return
	
	# Don't hit same team
	var target_entity = area.get_parent() as CombatEntity
	if target_entity and target_entity.get_team() == team:
		return
	
	# Don't hit same target multiple times
	if area.get_parent() in targets_hit:
		return
	
	# Add to targets hit
	targets_hit.append(area.get_parent())
	
	# Apply damage
	var target = area.get_parent()
	if target and target.has_method("take_damage"):
		target.take_damage(damage, self, direction * 100)  # Knockback in direction of projectile
	
	# Emit hit signal
	emit_signal("hit_target", target)
	
	# Create hit effect
	_create_hit_effect()
	
	# Check if we should destroy
	if destroy_on_hit or (pierce_count >= 0 and targets_hit.size() > pierce_count):
		queue_free()

func set_direction(dir: Vector2) -> void:
	"""Set the direction of the projectile"""
	direction = dir.normalized()
	
	# Update rotation if sprite exists
	if sprite:
		sprite.rotation = direction.angle()

func set_speed(value: float) -> void:
	"""Set the speed of the projectile"""
	speed = value

func set_damage(value: int) -> void:
	"""Set the damage of the projectile"""
	damage = value

func set_team(value: int) -> void:
	"""Set the team of the projectile"""
	team = value

func _create_hit_effect() -> void:
	"""Create hit effect when projectile hits target"""
	if not hit_effect_scene:
		return
	
	var effect = hit_effect_scene.instantiate()
	if effect:
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position

func _create_trail_effect() -> void:
	"""Create trail effect behind projectile"""
	if not trail_effect_scene:
		return
	
	var effect = trail_effect_scene.instantiate()
	if effect:
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position
