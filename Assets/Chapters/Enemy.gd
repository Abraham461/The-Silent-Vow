extends "res://Assets/Combat/EnemyCombat.gd"
#
## This script now extends EnemyCombat which provides all combat functionality
## You can override or extend any methods here for custom enemy behavior
#
## Additional enemy-specific properties
#@export var special_attack_chance: float = 0.2
#@export var enrage_threshold: float = 0.3  # Enrage when health below 30%
#
#func _ready() -> void:
	#super._ready()
	#
	## Set enemy-specific properties
	#max_health = 100
	#current_health = 100
	#
	## Enemy-specific initialization
	#print("Enemy combat system initialized")
#
#func _physics_process(delta: float) -> void:
	#super._physics_process(delta)
	#
	## Check for enrage state
	#if not is_enraged and current_health > 0:
		#var health_percentage = float(current_health) / float(max_health)
		#if health_percentage <= enrage_threshold:
			#enter_enrage_mode()
#
#func enter_enrage_mode() -> void:
	#"""Enter enraged state when health is low"""
	#is_enraged = true
	#
	## Increase stats when enraged
	#move_speed *= 1.8
	#attack_damage = int(attack_damage * 1.5)
	#attack_cooldown *= 0.7
	#animation_speed = 1.3
	#
	## Visual feedback for enrage
	#if sprite:
		#sprite.modulate = Color(1.5, 0.8, 0.8)
	#
	## Update animation speed
	#if sprite:
		#sprite.speed_scale = animation_speed
	#if animation_player:
		#animation_player.speed_scale = animation_speed
	#
	#print("Enemy entered enrage mode!")
#
#func start_attack():
	#"""Override to add special attack chance"""
	#if randf() < special_attack_chance and is_enraged:
		#perform_special_attack()
	#elif randf() < ranged_attack_chance:
		#perform_ranged_attack()
	#else:
		#super.start_attack()
#
#func perform_special_attack() -> void:
	#"""Perform a special attack when enraged"""
	#if attack_locked or current_state == EnemyState.ATTACK:
		#return
	#
	#attack_locked = true
	#change_state(EnemyState.ATTACK)
	#
	## Special attack - area slam
	#if sprite:
		#sprite.play("NightBorneAtk")
	#elif animation_player:
		#animation_player.play("NightBorneAtk")
	#
	## Windup with telegraph
	#if sprite:
		#sprite.modulate = Color(2, 1, 1)  # Red flash warning
	#
	#await get_tree().create_timer(0.5).timeout
	#
	#if sprite:
		#sprite.modulate = Color(1.5, 0.8, 0.8) if is_enraged else Color.WHITE
	#
	## Create shockwave effect
	#for i in range(3):
		#if not hitboxes.is_empty():
			#var hitbox = hitboxes[0] as CombatHitBox
			#if hitbox:
				## Expanding shockwave
				#var original_scale = hitbox.scale
				#hitbox.scale = Vector2(1 + i, 1 + i)
				#hitbox.set_attack_properties(attack_damage * 2, 400, "special")
				#hitbox.activate(attack_damage * 2, 0.1)
				#
				## Visual effect
				#if combat_effects:
					#combat_effects.create_hit_spark(global_position + Vector2(i * 30, 0), Color.RED)
					#combat_effects.create_hit_spark(global_position - Vector2(i * 30, 0), Color.RED)
				#
				#await get_tree().create_timer(0.1).timeout
				#hitbox.scale = original_scale
	#
	## Recovery
	#await get_tree().create_timer(0.5).timeout
	#
	#attack_locked = false
	#cooldown_timer = attack_cooldown * 1.5  # Longer cooldown for special
	#
	#if player_target and _distance_to_player() <= deaggro_radius:
		#change_state(EnemyState.CHASE)
	#else:
		#change_state(EnemyState.IDLE)
#
#func perform_ranged_attack() -> void:
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
#func on_death():
	#"""Override death behavior to drop items or give rewards"""
	#super.on_death()
	#
	## Drop items or give experience
	#print("Enemy defeated! Dropping loot...")
	#
	## You can spawn item pickups here
	## Example: spawn_loot()
