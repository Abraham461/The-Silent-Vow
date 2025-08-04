extends ProgressBar

@export var player: CharacterBody2D

func _ready():
	if player != null and player.has_signal("healthChanged"):
		player.healthChanged.connect(update)
		update()
	else:
		push_error("Player not assigned or signal missing!")


func update():
	value = player.currentHealth * 100/ player.maxHealth
