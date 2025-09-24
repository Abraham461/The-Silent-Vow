class_name OptionsMenu
extends Control

@onready var options_menu: OptionsMenu = $"."
@onready var back_button: Button = $TextureRect/Back_Button
@onready var click_button: AudioStreamPlayer = $Click_Button



func _ready():
	set_process(false)
	back_button.button_down.connect(on_back_pressed)
	
	
	
func on_back_pressed() -> void:
	click_button.play()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://Main_menu/menu/Main_Menu.tscn")
