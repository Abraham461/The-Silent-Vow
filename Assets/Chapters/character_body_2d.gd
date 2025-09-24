extends CharacterBody2D

signal healthChanged

var is_on_ladder := false

var facing_left: bool = false

func set_facing(left: bool) -> void:
	if facing_left == left:
		return
	facing_left = left

	# Flip the sprite
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.flip_h = facing_left
	elif has_node("Sprite2D"):
		$Sprite2D.flip_h = facing_left

	# Mirror hitbox and hurtbox positions
	for child in get_children():
		if child.is_in_group("HitBox") or child.is_in_group("HurtBox"):
			child.position.x = -abs(child.position.x) if facing_left else abs(child.position.x)

# Movement parameters
var can_enter_house: bool = false
#var currentHealth: int = 100
#var maxHealth: int = 100
var isHurt: bool = false
const WALK_SPEED := 200
const ROLL_SPEED := 300
const JUMP_FORCE := -400
const GRAVITY := 1000
const MAX_COMBO := 4
const SLIDE_SPEED := 310
const SLIDE_COOLDOWN := 0.8
const COMBO_WINDOW := 0.8
const ROLL_COOLDOWN := 0.8

const JUMP_ATK_DROP := 200      # tweak this to control how fast you slam down (higher -> faster)
const JUMP_ATK_HOLD_FRAME := 1     # 0-based frame index to hold (1 = second frame)
const JUMP_ATK_RESUME_FRAME := 2       # 0-based frame to resume from when landing (frame 3 -> index 2)

const SPEED = -200.0			#for ladder climbing
# Animation references


# Timers (only essential ones)

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ladder_ray_cast: RayCast2D = $LadderRayCast		#for ladder climbing

@onready var roll: AudioStreamPlayer = $roll
@onready var attack: AudioStreamPlayer = $attack


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var combo_timer: Timer = $ComboTimer
#@onready var roll_cooldown_timer: eadTimer = $RollCooldownTimer
@onready var roll_cooldown_timer: Timer = $RollCooldownTimer
@onready var roll_timer: Timer = $RollTimer
@onready var slide_cooldown_timer: Timer = $SlideCooldownTimer

@onready var player = $CollisionShape2D

@onready var effects = $AnimationPlayer
@onready var hurtTimer = $HurtTimer
@onready var slide_timer := $SlideTimer  # Make sure you add this Timer node in scene
@onready var running: AudioStreamPlayer = $running
@onready var player_jump: AudioStreamPlayer = $player_jump
#@onready var animation_player: AnimationPlayer = $AnimationPlayer


@onready var devil: AnimatedSprite2D = $"../enemydevil/AnimatedSprite2D"
@onready var animMod: AnimatedSprite2D = $"../enemy1/AnimatedSprite2D"

@onready var torch_light = $TorchLight

var torch_on: bool = false
var is_frozen: bool = false

@onready var hitbox: Area2D = $HitBox
@onready var hitbox_shape: CollisionShape2D = $HitBox/CollisionShape2D

# Extended hitboxes
@onready var hitbox2: Area2D = $HitBox2 if has_node("HitBox2") else null
@onready var hitbox2_shape: CollisionShape2D = $HitBox2/CollisionShape2D if has_node("HitBox2/CollisionShape2D") else null
@onready var hitbox3: Area2D = $HitBox3 if has_node("HitBox3") else null
@onready var hitbox3_shape: CollisionShape2D = $HitBox3/CollisionShape2D if has_node("HitBox3/CollisionShape2D") else null
@onready var hitbox4: Area2D = $HitBox4 if has_node("HitBox4") else null
@onready var hitbox4_shape: CollisionShape2D = $HitBox4/CollisionShape2D if has_node("HitBox4/CollisionShape2D") else null
#@onready var health: Node = $Healtha
enum State { IDLE, RUN, JUMP, ATTACK, ROLL, SLIDE, CLIMB, HEAL, PRAY }
@export var textbox_scene: PackedScene = preload("res://DuskBorne-Druid/Textboxmod.tscn")
@onready var health_bar: ProgressBar = $"../../CanvasLayer2/UHD/HealthBar"
@onready var Cha3cutscene_scene: PackedScene = preload("res://more cutscene/cutscene_third.tscn")
@onready var Cha3Dungeoncutscene_scene: PackedScene = preload("res://Assets/Chapters/chapter_3__2.tscn")
@onready var scene_change_tp: AnimatedSprite2D = $"../SceneChangeTP"
@onready var scenechange_area: Area2D = $"../SceneChangeTP/ScenechangeArea"
@onready var tween = get_tree().create_tween()
# State management
var current_state: State = State.IDLE
var combo_step: int = 0
var move_direction: float = 0
var facing_direction: float = 1
var slide_velocity: float = 0
var can_roll: bool = true
var can_slide: bool = true
var attack_buffered: bool = false
var knockbackPower: float = 250.0
var jumpatk_lock: bool = false
var was_on_floor: bool = false


	
@export var enemy1_path: NodePath
@export var exit_distance: float = 220.0
@export var exit_duration: float = 6.0
@onready var enemy1: CharacterBody2D = $"../enemy1"
@onready var devilanim: AnimatedSprite2D = $"../enemydevil/AnimatedSprite2D"
var devildeath = false
@onready var devil_aggro_zone: Area2D = $"../enemydevil/AggroZone"
@onready var devil_attackeffect: AnimatedSprite2D = $"../enemydevil/AnimatedSprite2D2"
@onready var enemyNightborne: CharacterBody2D = $"../Enemy"
@onready var enemymino: CharacterBody2D = $"../enemymino"

