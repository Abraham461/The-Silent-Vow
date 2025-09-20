extends CharacterBody2D

# --- Tweakables ---
@export var chase_speed: float = 100.0
@export var accel: float = 2000.0
@export var gravity: float = 1000.0
@export var stopping_distance: float = 20.0

@export var walk_anim_name: String = "minowalk"
@export var idle_anim_name: String = "minoidle"
@export var attack_anim_name: String = "minoatk"   # exact attack animation name
@export var death_anim_name: String = "minodeath"

@export var attack_hit_offset: float = 28.0        # horizontal offset of hitbox from enemy center
const ATTACK_HIT_FRAMES := [3]                      # active only on frame 3 (0-based)

# --- Nodes (adjust paths if your scene is different) ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aggro_area: Area2D = $Minoaggro
@onready var attack_zone: Area2D = $minoAttackZone
@onready var attack_hitbox: HitBox = $HitBox
@onready var health: Node = $minoHealth            # keep this if you have a health node

# --- State ---
var chase_target: Node2D = null
var is_attacking: bool = false
var minodeath: bool = false

# pending chase target when attack is still playing (so we don't interrupt animation)
var _pending_chase_target: Node2D = null

# A simple counter to identify the current attack instance (optional)
var _attack_instance_id: int = 0

func _ready() -> void:
	# ensure hitbox is off at start
	if is_instance_valid(attack_hitbox):
		attack_hitbox.monitoring = false

	# connect sprite signals for frame and animation events
	if sprite:
		if sprite.has_signal("frame_changed"):
			sprite.frame_changed.connect(_on_sprite_frame_changed)
		if sprite.has_signal("animation_finished"):
			sprite.animation_finished.connect(_on_sprite_animation_finished)

	# connect aggro/attack zone signals (expecting "player" group on player)
	if is_instance_valid(aggro_area):
		if aggro_area.has_signal("body_entered"):
			aggro_area.body_entered.connect(_on_aggro_body_entered)
		if aggro_area.has_signal("body_exited"):
			aggro_area.body_exited.connect(_on_aggro_body_exited)

	if is_instance_valid(attack_zone):
		if attack_zone.has_signal("body_entered"):
			attack_zone.body_entered.connect(_on_attack_zone_body_entered)
		if attack_zone.has_signal("body_exited"):
			attack_zone.body_exited.connect(_on_attack_zone_body_exited)


# ----------------------
# Movement / chasing
# ----------------------
func start_mino_chase(target: Node2D) -> void:
	chase_target = target
	_pending_chase_target = null
	# only change animation if not currently attacking
	if sprite and not is_attacking:
		sprite.play(walk_anim_name)

func stop_mino_chase() -> void:
	chase_target = null
	_pending_chase_target = null
	if sprite and not is_attacking:
		sprite.play(idle_anim_name)

func disable_mino_aggro() -> void:
	if is_instance_valid(aggro_area):
		aggro_area.set_deferred("monitoring", false)
	stop_mino_chase()
	velocity.x = 0.0

func enable_mino_aggro() -> void:
	if is_instance_valid(aggro_area):
		aggro_area.set_deferred("monitoring", true)


func _physics_process(delta: float) -> void:
	# gravity (simple)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	var is_moving := false

	# only chase when not attacking
	if not is_attacking and chase_target and is_instance_valid(chase_target):
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

	# built-in movement
	move_and_slide()

	# animation switching when not attacking
	if sprite and not is_attacking:
		if is_moving:
			if sprite.animation != walk_anim_name or not sprite.is_playing():
				sprite.play(walk_anim_name)
		else:
			if sprite.animation != idle_anim_name:
				sprite.play(idle_anim_name)


# ----------------------
# Attacking
# ----------------------
func attack_mino_player() -> void:
	# start an attack (called when player enters attack_zone)
	if is_attacking or minodeath:
		return
	is_attacking = true
	_attack_instance_id += 1
	# stop movement and temporarily disable aggro so the enemy doesn't chase mid-attack
	velocity.x = 0.0
	disable_mino_aggro()
	# play attack animation
	if sprite:
		sprite.play(attack_anim_name)


