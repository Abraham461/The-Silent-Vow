extends CharacterBody2D
signal healthChanged

# Movement parameters
var can_enter_house: bool = false
var currentHealth: int = 100
var maxHealth: int = 100
var isHurt: bool = false
const WALK_SPEED := 200
const ROLL_SPEED := 300
const JUMP_FORCE := -400
const GRAVITY := 1000
const MAX_COMBO := 4
const SLIDE_SPEED := 310
const SLIDE_COOLDOWN :=0.8
const COMBO_WINDOW := 0.3
const ROLL_COOLDOWN := 0.8
const JUMP_ATK_DROP := 200      # tweak this to control how fast you slam down (higher -> faster)
const JUMP_ATK_HOLD_FRAME := 1     # 0-based frame index to hold (1 = second frame)
const JUMP_ATK_RESUME_FRAME := 2       # 0-based frame to resume from when landing (frame 3 -> index 2)
# Animation references
@onready var sprite := $AnimatedSprite2D

# Timers (only essential ones)
@onready var combo_timer := $ComboTimer
@onready var roll_cooldown_timer := $RollCooldownTimer
@onready var roll_timer := $RollTimer
@onready var slide_cooldown_timer := $SlideCooldownTimer
@onready var roll: AudioStreamPlayer = $roll
@onready var attack: AudioStreamPlayer = $attack

@onready var player = $CollisionShape2D
@onready var effects = $AnimationPlayer
@onready var hurtTimer = $HurtTimer
@onready var slide_timer := $SlideTimer  # Make sure you add this Timer node in scene
@onready var running: AudioStreamPlayer = $running
@onready var player_jump: AudioStreamPlayer = $player_jump
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var torch_light = $TorchLight
var torch_on = false
var is_frozen: bool = false

# State management
enum State { IDLE, RUN, JUMP, ATTACK, ROLL, SLIDE, HEAL, PRAY }
var current_state: State = State.IDLE
var combo_step: int = 0
var move_direction: float = 0
var facing_direction: float = 1
var slide_velocity: float = 0
var can_roll: bool = true
var can_slide: bool = true
var attack_buffered: bool = false
var knockbackPower = 250.0  # or whatever value you need
var jumpatk_lock: bool = false  # true while JumpAtk must wait for landing

func _process(_delta):

	if Input.is_action_just_pressed("toggle_torch"):
		torch_on = !torch_on
		torch_light.visible = torch_on
	if Input.is_action_just_pressed("teleport"):
		position = Vector2(11200, 600)
	if is_frozen:
		return  # skip input actions like torch toggle, teleport, etc.
		
	# Footstep sound logic - based on AnimatedSprite2D's current animation
	if sprite.animation == "Run":
		if not running.playing:
			running.play()
	else:
		if running.playing:
			running.stop()
			
	if sprite.animation == "Jump":
		if not player_jump.playing:
			player_jump.play()
	else:
		if player_jump.playing:
			player_jump.stop()
			
	if sprite.animation == "Roll":
		if not roll.playing:
			roll.play()
	else:
		if roll.playing:
			roll.stop()
		
	if sprite.animation == "Atk":
		if not attack.playing:
			attack.play()
	else:
		if attack.playing:
			attack.stop()

	
