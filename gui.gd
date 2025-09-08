extends CanvasLayer

#@onready var gui = $GUI
#
#func _ready() -> void:
	## Safely check if GUI node exists
	#if gui == null:
		#print("GUI node not found!")
		#return
#
	## Check if current scene is loaded and named "chapter_2_1"
	#var current_scene = get_tree().current_scene
	#if current_scene != null and current_scene.name == "chapter_2_1":
		#gui.show()
	#else:
		#gui.hide()
