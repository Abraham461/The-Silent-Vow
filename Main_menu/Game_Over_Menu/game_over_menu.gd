extends Control

@onready var restart_btn: Button = $ColorRect/Panel/Restart_btn
@onready var exit_btn: Button = $ColorRect/Panel/Exit_btn
@onready var button_click: AudioStreamPlayer = $Button_Click


var current_scene_path: String = ""

func _ready() -> void:
	restart_btn.pressed.connect(_on_restart_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

func set_restart_scene(path: String) -> void:
	current_scene_path = path



func _on_restart_pressed() -> void:
	button_click.play()
	if current_scene_path != "":
		get_tree().change_scene_to_file(current_scene_path)


func _on_exit_pressed() -> void:
	button_click.play()
	get_tree().change_scene_to_file("res://Main_menu/menu/Main_Menu.tscn") 
