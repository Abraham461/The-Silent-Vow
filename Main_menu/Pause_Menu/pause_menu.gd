extends Control

@onready var options: Button = $GridContainer/Options

var _is_paused: bool = false


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
	get_tree().quit()
