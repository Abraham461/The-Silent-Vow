extends CharacterBody2D
class_name Player

# === Movement ===
const RUN_SPEED = 180.0
const GRAVITY = 900.0
const JUMP_FORCE = -400.0

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
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))
	change_state(PlayerState.IDLE)

func _physics_process(delta):
	if is_dead:
		handle_death()
		move_and_slide()
		return

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

func handle_input():
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
	var direction := Input.get_action_strength("right") - Input.get_action_strength("left")
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
	is_attacking = true
	has_jumped_attack = true
	attack_timer = ATTACK_COOLDOWN
	attack_delay_timer = COMBO_ATTACK_DELAY
	change_state(PlayerState.ATTACK)
	animation_player.play("JumpAtk")

func start_roll():
	is_rolling = true
	roll_timer = ROLL_DURATION
	roll_cooldown_timer = ROLL_COOLDOWN
	change_state(PlayerState.ROLL)
	animation_player.play("Roll")

	var direction = -1 if animated_sprite.flip_h else 1
	velocity.x = direction * ROLL_SPEED
	velocity.y = 0

func start_pray():
	change_state(PlayerState.PRAY)
	animation_player.play("Pray")

func handle_roll():
	# Roll motion handled in start_roll
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
	return current_state in [
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
