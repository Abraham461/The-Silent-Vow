extends CharacterBody2D
class_name Player

# === Movement ===
const RUN_SPEED = 180.0
const GRAVITY = 900.0
const JUMP_FORCE = -400.0
var dialogue_active: bool = false
var movement_disabled: bool = false   # NEW: hard freeze flag

# === Combat ===
var is_attacking = false
const ATTACK_COOLDOWN = 0.5
var attack_timer = 0.0

# === Combo System ===
var combo_step = 0
var combo_timer = 0.0
const COMBO_MAX_TIME = 0.5
var queued_next_attack = false
var attack_delay_timer = 0.0
const COMBO_ATTACK_DELAY = 0.15

# === Health ===
var max_health = 100
var health = max_health
var is_dead = false
var is_hurt = false
var hurt_timer = 0.0
const HURT_DURATION = 0.3

# === Roll ===
var is_rolling = false
const ROLL_SPEED = 300.0
const ROLL_DURATION = 0.4
const ROLL_COOLDOWN = 1.5
var roll_timer = 0.0
var roll_cooldown_timer = 0.0

# === Jump ===
var is_jumping = false
var has_jumped_attack = false

# === State Machine ===
enum PlayerState { IDLE, RUN, ATTACK, HURT, DEAD, JUMP, FALL, ROLL, PRAY }
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

# === Node References ===
@export var speed: int = 200
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var actionable_finder: Area2D = $Direction/ActionableFinder
var _dialogue_triggered := false
@onready var running_on_concrete: AudioStreamPlayer = $Running_on_concrete

# walls: Expect LeftWall and RightWall to have CollisionShape2D children.
@onready var left_wall_shape: CollisionShape2D = $LeftWall/CollisionShape2D
@onready var right_wall_shape: CollisionShape2D = $RightWall/CollisionShape2D

# store original parent collision layers so we can restore them if we toggle layers
var left_wall_parent_original_layer := 0
var right_wall_parent_original_layer := 0

func _ready():
	# Save original parent layers if parent exists
	if left_wall_shape and left_wall_shape.get_parent():
		left_wall_parent_original_layer = left_wall_shape.get_parent().collision_layer
	if right_wall_shape and right_wall_shape.get_parent():
		right_wall_parent_original_layer = right_wall_shape.get_parent().collision_layer

	# Ensure shapes are disabled initially (won't block player until dialogue)
	# Use set_deferred so we don't upset physics step timing.
	if left_wall_shape:
		left_wall_shape.set_deferred("disabled", true)
	if right_wall_shape:
		right_wall_shape.set_deferred("disabled", true)

	# Debug print to confirm node setup
	print("Left parent:", left_wall_shape.get_parent() if left_wall_shape else null)
	print("Right parent:", right_wall_shape.get_parent() if right_wall_shape else null)
	print("Player collision_mask:", collision_mask)

	# Connect spawn and animation finished
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)
	animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

	# Actionable finder signals
	actionable_finder.connect("area_entered", Callable(self, "_on_actionable_entered"))
	actionable_finder.connect("area_exited",  Callable(self, "_on_actionable_exited"))

	# Dialogue signals (if provided by your DialogueManager)
	if DialogueManager.has_signal("dialogue_started"):
		DialogueManager.dialogue_started.connect(_on_dialogue_started)
	if DialogueManager.has_signal("dialogue_finished"):
		DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

	change_state(PlayerState.IDLE)

func _on_dialogue_started():
	# enable blocking walls and freeze the player controls for dialogue only
	dialogue_active = true
	_enable_walls()
	freeze_player()  # note: freeze_player no longer toggles movement_disabled

func _on_dialogue_finished():
	# disable blocking walls and unfreeze the player controls
	dialogue_active = false
	_disable_walls()
	unfreeze_player()

# Helper: enable/disable walls (works with CollisionShape2D.disabled primarily)
func _enable_walls():
	if left_wall_shape:
		left_wall_shape.set_deferred("disabled", false)
		# if parent is StaticBody2D and you prefer layers: restore layer if it was zeroed
		var p = left_wall_shape.get_parent()
		if p and p.has_method("set_deferred") and left_wall_parent_original_layer != 0:
			p.set_deferred("collision_layer", left_wall_parent_original_layer)
	if right_wall_shape:
		right_wall_shape.set_deferred("disabled", false)
		var p2 = right_wall_shape.get_parent()
		if p2 and p2.has_method("set_deferred") and right_wall_parent_original_layer != 0:
			p2.set_deferred("collision_layer", right_wall_parent_original_layer)