@export var respawn_invul_time: float = 1.5   # seconds of invulnerability after respawn
var playerDeath: bool = false  # make sure this exists at the top of your script
var is_hurt: bool = false
var is_invulnerable: bool = false
@onready var hurt_box: Area2D = $HurtBox
var external_input_blocked: bool = false
@export var respawn_delay_after_death: float = 0.8 

var devil_in_aggro: bool = false
var has_triggeredmod := false
var devil_attack_loop_running: bool = false
var devil_aggro_body: CharacterBody2D = null


func _process(_delta):
	if is_instance_valid(enemyNightborne):
				# reset vertical velocity so gravity is applied fresh next physics frame
		enemyNightborne.velocity.y = 0
	else:
		push_warning("enemyNightborne not found or freed")
	if Input.is_action_just_pressed("toggle_torch"):
		torch_on = !torch_on
		torch_light.visible = torch_on
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

	
func _ready() -> void:
	
	# To call the scene after choosing to Restart the game
	Global.current_level_scene_path = "res://Assets/Chapters/chapter_2_1.tscn"

	torch_light.visible = torch_on
	combo_timer.wait_time = COMBO_WINDOW
	combo_timer.one_shot = true
	
	roll_cooldown_timer.wait_time = ROLL_COOLDOWN
	roll_cooldown_timer.one_shot = true
	roll_timer.wait_time = 0.4
	roll_timer.one_shot = true
	slide_cooldown_timer.wait_time = SLIDE_COOLDOWN
	slide_cooldown_timer.one_shot = true
	slide_timer.wait_time = 0.6
	slide_timer.one_shot = true
	
	# Connect signals
	sprite.animation_finished.connect(_on_animation_finished)
	if sprite.has_signal("frame_changed"):
		sprite.frame_changed.connect(_on_sprite_frame_changed)
	combo_timer.timeout.connect(_on_combo_timeout)
	roll_cooldown_timer.timeout.connect(_on_roll_cooldown_timeout)
	roll_timer.timeout.connect(_on_roll_timer_timeout)
	slide_cooldown_timer.timeout.connect(_on_slide_cooldown_timeout)
	slide_timer.timeout.connect(_on_slide_timer_timeout)

	# Default: disable hitbox until active attack frames
	if hitbox:
		hitbox.set_deferred("monitoring", false)
	if hitbox_shape:
		hitbox_shape.set_deferred("disabled", true)
	# Also disable any extra hitboxes if present
	if hitbox2:
		hitbox2.set_deferred("monitoring", false)
	if hitbox2_shape:
		hitbox2_shape.set_deferred("disabled", true)
	if hitbox3:
		hitbox3.set_deferred("monitoring", false)
	if hitbox3_shape:
		hitbox3_shape.set_deferred("disabled", true)
	if hitbox4:
		hitbox4.set_deferred("monitoring", false)
	if hitbox4_shape:
		hitbox4_shape.set_deferred("disabled", true)

	# Ensure we have a HurtBox for receiving enemy damage
	if not has_node("HurtBox"):
		var hb := Area2D.new()
		hb.name = "HurtBox"
		add_child(hb)
		var shape := CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		shape.shape.size = Vector2(18, 26)
		shape.position = Vector2(0, -4)
		hb.add_child(shape)
		var s := load("res://Assets/Chapters/HurtBox.gd")
		hb.set_script(s)

	var frames = sprite.sprite_frames
	for anim_name in ["Atk1", "Atk2", "Atk3", "Atk4", "JumpAtk"]:
		if frames.has_animation(anim_name):
			frames.set_animation_loop(anim_name, false)
			frames.set_animation_speed(anim_name, 12.0)

	if frames.has_animation("Heal"):
		frames.set_animation_loop("Heal", false)
	if frames.has_animation("Pray"):
		frames.set_animation_loop("Pray", false)

		return
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = !get_tree().paused
#var was_on_floor = false
	health.health_depleted.connect(_on_health_health_depleted)


