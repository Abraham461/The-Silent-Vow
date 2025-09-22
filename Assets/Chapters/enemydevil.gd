extends CharacterBody2D

# nodes
@onready var devilanim: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: Area2D = $AnimatedSprite2D/HitBox   # assuming HitBox is an Area2D
@onready var health: Health = $Health   # assuming your Health node is a child

# state
var devildeath := false

# CONFIGURABLE:
# Names of animations that should trigger hitbox activation (e.g. "attack", "bite")
@export var attack_animations: Array = ["AttackEffect"]
# Frames to activate the hitbox on. Default is 1-based [4,7] as you requested.
# If you prefer to use 0-based frames (Godot internal), set use_zero_index = true.
@export var active_frames: Array = [4, 7]
@export var use_zero_index: bool = false

# debug toggle
@export var debug_print: bool = false

func _ready() -> void:
	# ensure hitbox starts disabled
	_disable_hitbox_deferred()

	# connect health depleted
	if health and health.has_signal("health_depleted"):
		health.health_depleted.connect(_on_devil_health_health_depleted)

	# connect AnimatedSprite2D signals
	if animated_sprite_2d:
		animated_sprite_2d.frame_changed.connect(_on_frame_changed)
		animated_sprite_2d.animation_changed.connect(_on_animation_changed)
		animated_sprite_2d.animation_finished.connect(_on_animation_finished)

#func _on_devil_health_health_depleted() -> void:

func _on_devil_health_health_depleted() -> void:
	if devildeath:
		return
	devildeath = true
	if debug_print: print("Signal received: health depleted")
	devilanim.play("devildeath")
	# wait for animation to finish then free
	await devilanim.animation_finished
	queue_free()

func _on_animation_changed(old_anim: StringName, new_anim: StringName) -> void:
	# When animation switches, ensure hitbox is off unless new anim is in attack_animations
	if debug_print:
		print("Animation changed:", old_anim, "->", new_anim)
	# if new animation is not an attack animation, disable hitbox immediately
	if not attack_animations.has(new_anim):
		_disable_hitbox_deferred()
	# if it is an attack animation, we still only enable on configured frames via frame handler

func _on_animation_finished(anim_name: StringName) -> void:
	# disable when animation finishes to be safe
	_disable_hitbox_deferred()
	if debug_print: print("Animation finished:", anim_name)

func _on_frame_changed() -> void:
	# only run when playing an attack animation
	var anim_name := animated_sprite_2d.animation
	if not attack_animations.has(anim_name):
		_disable_hitbox_deferred()
		return

	# compute current frame in the same indexing as active_frames
	var current_frame_index := animated_sprite_2d.frame
	var current_frame_for_compare := current_frame_index
	if not use_zero_index:
		# convert to 1-based for comparison
		current_frame_for_compare = current_frame_index + 1

	# enable if current frame matches one of active_frames
	if active_frames.has(current_frame_for_compare):
		_enable_hitbox_deferred()
		if debug_print:
			print("HitBox ENABLED - anim:", anim_name, "frame:", current_frame_for_compare)
	else:
		_disable_hitbox_deferred()
		if debug_print:
			print("HitBox disabled - anim:", anim_name, "frame:", current_frame_for_compare)

# helper functions that toggle monitoring (safe during physics)
func _enable_hitbox_deferred() -> void:
	if hit_box:
		hit_box.set_deferred("monitoring", true)
		# optional: also set collision layer/mask or visibility if needed:
		# hit_box.set_deferred("visible", true)

func _disable_hitbox_deferred() -> void:
	if hit_box:
		hit_box.set_deferred("monitoring", false)
		# hit_box.set_deferred("visible", false)