func _disable_walls():
	if left_wall_shape:
		left_wall_shape.set_deferred("disabled", true)
		# optionally zero parent's layer to fully disable (comment out if not desired)
		var p = left_wall_shape.get_parent()
		if p and p.has_method("set_deferred"):
			p.set_deferred("collision_layer", 0)
	if right_wall_shape:
		right_wall_shape.set_deferred("disabled", true)
		var p2 = right_wall_shape.get_parent()
		if p2 and p2.has_method("set_deferred"):
			p2.set_deferred("collision_layer", 0)

# Freeze / unfreeze player movement & inputs
func freeze_player():
	# Do NOT change movement_disabled here — keep movement_disabled for other usages.
	# Dialogue flow uses dialogue_active to block movement. Here we just stop input processing & animations.
	velocity = Vector2.ZERO
	# make sure to stop motion immediately
	move_and_slide()
	animation_player.play("Idle")
	# stop _input callbacks (optional). Physics still runs so dialogue walls and collisions work.
	set_process_input(false)

func unfreeze_player():
	# Do NOT touch movement_disabled here.
	set_process_input(true)

func is_frozen() -> bool:
	# keep same semantics but also include movement_disabled
	return dialogue_active or is_dead or is_hurt or movement_disabled

func _on_spawn(position:Vector2,direction:String):
	global_position = position
	animation_player.play("move_"+direction)
	animation_player.stop()

func _physics_process(delta):
	# If we are frozen (dialogue_active or movement_disabled or death/hurt), don't allow movement or physics-controlled velocity changes
	if dialogue_active or movement_disabled or is_dead or is_hurt:
		velocity = Vector2.ZERO
		# ensure we still run move_and_slide so collisions update
		move_and_slide()
		return

	update_timers(delta)
	handle_input()

	if is_rolling:
		handle_roll()
	else:
		handle_movement()
		apply_gravity(delta)

	move_and_slide()
	update_animation()
	
	if animation_player.current_animation == "Run":
		if not running_on_concrete.playing: running_on_concrete.play()
	else:
		if running_on_concrete.playing: running_on_concrete.stop()

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
			change_state(PlayerState.IDLE)

	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta

func _on_actionable_entered(area: Area2D) -> void:
	if _dialogue_triggered:
		return
	if area.has_method("action"):
		area.action()
		call_deferred("_set_dialogue_triggered")

func _set_dialogue_triggered():
	_dialogue_triggered = true

func _on_actionable_exited(area: Area2D) -> void:
	if area.has_method("action"):
		_dialogue_triggered = false

func handle_input():
	# block input handling if movement is disabled OR dialogue is active
	if movement_disabled or dialogue_active:
		animated_sprite.play("Idle")
		return

	# keep dialogue_active effect for visuals (redundant guard)
	if dialogue_active:
		animated_sprite.play("Idle")

	if Input.is_action_just_pressed("Roll") and not is_state_locked() and roll_cooldown_timer <= 0:
		start_roll()

	if Input.is_action_just_pressed("Pray") and not is_state_locked():
		start_pray()

	if Input.is_action_just_pressed("Atk") and not is_state_locked():
		if not is_on_floor():
			if not has_jumped_attack:
				start_jump_attack()
		else:
			if is_attacking:
				queued_next_attack = true
			else:
				start_combo_attack()

	if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_state_locked():
		is_jumping = true
		velocity.y = JUMP_FORCE
		change_state(PlayerState.JUMP)
		animation_player.play("Jump111")

func handle_movement():
	if dialogue_active or movement_disabled:
		velocity.x = 0  # stop horizontal movement
		return
	var direction := Input.get_action_strength("Right") - Input.get_action_strength("Left")
	velocity.x = direction * RUN_SPEED

	if direction != 0:
		animated_sprite.flip_h = direction < 0

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
	if animation_player.current_animation != "Dead":
		animation_player.play("Dead")