func _physics_process(delta: float) -> void:

	if is_frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# NEW: honor external/local and global input locks
	# This forces the player to stop horizontally and play Idle while locked.

	if Input.is_action_just_pressed("teleport"):
		global_position = Vector2(11040, 550)
	# Apply variable jump height (better control)
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	var now_on_floor = is_on_floor()
	if Input.is_action_just_pressed("Atk"):
		if current_state == State.ATTACK:
			attack_buffered = true
		else:
			start_attack()

	if not is_on_floor() or current_state == State.JUMP:
		velocity.y += GRAVITY * delta

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
			handle_slide_state()
		State.CLIMB:
			handle_climb_state()
		State.HEAL, State.PRAY:
			pass

	move_and_slide()
	
	if jumpatk_lock and now_on_floor and not was_on_floor:
		_end_jumpatk()

	was_on_floor = now_on_floor
	update_animation()
	
	   
	
	
func _end_jumpatk() -> void:
	jumpatk_lock = false
	if sprite.sprite_frames.has_animation("JumpAtk"):
		sprite.animation = "JumpAtk"
		sprite.play("JumpAtk")
		await get_tree().process_frame
		sprite.frame = JUMP_ATK_RESUME_FRAME
		call_deferred("_force_resume_frame", JUMP_ATK_RESUME_FRAME)

	current_state = State.ATTACK
	combo_step = 0
	attack_buffered = false

func _force_resume_frame(frame: int) -> void:
	sprite.frame = frame
	sprite.speed_scale = 1.0

func handle_idle_state() -> void:
	move_direction = Input.get_axis("Left", "Right")
	
	# smoother acceleration/deceleration
	velocity.x = move_toward(velocity.x, move_direction * WALK_SPEED, WALK_SPEED * 0.25)
	
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

func handle_run_state() -> void:
	move_direction = Input.get_axis("Left", "Right")

	# more responsive acceleration toward run speed
	velocity.x = move_toward(velocity.x, move_direction * WALK_SPEED, WALK_SPEED * 0.3)

	if move_direction != 0:
		facing_direction = sign(move_direction)
		sprite.flip_h = facing_direction < 0

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		jump()
	elif Input.is_action_just_pressed("Roll") and can_roll:
		start_roll()
	elif Input.is_action_just_pressed("Slide") and is_on_floor():
		start_slide()
	elif Input.is_action_just_pressed("Atk"):
		start_attack()
	elif move_direction == 0:
		current_state = State.IDLE

func handle_jump_state() -> void:
	move_direction = Input.get_axis("Left", "Right")
	
	if move_direction != 0:
		facing_direction = sign(move_direction)
		sprite.flip_h = facing_direction < 0
	
	if Input.is_action_just_pressed("Atk"):
		start_attack()
	elif is_on_floor():
		current_state = State.RUN if abs(velocity.x) > 10 else State.IDLE
	
	# preserve air control but smoother
	velocity.x = move_toward(velocity.x, move_direction * WALK_SPEED, WALK_SPEED * 0.2)

func handle_attack_state() -> void:
	velocity.x = 0

func handle_roll_state() -> void:
	velocity.x = facing_direction * ROLL_SPEED
	velocity.y = 0

func handle_slide_state() -> void:
	velocity.x = facing_direction * SLIDE_SPEED
	velocity.y = 0

func handle_climb_state() -> void:
	velocity = Vector2.ZERO
	sprite.play("Climb")
	if not Input.is_action_pressed("Up") and not Input.is_action_pressed("Down"):
		return
	if Input.is_action_pressed("Up"):
		position.y -= WALK_SPEED * get_physics_process_delta_time()
	elif Input.is_action_pressed("Down"):
		position.y += WALK_SPEED * get_physics_process_delta_time()
	# exit climb when jump is pressed
	if Input.is_action_just_pressed("Jump"):
		current_state = State.JUMP
		jump()

