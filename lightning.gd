extends Node2D  # or whatever parent type
@onready var lightning: AnimatedSprite2D = $lightning


@onready var timer: Timer = Timer.new()

func _ready() -> void:
	if lightning.sprite_frames and lightning.sprite_frames.has_animation("lightningran"):
		lightning.sprite_frames.set_animation_loop("lightningran", false)

	lightning.visible = false

	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)

	# connect child's signal
	lightning.animation_finished.connect(_on_lightning_finished)

	_start_random_timer()


func _on_timer_timeout() -> void:
	lightning.visible = true
	lightning.play("lightningran")


func _on_lightning_finished() -> void:
	lightning.visible = false
	_start_random_timer()


func _start_random_timer() -> void:
	var wait_time = randf_range(10.0, 20.0)
	timer.start(wait_time)
