class_name GameLevel
extends Control

@onready var chapter_1: Button = $TextureRect/Chapter1
@onready var chapter_2: Button = $TextureRect/Chapter2
@onready var chapter_3: Button = $TextureRect/Chapter3
@onready var chapter_4: Button = $TextureRect/Chapter4
@onready var back_button: Button = $TextureRect/Back_Button


func _ready():
	handle_signals()

func on_chapter_1_button_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished 
	get_tree().change_scene_to_file("res://Chapter_1_cutscene/intro_cutscene.tscn")

func on_chapter_2_button_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished 
	get_tree().change_scene_to_file("res://more cutscene/cuts_second.tscn")
	
func on_chapter_3_button_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished 
	get_tree().change_scene_to_file("res://more cutscene/cutscene_third.tscn")
	
func on_chapter_4_button_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://more cutscene/cutscene_four.tscn")
	
func on_back_button_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://Main_menu/menu/Main_Menu.tscn")
	
func handle_signals() -> void:
	back_button.button_down.connect(on_back_button_pressed)
	chapter_1.button_down.connect(on_chapter_1_button_pressed)
	chapter_2.button_down.connect(on_chapter_2_button_pressed)
	chapter_3.button_down.connect(on_chapter_3_button_pressed)
	chapter_4.button_down.connect(on_chapter_4_button_pressed)
