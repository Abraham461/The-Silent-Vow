class_name PlayerCombat
extends CombatEntity

# Movement
const RUN_SPEED = 210.0
const GRAVITY = 900.0
const JUMP_FORCE = -400.0
const ROLL_SPEED = 300.0
const ROLL_DURATION = 0.4

# Combat
const ATTACK_COOLDOWN = 0.5
const COMBO_MAX_TIME = 0.5
const COMBO_ATTACK_DELAY = 0.15

# State Machine
enum PlayerState { IDLE, RUN, ATTACK, HURT, DEAD, JUMP, FALL, ROLL, PRAY }
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

# Combat state
var is_attacking = false
var attack_timer = 0.0
var combo_step = 0
var combo_timer = 0.0
var queued_next_attack = false
var attack_delay_timer = 0.0

# Movement state
var is_rolling = false
var roll_timer = 0.0
var roll_cooldown_timer = 0.0
var is_jumping = false
var has_jumped_attack = false

# Health state
var is_hurt = false
var hurt_timer = 0.0
const HURT_DURATION = 0.3

# Ranged attack properties
@export var ranged_attack_cooldown: float = 1.0
@export var projectile_scene: PackedScene = preload("res://Assets/Combat/Projectile.tscn")
var ranged_attack_timer: float = 0.0

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var health_component: HealthComponent = $HealthComponent if has_node("HealthComponent") else null
@onready var combat_effects: CombatEffects = $CombatEffects if has_node("CombatEffects") else null

# Attack damage values for combos
const COMBO_DAMAGES = [15, 18, 22, 30]  # Increasing damage for combo hits

func _ready():
	super._ready()
	
	# Add to player group
	add_to_group("player")
	
	# Set initial health
	max_health = 100
	current_health = 100
	
	# Connect animation signals
	if animation_player:
		animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	# Connect health signals
	if health_component:
		health_component.health_depleted.connect(_on_health_depleted)
		health_component.damage_taken.connect(_on_damage_taken)
	
	# Initialize state
	change_state(PlayerState.IDLE)
	
	# Ensure we have combat components
	_ensure_combat_components()

func _ensure_combat_components():
	"""Ensure player has necessary combat components"""
	# Create HitBox if missing
	if hitboxes.is_empty():
		var hitbox = CombatHitBox.new()
		hitbox.name = "HitBox"
		hitbox.position = Vector2(20, 0)
		add_child(hitbox)
		
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(30, 40)
		shape.shape = rect
		hitbox.add_child(shape)
		
		hitboxes.append(hitbox)
	
	# Create HurtBox if missing
	if hurtboxes.is_empty():
		var hurtbox = CombatHurtBox.new()
		hurtbox.name = "HurtBox"
		add_child(hurtbox)
		
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 30)
		shape.shape = rect
		shape.position = Vector2(0, -5)
		hurtbox.add_child(shape)
		
		hurtboxes.append(hurtbox)
	
	# Create HealthComponent if missing
	if not health_component:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		health_component.max_health = max_health
		health_component.current_health = current_health
		add_child(health_component)
	
	# Create CombatEffects if missing
	if not combat_effects:
		combat_effects = CombatEffects.new()
		combat_effects.name = "CombatEffects"
		add_child(combat_effects)

func _physics_process(delta):
	if current_state == PlayerState.DEAD:
		handle_death()
		move_and_slide()
		return
	
	# Call parent physics process
	super._physics_process(delta)
	
	update_timers(delta)
	handle_input()
	
	if is_rolling:
		handle_roll()
	else:
		if not is_state_locked():
			handle_movement()
		apply_gravity(delta)
	
	move_and_slide()
	update_animation()
	
	# Handle combo timeout
	if combo_step > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()

func update_timers(delta):
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
	
	if is_hurt:
		hurt_timer -= delta
		if hurt_timer <= 0:
			is_hurt = false
			change_state(previous_state)
	
	if attack_delay_timer > 0:
		attack_delay_timer -= delta
	
	if roll_timer > 0:
		roll_timer -= delta
		if roll_timer <= 0:
			is_rolling = false
			is_invincible = false
			_set_hurtboxes_enabled(true)
			change_state(PlayerState.IDLE)
	
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
	
	# Update ranged attack timer
	if ranged_attack_timer > 0:
		ranged_attack_timer -= delta