func _ready():
	
	# Configure timers
	torch_light.visible = torch_on
	combo_timer.wait_time = COMBO_WINDOW
	combo_timer.one_shot = true
	
	roll_cooldown_timer.wait_time = ROLL_COOLDOWN
	roll_cooldown_timer.one_shot = true
	# RollTimer governs how londg the roll lasts; set this in the inspector or here:
	roll_timer.wait_time = 0.4    # e.g. 0.4 seconds of roll
	roll_timer.one_shot = true
	slide_cooldown_timer.wait_time = SLIDE_COOLDOWN
	slide_cooldown_timer.one_shot = true
	slide_timer.wait_time = 0.6
	slide_timer.one_shot = true
	# Connect signals
	sprite.animation_finished.connect(_on_animation_finished)
	combo_timer.timeout.connect(_on_combo_timeout)
	roll_cooldown_timer.timeout.connect(_on_roll_cooldown_timeout)
	roll_timer.timeout.connect(_on_roll_timer_timeout)
	slide_cooldown_timer.timeout.connect(_on_slide_cooldown_timeout)
	slide_timer.timeout.connect(_on_slide_timer_timeout)
	

		# ensure your attack animations play at a visible rate
	var frames = sprite.sprite_frames

	# Make sure each combo only plays once:
	# Make each combo play only once at 8 FPS
	for anim_name in ["Atk1", "Atk2", "Atk3", "Atk4", "JumpAtk", ]:
		if frames.has_animation(anim_name):
			frames.set_animation_loop(anim_name, false)
			frames.set_animation_speed(anim_name, 19.0)

	# rest of your _ready...

	# And still one-shot Heal/Pray
	if frames.has_animation("Heal"):
		frames.set_animation_loop("Heal", false)
	if frames.has_animation("Pray"):
		frames.set_animation_loop("Pray", false)
var was_on_floor = false
	

func _physics_process(delta):
	if is_frozen:
		velocity = Vector2.ZERO  # stop all movement
		move_and_slide()
		return
	var now_on_floor = is_on_floor()
	# 1) catch any click before state logic
	# 1) Always catch an attack click
	if Input.is_action_just_pressed("Atk"):
		if current_state == State.ATTACK:
			attack_buffered = true
		else:
			start_attack()

	# 2) ALWAYS apply gravity
	if not is_on_floor() or current_state == State.JUMP:
		velocity.y += GRAVITY * delta

	# 3) run your state‐machine
	match current_state:
		State.IDLE:   handle_idle_state()
		State.RUN:    handle_run_state()
		State.JUMP:   handle_jump_state()
		State.ATTACK: handle_attack_state()
		State.ROLL:   handle_roll_state()
		State.SLIDE:  handle_slide_state()
		State.HEAL, State.PRAY: pass

	move_and_slide()
		# If we were holding JumpAtk until landing, check for landing now
	if jumpatk_lock and now_on_floor and not was_on_floor:
		_end_jumpatk()

	was_on_floor = now_on_floor
	update_animation()
# --- New helper to finish JumpAtk when landed ---


func _end_jumpatk():
	jumpatk_lock = false
	if sprite.sprite_frames.has_animation("JumpAtk"):
		sprite.animation = "JumpAtk"
		sprite.play("JumpAtk")
		await get_tree().process_frame
		sprite.frame = JUMP_ATK_RESUME_FRAME

		call_deferred("_force_resume_frame", JUMP_ATK_RESUME_FRAME)
		print("update_animation set anim:", sprite.animation, " state:", current_state)

	# Keep state as ATTACK until tail finishes
	current_state = State.ATTACK
	combo_step = 0
	attack_buffered = false
	# 🚫 Don't immediately change to RUN/IDLE or call update_animation()

func _force_resume_frame(frame):
	sprite.frame = frame
	sprite.speed_scale = 1.0

func handle_idle_state():
	move_direction = Input.get_axis("Left", "Right")
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		jump()
	elif move_direction != 0:
		current_state = State.RUN
	elif Input.is_action_just_pressed("Roll") and can_roll:
		start_roll()
	elif Input.is_action_just_pressed("Slide") and can_slide:
		start_slide()
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
	elif Input.is_action_just_pressed("Slide") and is_on_floor():
		# start a ground slide
		start_slide()
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

func handle_slide_state():
	velocity.x = facing_direction * SLIDE_SPEED
	velocity.y = 0
		# --- start slide ---
func start_slide():
	current_state = State.SLIDE
	sprite.play("Slide")
	can_roll = false
	slide_cooldown_timer.start()
	slide_timer.start()

# Action starters
func jump():
	current_state = State.JUMP
	sprite.play("Jump")
	velocity.y = JUMP_FORCE

func start_roll():
	current_state = State.ROLL
	sprite.play("Roll")
	can_roll = false
	roll_cooldown_timer.start()
	roll_timer.start()

