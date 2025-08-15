class_name GameLevel
extends Control

@onready var chapter_1: Button = $TextureRect/Chapter1
@onready var chapter_2: Button = $TextureRect/Chapter2
@onready var chapter_3: Button = $TextureRect/Chapter3
@onready var back_button: Button = $TextureRect/Back_Button



func _ready():
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	handle_signals()
	
	
func on_back_button_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://Main_menu/menu/Main_Menu.tscn")
	
func handle_signals() -> void:
	back_button.button_down.connect(on_back_button_pressed)
