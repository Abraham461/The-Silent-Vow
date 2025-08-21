extends CharacterBody2D

enum State { Idle, Run, ATTACK, HURT, DEAD }

@export var move_speed: float = 100.0
@export var gravity: float = 900.0
@export var aggro_radius: float = 260.0
@export var deaggro_radius: float = 400.0
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 1.0
@export var attack_damage: int = 10
@export var dash_speed: float = 360.0
@export var attack_windup: float = 1.0
@export var attack_active: float = 0.18
@export var attack_recovery: float = 0.35

# New: global animation speed multiplier (1.0 = normal)
@export var animation_speed: float = 1.0
# New: chance an incoming hit will interrupt an in-progress attack (0.0 - 1.0)
@export var attack_interrupt_chance: float = 0.35

@onready var _sprite: AnimatedSprite2D = _find_sprite()
@onready var _health: Node = get_node_or_null("Health")
@onready var _hurtbox: Area2D = get_node_or_null("HurtBox")
@onready var _hitbox: Area2D = _ensure_hitbox()
@onready var _hitbox_shape: CollisionShape2D = _hitbox.get_node_or_null("CollisionShape2D") if _hitbox else null
@onready var _anim_player: AnimationPlayer = get_node_or_null("Enemy2") as AnimationPlayer

var _state: State = State.Idle
var _cooldown_timer: float = 0.0
var _direction: int = 1
var _player: CharacterBody2D = null
var _activated: bool = false

# attack control
var _attack_locked: bool = false        # prevents re-entry
var _attack_cancelled: bool = false     # set to true when interrupted
# new helpers / tuning



func _ready():
	# wire signals
	if _health and _health.has_signal("health_depleted") and not _health.health_depleted.is_connected(_on_health_depleted):
		_health.health_depleted.connect(_on_health_depleted)
	if _hurtbox and _hurtbox.has_signal("recieved_damage") and not _hurtbox.recieved_damage.is_connected(_on_recieved_damage):
		_hurtbox.recieved_damage.connect(_on_recieved_damage)

	_set_hitbox_active(false)
	_player = _find_player()

	var actionable: Area2D = get_node_or_null("Actionable") as Area2D
	if actionable and not actionable.is_connected("body_entered", Callable(self, "_on_actionable_body_entered")):
		actionable.connect("body_entered", Callable(self, "_on_actionable_body_entered"))

	# Apply animation speed to nodes that support it
	if _sprite:
		_sprite.speed_scale = animation_speed
	if _anim_player:
		_anim_player.speed_scale = animation_speed

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not _activated:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_facing()
		_update_animation()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if _player == null or not is_instance_valid(_player):
		_player = _find_player()

	match _state:
		State.Idle:
			velocity.x = 0
			if _player and _distance_to_player() <= aggro_radius:
				_change_state(State.Run)
		State.Run:
			if not _player:
				_change_state(State.Idle)
				pass
			else:
				var dist := _distance_to_player()
				if dist > deaggro_radius:
					_change_state(State.Idle)
				else:
					_chase_player()
					if dist <= attack_range and _cooldown_timer <= 0.0:
						_start_attack()
		State.ATTACK:
			# movement during attack is controlled by _start_attack()
			pass
		State.HURT:
			velocity.x = move_toward(velocity.x, 0, 600 * delta)

	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	move_and_slide()
	_update_facing()
	_update_animation()

func _chase_player() -> void:
	var dir: float = sign(_player.global_position.x - global_position.x)
	if dir != 0.0:
		_direction = -1 if dir < 0.0 else 1
	velocity.x = _direction * move_speed

