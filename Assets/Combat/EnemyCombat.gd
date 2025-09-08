#class_name EnemyCombat
#extends CombatEntity
#
## Enemy states
#enum EnemyState { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD, BOSS_PHASE }
#var current_state: EnemyState = EnemyState.IDLE
#
## Movement properties
#@export var move_speed: float = 200.0
#@export var patrol_speed: float = 50.0
#@export var gravity: float = 900.0
#
## AI properties
#@export var aggro_radius: float = 260.0
#@export var deaggro_radius: float = 400.0
#@export var attack_range: float = 60.0
#@export var patrol_distance: float = 100.0
#
## Combat properties
#@export var attack_cooldown: float = 1.0
#@export var attack_damage: int = 10
#@export var attack_windup: float = 0.5
#@export var attack_active: float = 0.2
#@export var attack_recovery: float = 0.3
#@export var dash_speed: float = 360.0
#
## Animation speed
#@export var animation_speed: float = 1.0
#@export var attack_interrupt_chance: float = 0.35
#
## Node references
#@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
#@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
#@onready var health_component: HealthComponent = $HealthComponent if has_node("HealthComponent") else null
#@onready var combat_effects: CombatEffects = $CombatEffects if has_node("CombatEffects") else null
#@onready var detection_area: Area2D = $DetectionArea if has_node("DetectionArea") else null
#
## Internal state
#var player_target: Node2D = null
#var cooldown_timer: float = 0.0
#var is_activated: bool = false
#var attack_locked: bool = false
#var attack_cancelled: bool = false
#var patrol_origin: Vector2
#var patrol_direction: int = 1
#var hurt_timer: float = 0.0
#
## Additional enemy-specific properties
#@export var ranged_attack_chance: float = 0.1  # Chance to use ranged attack
#@export var projectile_scene: PackedScene = preload("res://Assets/Combat/Projectile.tscn")
#var is_enraged: bool = false
#
## Attack patterns
#var current_attack_pattern: int = 0
#const ATTACK_PATTERNS = ["light", "heavy", "thrust"]
#
#func _ready():
	#super._ready()
	#
	## Add to enemy group
	#add_to_group("enemies")
	#
	## Set initial health
	#max_health = 100
	#current_health = 100
	#
	## Store patrol origin
	#patrol_origin = global_position
	#
	## Connect health signals
	#if health_component:
		#health_component.health_depleted.connect(_on_health_depleted)
		#health_component.damage_taken.connect(_on_damage_taken)
	#
	## Setup detection area
	#_setup_detection_area()
	#
	## Ensure combat components
	#_ensure_combat_components()
	#
	## Apply animation speed
	#if sprite:
		#sprite.speed_scale = animation_speed
	#if animation_player:
		#animation_player.speed_scale = animation_speed
	#
	## Find player
	#player_target = _find_player()
#
#func _ensure_combat_components():
	#"""Ensure enemy has necessary combat components"""
	## Create HitBox if missing
	#if hitboxes.is_empty():
		#var hitbox = CombatHitBox.new()
		#hitbox.name = "HitBox"
		#hitbox.position = Vector2(20, 0)
		#hitbox.base_damage = attack_damage
		#add_child(hitbox)
		#
		#var shape = CollisionShape2D.new()
		#var rect = RectangleShape2D.new()
		#rect.size = Vector2(30, 40)
		#shape.shape = rect
		#hitbox.add_child(shape)
		#
		#hitboxes.append(hitbox)
	#
	## Create HurtBox if missing
	#if hurtboxes.is_empty():
		#var hurtbox = CombatHurtBox.new()
		#hurtbox.name = "HurtBox"
		#add_child(hurtbox)
		#
		#var shape = CollisionShape2D.new()
		#var rect = RectangleShape2D.new()
		#rect.size = Vector2(20, 30)
		#shape.shape = rect
		#shape.position = Vector2(0, -5)
		#hurtbox.add_child(shape)
		#
		#hurtboxes.append(hurtbox)
	#
	## Create HealthComponent if missing
	#if not health_component:
		#health_component = HealthComponent.new()
		#health_component.name = "HealthComponent"
		#health_component.max_health = max_health
		#health_component.current_health = current_health
		#add_child(health_component)
	#
	## Create CombatEffects if missing
	#if not combat_effects:
		#combat_effects = CombatEffects.new()
		#combat_effects.name = "CombatEffects"
		#add_child(combat_effects)
