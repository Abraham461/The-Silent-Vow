extends CharacterBody2D
@onready var lightning_aura: AnimatedSprite2D = $lightningAura

@export var chase_speed: float = 130.0
@export var accel: float = 2000.0
@export var gravity: float = 1000.0
@export var stopping_distance: float = 20.0
@export var attack_anim_name: String = "NightborneAtk"   # change to your exact attack animation name
@export var attack_hit_offset: float = 28.0             # horizontal offset of hitbox from enemy center
# Set frames where hitbox should be active (frame indices, 0-based)
# Default below activates on frames 9 and 10 (0-based). Use [8,9] if you meant 1-based 9 & 10.
const ATTACK_HIT_FRAMES := [9]
var chase_target: Node2D = null
@onready var sprite: AnimatedSprite2D = $Enemy
# adjust this path to the actual Aggro Area2D node on the enemy
@onready var aggro_area: Area2D = $NightborneAggro
@onready var health: Health = $Health   # assuming your Health node is a child
@onready var attack_hitbox: HitBox = $HitBox
@onready var nightborne: CharacterBody2D = $"."
@onready var attack_zone: Area2D = $AttackZone
@onready var hurt_box: Area2D = $HurtBox

func start_chase(target: Node2D) -> void:
	chase_target = target
	if sprite:
		sprite.play("NightborneRun")

func stop_chase() -> void:
	chase_target = null
	if sprite:
		sprite.play("Idle")

func disable_aggro() -> void:
	# disable the aggro Area so it won't fire body_entered while in attack range
	if is_instance_valid(aggro_area):
		# use set_deferred to avoid changing properties mid-signal/physics
		aggro_area.set_deferred("monitoring", false)
	# also stop chasing immediately
	stop_chase()
	velocity.x = 0.0
#
#func disable_hurt() ->void:
	#if is_instance_valid(hurt_box):
		#hurt_box.set_deferred("monitoring",false)
func enable_aggro() -> void:
	if is_instance_valid(aggro_area):
		aggro_area.set_deferred("monitoring", true)
#func disable_attack() ->void:
	#if is_instance_valid(attack_zone):
		#attack_zone.set_deferred("monitoring",false)
func attack_player() -> void:
	# encapsulate attack behavior: disable aggro and play attack anim
	disable_aggro()
	if sprite:
		sprite.play("NightborneAtk")

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	var is_moving := false

	if chase_target and is_instance_valid(chase_target):
		var dir: Vector2 = chase_target.global_position - global_position
		if abs(dir.x) > stopping_distance:
			var desired_x: float = sign(dir.x) * chase_speed
			velocity.x = move_toward(velocity.x, desired_x, accel * delta)
			is_moving = true
			if sprite:
				sprite.flip_h = dir.x < 0
		else:
			velocity.x = move_toward(velocity.x, 0.0, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, accel * delta)

	move_and_slide()

	# animations
	if sprite:
		if is_moving and not sprite.is_playing():
			sprite.play("NightborneRun")
		elif not is_moving and sprite.animation != "Idle":
			sprite.play("Idle")




var Nightbornedeath := false
func _ready() -> void:
	# Connect the signal
	health.health_depleted.connect(_on_health_health_depleted)
	# make sure hitbox is off at start
	if is_instance_valid(attack_hitbox):
		attack_hitbox.monitoring = false
	# connect the frame changed signal to run our frame-based logic
	if sprite and sprite.has_signal("frame_changed"):
		sprite.frame_changed.connect(_on_sprite_frame_changed)
	# also ensure hitbox disabled when animation ends (safety)
	if sprite and sprite.has_signal("animation_finished"):
		sprite.animation_finished.connect(_on_sprite_animation_finished)
# Decide which side the player is on; returns 1 (right) or -1 (left)
func _determine_player_side() -> int:
	if chase_target and is_instance_valid(chase_target):
		var dx := chase_target.global_position.x - global_position.x
		if dx == 0:
			return 1
		return int(sign(dx))
	# fallback: use sprite.flip_h if no chase_target
	if sprite:
		return -1 if sprite.flip_h else 1
	return 1

# Called every time the sprite frame changes
func _on_sprite_frame_changed() -> void:
	# only do anything if we're in the attack animation
	if not sprite:
		return
	if String(sprite.animation) != attack_anim_name:
		# ensure hitbox off if other anims are playing
		if is_instance_valid(attack_hitbox) and attack_hitbox.monitoring:
			attack_hitbox.set_deferred("monitoring", false)
		return

	var f := sprite.frame
	# Activate hitbox only on the selected frames
	if f in ATTACK_HIT_FRAMES:
		# place hitbox left or right depending on player position
		var side := _determine_player_side()   # 1 or -1
		if is_instance_valid(attack_hitbox):
			attack_hitbox.position.x = abs(attack_hit_offset) * side
			attack_hitbox.set_deferred("monitoring", true)
			# optional debug:
			# print("Hitbox ON at frame", f, "side", side, "pos", attack_hitbox.position)
	else:
		# turn off when not in active frames
		if is_instance_valid(attack_hitbox) and attack_hitbox.monitoring:
			attack_hitbox.set_deferred("monitoring", false)

# Safety: ensure hitbox off when attack animation ends
func _on_sprite_animation_finished() -> void:
	if is_instance_valid(attack_hitbox):
		attack_hitbox.set_deferred("monitoring", false)


func _on_health_health_depleted() -> void:
	if Nightbornedeath:
		return
	print("Signal received")
	print("Now playing: ", sprite.animation)
	print("Total frames: ", sprite.sprite_frames.get_frame_count("Nightbornedeath"))
	print("Current frame: ", sprite.frame)
	print("Is playing: ", sprite.is_playing())
	Nightbornedeath = true
	stop_chase()
	sprite.play("Nightbornedeath")
	await sprite.animation_finished
	queue_free()
	