func start_slide() -> void:
	current_state = State.SLIDE
	sprite.play("Slide")
	can_roll = false
	slide_cooldown_timer.start()
	slide_timer.start()

func jump() -> void:
	current_state = State.JUMP
	sprite.play("Jump")
	velocity.y = JUMP_FORCE

func start_roll() -> void:
	current_state = State.ROLL
	sprite.play("Roll")
	can_roll = false
	roll_cooldown_timer.start()
	roll_timer.start()
	# grant i-frames: disable HurtBox and disable collision during roll
	if has_node("HurtBox"):
		var hb := get_node("HurtBox")
		if hb and hb is Area2D:
			hb.set_deferred("monitoring", false)

	var col := $CollisionShape2D if has_node("CollisionShape2D") else null

	#var col := $CollisionShape2D if has_node("CollisionShape2D") else null

	#if col and col is CollisionShape2D:
		#col.set_deferred("disabled", true)

#func start_attack():
		# If in air, play JumpAtk and do not run ground combo logic
	# If in air, play JumpAtk and hold a specific frame until landing
# --- Control API for external systems to force-stop / resume the player ---

# Force-stop motion and lock player input locally.
# play_idle: whether to force the Idle animation immediately.
func stop_immediately(play_idle: bool = true) -> void:
	external_input_blocked = true
	# stop horizontal motion immediately
	velocity.x = 0
	# clear attack/slide/roll states so no motion resumes unexpectedly
	if current_state in [State.ROLL, State.SLIDE]:
		current_state = State.IDLE
	# force Idle animation if requested
	if play_idle and sprite:
		sprite.play("Idle")
	# stop any timers that could re-enable movement
	if combo_timer: combo_timer.stop()
	if roll_timer: roll_timer.stop()
	if slide_timer: slide_timer.stop()
	# optionally disable hurtbox or other systems if desired:
	# if has_node("HurtBox"): $HurtBox.set_deferred("monitoring", false)

# Resume normal player behavior
func resume_input() -> void:
	external_input_blocked = false
	# optionally restart timers if they should continue (usually not)
	# combo_timer.start()  # only if needed

func start_attack() -> void:
	print(">> start_attack() fired! current_state was:", current_state)
	# Improved combat: input buffering, cancel windows, and combo scaling
	if current_state == State.ATTACK:
		# buffer if already attacking
		attack_buffered = true
		return

	if current_state == State.JUMP:
		current_state = State.ATTACK
		jumpatk_lock = true
		velocity.y = max(velocity.y, JUMP_ATK_DROP)
		if sprite.sprite_frames.has_animation("JumpAtk"):
			await get_tree().process_frame
			sprite.play("JumpAtk")
			sprite.frame = JUMP_ATK_HOLD_FRAME
			var frame_count = sprite.sprite_frames.get_frame_count("JumpAtk")
			sprite.frame = clamp(JUMP_ATK_HOLD_FRAME, 0, frame_count - 1)
			sprite.stop()
		else:
			push_warning("JumpAtk animation missing on AnimatedSprite2D")
		return

	# ground combo
	current_state = State.ATTACK
	combo_step = (combo_step % MAX_COMBO) + 1
	sprite.play("Atk%d" % combo_step)
	combo_timer.start()
	await get_tree().process_frame

	var base_damage := 10
	var dmg := base_damage + int(3 * (combo_step - 1))
	_set_hitboxes_damage(dmg)

@onready var health: playerHealth = $playerHealth

func start_heal() -> void:
	current_state = State.HEAL
	health_bar.value +=40
	health.set_health(health.get_health() + 40)
	sprite.play("Heal")

func start_pray() -> void:
	current_state = State.PRAY
	sprite.play("Pray")

func update_animation() -> void:
	if current_state in [State.ATTACK, State.ROLL, State.SLIDE, State.HEAL, State.PRAY]:
		return
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
func _on_combo_timeout() -> void:
	# Reset combo if timer expires
	if current_state == State.ATTACK:
		current_state = State.IDLE
		combo_step = 0

func _on_roll_cooldown_timeout() -> void:
	can_roll = true

