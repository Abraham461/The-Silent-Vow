extends CharacterBody2D

enum State { Idle, Run, ATTACK, HURT, DEAD }

@export var move_speed: float = 100.0
@export var gravity: float = 900.0
@export var aggro_radius: float = 260.0
@export var deaggro_radius: float = 400.0
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 1.2
@export var attack_damage: int = 10
@export var dash_speed: float = 360.0
@export var attack_windup: float = 0.25
@export var attack_active: float = 0.18
@export var attack_recovery: float = 0.35

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

func _ready():
	if _health and _health.has_signal("health_depleted") and not _health.health_depleted.is_connected(_on_health_depleted):
		_health.health_depleted.connect(_on_health_depleted)
	if _hurtbox and _hurtbox.has_signal("recieved_damage") and not _hurtbox.recieved_damage.is_connected(_on_recieved_damage):
		_hurtbox.recieved_damage.connect(_on_recieved_damage)

	# Default: disable hitbox until active window
	_set_hitbox_active(false)
	# Try to resolve player reference
	_player = _find_player()

	# Hook Actionable (if present) to activate this enemy when the player enters it
	var actionable: Area2D = get_node_or_null("Actionable") as Area2D
	if actionable and not actionable.is_connected("body_entered", Callable(self, "_on_actionable_body_entered")):
		actionable.connect("body_entered", Callable(self, "_on_actionable_body_entered"))

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Gate movement and gravity until activated by Actionable area
	if not _activated:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_facing()
		_update_animation()
		return

	# gravity (only after activation)
	if not is_on_floor():
		velocity.y += gravity * delta

	# reacquire player if needed
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
			# during attack we typically control x movement (dash/thrust) inside timers
			pass
		State.HURT:
			# simple brief stun: slide to stop
			velocity.x = move_toward(velocity.x, 0, 600 * delta)

	# cooldowns
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
	_change_state(State.ATTACK)
	_cooldown_timer = attack_cooldown
	# pick a pattern: 0 light, 1 heavy, 2 thrust. Bias based on distance
	var dist := _distance_to_player()
	var pattern := 0
	if dist < attack_range * 0.6:
		pattern = randi() % 2   # 0 or 1
	else:
		pattern = 2
	# windup
	velocity.x = 0
	_set_hitbox_active(false)
	if _sprite and _sprite.sprite_frames:
		var frames: SpriteFrames = _sprite.sprite_frames
		if frames.has_animation("NightBorneAtk"):
			_sprite.play("NightBorneAtk")
		elif frames.has_animation("Atk"):
			_sprite.play("Atk")
		elif frames.has_animation("Attack"):
			_sprite.play("Attack")

	# schedule active window and optional dash
	var dash_vel := Vector2.ZERO
	if pattern == 2:
		dash_vel.x = _direction * dash_speed
	await get_tree().create_timer(attack_windup).timeout
	# active frames
	if _hitbox:
		_hitbox.set("damage", attack_damage)
	_set_hitbox_active(true)
	if pattern == 2:
		velocity.x = dash_vel.x
	await get_tree().create_timer(attack_active).timeout
	_set_hitbox_active(false)
	# recovery
	velocity.x = 0
	await get_tree().create_timer(attack_recovery).timeout
	# possibly chain a quick light follow-up
	if pattern == 0 and randf() < 0.35 and _player and _distance_to_player() <= attack_range * 1.1:
		_cooldown_timer = max(_cooldown_timer, 0.25)
		_start_attack()
		return
	_change_state(State.Run)

func _update_facing() -> void:
	if _sprite:
		_sprite.flip_h = _direction < 0

func _update_animation() -> void:
	if not _sprite:
		return
	if _state == State.DEAD:
		if _sprite.animation != "NightBorneDeath":
			_sprite.play("Death")
		return
	if _state == State.HURT:
		if _sprite.animation != "NightBorneTakeHit":
			_sprite.play("TakeHit")
		return
	if _state == State.ATTACK:
		return
	if abs(velocity.x) > 5 and is_on_floor():
		if _sprite.animation != "NightBorneRun":
			_sprite.play("Run")
	else:
		if _sprite.animation != "NightBorneIdle":
			_sprite.play("Idle")

func _on_recieved_damage(_dmg: int) -> void:
	if _state == State.DEAD:
		return
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
	_change_state(State.DEAD)
	_set_hitbox_active(false)
	velocity = Vector2.ZERO
	# Play death animation if available, otherwise free immediately
	if _anim_player and _anim_player.has_animation("NightBorneDeath"):
		_anim_player.play("NightBorneDeath")
		var anim: Animation = _anim_player.get_animation("NightBorneDeath")
		if anim:
			anim.loop_mode = Animation.LOOP_NONE
		if not _anim_player.animation_finished.is_connected(_on_death_animation_finished):
			_anim_player.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
	else:
		queue_free()

func _on_health_health_depleted() -> void:
	_on_health_depleted()

func _on_death_animation_finished(anim_name: String) -> void:
	if anim_name == "NightBorneDeath":
		queue_free()

func _change_state(s: State) -> void:
	_state = s

func _set_hitbox_active(active: bool) -> void:
	if _hitbox:
		_hitbox.set_deferred("monitoring", active)
	if _hitbox_shape:
		_hitbox_shape.set_deferred("disabled", not active)
	if active and _hitbox:
		# place slightly in front
		_hitbox.position.x = 16.0 * _direction

func _distance_to_player() -> float:
	if not _player:
		return INF
	return global_position.distance_to(_player.global_position)

func _find_player() -> CharacterBody2D:
	# 1) sibling named CharacterBody2D
	var p := get_parent()
	if p and p.has_node("CharacterBody2D"):
		var n = p.get_node("CharacterBody2D")
		if n is CharacterBody2D:
			return n
	# 2) nearest CharacterBody2D in scene (prefer one with common player fields)
	var best: CharacterBody2D = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group(""):
		pass # placeholder no-op
	# fallback: brute-force search
	var root := get_tree().current_scene
	if root:
		var stack := [root]
		while stack.size() > 0:
			var cur = stack.pop_back()
			for c in cur.get_children():
				stack.push_back(c)
				if c is CharacterBody2D and c != self:
					var d = global_position.distance_to(c.global_position)
					if d < best_dist:
						best = c
						best_dist = d
	return best

func _find_sprite() -> AnimatedSprite2D:
	# prefer child named Enemy, else first AnimatedSprite2D
	if has_node("Enemy") and get_node("Enemy") is AnimatedSprite2D:
		return get_node("Enemy")
	for c in get_children():
		if c is AnimatedSprite2D:
			return c
	return null

func _ensure_hitbox() -> Area2D:
	if has_node("HitBox") and get_node("HitBox") is Area2D:
		return get_node("HitBox")
	# create a simple HitBox if missing
	var hb := Area2D.new()
	hb.name = "HitBox"
	add_child(hb)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(22, 16)
	hb.add_child(shape)
	hb.set("damage", attack_damage)
	return hb
