# malrikHitBox.gd
class_name malrikHitBox
extends Area2D

# backing storage for damage (avoid recursive setter)
var _damage_internal: int = 20

# exported property (use inspector to change)
@export var damage: int = 20 : set = set_damage, get = get_damage

# horizontal offset magnitude (pixels). Positive number; side applied by sign.
@export var offset_x: float = 20.0

# group name that PlayerHurtBox registers with (default matches earlier examples)
@export var player_hurtbox_group: String = "player_hurtbox"

# if true, this HitBox will automatically emit when a body enters (body_entered)
# if false (recommended), call pulse() from the enemy at the attack frame
@export var auto_emit_on_enter: bool = false

# seconds between repeated hits on same target
@export var per_target_cooldown: float = 0.25

# enable debug prints
@export var debug: bool = false

# collision shape node (assumes child named CollisionShape2D)
@onready var collision_shape_2d: CollisionShape2D = get_node_or_null("CollisionShape2D")

signal hit_emitted(damage: int, pos: Vector2)

# runtime: last-hit ms per target instance id
var _last_hit_ms: Dictionary = {}

# store original collision shape local position so we can restore
var _collision_shape_orig_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# keep monitoring off by default when using pulse() (pulse will enable briefly)
	monitoring = auto_emit_on_enter

	# connect body_entered so auto_emit_on_enter works and for debug
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

	# remember original collision shape position
	if collision_shape_2d:
		_collision_shape_orig_pos = collision_shape_2d.position

	if debug:
		print("malrikHitBox ready. damage=", _damage_internal, "offset_x=", offset_x, "auto_emit=", auto_emit_on_enter)


# setter/getter (non-recursive)
func set_damage(v: int) -> void:
	_damage_internal = v

func get_damage() -> int:
	return _damage_internal


# Auto mode: called when something enters this Area2D
func _on_body_entered(body: Node) -> void:
	if not auto_emit_on_enter:
		return
	if not body:
		return
	# only accept nodes in the 'player' group (adjust if you use a different group)
	if body.is_in_group("player"):
		_try_emit_for_body(body)


# -------------------------
# Public API for direct control
# Set which side the collision shape sits on. 
# right == true => x = +offset_x
# right == false => x = -offset_x
func set_side(right: bool) -> void:
	if not collision_shape_2d:
		if debug: print("malrikHitBox.set_side: no CollisionShape2D found")
		return
	collision_shape_2d.position.x = (offset_x if right else -offset_x)
	if debug:
		print("malrikHitBox.set_side: right=", right, "collision_shape.x=", collision_shape_2d.position.x)


# Change the offset magnitude (keeps current sign on collision_shape)
func set_offset_x(value: float) -> void:
	offset_x = abs(value)
	# if collision_shape exists, reapply sign based on current x sign
	if collision_shape_2d:
		var sign = 1 if collision_shape_2d.position.x >= 0 else -1
		collision_shape_2d.position.x = sign * offset_x
	if debug:
		print("malrikHitBox.set_offset_x ->", offset_x)


# Convenience: set side and pulse in one call (call_deferred from enemy)
func pulse_side(right: bool) -> void:
	set_side(right)
	call_deferred("pulse")


# -------------------------
# Recommended: call this from the enemy at the exact attack frame (use animation call method or frame callback).
# Example: in enemy sprite frame handler -> hit_box.call_deferred("pulse_side", facing_right)
func pulse() -> void:
	# enable monitoring briefly so get_overlapping_bodies() returns correct list
	var was_monitoring := monitoring
	monitoring = true

	var handled_any: bool = false
	# collect overlapping bodies (Area2D method)
	if has_method("get_overlapping_bodies"):
		var bodies := get_overlapping_bodies()
		for b in bodies:
			if b and b.is_in_group("player"):
				_try_emit_for_body(b)
				handled_any = true

	# restore previous monitoring state
	monitoring = was_monitoring

	# fallback: if no overlapping players found, broadcast to player_hurtbox group
	if not handled_any:
		if debug:
			print("malrikHitBox.pulse: no overlapping player found, broadcasting to group:", player_hurtbox_group)
		get_tree().call_group(player_hurtbox_group, "receive_damage", _damage_internal, global_position)
		emit_signal("hit_emitted", _damage_internal, global_position)


# internal helper — emits damage for a specific body while honoring cooldown
func _try_emit_for_body(body: Node) -> void:
	if not body:
		return
	var id := body.get_instance_id()
	var now_ms := int(Time.get_ticks_msec())
	if _last_hit_ms.has(id):
		var elapsed := now_ms - int(_last_hit_ms[id])
		if elapsed < int(per_target_cooldown * 1000.0):
			if debug:
				print("malrikHitBox: cooldown for target", id, "elapsed", elapsed, "ms")
			return
	_last_hit_ms[id] = now_ms

	if debug:
		print("malrikHitBox: applying", _damage_internal, "to", body, "at", global_position)

	# Prefer calling a direct method on the collided body if present
	if body.has_method("receive_damage"):
		# call_deferred so this runs safely outside of physics callback
		body.call_deferred("receive_damage", _damage_internal, global_position)
	else:
		# otherwise broadcast to player hurtboxes in the group
		get_tree().call_group(player_hurtbox_group, "receive_damage", _damage_internal, global_position)

	emit_signal("hit_emitted", _damage_internal, global_position)


# optional utility
func clear_cooldowns() -> void:
	_last_hit_ms.clear()
	if debug:
		print("malrikHitBox: cooldowns cleared")


# Restore collision shape to original saved position (optional convenience)
func restore_collision_shape_position() -> void:
	if collision_shape_2d:
		collision_shape_2d.position = _collision_shape_orig_pos
		if debug:
			print("malrikHitBox: collision shape restored to", _collision_shape_orig_pos)