func _on_roll_timer_timeout() -> void:
	# restore HurtBox and collision when roll ends
	if has_node("HurtBox"):
		var hb := get_node("HurtBox")
		if hb and hb is Area2D:
			hb.set_deferred("monitoring", true)
	var col := $CollisionShape2D if has_node("CollisionShape2D") else null
	if col and col is CollisionShape2D:
		col.set_deferred("disabled", false)

	if current_state == State.ROLL:
		current_state = State.IDLE
		velocity.x = 0

func _on_slide_cooldown_timeout() -> void:
	can_roll = true

func _on_slide_timer_timeout() -> void:
	if current_state == State.SLIDE:
		current_state = State.IDLE
		velocity.x = 0

func _on_animation_finished() -> void:
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
				attack_buffered = false
				combo_step += 1
				await get_tree().process_frame
				sprite.play("Atk%d" % combo_step)
				combo_timer.start()
				var base_damage2 := 10
				var dmg2 := base_damage2 + int(3 * (combo_step - 1))
				_set_hitboxes_damage(dmg2)
			else:
				current_state = State.IDLE
				combo_step = 0
				attack_buffered = false
				_set_hitbox_active(false)
		State.ROLL, State.SLIDE, State.HEAL, State.PRAY:
			# for slide we also fall back when velocity decays
			if current_state in [State.HEAL, State.PRAY]:
				current_state = State.IDLE
#
#func hurtByEnemy(area: Area2D) -> void:
	#var dmg: int = 20
	#if area != null:
		#if area.has_method("get_damage"):
			#var maybe: Variant = area.get_damage()
			#if typeof(maybe) == TYPE_INT:
				#dmg = int(maybe)
		#elif "damage" in area:
			#var v: Variant = area.get("damage")
			#if typeof(v) == TYPE_INT:
				#dmg = int(v)
	#currentHealth -= dmg
	#if currentHealth < 0:
		#currentHealth = maxHealth
#
	#isHurt = true
	#healthChanged.emit()
#
	#knockback(area.get_parent().velocity)
	#effects.play("TakeHit")
	#hurtTimer.start()
	#await hurtTimer.timeout
	#effects.play("RESET")
	#isHurt = false
#
#func knockback(enemyVelocity: Vector2) -> void:
	#var knockbackDirection = (enemyVelocity - velocity).normalized() * knockbackPower
	#velocity = knockbackDirection
	#move_and_slide()

func trigger_dialogue(dialogue_resource) -> void:
	if dialogue_resource and Engine.has_singleton("DialogueManager"):
		var DialogueManager = Engine.get_singleton("DialogueManager")
		DialogueManager.show_dialogue(dialogue_resource)


# Handle incoming enemy HitBoxes
func _on_area_entered(area: Area2D) -> void:
	# ignore our own hitbox if layers overlap incorrectly
	if area == null:
		return
	if area.get_parent() == self:
		return
	# Player is immune to enemy damage, so ignore any hostile hitboxes
	return

# Toggle HitBox based on current attack animation frame
func _on_sprite_frame_changed() -> void:
	if not sprite:
		return
	var anim: StringName = sprite.animation
	var frame: int = sprite.frame
	var frames: SpriteFrames = sprite.sprite_frames
	var count: int = 0
	if frames and frames.has_animation(anim):
		count = frames.get_frame_count(anim)
	var active: bool = false
	if anim.begins_with("Atk"):
		var start: int = 1
		var end: int = min(3, max(1, count - 1))
		active = frame >= start and frame <= end
		_set_combo_hitboxes_active(anim, active)
	elif anim == "JumpAtk":
		var start2: int = JUMP_ATK_RESUME_FRAME
		var end2: int = max(start2, min(start2 + 2, count - 1))
		active = frame >= start2 and frame <= end2
		_set_jumpatk_hitbox_active(active)
	else:
		active = false
		_set_all_hitboxes_inactive()

func _set_hitbox_active(active: bool) -> void:
	if not hitbox or not hitbox_shape:
		return
	# position in front of player
	hitbox.position.x = 20.0 * facing_direction
	hitbox.set_deferred("monitoring", active)
	hitbox_shape.set_deferred("disabled", not active)
	# keep secondary boxes aligned too if they exist
	if hitbox2 and hitbox2_shape:
		hitbox2.position.x = 26.0 * facing_direction
		hitbox2.set_deferred("monitoring", active)
		hitbox2_shape.set_deferred("disabled", not active)
	if hitbox3 and hitbox3_shape:
		hitbox3.position.x = 32.0 * facing_direction
		hitbox3.set_deferred("monitoring", active)
		hitbox3_shape.set_deferred("disabled", not active)
	if hitbox4 and hitbox4_shape:
		hitbox4.position.x = 20.0 * facing_direction
		hitbox4.set_deferred("monitoring", active)
		hitbox4_shape.set_deferred("disabled", not active)

