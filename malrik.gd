# Demon.gd
extends CharacterBody2D

@onready var health: ProgressBar = $"../ProgressBar"
@onready var hurt_box: Area2D = $HurtBox
@onready var hit_box: Area2D = $HitBox
@onready var demonaggrozone: Area2D = $Malrikaggro
@onready var demonattackzone: Area2D = $MalrikAtkzone
@onready var sprite: AnimatedSprite2D = $Malrik
@onready var sprite2d: Sprite2D = get_node_or_null("Sprite2D")
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

const GRAVITY := 1000

@export var attack_anim_name: String = "FinalbossAtk"
@export var ATTACK_HIT_FRAMES: Array = [5,7,14,27,34]
@export var attack_cooldown: float = 1.0
@export var damage: int = 10

# true if sprite assets face RIGHT in editor; set appropriately in Inspector
@export var sprite_default_faces_right: bool = true

@export var debug: bool = false

@export var patrol_speed: float = 20.0
@export var chase_speed: float = 180.0

enum State { PATROL, CHASE, ATTACK }
var state: State = State.PATROL

var _player_ref: Node = null
var _player_in_aggro: bool = false
var _player_in_attack: bool = false
var _patrol_timer: float = 0.0
var _attack_timer: float = 0.0
var _start_pos: Vector2 = Vector2.ZERO

var facing_right: bool = true

var _hitbox_orig_pos: Vector2 = Vector2.ZERO
var _hitbox_offset: float = 0.0

func _ready() -> void:
	_start_pos = global_position
	# If you want the demon to initially face the direction the sprite art shows,
	# set facing_right to sprite_default_faces_right. You can override after testing.
	facing_right = sprite_default_faces_right

	if demonaggrozone:
		demonaggrozone.connect("body_entered", Callable(self, "_on_demonaggrozone_body_entered"))
		demonaggrozone.connect("body_exited", Callable(self, "_on_demonaggrozone_body_exited"))
	if demonattackzone:
		demonattackzone.connect("body_entered", Callable(self, "_on_demonattackzone_body_entered"))
		demonattackzone.connect("body_exited", Callable(self, "_on_demonattackzone_body_exited"))

	_attack_timer = 0.0

	if is_instance_valid(hit_box):
		_hitbox_orig_pos = hit_box.position
		_hitbox_offset = abs(_hitbox_orig_pos.x)
		hit_box.monitoring = false

	if sprite:
		if sprite.has_signal("frame_changed"):
			sprite.frame_changed.connect(_on_sprite_frame_changed)
		if sprite.has_signal("animation_finished"):
			sprite.animation_finished.connect(_on_sprite_animation_finished)

	# debug: report available animations for quick checking
	if debug and sprite and sprite.sprite_frames:
		var names = sprite.sprite_frames.get_animation_names()
		print("[Demon] AnimatedSprite2D animations:", names)

	_apply_visual_facing(facing_right)
	_set_hitbox_side(facing_right)

	if debug:
		print("Demon ready. sprite_default_faces_right=", sprite_default_faces_right, " initial facing_right=", facing_right)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = velocity.y # keep current y (or zero above if you want)

	if _player_ref and not is_instance_valid(_player_ref):
		_player_ref = null
		_player_in_aggro = false
		_player_in_attack = false

	if _player_ref and is_instance_valid(_player_ref):
		_update_facing_towards_point(_player_ref.global_position)
	else:
		if state == State.PATROL and abs(velocity.x) > 1e-4:
			_apply_facing(velocity.x > 0.0)

	# choose state
	if _player_in_attack and _player_ref:
		state = State.ATTACK
	elif _player_in_aggro and _player_ref:
		state = State.CHASE
	else:
		state = State.PATROL

	match state:
		State.PATROL:
			_patrol_timer += delta
			_play_directional_anim("Finalbossrun", facing_right)
			var vx = cos(_patrol_timer * 2.8) * patrol_speed
			velocity.x = vx
			move_and_slide()

		State.CHASE:
			_play_directional_anim("Finalbossrun", facing_right)
			if _player_ref and is_instance_valid(_player_ref):
				var dir = (_player_ref.global_position - global_position)
				if dir.length() > 0.1:
					dir = dir.normalized()
					# only chase horizontally (preserve gravity/vertical velocity)
					velocity.x = dir.x * chase_speed
				else:
					velocity.x = 0.0
			else:
				velocity.x = 0.0
			move_and_slide()

		State.ATTACK:
			_play_directional_anim(attack_anim_name, facing_right)
			velocity.x = 0.0
			move_and_slide()
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_attack_timer = attack_cooldown
				_do_attack()


func _do_attack() -> void:
	if not _player_ref or not is_instance_valid(_player_ref):
		return
	if _player_ref.has_method("take_damage"):
		_player_ref.take_damage(damage)
	elif _player_ref.has_method("apply_damage"):
		_player_ref.apply_damage(damage)


# Area callbacks
func _on_demonaggrozone_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_aggro = true
		_player_ref = body
		if debug: print("Aggro enter:", body)
	else:
		if debug: print("Non-player entered aggro zone:", body)
		_update_facing_towards_point(body.global_position)