#
#func _setup_detection_area():
	#"""Setup detection area for player detection"""
	#if not detection_area:
		#detection_area = Area2D.new()
		#detection_area.name = "DetectionArea"
		#add_child(detection_area)
		#
		#var shape = CollisionShape2D.new()
		#var circle = CircleShape2D.new()
		#circle.radius = aggro_radius
		#shape.shape = circle
		#detection_area.add_child(shape)
	#
	## Connect detection signals
	#if not detection_area.body_entered.is_connected(_on_detection_body_entered):
		#detection_area.body_entered.connect(_on_detection_body_entered)
#
#func _physics_process(delta: float):
	#if current_state == EnemyState.DEAD:
		#velocity = Vector2.ZERO
		#move_and_slide()
		#return
	#
	## Call parent physics process
	#super._physics_process(delta)
	#
	## Apply gravity
	#if not is_on_floor():
		#velocity.y += gravity * delta
	#else:
		#velocity.y = 0
	#
	## Update cooldown
	#if cooldown_timer > 0:
		#cooldown_timer -= delta
	#
	## Update hurt timer
	#if hurt_timer > 0:
		#hurt_timer -= delta
		#if hurt_timer <= 0 and current_state == EnemyState.HURT:
			#_exit_hurt_state()
	#
	## Find player if needed
	#if not player_target or not is_instance_valid(player_target):
		#player_target = _find_player()
	#
	## State machine
	#match current_state:
		#EnemyState.IDLE:
			#handle_idle_state()
		#EnemyState.PATROL:
			#handle_patrol_state()
		#EnemyState.CHASE:
			#handle_chase_state()
		#EnemyState.ATTACK:
			#handle_attack_state()
		#EnemyState.HURT:
			#handle_hurt_state()
		#EnemyState.BOSS_PHASE:
			#handle_boss_phase()
	#
	#move_and_slide()
	#update_animation()
#
#func handle_idle_state():
	#velocity.x = 0
	#
	#if not is_activated:
		#return
	#
	## Check for player
	#if player_target and _distance_to_player() <= aggro_radius:
		#change_state(EnemyState.CHASE)
	#else:
		## Start patrolling after a moment
		#await get_tree().create_timer(2.0).timeout
		#if current_state == EnemyState.IDLE:
			#change_state(EnemyState.PATROL)
#
#func handle_patrol_state():
	## Patrol back and forth
	#var distance_from_origin = abs(global_position.x - patrol_origin.x)
	#
	#if distance_from_origin >= patrol_distance:
		#patrol_direction *= -1
		#set_facing_direction(patrol_direction < 0)
	#
	#velocity.x = patrol_direction * patrol_speed
	#
	## Check for player
	#if player_target and _distance_to_player() <= aggro_radius:
		#change_state(EnemyState.CHASE)
#
#func handle_chase_state():
	#if not player_target:
		#change_state(EnemyState.IDLE)
		#return
	#
	#var dist = _distance_to_player()
	#
	## Check if player is out of range
	#if dist > deaggro_radius:
		#change_state(EnemyState.PATROL)
		#return
	#
	## Check if in attack range
	#if dist <= attack_range and cooldown_timer <= 0:
		#start_attack()
		#return
	#
	## Chase player
	#var direction = sign(player_target.global_position.x - global_position.x)
	#if direction != 0:
		#set_facing_direction(direction < 0)
		#velocity.x = move_toward(velocity.x, direction * move_speed, move_speed * 0.25)
#
#func handle_attack_state():
	## Attack motion handled in start_attack()
	#velocity.x = 0
#
#func handle_hurt_state():
	#velocity.x = move_toward(velocity.x, 0, 600 * get_physics_process_delta_time())
#
#func handle_boss_phase():
	## Boss pattern logic
	#pass
