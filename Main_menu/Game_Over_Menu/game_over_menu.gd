extends Control


@onready var restart_btn: Button = $ColorRect/GridContainer/Restart_btn
@onready var exit_btn: Button = $ColorRect/GridContainer/Exit_btn
@onready var button_click: AudioStreamPlayer = $Button_Click



func _ready() -> void:
	restart_btn.pressed.connect(_on_restart_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)



func _on_restart_pressed() -> void:
	button_click.play()
	if Global.current_level_scene_path != "":
		get_tree().change_scene_to_file(Global.current_level_scene_path)
	else:
			push_warning("No level set in Global. Going back to the main menu")
			get_tree().change_scene_to_file("res://Main_menu/menu/Main_Menu.tscn")

func _on_exit_pressed() -> void:
	button_click.play()
	get_tree().change_scene_to_file("res://Main_menu/menu/Main_Menu.tscn") 
