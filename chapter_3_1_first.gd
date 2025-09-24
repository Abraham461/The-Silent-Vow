extends Node2D
@onready var boss: AnimatedSprite2D = $CharacterBody2D2/AnimatedSprite2D
@onready var player: AnimatedSprite2D = $CharacterBody2D/AnimatedSprite2D
@onready var princess: AnimatedSprite2D = $Princess/AnimatedSprite2D
@onready var princessbody: CharacterBody2D = $Princess

const TARGET_POS := Vector2(-450, 348)
const WALK_SPEED := 80.0  # pixels per second, adjust to taste

func _ready() -> void:
	Chapter3Bosstheme.stop()
	Chapter3Finaltheme._play_music_level()
	player.play("ch3death")
	# start walk animation
	princess.play("pricesswalk")

	# if already at (or very close to) target, just go idle
	var dist := princessbody.global_position.distance_to(TARGET_POS)
	if dist < 1.0:
		princess.play("princessidle")
		return

	# calculate duration from distance and speed
	var duration := dist / WALK_SPEED

	# create a tween to move the body to the global target, then call arrival handler
	var tween := create_tween()
	tween.tween_property(princessbody, "global_position", TARGET_POS, duration)\
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(Callable(self, "_on_princess_arrived"))

func _on_princess_arrived() -> void:
	# ensure exact final position and switch animation
	princessbody.global_position = TARGET_POS
	princess.play("princessidle")
