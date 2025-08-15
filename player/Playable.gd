extends Node2D

@onready var player = $Player

var scene_changed := false
const NEXT_SCENE := "res://more cutscene/cuts_second.tscn"

func _ready():
	# connect the ExitRight Area2D if present
	if has_node("ExitRight"):
		var exit_area = $ExitRight
		exit_area.connect("body_entered", Callable(self, "_on_exit_area_body_entered"))
	else:
		push_warning("ExitRight Area2D not found. Add an Area2D named 'ExitRight' as a child of Playable.")

func _on_exit_area_body_entered(body):
	if scene_changed:
		return

	# Prefer group check. Add the Player node to the "player" group in the editor.
	if body.is_in_group("player") or body.name == "Player":
		scene_changed = true
		get_tree().change_scene_to_file(NEXT_SCENE)