func _set_all_hitboxes_inactive() -> void:
	if hitbox and hitbox_shape:
		hitbox.set_deferred("monitoring", false)
		hitbox_shape.set_deferred("disabled", true)
	if hitbox2 and hitbox2_shape:
		hitbox2.set_deferred("monitoring", false)
		hitbox2_shape.set_deferred("disabled", true)
	if hitbox3 and hitbox3_shape:
		hitbox3.set_deferred("monitoring", false)
		hitbox3_shape.set_deferred("disabled", true)
	if hitbox4 and hitbox4_shape:
		hitbox4.set_deferred("monitoring", false)
		hitbox4_shape.set_deferred("disabled", true)

func _set_combo_hitboxes_active(anim: String, active: bool) -> void:
	# Atk1, Atk2 -> HitBox
	# Atk3 -> HitBox + HitBox2
	# Atk4 -> HitBox + HitBox2 + HitBox3
	# While inactive, ensure all are disabled
	if not active:
		_set_all_hitboxes_inactive()
		return
	# Position and enable per mapping
	if anim == "Atk1" or anim == "Atk2":
		if hitbox and hitbox_shape:
			hitbox.position.x = 20.0 * facing_direction
			hitbox.set_deferred("monitoring", true)
			hitbox_shape.set_deferred("disabled", false)
		# ensure others are off
		if hitbox2_shape:
			hitbox2_shape.set_deferred("disabled", true)
		if hitbox2:
			hitbox2.set_deferred("monitoring", false)
		if hitbox3_shape:
			hitbox3_shape.set_deferred("disabled", true)
		if hitbox3:
			hitbox3.set_deferred("monitoring", false)
		if hitbox4_shape:
			hitbox4_shape.set_deferred("disabled", true)
		if hitbox4:
			hitbox4.set_deferred("monitoring", false)
	elif anim == "Atk3":
		if hitbox and hitbox_shape:
			hitbox.position.x = 18.0 * facing_direction
			hitbox.set_deferred("monitoring", true)
			hitbox_shape.set_deferred("disabled", false)
		if hitbox2 and hitbox2_shape:
			hitbox2.position.x = 28.0 * facing_direction
			hitbox2.set_deferred("monitoring", true)
			hitbox2_shape.set_deferred("disabled", false)
		# turn off others
		if hitbox3_shape:
			hitbox3_shape.set_deferred("disabled", true)
		if hitbox3:
			hitbox3.set_deferred("monitoring", false)
		if hitbox4_shape:
			hitbox4_shape.set_deferred("disabled", true)
		if hitbox4:
			hitbox4.set_deferred("monitoring", false)
	elif anim == "Atk4":
		if hitbox and hitbox_shape:
			hitbox.position.x = 16.0 * facing_direction
			hitbox.set_deferred("monitoring", true)
			hitbox_shape.set_deferred("disabled", false)
		if hitbox2 and hitbox2_shape:
			hitbox2.position.x = 26.0 * facing_direction
			hitbox2.set_deferred("monitoring", true)
			hitbox2_shape.set_deferred("disabled", false)
		if hitbox3 and hitbox3_shape:
			hitbox3.position.x = 34.0 * facing_direction
			hitbox3.set_deferred("monitoring", true)
			hitbox3_shape.set_deferred("disabled", false)
		# ensure HitBox4 off
		if hitbox4_shape:
			hitbox4_shape.set_deferred("disabled", true)
		if hitbox4:
			hitbox4.set_deferred("monitoring", false)
	else:
		# fallback to primary only
		_set_hitbox_active(true)

func _set_jumpatk_hitbox_active(active: bool) -> void:
	if not active:
		_set_all_hitboxes_inactive()
		return
	# activate only HitBox4 during JumpAtk
	if hitbox4 and hitbox4_shape:
		hitbox4.position.x = 20.0 * facing_direction
		hitbox4.set_deferred("monitoring", true)
		hitbox4_shape.set_deferred("disabled", false)
	# others off
	if hitbox and hitbox_shape:
		hitbox.set_deferred("monitoring", false)
		hitbox_shape.set_deferred("disabled", true)
	if hitbox2 and hitbox2_shape:
		hitbox2.set_deferred("monitoring", false)
		hitbox2_shape.set_deferred("disabled", true)
	if hitbox3 and hitbox3_shape:
		hitbox3.set_deferred("monitoring", false)
		hitbox3_shape.set_deferred("disabled", true)