func handle_input():
	# Update facing direction based on input
	var input_dir = Input.get_axis("left", "right")
	if input_dir != 0 and not is_state_locked():
		set_facing_direction(input_dir < 0)
	
	# Roll
	if Input.is_action_just_pressed("Roll") and not is_state_locked() and roll_cooldown_timer <= 0:
		start_roll()
	
	# Pray
	if Input.is_action_just_pressed("Pray") and not is_state_locked():
		start_pray()
	
	# Attack
	if Input.is_action_just_pressed("Atk") and not is_state_locked():
		if not is_on_floor():
			if not has_jumped_attack:
				start_jump_attack()
		else:
			if is_attacking:
				queued_next_attack = true
			else:
				start_combo_attack()
	
	# Ranged Attack
	if Input.is_action_just_pressed("RangedAtk") and not is_state_locked() and ranged_attack_timer <= 0:
		start_ranged_attack()
	
	# Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_state_locked():
		is_jumping = true
		velocity.y = JUMP_FORCE
		change_state(PlayerState.JUMP)
		if animation_player:
			animation_player.play("Jump")

func handle_movement():
	var direction := Input.get_axis("left", "right")
	velocity.x = direction * RUN_SPEED
	
	if is_jumping:
		change_state(PlayerState.JUMP)
	elif direction == 0:
		change_state(PlayerState.IDLE)
	else:
		change_state(PlayerState.RUN)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if velocity.y > 0 and current_state != PlayerState.FALL:
			change_state(PlayerState.FALL)
	else:
		if current_state in [PlayerState.JUMP, PlayerState.FALL]:
			is_jumping = false
			has_jumped_attack = false
			change_state(PlayerState.IDLE)
			velocity.y = 0

func handle_death():
	velocity = Vector2.ZERO
	if animation_player and animation_player.current_animation != "Dead":
		animation_player.play("Dead")

func start_combo_attack():
	if attack_delay_timer > 0:
		return
	
	combo_step += 1
	if combo_step > 4:
		combo_step = 1
	
	combo_timer = COMBO_MAX_TIME
	is_attacking = true
	attack_timer = ATTACK_COOLDOWN
	attack_delay_timer = COMBO_ATTACK_DELAY
	change_state(PlayerState.ATTACK)
	
	# Set damage based on combo step
	var damage = COMBO_DAMAGES[min(combo_step - 1, COMBO_DAMAGES.size() - 1)]
	
	# Activate hitbox with appropriate damage
	if not hitboxes.is_empty():
		var hitbox = hitboxes[0] as CombatHitBox
		if hitbox:
			hitbox.set_attack_properties(damage, 200 + combo_step * 50, "normal")
			# Delay activation to match animation
			await get_tree().create_timer(0.1).timeout
			hitbox.activate(damage, 0.2)
	
	# Play animation
	if animation_player:
		match combo_step:
			1: animation_player.play("NormalAtk1")
			2: animation_player.play("NormalAtk2")
			3: animation_player.play("NormalAtk3")
			4: animation_player.play("NormalAtk4")

func start_jump_attack():
	is_attacking = true
	has_jumped_attack = true
	attack_timer = ATTACK_COOLDOWN
	attack_delay_timer = COMBO_ATTACK_DELAY
	change_state(PlayerState.ATTACK)
	
	# Activate hitbox for jump attack
	if not hitboxes.is_empty():
		var hitbox = hitboxes[0] as CombatHitBox
		if hitbox:
			hitbox.set_attack_properties(25, 300, "aerial")
			hitbox.activate(25, 0.3)
	
	if animation_player:
		animation_player.play("JumpAtk")

func start_roll():
	is_rolling = true
	roll_timer = ROLL_DURATION
	roll_cooldown_timer = 1.5
	change_state(PlayerState.ROLL)
	
	# Grant invincibility during roll
	is_invincible = true
	_set_hurtboxes_enabled(false)
	
	if animation_player:
		animation_player.play("Roll")
	
	var direction = -1 if facing_left else 1
	velocity.x = direction * ROLL_SPEED
	velocity.y = 0

