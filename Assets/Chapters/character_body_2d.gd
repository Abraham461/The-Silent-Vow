extends CharacterBody2D

# Movement parameters
const WALK_SPEED := 200
const ROLL_SPEED := 300
const JUMP_FORCE := -400
const GRAVITY := 1000
const MAX_COMBO := 4
const SLIDE_SPEED := 230
const COMBO_WINDOW := 0.3
const ROLL_COOLDOWN := 0.8

# Animation references
@onready var sprite := $AnimatedSprite2D

# Timers (only essential ones)
@onready var combo_timer := $ComboTimer
@onready var roll_cooldown_timer := $RollCooldownTimer

# State management
enum State { IDLE, RUN, JUMP, ATTACK, ROLL, SLIDE, HEAL, PRAY }
var current_state: State = State.IDLE
var combo_step: int = 0
var move_direction: float = 0
var facing_direction: float = 1
var slide_velocity: float = 0
var can_roll: bool = true

func _ready():
	# Configure timers
	combo_timer.wait_time = COMBO_WINDOW
	combo_timer.one_shot = true
	
	roll_cooldown_timer.wait_time = ROLL_COOLDOWN
	roll_cooldown_timer.one_shot = true
	
	# Connect signals
	sprite.animation_finished.connect(_on_animation_finished)
	combo_timer.timeout.connect(_on_combo_timeout)
	roll_cooldown_timer.timeout.connect(_on_roll_cooldown_timeout)

func _physics_process(delta):
	# Apply gravity only when not grounded or jumping
	if not is_on_floor() or current_state == State.JUMP:
		velocity.y += GRAVITY * delta
	
	# Process state logic
	match current_state:
		State.IDLE:
			handle_idle_state()
		State.RUN:
			handle_run_state()
		State.JUMP:
			handle_jump_state()
		State.ATTACK:
			handle_attack_state()
		State.ROLL:
			handle_roll_state()
		State.SLIDE:
			handle_slide_state(delta)
		State.HEAL, State.PRAY:
			pass  # Special states handled by animation
	
	move_and_slide()
	update_animation()

func handle_idle_state():
	move_direction = Input.get_axis("Left", "Right")
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		jump()
	elif move_direction != 0:
		current_state = State.RUN
	elif Input.is_action_just_pressed("Roll") and can_roll:
		start_roll()
	elif Input.is_action_just_pressed("Atk"):
		start_attack()
	elif Input.is_action_just_pressed("Heal"):
		start_heal()
	elif Input.is_action_just_pressed("Pray"):
		start_pray()
	
	velocity.x = 0

func handle_run_state():
	move_direction = Input.get_axis("Left", "Right")
	
	if move_direction != 0:
		facing_direction = sign(move_direction)
		sprite.flip_h = facing_direction < 0
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		jump()
	elif Input.is_action_just_pressed("Roll") and can_roll:
		start_roll()
	elif Input.is_action_just_pressed("Atk"):
		start_attack()
	elif move_direction == 0:
		current_state = State.IDLE
	
	velocity.x = move_direction * WALK_SPEED

func handle_jump_state():
	move_direction = Input.get_axis("Left", "Right")
	
	if move_direction != 0:
		facing_direction = sign(move_direction)
		sprite.flip_h = facing_direction < 0
	
	if Input.is_action_just_pressed("Atk"):
		start_attack()
	elif is_on_floor():
		current_state = State.RUN if abs(velocity.x) > 10 else State.IDLE
	
	velocity.x = move_direction * WALK_SPEED

func handle_attack_state():
	velocity.x = 0

func handle_roll_state():
	velocity.x = facing_direction * ROLL_SPEED
	velocity.y = 0

func handle_slide_state(delta):
	slide_velocity = move_toward(slide_velocity, 0, delta * 1000)
	velocity.x = facing_direction * slide_velocity
	velocity.y = 0
	
	if slide_velocity <= 10:
		current_state = State.IDLE

# Action starters
func jump():
	current_state = State.JUMP
	sprite.play("Jump")
	velocity.y = JUMP_FORCE

func start_roll():
	current_state = State.ROLL
	sprite.play("Roll")
	can_roll = false
	velocity.x = facing_direction * ROLL_SPEED
	roll_cooldown_timer.start()

func start_slide():
	current_state = State.SLIDE
	sprite.play("Slide")
	slide_velocity = SLIDE_SPEED
	velocity.x = facing_direction * slide_velocity

func start_attack():
	current_state = State.ATTACK
	combo_step = 1
	sprite.play("Atk1")
	combo_timer.start()

func start_heal():
	current_state = State.HEAL
	sprite.play("Heal")

func start_pray():
	current_state = State.PRAY
	sprite.play("Pray")

func update_animation():
	if current_state in [State.ATTACK, State.ROLL, State.SLIDE, State.HEAL, State.PRAY]:
		return
	
	match current_state:
		State.IDLE:
			sprite.play("Idle")
		State.RUN:
			sprite.play("Run")
		State.JUMP:
			sprite.play("Jump" if velocity.y < 0 else "Fall")

# Timer callbacks
func _on_combo_timeout():
	# Reset combo if timer expires
	if current_state == State.ATTACK:
		current_state = State.IDLE
		combo_step = 0

func _on_roll_cooldown_timeout():
	can_roll = true

func _on_animation_finished():
	match current_state:
		State.ATTACK:
			if combo_step < MAX_COMBO and Input.is_action_pressed("Atk"):
				# Continue combo
				combo_step += 1
				sprite.play("Atk%d" % combo_step)
				combo_timer.start()  # Restart combo window
			else:
				# End attack sequence
				current_state = State.IDLE
				combo_step = 0
		
		State.ROLL:
			current_state = State.IDLE
		
		State.SLIDE:
			current_state = State.IDLE
		
		State.HEAL, State.PRAY:
			current_state = State.IDLE