#
#func start_attack():
	#if attack_locked or current_state == EnemyState.ATTACK:
		#return
	#
	## Check if we should use a ranged attack
	#if randf() < ranged_attack_chance and projectile_scene and player_target:
		#start_ranged_attack()
		#return
	#
	#attack_locked = true
	#attack_cancelled = false
	#change_state(EnemyState.ATTACK)
	#
	## Choose attack pattern based on distance
	#var dist = _distance_to_player() if player_target else attack_range
	#if dist < attack_range * 0.6:
		#current_attack_pattern = randi() % 2  # Light or heavy
	#else:
		#current_attack_pattern = 2  # Thrust
	#
	## Execute attack
	#_execute_attack_pattern()
#
#func start_ranged_attack():
	#"""Fire a projectile at the player"""
	#if not player_target or not projectile_scene:
		#return
	#
	## Calculate direction to player
	#var direction = (player_target.global_position - global_position).normalized()
	#
	## Fire projectile
	#var projectile = fire_projectile(projectile_scene, direction, 200, attack_damage)
	#if projectile:
		## Visual effect
		#if combat_effects:
			#combat_effects.create_hit_spark(global_position, Color.MAGENTA)
	#
	## Set cooldown
	#cooldown_timer = attack_cooldown * 2  # Ranged attacks have longer cooldown
#
#func _execute_attack_pattern():
	#velocity.x = 0
	#
	## Play attack animation
	#if sprite:
		#sprite.play("NightBorneAtk")
	#elif animation_player:
		#animation_player.play("NightBorneAtk")
	#
	## Windup
	#await get_tree().create_timer(attack_windup).timeout
	#if attack_cancelled:
		#_handle_attack_interruption()
		#return
	#
	## Activate hitbox
	#if not hitboxes.is_empty():
		#var hitbox = hitboxes[0] as CombatHitBox
		#if hitbox:
			#var damage = attack_damage
			#var knockback = 200.0
			#
			## Modify based on pattern
			#match current_attack_pattern:
				#1:  # Heavy
					#damage = int(damage * 1.5)
					#knockback = 300.0
				#2:  # Thrust
					#damage = int(damage * 1.2)
					#knockback = 250.0
					## Add dash
					#velocity.x = (dash_speed if not facing_left else -dash_speed)
			#
			#hitbox.set_attack_properties(damage, knockback, ATTACK_PATTERNS[current_attack_pattern])
			#hitbox.activate(damage, attack_active)
	#
	## Active frames
	#await get_tree().create_timer(attack_active).timeout
	#if attack_cancelled:
		#deactivate_all_hitboxes()
		#_handle_attack_interruption()
		#return
	#
	## Deactivate hitbox
	#deactivate_all_hitboxes()
	#velocity.x = 0
	#
	## Recovery
	#await get_tree().create_timer(attack_recovery).timeout
	#if attack_cancelled:
		#_handle_attack_interruption()
		#return
	#
	## Attack complete
	#attack_locked = false
	#cooldown_timer = attack_cooldown
	#
	## Return to chase or idle
	#if player_target and _distance_to_player() <= deaggro_radius:
		#change_state(EnemyState.CHASE)
	#else:
		#change_state(EnemyState.IDLE)
#
#func _handle_attack_interruption():
	#attack_locked = false
	#attack_cancelled = false
	#deactivate_all_hitboxes()
	#velocity.x = 0
	#change_state(EnemyState.HURT)
	#
	#if sprite:
		#sprite.play("NightBorneTakeHit")
	#elif animation_player:
		#animation_player.play("NightBorneTakeHit")
#
#func take_damage(damage: int, attacker: Node = null, knockback_force: Vector2 = Vector2.ZERO):
	#if current_state == EnemyState.DEAD:
		#return
	#
	## Check for attack interruption
	#if attack_locked and randf() < attack_interrupt_chance:
		#attack_cancelled = true
	#
	## Call parent take_damage
	#super.take_damage(damage, attacker, knockback_force)
	#
	## Enter hurt state if not attacking or if interrupted
	#if current_health > 0 and (not attack_locked or attack_cancelled):
		#change_state(EnemyState.HURT)
		#hurt_timer = 0.3
		#
		## Visual feedback
		#if combat_effects:
			#combat_effects.play_hit_effect(damage, global_position)