func _set_hitboxes_damage(dmg: int) -> void:
	if hitbox:
		hitbox.set("damage", dmg)
	if hitbox2:
		hitbox2.set("damage", dmg)
	if hitbox3:
		hitbox3.set("damage", dmg)
	if hitbox4:
		hitbox4.set("damage", dmg)
		
		# after the dialogue ends, run the exit sequence for enemy1

func _on_enemyarea_body_entered(body: Node2D) -> void:
	if has_triggeredmod:
		return
	has_triggeredmod = true
	if body.is_in_group("player"):
		enemy1.visible = true
		# 1) Play death animation once
		animMod.sprite_frames.set_animation_loop("moddeath", false)
		animMod.play("moddeath")
	# FORCE player to stop immediately (safe API call)
		# Show dialogue immediately after death animation starts
		#var txt = textbox_scene.instantiate()
		#get_tree().current_scene.add_child(txt)
		#if txt.has_method("enqueue_message"):
			#txt.enqueue_message("Lo, the Hollow Star doth awaken, and from its dread breath rise the beasts of shadow. ")
			#txt.enqueue_message("Tread not where the sun shineth not, for there the dark claimeth thee, and none return unbroken. ")
		# 2) Play idle animation for 2 seconds
		animMod.play("modIdle")
		await get_tree().create_timer(2.0).timeout
		# 3) Play walk animation while moving left
		animMod.play("modwalk")
		var target_pos = enemy1.position + Vector2(-280, 0)
		var tween = create_tween()
		tween.tween_property(enemy1, "position", target_pos, 10.0)
		await tween.finished  # wait until walk completes
		# 4) Play "modHurt" animation and move slightly back (-20px)
		animMod.sprite_frames.set_animation_loop("modHurt", false)
		animMod.play("modHurt")
 # adjust duration to match animation
		await animMod.animation_finished
		# 5) Play "modDis" animation
		animMod.sprite_frames.set_animation_loop("modDis", false)
		animMod.play("modDis")
		await animMod.animation_finished
		# 6) Remove enemy node from scene
		enemy1.queue_free()
		#scene_change_tp.visible = true
		#scenechange_area.monitoring = true


func _on_minoarea_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_tparea_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # make sure only the player teleports
		body.global_position = Vector2(1871, -254)
		

func _on_scenechange_area_body_entered(body: Node2D) -> void:
	# change_scene_to accepts a PackedScene resource in Godot 4
	if body.is_in_group("player"): 
		get_tree().change_scene_to_packed(Cha3cutscene_scene)

func _on_cha_3_cutscene_tp_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): 
		get_tree().change_scene_to_file("res://Assets/Chapters/chapter_3__2.tscn")

func _on_aggro_zone_body_entered(body: Node2D) -> void:
	if devildeath:
		return
	if body is CharacterBody2D:
		devil_in_aggro = true
		devil_aggro_body = body
		start_attack_cycle()  # start the attack asynchronously


func _on_aggro_zone_body_exited(body: Node2D) -> void:
	if body == devil_aggro_body:
		devil_in_aggro = false
		devil_aggro_body = null
		devil_attackeffect.stop()
		if is_instance_valid(devilanim):
			devilanim.play("devilidle")  # force idle immediately
func start_attack_cycle() -> void:
	# stop if devil dead or player left aggro
	if devildeath or not devil_in_aggro:
		if is_instance_valid(devilanim):
			devilanim.play("devilidle")
		return

	if not is_instance_valid(devilanim):
		return

	# play attack animation
	devilanim.play("devilatk2")
	await get_tree().process_frame
	await get_tree().process_frame

	if not devil_in_aggro or devildeath:
		if is_instance_valid(devilanim):
			devilanim.play("devilidle")
		return

	# freeze at frame 2


	if is_instance_valid(devil_attackeffect):
		devil_attackeffect.play("AttackEffect")
	var frames := devilanim.get_sprite_frames()
	if frames and frames.has_animation("devilatk2"):
		var max_idx := frames.get_frame_count("devilatk2") - 1
		devilanim.frame = clamp(2, 0, max_idx)
	else:
		devilanim.frame = 2
	devilanim.pause()
	await get_tree().create_timer(2.0).timeout

	if not devil_in_aggro or devildeath:
		if is_instance_valid(devilanim):
			devilanim.play("devilidle")
		return

	# return to idle
	if is_instance_valid(devilanim):
		devilanim.play("devilidle")

	await get_tree().create_timer(1.0).timeout

	# call next attack safely
	start_attack_cycle()