func start_combo_attack():
	# respect dialogue_active and hard freeze
	if movement_disabled or dialogue_active: return
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

	match combo_step:
		1: animation_player.play("NormalAtk1")
		2: animation_player.play("NormalAtk2")
		3: animation_player.play("NormalAtk3")
		4: animation_player.play("NormalAtk4")

func start_jump_attack():
	if movement_disabled or dialogue_active: return
	is_attacking = true
	has_jumped_attack = true
	attack_timer = ATTACK_COOLDOWN
	attack_delay_timer = COMBO_ATTACK_DELAY
	change_state(PlayerState.ATTACK)
	animation_player.play("JumpAtk")

func start_roll():
	if movement_disabled or dialogue_active: return
	is_rolling = true
	roll_timer = ROLL_DURATION
	roll_cooldown_timer = ROLL_COOLDOWN
	change_state(PlayerState.ROLL)
	animation_player.play("Roll")

	var direction = -1 if animated_sprite.flip_h else 1
	velocity.x = direction * ROLL_SPEED
	velocity.y = 0

func start_pray():
	if movement_disabled or dialogue_active: return
	change_state(PlayerState.PRAY)
	animation_player.play("Pray")

func handle_roll():
	pass

func reset_combo():
	combo_step = 0
	combo_timer = 0.0
	queued_next_attack = false
	is_attacking = false
	if not is_hurt and is_on_floor():
		change_state(PlayerState.IDLE)

func take_damage(damage: int):
	if is_dead or is_rolling or current_state == PlayerState.PRAY:
		return
	health -= damage
	if health <= 0:
		health = 0
		is_dead = true
		change_state(PlayerState.DEAD)
	else:
		is_hurt = true
		hurt_timer = HURT_DURATION
		change_state(PlayerState.HURT)
		velocity = -velocity.normalized() * 100

func is_state_locked() -> bool:
	# Include dialogue_active/movement_disabled so actions won't start during dialogue
	return dialogue_active or movement_disabled or current_state in [
		PlayerState.ATTACK,
		PlayerState.HURT,
		PlayerState.DEAD,
		PlayerState.ROLL,
		PlayerState.PRAY
	]

func change_state(new_state: PlayerState):
	if is_dead:
		return
	if current_state in [PlayerState.ATTACK, PlayerState.HURT, PlayerState.ROLL] and (is_attacking or is_hurt or is_rolling):
		return
	if new_state != current_state:
		previous_state = current_state
	current_state = new_state
	if new_state != PlayerState.JUMP:
		is_jumping = false

func update_animation():
	match current_state:
		PlayerState.ATTACK:
			pass
		PlayerState.HURT:
			animation_player.play("Hurt")
		PlayerState.DEAD:
			animation_player.play("Dead")
		PlayerState.ROLL:
			if animation_player.current_animation != "Roll":
				animation_player.play("Roll")
		PlayerState.JUMP:
			if not animation_player.is_playing():
				animation_player.play("Jump")
		PlayerState.FALL:
			if animation_player.current_animation != "Fall":
				animation_player.play("Fall")
		PlayerState.RUN:
			animation_player.play("Run")
		PlayerState.IDLE:
			animation_player.play("Idle")
		PlayerState.PRAY:
			if animation_player.current_animation != "Pray":
				animation_player.play("Pray")

func _on_animation_finished(_anim_name: String):
	if current_state == PlayerState.ATTACK:
		is_attacking = false
		if queued_next_attack and combo_step < 4 and is_on_floor():
			queued_next_attack = false
			start_combo_attack()
		else:
			reset_combo()
	elif current_state == PlayerState.ROLL:
		is_rolling = false
		change_state(PlayerState.IDLE)
	elif current_state == PlayerState.JUMP and is_on_floor():
		is_jumping = false
		change_state(PlayerState.IDLE)
	elif current_state == PlayerState.PRAY:
		change_state(PlayerState.IDLE)

func reset_player():
	health = max_health
	is_dead = false
	is_hurt = false
	is_attacking = false
	is_rolling = false
	is_jumping = false
	has_jumped_attack = false
	combo_step = 0
	queued_next_attack = false
	change_state(PlayerState.IDLE)
	position = Vector2.ZERO
	velocity = Vector2.ZERO
