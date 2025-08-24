extends CharacterBody2D

@onready var devilanim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: Health = $Health   # assuming your Health node is a child
var devildeath := false
func _ready() -> void:
	# Connect the signal
	health.health_depleted.connect(_on_health_health_depleted)

func _on_health_health_depleted() -> void:
	if devildeath:
		return
	devildeath = true
	print("Signal received")
	devilanim.play("devildeath")
	print("Now playing: ", devilanim.animation)
	print("Total frames: ", devilanim.sprite_frames.get_frame_count("devildeath"))
	print("Current frame: ", devilanim.frame)
	print("Is playing: ", devilanim.is_playing())
	await devilanim.animation_finished
	queue_free()
	
