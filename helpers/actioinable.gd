extends Area2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
var has_triggered := false

func action() -> void:
	if has_triggered:
		return
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)
	has_triggered = true
