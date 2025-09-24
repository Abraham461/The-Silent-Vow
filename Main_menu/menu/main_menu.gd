class_name MainMenu
extends Control
@onready var start_button: Button = $Panel/Start_Button
@onready var options_button: Button = $Panel/Options_Button
@onready var exit_button: Button = $Panel/Exit_Button


func _ready():
	Chapter3Finaltheme.stop()
	#AudioPlayer.play_music_level()
	handle_connection_signals()

func _on_start_button_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://Main_menu/menu/Game_level.tscn")
	
func _on_options_button_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://Main_menu/Options_menu/options_menu.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()


func handle_connection_signals() -> void:
	start_button.button_down.connect(_on_start_button_pressed)
	options_button.button_down.connect(_on_options_button_pressed)
	exit_button.button_down.connect(_on_exit_button_pressed)
