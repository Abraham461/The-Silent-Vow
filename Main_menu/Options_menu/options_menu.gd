class_name OptionsMenu
extends Control

@onready var options_menu: OptionsMenu = $"."
@onready var exit_button: Button = $TextureRect/Exit_Button
@onready var back_button: Button = $TextureRect/Back_Button



func _ready():
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)
	back_button.button_down.connect(on_back_pressed)
	
func on_exit_pressed() -> void:
	get_tree().quit()
	
func on_back_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://Main_menu/menu/Main_Menu.tscn")
	


	
