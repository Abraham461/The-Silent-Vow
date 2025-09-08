class_name CombatHitBox
extends Area2D



@export var damage: int = 1 : set = set_damage, get = get_damage

func set_damage(value: int):
	damage = value
	
	
func get_damage() -> int:
	return damage
































#
## Signals
#signal hit_confirmed(target: Node, damage: int)
#
## Combat properties
#@export var base_damage: int = 10
#@export var knockback_force: float = 200.0
#@export var attack_type: String = "normal"  # normal, heavy, special
#@export var critical_chance: float = 0.1  # 10% chance
#@export var critical_multiplier: float = 1.5
#@export var team: int = 0  # Team this hitbox belongs to
#
## Active frame management
#@export var auto_disable: bool = true
#@export var active_duration: float = 0.1
#
## Internal state
#var is_active: bool = false
#var has_hit_targets: Array = []  # Track what we've already hit this activation
#
#func _ready() -> void:
	#add_to_group("HitBox")
	#monitoring = false
	#monitorable = true
	#
	## Connect to area entered signal
	#if not area_entered.is_connected(_on_area_entered):
		#area_entered.connect(_on_area_entered)
	#
	## Disable collision shapes by default
	#for child in get_children():
		#if child is CollisionShape2D or child is CollisionPolygon2D:
			#child.disabled = true
#
#func activate(damage_override: int = -1, duration_override: float = -1) -> void:
	#"""Activate the hitbox with optional parameter overrides"""
	#if is_active:
		#return
	#
	#is_active = true
	#has_hit_targets.clear()
	#
	## Apply damage override if provided
	#if damage_override > 0:
		#base_damage = damage_override
	#
	## Enable monitoring
	#set_deferred("monitoring", true)
	#
	## Enable collision shapes
	#for child in get_children():
		#if child is CollisionShape2D or child is CollisionPolygon2D:
			#child.set_deferred("disabled", false)
	#
	## Auto-disable after duration
	#if auto_disable:
		#var duration = duration_override if duration_override > 0 else active_duration
		#await get_tree().create_timer(duration).timeout
		#deactivate()
#
#func deactivate() -> void:
	#"""Deactivate the hitbox"""
	#is_active = false
	#has_hit_targets.clear()
	#
	## Disable monitoring
	#set_deferred("monitoring", false)
	#
	## Disable collision shapes
	#for child in get_children():
		#if child is CollisionShape2D or child is CollisionPolygon2D:
			#child.set_deferred("disabled", true)
#
#func get_damage() -> int:
	#"""Calculate and return the damage for this hit"""
	#var damage = base_damage
	#
	## Apply critical hit
	#if randf() < critical_chance:
		#damage = int(damage * critical_multiplier)
	#
	#return damage
#
#func get_knockback_vector(from_position: Vector2, to_position: Vector2) -> Vector2:
	#"""Calculate knockback vector from attacker to target"""
	#var direction = (to_position - from_position).normalized()
	#return direction * knockback_force
#
#func _on_area_entered(area: Area2D) -> void:
	#"""Handle collision with hurtboxes"""
	## Only process hurtboxes
	#if not area.is_in_group("HurtBox"):
		#return
	#
	## Don't hit the same target twice in one activation
	#var target = area.get_parent()
	#if target in has_hit_targets:
		#return
	#
	## Don't hit ourselves
	#if target == get_parent():
		#return
	#
	## Check team-based combat - don't hit same team
	#var target_entity = target as CombatEntity
	#if target_entity and target_entity.get_team() == team:
		#return
	#
	## Mark target as hit
	#has_hit_targets.append(target)
	#
	## Calculate damage
	#var damage = get_damage()
	#
	## Calculate knockback
	#var knockback = Vector2.ZERO
	#if target and target is Node2D:
		#knockback = get_knockback_vector(global_position, target.global_position)
	#
	## Apply damage to target
	#if target and target.has_method("take_damage"):
		#target.take_damage(damage, get_parent(), knockback)
	#
	## Emit hit confirmation
	#hit_confirmed.emit(target, damage)
	#
	## Notify parent of successful hit
	#var parent = get_parent()
	#if parent and parent.has_method("on_hit_landed"):
		#parent.on_hit_landed(target, damage)
#
#func set_attack_properties(damage: int, knockback: float, type: String = "normal") -> void:
	#"""Set attack properties for this activation"""
	#base_damage = damage
	#knockback_force = knockback
	#attack_type = type
#
#func flip_horizontal() -> void:
	#"""Flip the hitbox horizontally (called by parent entity)"""
	#position.x = -position.x
	#
	## Flip collision shapes
	#for child in get_children():
		#if child is CollisionShape2D or child is CollisionPolygon2D:
			#child.position.x = -child.position.x
			#
			## If it's a polygon, flip the points
			#if child is CollisionPolygon2D:
				#var polygon = child.polygon
				#var flipped_polygon = PackedVector2Array()
				#for point in polygon:
					#flipped_polygon.append(Vector2(-point.x, point.y))
				#child.polygon = flipped_polygon
