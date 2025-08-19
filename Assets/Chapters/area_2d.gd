extends Area2D

@export var dialogue_resource: DialogueResource   # drag your .dialogue file here
@export var auto_trigger: bool = true             # triggers automatically when player enters

func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("CharacterBody2D") and dialogue_resource:
		if auto_trigger:
			DialogueManager.show_dialogue(dialogue_resource)
		else:
			# optional: wait for player input (like "press E to talk")
			pass
