#extends Node
#
#var coins = 0
#
#func _process(_delta: float) -> void:
	#$"GUI/CoinsValue".text = str(coins)
	#
#@onready var gui = $GUI

extends Node

const TARGET_SCENE = "res://Assets/Chapters/chapter_2_1.tscn"

var coins = 0
@onready var gui = $GUI
@onready var coins_label = $"GUI/CoinsValue"

func _ready():
	if gui == null:
		print("GUI node not found!")
		return

	if get_tree().current_scene.scene_file_path == TARGET_SCENE:
		gui.show()
	else:
		gui.hide()

func _process(_delta: float) -> void:
	$"GUI/CoinsValue".text = str(coins)