func start_attack():
	print(">> start_attack() fired! current_state was:", current_state)
		# If in air, play JumpAtk and do not run ground combo logic
	# If in air, play JumpAtk and hold a specific frame until landing
	if current_state == State.JUMP:
		current_state = State.ATTACK
		jumpatk_lock = true
		# force a stronger downward velocity so the character drops faster
		velocity.y = max(velocity.y, JUMP_ATK_DROP)
		# start the animation and immediately freeze it on the chosen frame
		if sprite.sprite_frames.has_animation("JumpAtk"):
			await get_tree().process_frame
			sprite.play("JumpAtk")
			sprite.frame = JUMP_ATK_HOLD_FRAME
			sprite.stop()  # freeze at this frame
			var frame_count = sprite.sprite_frames.get_frame_count("JumpAtk")
			sprite.frame = clamp(JUMP_ATK_HOLD_FRAME, 0, frame_count - 1)
			# freeze the animation by stopping it
			sprite.stop()
		else:
			# fallback: just ensure we're in attack state if animation missing
			push_warning("JumpAtk animation missing on AnimatedSprite2D")
		return
	# ground combo
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
	if current_state == State.ATTACK:
		return  # don't touch animation, let it finish
	if sprite.animation == "JumpAtk" and sprite.frame == JUMP_ATK_HOLD_FRAME:
		return

	match current_state:
		State.IDLE:
			sprite.play("Idle")
		State.RUN:
			sprite.play("Run")
			#if not $running_on_concrete.playing:
				#$running_on_concrete.play()
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

func _on_roll_timer_timeout():
	if current_state == State.ROLL:
		current_state = State.IDLE
		velocity.x = 0
		
func _on_slide_cooldown_timeout():
	can_roll = true
func _on_slide_timer_timeout():
	if current_state == State.SLIDE:
		current_state = State.IDLE
		velocity.x = 0
		
func _on_animation_finished():
	print(">> animation_finished for: ", sprite.animation)  # debug
	var anim = sprite.animation

	# If JumpAtk finishing event fired:
	if anim == "JumpAtk":
		# If still locked for some reason, ignore finishing (shouldn't happen because we stopped)
		if jumpatk_lock:
			return

		# JumpAtk finished normally (we had resumed at landing and played frames 3..end)
		# Now return to an appropriate grounded state
		if is_on_floor():
			current_state = State.RUN if abs(velocity.x) > 10 else State.IDLE
		else:
			# if somehow not on floor, keep JUMP state (safety)
			current_state = State.JUMP

		# cleanup combo flags
		combo_step = 0
		attack_buffered = false
		return

	# Slide finished -> stop sliding
	if anim == "Slide":
		if current_state == State.SLIDE:
			current_state = State.IDLE
			velocity.x = 0
		return
	match current_state:
		State.ATTACK:
			if combo_step < MAX_COMBO and attack_buffered:
				attack_buffered = false             # consume the buffered click
				combo_step += 1
				sprite.play("Atk%d" % combo_step)
				combo_timer.start()
			else:
				current_state = State.IDLE
				combo_step = 0
				attack_buffered = false             # clear any leftover
		
		State.ROLL, State.SLIDE, State.HEAL, State.PRAY:
			# for slide we also fall back when velocity decays
			if current_state in [State.HEAL, State.PRAY]:
				current_state = State.IDLE

func hurtByEnemy(area):
	currentHealth -= 20
	if currentHealth < 0:
		currentHealth = maxHealth

	isHurt = true
	healthChanged.emit()

	knockback(area.get_parent().velocity)
	effects.play("TakeHit")
	hurtTimer.start()
	await hurtTimer.timeout
	effects.play("RESET")
	isHurt = false


func knockback(enemyVelocity: Vector2):
	var knockbackDirection = (enemyVelocity - velocity).normalized() * knockbackPower
	velocity = knockbackDirection
	move_and_slide()

func trigger_dialogue(dialogue_resource: DialogueResource) -> void:
	if dialogue_resource and Engine.has_singleton("DialogueManager"):
		DialogueManager.show_dialogue(dialogue_resource)

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Collision with: ", body.name)
