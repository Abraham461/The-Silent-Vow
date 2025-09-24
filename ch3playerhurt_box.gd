extends Area2D

signal received_damage(damage: int)

@onready var health: playerHealth = $"../playerHealth"


@onready var playeranim: AnimatedSprite2D = $"../AnimatedSprite2D"

var _hitboxes_in_contact := {}
var is_hurt: bool = false
var player: bool = false

#@onready var health_bar: ProgressBar = $"../../../CanvasLayer2/UHD/HealthBar"
@onready var health_bar: ProgressBar = $"../../CanvasLayer2/UHD/HealthBar"

@onready var hurt_cooldown: Timer = $"../HurtTimer"
@onready var hurt_box: Area2D = $"."
@onready var shield: AnimatedSprite2D = $shield

func _ready() -> void:
	shield.play("default")
	# connect area signals
	if not is_connected("area_entered", Callable(self, "_on_hit_box_area_entered")):
		connect("area_entered", Callable(self, "_on_hit_box_area_entered"))
	if not is_connected("area_exited", Callable(self, "_on_area_exited")):
		connect("area_exited", Callable(self, "_on_area_exited"))

	# ensure the 'TakeHit' animation is NOT looping
	if playeranim.sprite_frames and playeranim.sprite_frames.has_animation("TakeHit"):
		playeranim.sprite_frames.set_animation_loop("TakeHit", false)

	# connect AnimatedSprite2D's animation_finished
	if not playeranim.is_connected("animation_finished", Callable(self, "_on_devil_animation_finished")):
		playeranim.connect("animation_finished", Callable(self, "_on_devil_animation_finished"))

	# listen to health depletion → mark as dead
	if not health.health_depleted.is_connected(Callable(self, "_on_health_depleted")):
		health.health_depleted.connect(_on_health_depleted)





func _on_devil_animation_finished() -> void:
	if playeranim.animation == "Death":
		is_hurt = false
		# only return to idle if still alive
		if not player:
			playeranim.play("Idle")
			


func _on_health_depleted() -> void:
	# mark death so HurtBox ignores future hits
	player = true
	is_hurt = false
	playeranim.play("Death")
	await playeranim.animation_finished
	print("player died! HurtBox disabled.")



#func _on_area_exited(area: Area2D) -> void:

func _on_hit_box_area_exited(area: Area2D) -> void:
	if area is malrikHitBox:
		var id := area.get_instance_id()
		if id in _hitboxes_in_contact:
			_hitboxes_in_contact.erase(id)
			print("malrikHitBox exit, cleared from contact set: ", area)
var is_rolling := false

# ----- Input / roll checks -----
func _physics_process(delta: float) -> void:
	# continuously check for roll start / end while processing input
	_check_roll_start()
	_check_roll_end()

# Call this to check if the player started a roll or slide
func _check_roll_start() -> void:
	if Input.is_action_just_pressed("Roll") or Input.is_action_just_pressed("Slide"):
		_on_roll_started()

# Call this to check if roll should be ended by an input (Jump, Atk, Heal, Pray)
func _check_roll_end() -> void:
	if is_rolling:
		if Input.is_action_just_pressed("Jump") \
		or Input.is_action_just_pressed("Atk") \
		or Input.is_action_just_pressed("Heal") \
		or Input.is_action_just_pressed("Left") \
		or Input.is_action_just_pressed("Right") \
		or Input.is_action_just_pressed("Pray"):
			_on_roll_ended()

func _on_roll_started() -> void:
	is_rolling = true
	shield.visible = true
	# optionally stop hurt detection while rolling (deferred to be safe)
	if hurt_box:
		hurt_box.set_deferred("monitoring", false)
	# play roll animation / apply roll velocity here:
	# playeranim.play("Roll")
	# velocity.x = roll_speed * facing_sign  (if you use that)

func _on_roll_ended() -> void:
	is_rolling = false
	shield.visible = false
	if hurt_box:
		hurt_box.set_deferred("monitoring", true)
	# revert animation/velocity changes as needed
	# playeranim.play("Idle")		
func _on_hit_box_area_entered(area: Area2D) -> void:
	# If currently rolling, ignore damage
	if is_rolling:
		return

	if area is malrikHitBox:
		
		var hb: malrikHitBox = area
		var hb_id := hb.get_instance_id()        # store the id now
		_hitboxes_in_contact[hb_id] = true
		health.set_health(health.get_health() - hb.damage)
		health_bar.value -= hb.damage
		received_damage.emit(hb.damage)
		playeranim.play("TakeHit")
		is_hurt = true
		var tween  = get_tree().create_tween()
		tween.tween_method(SetShader_BlinkIntensity, 1.0,0.0,0.5)


		await get_tree().create_timer(1).timeout
		is_hurt = false

		_hitboxes_in_contact.erase(hb_id)

func SetShader_BlinkIntensity(newValue : float):
	playeranim.material.set_shader_parameter("blink_intensity", newValue)
func frameFreeze(timeScale, duration):
	Engine.time_scale = timeScale
	await(get_tree().create_timer(duration * timeScale).timeout)
	Engine.time_scale = 1.0
	
	#if Input.is_action_just_pressed("Jump"):
		#hurt_box.monitoring = true
	#elif Input.is_action_just_pressed("Roll"):
		#hurt_box.monitoring = false
	#elif Input.is_action_just_pressed("Slide"):
		#hurt_box.monitoring = false
	#elif Input.is_action_just_pressed("Atk"):
		#hurt_box.monitoring = true
	#elif Input.is_action_just_pressed("Heal"):
		#hurt_box.monitoring = true
	#elif Input.is_action_just_pressed("Pray"):
		#hurt_box.monitoring = true
	#if player or (hurt_cooldown and not hurt_cooldown.is_stopped()):
		#return  # ignore hits if dead or iFrame active
			# do not reference `hb` after awaits — use hb_id when you need to remove it
		#await get_tree().create_timer(0.3).timeout
		#playeranim.play("TakeHit")
		#print("It's a malrikHitBox! Damage = ", hb.damage)  # only safe if you still reference hb here;
		# if hb might be freed, avoid using hb.* fields after awaits (use stored data instead)
# ensure this is initialized (e.g. in _ready)