#
#func _exit_hurt_state():
	#if current_state != EnemyState.HURT:
		#return
	#
	## Return to appropriate state
	#if player_target and _distance_to_player() <= deaggro_radius:
		#change_state(EnemyState.CHASE)
	#else:
		#change_state(EnemyState.IDLE)
#
#func change_state(new_state: EnemyState):
	#if current_state == EnemyState.DEAD:
		#return
	#
	## Don't interrupt boss phase unless dying
	#if current_state == EnemyState.BOSS_PHASE and new_state != EnemyState.DEAD:
		#return
	#
	## Don't interrupt attack unless forced or dying
	#if current_state == EnemyState.ATTACK and not attack_cancelled and new_state != EnemyState.DEAD:
		#return
	#
	#current_state = new_state
	#
	## Reset velocity for certain states
	#if new_state in [EnemyState.IDLE, EnemyState.HURT, EnemyState.DEAD]:
		#velocity.x = 0
#
#func update_animation():
	#if not sprite and not animation_player:
		#return
	#
	#match current_state:
		#EnemyState.IDLE:
			#if sprite and sprite.animation != "NightBorneIdle":
				#sprite.play("NightBorneIdle")
			#elif animation_player and animation_player.current_animation != "NightBorneIdle":
				#animation_player.play("NightBorneIdle")
		#
		#EnemyState.PATROL, EnemyState.CHASE:
			#if abs(velocity.x) > 5:
				#if sprite and sprite.animation != "NightBorneRun":
					#sprite.play("NightBorneRun")
				#elif animation_player and animation_player.current_animation != "NightBorneRun":
					#animation_player.play("NightBorneRun")
			#else:
				#if sprite and sprite.animation != "NightBorneIdle":
					#sprite.play("NightBorneIdle")
				#elif animation_player and animation_player.current_animation != "NightBorneIdle":
					#animation_player.play("NightBorneIdle")
		#
		#EnemyState.HURT:
			#if sprite and sprite.animation != "NightBorneTakeHit":
				#sprite.play("NightBorneTakeHit")
			#elif animation_player and animation_player.current_animation != "NightBorneTakeHit":
				#animation_player.play("NightBorneTakeHit")
		#
		#EnemyState.DEAD:
			#if sprite and sprite.animation != "NightBorneDeath":
				#sprite.play("NightBorneDeath")
			#elif animation_player and animation_player.current_animation != "NightBorneDeath":
				#animation_player.play("NightBorneDeath")
#
#func _on_detection_body_entered(body: Node2D):
	#if body.is_in_group("player"):
		#is_activated = true
		#player_target = body
#
#func _on_health_depleted():
	#change_state(EnemyState.DEAD)
	#deactivate_all_hitboxes()
	#
	## Play death effect
	#if combat_effects:
		#combat_effects.play_death_effect()
	#
	## Remove after animation
	#await get_tree().create_timer(1.0).timeout
	#queue_free()
#
#func _on_damage_taken(amount: int):
	## Flash effect or other visual feedback
	#pass
#
#func _distance_to_player() -> float:
	#if not player_target:
		#return INF
	#return global_position.distance_to(player_target.global_position)
#
#func _find_player() -> Node2D:
	#var players = get_tree().get_nodes_in_group("player")
	#if players.size() > 0:
		#return players[0] as Node2D
	#return null
#
#func on_hit_landed(target: Node, damage: int):
	#"""Called when enemy successfully hits the player"""
	#super.on_hit_landed(target, damage)
	#
	## Play hit effect
	#if combat_effects and target is Node2D:
		#combat_effects.create_hit_spark(target.global_position, Color.RED)
#
#func on_death():
	#"""Override death behavior"""
	#change_state(EnemyState.DEAD)
#
#func start_boss_pattern():
	#"""Start a boss attack pattern"""
	#if current_state == EnemyState.DEAD:
		#return
	#
	#change_state(EnemyState.BOSS_PHASE)
	## Implement boss patterns here