func _start_attack() -> void:
	# Prevent re-entry if an attack already executing
	if _attack_locked or _state == State.ATTACK:
		return

	_attack_locked = true
	_attack_cancelled = false
	_change_state(State.ATTACK)
	# NOTE: set cooldown at end of the full attack sequence (including chains)
	# pick a pattern: 0 light, 1 heavy, 2 thrust. Bias based on distance
	var dist := _distance_to_player()
	var pattern := 0
	if dist < attack_range * 0.6:
		pattern = randi() % 2
	else:
		pattern = 2

	# We'll allow chaining inside the same coroutine to avoid re-entrancy
	while true:
		velocity.x = 0
		_set_hitbox_active(false)

		# pick sprite animation
		if _sprite and _sprite.sprite_frames:
			var frames: SpriteFrames = _sprite.sprite_frames
			if frames.has_animation("NightBorneAtk"):
				_sprite.play("NightBorneAtk")
			elif frames.has_animation("Atk"):
				_sprite.play("Atk")
			elif frames.has_animation("Attack"):
				_sprite.play("Attack")
			_sprite.speed_scale = animation_speed

		# optional dash
		var dash_vel := Vector2.ZERO
		if pattern == 2:
			dash_vel.x = _direction * dash_speed

		# WINDUP (can be interrupted here)
		await get_tree().create_timer(attack_windup).timeout
		if _attack_cancelled:
			# attack interrupted during windup
			_handle_attack_interruption()
			# set cooldown so enemy doesn't immediately try again
			_cooldown_timer = attack_cooldown
			return

		# ACTIVE
		if _hitbox:
			_hitbox.set("damage", attack_damage)
		_set_hitbox_active(true)
		if pattern == 2:
			velocity.x = dash_vel.x

		await get_tree().create_timer(attack_active).timeout
		if _attack_cancelled:
			# interrupted during active frames
			_set_hitbox_active(false)
			velocity.x = 0
			_handle_attack_interruption()
			_cooldown_timer = attack_cooldown
			return

		# finish active window
		_set_hitbox_active(false)
		velocity.x = 0

		# RECOVERY (can also be interrupted here if you want — current logic allows interruptions)
		await get_tree().create_timer(attack_recovery).timeout
		if _attack_cancelled:
			_handle_attack_interruption()
			_cooldown_timer = attack_cooldown
			return

		# optional quick chain only for light attack (pattern 0)
		var do_chain := false
		if pattern == 0 and randf() < 0.35 and _player and _distance_to_player() <= attack_range * 1.1:
			do_chain = true

		if do_chain:
			# Prepare for next iteration (keep lock, recalc pattern if needed)
			_cooldown_timer = max(_cooldown_timer, 0.25)
			# keep pattern as light (0) for a follow-up — or you can recompute based on new distance
			pattern = 0
			# loop continues and we perform another attack immediately (no re-entry)
			continue
		else:
			# end entire attack flow:
			_attack_locked = false
			_cooldown_timer = attack_cooldown
			_change_state(State.Run)
			return

func _handle_attack_interruption() -> void:
	# cancel state and play interruption animation
	_attack_locked = false
	_attack_cancelled = false
	_set_hitbox_active(false)
	velocity.x = 0
	_change_state(State.HURT)
	if _sprite and _sprite.sprite_frames:
		if _sprite.sprite_frames.has_animation("Interrupted"):
			_sprite.play("Interrupted")
		else:
			_sprite.play("TakeHit")

func _update_facing() -> void:
	if _sprite:
		_sprite.flip_h = _direction < 0

func _update_animation() -> void:
	if not _sprite:
		return

	# keep node speed in sync (in case you change animation_speed at runtime)
	_sprite.speed_scale = animation_speed
	if _anim_player:
		_anim_player.speed_scale = animation_speed

	if _state == State.DEAD:
		# if AnimatedSprite has death anim, play it; animation player also used for death
		if _sprite.sprite_frames and _sprite.sprite_frames.has_animation("NightBorneDeath"):
			if _sprite.animation != "NightBorneDeath":
				_sprite.play("NightBorneDeath")
		elif _sprite.sprite_frames and _sprite.sprite_frames.has_animation("Death"):
			if _sprite.animation != "Death":
				_sprite.play("Death")
		return

	if _state == State.HURT:
		# if Interrupted animation exists, prefer that (it may be used by _handle_attack_interruption)
		if _sprite.animation != "NightBorneTakeHit" and _sprite.animation != "Interrupted":
			if _sprite.sprite_frames and _sprite.sprite_frames.has_animation("NightBorneTakeHit"):
				_sprite.play("NightBorneTakeHit")
			else:
				_sprite.play("TakeHit")
		return

	if _state == State.ATTACK:
		# attack animation is handled in _start_attack; don't override here
		return

	if abs(velocity.x) > 5 and is_on_floor():
		if _sprite.animation != "NightBorneRun":
			_sprite.play("Run")
	else:
		if _sprite.animation != "NightBorneIdle":
			_sprite.play("Idle")

