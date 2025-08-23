class_name CombatEntity
extends CharacterBody2D

# Signals
signal health_changed(current_health: int, max_health: int)
signal damage_taken(damage: int, attacker: Node)
signal health_depleted()
signal facing_changed(facing_left: bool)
signal hit_landed(target: Node, damage: int)
signal state_changed(old_state: int, new_state: int)

# Health properties
@export var max_health: int = 100
@export var current_health: int = 100

# Combat properties
@export var base_defense: int = 0
@export var invincibility_duration: float = 0.5
@export var knockback_resistance: float = 0.0  # 0.0 to 1.0
@export var team: int = 0  # 0 = player, 1 = enemy, 2 = neutral
@export var show_debug_visuals: bool = false

# Facing direction
var facing_left: bool = false
var is_invincible: bool = false
var invincibility_timer: float = 0.0

# Combat state
enum CombatState { IDLE, ATTACKING, HURT, BLOCKING, DEAD }
var combat_state: CombatState = CombatState.IDLE

# Node references
var sprite_node: Node2D = null
var hitboxes: Array[Area2D] = []
var hurtboxes: Array[Area2D] = []
var debug_visuals: Node2D = null

# Ranged combat support
var projectiles: Array = []

func _ready() -> void:
	add_to_group("combat_entities")
	current_health = max_health
	
	# Find sprite node (AnimatedSprite2D or Sprite2D)
	for child in get_children():
		if child is AnimatedSprite2D or child is Sprite2D:
			sprite_node = child
			break
	
	# Collect all hitboxes and hurtboxes
	_collect_combat_areas()
	
	# Connect hurtbox signals
	for hurtbox in hurtboxes:
		if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			hurtbox.area_entered.connect(_on_hurtbox_area_entered.bind(hurtbox))
	
	# Create debug visuals if enabled
	if show_debug_visuals:
		_create_debug_visuals()

func _physics_process(delta: float) -> void:
	# Handle invincibility frames
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			_set_hurtboxes_enabled(true)
	
	# Update debug visuals if enabled
	if show_debug_visuals:
		_update_debug_visuals()
	
	# Update projectiles
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile = projectiles[i]
		if projectile and is_instance_valid(projectile):
			# Update projectile logic here if needed
			pass
		else:
			projectiles.remove_at(i)

func _collect_combat_areas() -> void:
	"""Collect all hitbox and hurtbox areas from children"""
	hitboxes.clear()
	hurtboxes.clear()
	
	for child in get_children():
		if child is Area2D:
			if child.is_in_group("HitBox"):
				hitboxes.append(child)
			elif child.is_in_group("HurtBox"):
				hurtboxes.append(child)

func _create_debug_visuals() -> void:
	"""Create debug visualization for hitboxes and hurtboxes"""
	debug_visuals = Node2D.new()
	debug_visuals.name = "DebugVisuals"
	add_child(debug_visuals)
	
	# Create visual representations for hitboxes
	for i in range(hitboxes.size()):
		var hitbox = hitboxes[i]
		var debug_shape = _create_debug_shape(hitbox, Color.RED)
		debug_shape.name = "DebugHitBox%d" % i
		debug_visuals.add_child(debug_shape)
	
	# Create visual representations for hurtboxes
	for i in range(hurtboxes.size()):
		var hurtbox = hurtboxes[i]
		var debug_shape = _create_debug_shape(hurtbox, Color.GREEN)
		debug_shape.name = "DebugHurtBox%d" % i
		debug_visuals.add_child(debug_shape)

func _create_debug_shape(area: Area2D, color: Color) -> Node2D:
	"""Create a debug visualization shape for an area"""
	var debug_node = Node2D.new()
	debug_node.position = area.position
	
	# Find collision shapes in the area
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			var debug_shape = null
			
			if shape is RectangleShape2D:
				debug_shape = RectangleShape2D.new()
				debug_shape.size = shape.size
			elif shape is CircleShape2D:
				debug_shape = CircleShape2D.new()
				debug_shape.radius = shape.radius
			
			if debug_shape:
				var debug_collision = CollisionShape2D.new()
				debug_collision.shape = debug_shape
				debug_collision.position = child.position
				debug_collision.disabled = false
				
				# Create a visual representation
				var debug_sprite = Sprite2D.new()
				debug_sprite.modulate = color
				debug_sprite.modulate.a = 0.5  # Semi-transparent
				debug_sprite.centered = true
				
				debug_node.add_child(debug_collision)
				debug_node.add_child(debug_sprite)
	
	return debug_node

