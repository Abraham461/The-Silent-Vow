extends "res://Assets/Combat/PlayerCombat.gd"
# This script now extends PlayerCombat which provides all combat functionality
# You can override or extend any methods here for custom behavior

# Additional player-specific properties can be added here
@export var special_ability_cooldown: float = 5.0
var special_ability_timer: float = 0.0

func _ready():
	super._ready()
	
	# Any additional player-specific initialization
	print("Player combat system initialized")

func _physics_process(delta):
	super._physics_process(delta)
	
	# Update special ability timer
	if special_ability_timer > 0:
		special_ability_timer -= delta
	
	# Check for special ability input
	if Input.is_action_just_pressed("special_ability") and special_ability_timer <= 0:
		perform_special_ability()
	
	# Check for ranged attack input
	if Input.is_action_just_pressed("RangedAtk") and ranged_attack_timer <= 0:
		perform_ranged_attack()

func perform_special_ability():
	"""Execute a special ability"""
	if current_state != PlayerState.IDLE and current_state != PlayerState.RUN:
		return
	
	special_ability_timer = special_ability_cooldown
	
	# Create a powerful area attack
	if not hitboxes.is_empty():
		var hitbox = hitboxes[0] as CombatHitBox
		if hitbox:
			# Special ability does high damage in a larger area
			hitbox.set_attack_properties(50, 400, "special")
			
			# Temporarily increase hitbox size
			var original_scale = hitbox.scale
			hitbox.scale = Vector2(2, 2)
			
			# Activate for longer duration
			hitbox.activate(50, 0.5)
			
			# Visual effect
			if combat_effects:
				combat_effects.create_hit_spark(global_position, Color.CYAN)
				combat_effects.shake_screen(2.0)
			
			# Reset scale after attack
			await get_tree().create_timer(0.5).timeout
			hitbox.scale = original_scale
	
	# Play special animation if available
	if animation_player and animation_player.has_animation("Special"):
		animation_player.play("Special")

func perform_ranged_attack():
	"""Fire a projectile in the direction the player is facing"""
	if ranged_attack_timer > 0:
		return
	
	# Set cooldown
	ranged_attack_timer = ranged_attack_cooldown
	
	# Determine direction
	var direction = Vector2.LEFT if facing_left else Vector2.RIGHT
	
	# Fire projectile
	if projectile_scene:
		var projectile = fire_projectile(projectile_scene, direction, 300, 15)
		if projectile:
			# Visual effect
			if combat_effects:
				combat_effects.create_hit_spark(global_position + Vector2(0, -10), Color.BLUE)