# Called when the sprite's frame changes; we'll enable the hitbox only on frame 3
func _on_sprite_frame_changed() -> void:
	if not sprite:
		return

	# If not the attack animation, ensure hitbox off and skip
	if String(sprite.animation) != attack_anim_name:
		if is_instance_valid(attack_hitbox):
			attack_hitbox.set_deferred("monitoring", false)
		return

	# Get current frame (0-based)
	var f := sprite.frame
	# Only enable the hitbox on the exact frame we want (frame 3 here)
	if f in ATTACK_HIT_FRAMES:
		# decide left/right (1 -> right, -1 -> left)
		var side := _determine_player_side()
		if is_instance_valid(attack_hitbox):
			# set position immediately so the hitbox is placed correctly this frame
			attack_hitbox.position.x = abs(attack_hit_offset) * side
			# enable monitoring immediately for this frame
			attack_hitbox.monitoring = true
			attack_hitbox.set_meta("attack_id", _attack_instance_id)
	else:
		# for all other frames of the attack animation, disable the hitbox
		if is_instance_valid(attack_hitbox):
			attack_hitbox.set_deferred("monitoring", false)


# Called when attack animation finishes
func _on_sprite_animation_finished() -> void:
	# if attack finished, clear state and re-enable aggro
	if sprite and String(sprite.animation) == attack_anim_name:
		is_attacking = false
		# guarantee hitbox is off
		if is_instance_valid(attack_hitbox):
			attack_hitbox.set_deferred("monitoring", false)
		# re-enable aggro so enemy can chase again
		enable_mino_aggro()
		# if a chase was requested while attacking, start it now; otherwise pick anim
		if _pending_chase_target and is_instance_valid(_pending_chase_target):
			start_mino_chase(_pending_chase_target)
			_pending_chase_target = null
		else:
			if chase_target:
				sprite.play(walk_anim_name)
			else:
				sprite.play(idle_anim_name)
	else:
		# safety: ensure hitbox off for any other animation end
		if is_instance_valid(attack_hitbox):
			attack_hitbox.set_deferred("monitoring", false)


# ----------------------
# Utility / signals from areas
# ----------------------
func _determine_player_side() -> int:
	# if chasing a player use its position, otherwise use sprite.flip_h
	if chase_target and is_instance_valid(chase_target):
		var dx := chase_target.global_position.x - global_position.x
		if dx == 0:
			return 1
		return int(sign(dx))
	if sprite:
		return -1 if sprite.flip_h else 1
	return 1


func _on_aggro_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# If the player enters the aggro area, start chasing immediately
		start_mino_chase(body)

func _on_aggro_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		# if the current chase target left the aggro area, stop chasing
		if chase_target == body:
			stop_mino_chase()


func _on_attack_zone_body_entered(body: Node) -> void:
	# when player enters attack zone, start an attack
	if body.is_in_group("player"):
		attack_mino_player()

func _on_attack_zone_body_exited(body: Node) -> void:
	# When the player leaves the attack (close) zone, re-enable aggro and chase the player
	# BUT: if we're currently mid-attack, queue the chase until the attack animation finishes.
	if not body.is_in_group("player"):
		return
	if minodeath:
		return

	# Ensure aggro monitoring is enabled so aggro/exit logic works as expected afterwards
	enable_mino_aggro()

	# If we're still playing the attack animation, queue the chase target to start when the attack ends
	if is_attacking:
		_pending_chase_target = body
	else:
		# start chasing immediately
		start_mino_chase(body)


# Example: when health reaches zero (if your health node emits this)
func _on_mino_health_health_depleted() -> void:
	if minodeath:
		return
	minodeath = true
	stop_mino_chase()
	if sprite:
		sprite.play(death_anim_name)
		await sprite.animation_finished
	queue_free()