func _on_nightborne_aggro_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_instance_valid(enemyNightborne):
		if enemyNightborne.has_method("start_chase"):
			enemyNightborne.start_chase(body)
func _on_minoaggro_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_instance_valid(enemymino):
		if enemymino.has_method("start_mino_chase"):
			enemymino.start_mino_chase(body)
			
			
func _on_nightborne_aggro_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_instance_valid(enemyNightborne):
		if enemyNightborne.has_method("stop_chase"):
			enemyNightborne.stop_chase()
			
			
			
func _on_minoaggro_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_instance_valid(enemymino):
		if enemymino.has_method("stop_mino_chase"):
			enemymino.stop_mino_chase()
			
			

func _on_attack_zone_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_instance_valid(enemyNightborne):
		if enemyNightborne.has_method("attack_player"):
			enemyNightborne.attack_player()


func _on_mino_attack_zone_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_instance_valid(enemymino):
		if enemymino.has_method("attack_mino_player"):
			enemymino.attack_mino_player()

func _on_attack_zone_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_instance_valid(enemyNightborne):
		# re-enable the aggro area and resume chasing the player
		if enemyNightborne.has_method("enable_aggro"):
			enemyNightborne.enable_aggro()
		if enemyNightborne.has_method("start_chase"):
			enemyNightborne.start_chase(body)
  # seconds to wait AFTER Death animation, before respawn


func _on_mino_attack_zone_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_instance_valid(enemymino):
		# re-enable the aggro area and resume chasing the player
		if enemymino.has_method("enable_mino_aggro"):
			enemymino.enable_mino_aggro()
		if enemymino.has_method("start_mino_chase"):
			enemymino.start_mino_chase(body)

func _on_health_health_depleted() -> void:
	# 1) guard so we don't run twice
	if playerDeath:
		return
	playerDeath = true
	# 2) stop input & movement
	is_frozen = true
	is_hurt = false
	velocity = Vector2.ZERO
	# 3) disable collisions / hurtboxes so no more hits or pushes
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if has_node("HurtBox"):
		var hb = $HurtBox
		if hb is Area2D:
			hb.set_deferred("monitoring", false)
	# 4) stop timers/ongoing actions that might re-enable behaviors (optional)
	if has_node("ComboTimer"):
		$ComboTimer.stop()
	if has_node("RollCooldownTimer"):
		$RollCooldownTimer.stop()
	# 5) play Death animation if present (ensure it does NOT loop), otherwise short delay
	var death_anim := "Death"
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(death_anim):
		sprite.sprite_frames.set_animation_loop(death_anim, false)
		sprite.play(death_anim)
		print("player died! playing:", death_anim)
		await sprite.animation_finished
	else:
		push_warning("Death animation missing or sprite invalid; continuing after short delay")
		await get_tree().create_timer(0.25).timeout
	# ---- EXTRA PAUSE AFTER DEATH (so the death frame lingers) ----
	#if respawn_delay_after_death > 0.0:
		#await get_tree().create_timer(respawn_delay_after_death).timeout

	# ----------------- CHANGE SCENE TO CHAPTER_2_1 -----------------
	# Replace this path with the correct one in your project if needed:
	
	#var scene_path: String = "res://Assets/Chapters/chapter_2_1.tscn"
	get_tree().change_scene_to_file("res://Main_menu/Game_Over_Menu/Game_over_menu.tscn") # Call game over menu after the player die
	#var err := get_tree().change_scene_to_file(scene_path)
	#if err != OK:
		#push_warning("Failed to change scene to '%s' (error code %d). Check the path.".format(scene_path, err))
	#else:
		#print("Changing scene to: ", scene_path)
		# Note: once the scene actually changes, this node will be freed along with the current scene,
		# so no need to manually reset flags here.
		#if body.has_method("stop_immediately"):
			#body.stop_immediately(true)
#
		## then block global inputs (events + InputMap)
		#AutoLoad.block_all_except_space()
		
		
		#AutoLoad.restore_all_input()
		## resume player's local input state
		#if body.has_method("resume_input"):
			#body.resume_input()