func _on_demonaggrozone_body_exited(body: Node) -> void:
	if body == _player_ref:
		_player_in_aggro = false
		if not _player_in_attack:
			_player_ref = null
		if debug: print("Aggro exit:", body)


func _on_demonattackzone_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_attack = true
		_player_ref = body
		_attack_timer = 0.0
		_update_facing_towards_point(body.global_position)
		if debug: print("Attack zone enter:", body)


func _on_demonattackzone_body_exited(body: Node) -> void:
	if body == _player_ref:
		_player_in_attack = false
		if not _player_in_aggro:
			_player_ref = null
		if debug: print("Attack zone exit:", body)


# AnimatedSprite2D frame logic
func _on_sprite_frame_changed() -> void:
	if not sprite:
		return
	var current_anim := String(sprite.animation)
	if not current_anim.begins_with(attack_anim_name):
		if is_instance_valid(hit_box) and hit_box.monitoring:
			hit_box.set_deferred("monitoring", false)
		return

	var f := sprite.frame
	if debug: print("Attack frame:", f, "anim:", current_anim)

	if f in ATTACK_HIT_FRAMES:
		_set_hitbox_side(facing_right)
		if is_instance_valid(hit_box) and hit_box.has_method("pulse"):
			hit_box.call_deferred("pulse")
			if debug: print("pulse() called")
		else:
			if is_instance_valid(hit_box):
				hit_box.set_deferred("monitoring", true)
	else:
		if is_instance_valid(hit_box) and hit_box.monitoring:
			hit_box.set_deferred("monitoring", false)


func _on_sprite_animation_finished() -> void:
	if is_instance_valid(hit_box):
		hit_box.set_deferred("monitoring", false)
		if debug: print("Animation finished - hitbox disabled")


# Facing helpers
func _update_facing_towards_point(point: Vector2) -> void:
	var to_player_x = point.x - global_position.x
	if abs(to_player_x) > 1.0:
		_apply_facing(to_player_x > 0.0)


func _apply_facing(right: bool) -> void:
	facing_right = right
	_apply_visual_facing(right)
	_set_hitbox_side(right)


func _apply_visual_facing(right: bool) -> void:
	# flip_h decision: true if we need to flip horizontally
	var desired_flip = (right != sprite_default_faces_right)
	if sprite:
		sprite.flip_h = desired_flip
		if debug: print("AnimatedSprite2D.flip_h =", sprite.flip_h, " right:", right, " sprite_default_faces_right:", sprite_default_faces_right)
	elif sprite2d:
		sprite2d.flip_h = desired_flip
		if debug: print("Sprite2D.flip_h =", sprite2d.flip_h)
	else:
		if debug: print("No sprite node found to flip; skipping visual flip")


func _set_hitbox_side(right: bool) -> void:
	if is_instance_valid(hit_box):
		hit_box.position = Vector2(_hitbox_offset * (1 if right else -1), _hitbox_orig_pos.y)
		if debug: print("Hitbox positioned:", hit_box.position)


# Animation helpers
func _play_directional_anim(base_name: String, right: bool) -> void:
	var candidate := _get_directional_anim_name(base_name, right)
	_play_anim_safe(candidate)


func _get_directional_anim_name(base_name: String, right: bool) -> String:
	var right_name = base_name + "Right"
	var left_name  = base_name + "Left"

	if sprite:
		var sf = sprite.sprite_frames
		if sf:
			# debug: show candidates
			if debug: print("_get_directional_anim_name candidates:", right_name, left_name, base_name)
			if right and sf.has_animation(right_name):
				return right_name
			if not right and sf.has_animation(left_name):
				return left_name
			if sf.has_animation(base_name):
				return base_name
			if sf.has_animation(left_name):
				return left_name
			if sf.has_animation(right_name):
				return right_name
			return base_name

	if anim_player:
		if debug: print("_get_directional_anim_name (anim_player) candidates:", right_name, left_name, base_name)
		if right and anim_player.has_animation(right_name):
			return right_name
		if not right and anim_player.has_animation(left_name):
			return left_name
		if anim_player.has_animation(base_name):
			return base_name
		if anim_player.has_animation(left_name):
			return left_name
		if anim_player.has_animation(right_name):
			return right_name
		return base_name

	return base_name


func _play_anim_safe(anim_name: String) -> void:
	if sprite:
		var sf = sprite.sprite_frames
		var exists := sf and sf.has_animation(anim_name)
		if debug: print("[play_anim_safe] trying:", anim_name, "exists:", exists)
		if sf and exists:
			if sprite.animation != anim_name:
				sprite.play(anim_name)
		else:
			# helpful debug: list available animations when missing
			if debug and sf:
				print("[play_anim_safe] available animations:", sf.get_animation_names())
		return
	if anim_player:
		if debug: print("[play_anim_safe] using AnimationPlayer, trying:", anim_name, "exists:", anim_player.has_animation(anim_name))
		if anim_player.has_animation(anim_name):
			if anim_player.current_animation != anim_name:
				anim_player.play(anim_name)
		return
