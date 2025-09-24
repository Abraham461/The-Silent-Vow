extends Node2D
@onready var scenechange_gate: AnimatedSprite2D = $scenechangeGate

func _ready():
	scenechange_gate.play("default")
	Chapter3Theme._play_music_level()