func start_pray():
	change_state(PlayerState.PRAY)
	if animation_player:
		animation_player.play("Pray")

func start_ranged_attack():
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

func handle_roll():
	# Roll motion is set in start_roll
	pass

func reset_combo():
	combo_step = 0
	combo_timer = 0.0
	queued_next_attack = false
	is_attacking = false
	deactivate_all_hitboxes()
	if not is_hurt and is_on_floor():
		change_state(PlayerState.IDLE)

func take_damage(damage: int, attacker: Node = null, knockback_force: Vector2 = Vector2.ZERO):
	if current_state == PlayerState.DEAD or is_rolling or current_state == PlayerState.PRAY:
		return
	
	# Call parent take_damage
	super.take_damage(damage, attacker, knockback_force)
	
	# Play hurt animation
	if current_health > 0:
		is_hurt = true
		hurt_timer = HURT_DURATION
		change_state(PlayerState.HURT)
		
		if animation_player:
			animation_player.play("Hurt")
		
		# Visual feedback
		if combat_effects:
			combat_effects.play_hit_effect(damage, global_position)

func is_state_locked() -> bool:
	return current_state in [
		PlayerState.ATTACK,
		PlayerState.HURT,
		PlayerState.DEAD,
		PlayerState.ROLL,
		PlayerState.PRAY
	]

func change_state(new_state: PlayerState):
	if current_state == PlayerState.DEAD:
		return
	if current_state in [PlayerState.ATTACK, PlayerState.HURT, PlayerState.ROLL] and (is_attacking or is_hurt or is_rolling):
		return
	if new_state != current_state:
		previous_state = current_state
	current_state = new_state
	if new_state != PlayerState.JUMP:
		is_jumping = false

func update_animation():
	if not animation_player:
		return
	
	match current_state:
		PlayerState.ATTACK:
			pass  # Animation set in attack functions
		PlayerState.HURT:
			if animation_player.current_animation != "Hurt":
				animation_player.play("Hurt")
		PlayerState.DEAD:
			if animation_player.current_animation != "Dead":
				animation_player.play("Dead")
		PlayerState.ROLL:
			if animation_player.current_animation != "Roll":
				animation_player.play("Roll")
		PlayerState.JUMP:
			if animation_player.current_animation != "Jump":
				animation_player.play("Jump")
		PlayerState.FALL:
			if animation_player.current_animation != "Fall":
				animation_player.play("Fall")
		PlayerState.RUN:
			if animation_player.current_animation != "Run":
				animation_player.play("Run")
		PlayerState.IDLE:
			if animation_player.current_animation != "Idle":
				animation_player.play("Idle")
		PlayerState.PRAY:
			if animation_player.current_animation != "Pray":
				animation_player.play("Pray")

func _on_animation_finished(anim_name: String):
	if current_state == PlayerState.ATTACK:
		is_attacking = false
		deactivate_all_hitboxes()
		
		if queued_next_attack and combo_step < 4 and is_on_floor():
			queued_next_attack = false
			start_combo_attack()
		else:
			reset_combo()
	elif current_state == PlayerState.ROLL:
		is_rolling = false
		is_invincible = false
		_set_hurtboxes_enabled(true)
		change_state(PlayerState.IDLE)
	elif current_state == PlayerState.JUMP and is_on_floor():
		is_jumping = false
		change_state(PlayerState.IDLE)
	elif current_state == PlayerState.PRAY:
		change_state(PlayerState.IDLE)

func _on_health_depleted():
	current_state = PlayerState.DEAD
	deactivate_all_hitboxes()
	if combat_effects:
		combat_effects.play_death_effect()

func _on_damage_taken(amount: int):
	# Update health display if needed
	pass

func on_hit_landed(target: Node, damage: int):
	"""Called when player successfully hits an enemy"""
	super.on_hit_landed(target, damage)
	
	# Play hit effect at target position
	if combat_effects and target is Node2D:
		combat_effects.create_hit_spark(target.global_position, Color.YELLOW)
	
	# Small hit stop for impact
	if combat_effects:
		combat_effects.apply_hit_stop()

func on_death():
	"""Override death behavior"""
	change_state(PlayerState.DEAD)
	deactivate_all_hitboxes()
