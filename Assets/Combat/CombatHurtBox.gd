class_name CombatHurtBox
extends Area2D

# Signals
signal damage_received(damage: int, attacker: Node)
signal hit_detected(hitbox: Area2D)

# Vulnerability properties
@export var damage_multiplier: float = 1.0  # Can be used for weak points
@export var can_be_hit: bool = true
@export var counter_hit_multiplier: float = 1.2  # Extra damage during certain states

# State tracking
var is_vulnerable: bool = true
var recently_hit_by: Array = []  # Track recent attackers to prevent double hits

func _ready() -> void:
	add_to_group("HurtBox")
	monitoring = true
	monitorable = true
	
	# Connect to area entered signal
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	# Enable collision shapes by default
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = false

func set_vulnerable(vulnerable: bool) -> void:
	"""Set whether this hurtbox can be hit"""
	is_vulnerable = vulnerable
	can_be_hit = vulnerable
	
	# Update monitoring state
	set_deferred("monitoring", vulnerable)
	
	# Update collision shapes
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", not vulnerable)

func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with hitboxes"""
	# Only process hitboxes
	if not area.is_in_group("HitBox"):
		return
	
	# Check if we can be hit
	if not can_be_hit or not is_vulnerable:
		return
	
	# Don't get hit by our own hitboxes
	var attacker = area.get_parent()
	if attacker == get_parent():
		return
	
	# Check team-based combat - don't get hit by same team
	var attacker_entity = attacker as CombatEntity
	var parent_entity = get_parent() as CombatEntity
	if attacker_entity and parent_entity and attacker_entity.get_team() == parent_entity.get_team():
		return
	
	# Prevent double hits from the same hitbox in rapid succession
	if attacker in recently_hit_by:
		return
	
	# Add to recent hits and clear after a short delay
	recently_hit_by.append(attacker)
	get_tree().create_timer(0.1).timeout.connect(func(): recently_hit_by.erase(attacker))
	
	# Get damage from hitbox
	var base_damage = 10
	if area.has_method("get_damage"):
		base_damage = area.get_damage()
	elif "damage" in area:
		base_damage = area.get("damage")
	
	# Apply damage multipliers
	var final_damage = int(base_damage * damage_multiplier)
	
	# Check for counter hit
	var parent = get_parent()
	if parent and parent.has_method("is_in_counter_state") and parent.is_in_counter_state():
		final_damage = int(final_damage * counter_hit_multiplier)
	
	# Get knockback if available
	var knockback = Vector2.ZERO
	if area.has_method("get_knockback_vector") and parent is Node2D:
		knockback = area.get_knockback_vector(area.global_position, parent.global_position)
	elif attacker and attacker is Node2D and parent is Node2D:
		var direction = (parent.global_position - attacker.global_position).normalized()
		knockback = direction * 200  # Default knockback
	
	# Apply damage to parent
	if parent and parent.has_method("take_damage"):
		parent.take_damage(final_damage, attacker, knockback)
	
	# Emit signals
	damage_received.emit(final_damage, attacker)
	hit_detected.emit(area)

func flip_horizontal() -> void:
	"""Flip the hurtbox horizontally (called by parent entity)"""
	position.x = -position.x
	
	# Flip collision shapes
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.position.x = -child.position.x
			
			# If it's a polygon, flip the points
			if child is CollisionPolygon2D:
				var polygon = child.polygon
				var flipped_polygon = PackedVector2Array()
				for point in polygon:
					flipped_polygon.append(Vector2(-point.x, point.y))
				child.polygon = flipped_polygon

func enable() -> void:
	"""Enable the hurtbox"""
	set_vulnerable(true)

func disable() -> void:
	"""Disable the hurtbox (for invincibility frames, etc.)"""
	set_vulnerable(false)

func reset() -> void:
	"""Reset the hurtbox state"""
	recently_hit_by.clear()
	set_vulnerable(true)