func _update_debug_visuals() -> void:
	"""Update debug visualization positions"""
	if not debug_visuals:
		return
	
	# Update hitbox debug visuals
	for i in range(min(hitboxes.size(), debug_visuals.get_child_count())):
		var hitbox = hitboxes[i]
		var debug_node = debug_visuals.get_child(i)
		if debug_node:
			debug_node.position = hitbox.position
			debug_node.visible = hitbox.monitoring
	
	# Update hurtbox debug visuals (offset by hitbox count)
	var hurtbox_offset = hitboxes.size()
	for i in range(min(hurtboxes.size(), debug_visuals.get_child_count() - hurtbox_offset)):
		var hurtbox = hurtboxes[i]
		var debug_node = debug_visuals.get_child(i + hurtbox_offset)
		if debug_node:
			debug_node.position = hurtbox.position
			debug_node.visible = hurtbox.monitoring

func set_facing_direction(left: bool) -> void:
	"""Set the facing direction and flip all relevant nodes"""
	if facing_left == left:
		return
	
	facing_left = left
	
	# Flip sprite
	if sprite_node:
		if sprite_node is AnimatedSprite2D or sprite_node is Sprite2D:
			sprite_node.flip_h = facing_left
	
	# Flip all hitboxes
	for hitbox in hitboxes:
		_flip_area_position(hitbox)
		# Also flip any child collision shapes
		for child in hitbox.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				_flip_collision_shape(child)
	
	# Flip all hurtboxes
	for hurtbox in hurtboxes:
		_flip_area_position(hurtbox)
		# Also flip any child collision shapes
		for child in hurtbox.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				_flip_collision_shape(child)
	
	# Update debug visuals if enabled
	if show_debug_visuals:
		_update_debug_visuals()
	
	facing_changed.emit(facing_left)

func fire_projectile(projectile_scene: PackedScene, direction: Vector2, speed: float = 200.0, damage: int = 10) -> Node2D:
	"""Fire a projectile in the specified direction"""
	if not projectile_scene:
		return null
	
	var projectile = projectile_scene.instantiate()
	if not projectile:
		return null
	
	# Add to scene
	get_parent().add_child(projectile)
	
	# Set projectile properties
	projectile.global_position = global_position
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)
	if projectile.has_method("set_speed"):
		projectile.set_speed(speed)
	if projectile.has_method("set_damage"):
		projectile.set_damage(damage)
	if projectile.has_method("set_team"):
		projectile.set_team(team)
	
	# Store reference
	projectiles.append(projectile)
	
	return projectile

func change_combat_state(new_state: CombatState) -> void:
	"""Change the combat state and emit signal"""
	var old_state = combat_state
	combat_state = new_state
	state_changed.emit(old_state, new_state)

func is_in_counter_state() -> bool:
	"""Check if entity is in a state where they can counter attacks"""
	return combat_state == CombatState.BLOCKING

func get_team() -> int:
	"""Get the team this entity belongs to"""
	return team

func set_team(value: int) -> void:
	"""Set the team this entity belongs to"""
	team = value

func _flip_area_position(area: Area2D) -> void:
	"""Flip the X position of an Area2D"""
	area.position.x = -area.position.x

func _flip_collision_shape(shape: Node2D) -> void:
	"""Flip the position of a collision shape"""
	shape.position.x = -shape.position.x
	
	# If it's a polygon, also flip the polygon points
	if shape is CollisionPolygon2D:
		var polygon = shape.polygon
		var flipped_polygon = PackedVector2Array()
		for point in polygon:
			flipped_polygon.append(Vector2(-point.x, point.y))
		shape.polygon = flipped_polygon

