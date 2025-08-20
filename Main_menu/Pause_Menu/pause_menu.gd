extends Control

@onready var resume: Button = $ColorRect/GridContainer/Resume
@onready var exit: Button = $ColorRect/GridContainer/Exit
@onready var options: Button = $ColorRect/GridContainer/Options


var _is_paused: bool = false


func _ready() -> void:
	#process_mode = Node.PROCESS_MODE_ALWAYS
	#visible = false
	resume.pressed.connect(_on_resume_pressed)
	exit.pressed.connect(_on_exit_pressed)
	options.pressed.connect(_on_options_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(!_is_paused)

func set_paused(value: bool) -> void:
	_is_paused = value
	get_tree().paused = _is_paused
	visible = _is_paused

func _on_resume_pressed() -> void:
	set_paused(false)


func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Main_menu/menu/Game_level.tscn")


func _on_options_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Main_menu/Options_menu/options_menu.tscn")
