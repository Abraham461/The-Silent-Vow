extends AnimatedSprite2D

@onready var timer: Timer = Timer.new()

func _ready() -> void:
	# ensure the "lightning" animation does NOT loop
	if sprite_frames and sprite_frames.has_animation("lightningran"):
		sprite_frames.set_animation_loop("lightningran", false)

	# invisible until play
	visible = false

	# timer setup
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)

	# connect the finished signal once
	animation_finished.connect(_on_lightning_finished)

	_start_random_timer()


func _on_timer_timeout() -> void:
	visible = true
	play("lightningran")


func _on_lightning_finished() -> void:
	visible = false
	_start_random_timer()


func _start_random_timer() -> void:
	var wait_time = randf_range(300.0, 600.0) # 300s = 5min, 600s = 10min
	timer.start(wait_time)
