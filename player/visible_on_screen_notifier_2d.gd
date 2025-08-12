extends VisibleOnScreenNotifier2D

var player_body: StaticBody2D
var scene_changed := false
const NEXT_SCENE := "res://more cutscene/cuts_second.tscn"

func _ready():
	# go up twice: from notifier → Player → Playable
	var playable := get_parent().get_parent()
	player_body = playable.get_node("StaticBody2D")

	connect("screen_exited", Callable(self, "_on_player_screen_exited"))

func _on_player_screen_exited():
	if scene_changed:
		return
	scene_changed = true
	get_tree().change_scene_to_file(NEXT_SCENE)