func activate_hitbox(hitbox_index: int = 0, damage: int = 10, duration: float = 0.1) -> void:
	"""Activate a specific hitbox for a duration"""
	if hitbox_index >= 0 and hitbox_index < hitboxes.size():
		var hitbox = hitboxes[hitbox_index]
		hitbox.set("damage", damage)
		hitbox.set_deferred("monitoring", true)
		
		# Disable collision shape
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", false)
		
		# Auto-disable after duration
		if duration > 0:
			await get_tree().create_timer(duration).timeout
			deactivate_hitbox(hitbox_index)

func deactivate_hitbox(hitbox_index: int = 0) -> void:
	"""Deactivate a specific hitbox"""
	if hitbox_index >= 0 and hitbox_index < hitboxes.size():
		var hitbox = hitboxes[hitbox_index]
		hitbox.set_deferred("monitoring", false)
		
		# Disable collision shape
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)

func deactivate_all_hitboxes() -> void:
	"""Deactivate all hitboxes"""
	for i in range(hitboxes.size()):
		deactivate_hitbox(i)

func take_damage(damage: int, attacker: Node = null, knockback_force: Vector2 = Vector2.ZERO) -> void:
	"""Take damage from an attack"""
	if is_invincible or current_health <= 0:
		return
	
	# Calculate final damage
	var final_damage = max(1, damage - base_defense)
	current_health = max(0, current_health - final_damage)
	
	# Emit signals
	damage_taken.emit(final_damage, attacker)
	health_changed.emit(current_health, max_health)
	
	# Apply knockback
	if knockback_force != Vector2.ZERO:
		apply_knockback(knockback_force)
	
	# Start invincibility frames
	if invincibility_duration > 0:
		start_invincibility(invincibility_duration)
	
	# Check for death
	if current_health <= 0:
		health_depleted.emit()
		on_death()

func apply_knockback(force: Vector2) -> void:
	"""Apply knockback force to the entity"""
	var adjusted_force = force * (1.0 - knockback_resistance)
	velocity += adjusted_force

func start_invincibility(duration: float) -> void:
	"""Start invincibility frames"""
	is_invincible = true
	invincibility_timer = duration
	_set_hurtboxes_enabled(false)
	
	# Visual feedback - make sprite blink
	if sprite_node:
		_blink_sprite(duration)

func _blink_sprite(duration: float) -> void:
	"""Make the sprite blink during invincibility"""
	var blink_count = int(duration / 0.1)
	for i in range(blink_count):
		if sprite_node:
			sprite_node.modulate.a = 0.5
			await get_tree().create_timer(0.05).timeout
			sprite_node.modulate.a = 1.0
			await get_tree().create_timer(0.05).timeout

func _set_hurtboxes_enabled(enabled: bool) -> void:
	"""Enable or disable all hurtboxes"""
	for hurtbox in hurtboxes:
		hurtbox.set_deferred("monitoring", enabled)
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", not enabled)

func _on_hurtbox_area_entered(area: Area2D, hurtbox: Area2D) -> void:
	"""Handle when a hitbox enters our hurtbox"""
	if area.is_in_group("HitBox") and area.get_parent() != self:
		# Get damage from the hitbox
		var damage = 10  # Default damage
		if area.has_method("get_damage"):
			damage = area.get_damage()
		elif "damage" in area:
			damage = area.get("damage")
		
		# Calculate knockback direction
		var attacker = area.get_parent()
		var knockback = Vector2.ZERO
		if attacker and attacker is Node2D:
			var direction = global_position - attacker.global_position
			knockback = direction.normalized() * 200  # Base knockback force
		
		# Take damage
		take_damage(damage, attacker, knockback)
		
		# Notify attacker of successful hit
		if attacker and attacker.has_method("on_hit_landed"):
			attacker.on_hit_landed(self, damage)

func on_hit_landed(target: Node, damage: int) -> void:
	"""Called when this entity successfully hits another"""
	hit_landed.emit(target, damage)

func heal(amount: int) -> void:
	"""Heal the entity"""
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func on_death() -> void:
	"""Override this method for death behavior"""
	pass

func reset_health() -> void:
	"""Reset health to maximum"""
	current_health = max_health
	health_changed.emit(current_health, max_health)