func _on_recieved_damage(_dmg: int) -> void:
	# if dead already, ignore
	if _state == State.DEAD:
		return

	# if attacking, maybe interrupt depending on chance
	if _attack_locked:
		# interruption chance (can tune). If interrupted, set cancel flag and play immediate interruption anim
		if randf() < clamp(attack_interrupt_chance, 0.0, 1.0):
			_attack_cancelled = true
			# immediate visual reaction handled by _handle_attack_interruption / attack coroutine check
			# we also proactively call _handle_attack_interruption to show instant feedback
			_handle_attack_interruption()
			# optionally reduce health handled by Health node elsewhere
			return
		else:
			# not interrupted: ignore state change but still allow health change
			return

	# normal hurt flow if not attacking
	_change_state(State.HURT)
	await get_tree().create_timer(0.2).timeout
	if _health and _health.get("health") > 0:
		if _player and _distance_to_player() <= deaggro_radius:
			_change_state(State.Run)
		else:
			_change_state(State.Idle)

func _on_actionable_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		_activated = true

func _on_health_depleted() -> void:
	# allow death even if mid-attack; force transitions
	_change_state(State.DEAD, true)
	_attack_cancelled = true
	_attack_locked = false
	_set_hitbox_active(false)
	velocity = Vector2.ZERO

	# AnimatedSprite2D death if available
	if _sprite and _sprite.sprite_frames:
		if _sprite.sprite_frames.has_animation("NightBorneDeath"):
			_sprite.play("NightBorneDeath")
		elif _sprite.sprite_frames.has_animation("Death"):
			_sprite.play("Death")

	# AnimationPlayer death if available
	if _anim_player and _anim_player.has_animation("NightBorneDeath"):
		_anim_player.speed_scale = animation_speed
		_anim_player.play("NightBorneDeath")
		var anim: Animation = _anim_player.get_animation("NightBorneDeath")
		if anim:
			anim.loop_mode = Animation.LOOP_NONE
		if not _anim_player.animation_finished.is_connected(_on_death_animation_finished):
			_anim_player.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
	else:
		# fallback: give brief moment for sprite animation to play, then free
		await get_tree().create_timer(0.05).timeout
		queue_free()

func _on_health_health_depleted() -> void:
	_on_health_depleted()

func _on_death_animation_finished(anim_name: String) -> void:
	if anim_name == "NightBorneDeath":
		queue_free()

# changed: optional 'force' so death can override attack lock
func _change_state(s: State, force: bool=false) -> void:
	# if currently attacking, don't switch out of attack unless forced or becoming DEAD
	if _state == State.ATTACK and not force and s != State.DEAD:
		return
	_state = s

func _set_hitbox_active(active: bool) -> void:
	if _hitbox:
		_hitbox.set_deferred("monitoring", active)
	if _hitbox_shape:
		_hitbox_shape.set_deferred("disabled", not active)
	if active and _hitbox:
		_hitbox.position.x = 16.0 * _direction

func _distance_to_player() -> float:
	if not _player:
		return INF
	return global_position.distance_to(_player.global_position)

func _find_player() -> CharacterBody2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		for p in players:
			if p is CharacterBody2D:
				return p

	var root := get_tree().current_scene
	if root:
		var stack := [root]
		while stack.size() > 0:
			var cur = stack.pop_back()
			for c in cur.get_children():
				stack.push_back(c)
				if c is CharacterBody2D and c != self:
					return c
	return null

func _find_sprite() -> AnimatedSprite2D:
	if has_node("Enemy") and get_node("Enemy") is AnimatedSprite2D:
		return get_node("Enemy")
	for c in get_children():
		if c is AnimatedSprite2D:
			return c
	return null

func _ensure_hitbox() -> Area2D:
	if has_node("HitBox") and get_node("HitBox") is Area2D:
		return get_node("HitBox")
	var hb := Area2D.new()
	hb.name = "HitBox"
	add_child(hb)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# RectangleShape2D uses 'extents' (half-size), not 'size'
	rect.extents = Vector2(11, 8)
	shape.shape = rect
	hb.add_child(shape)
	hb.set("damage", attack_damage)
	return hb
